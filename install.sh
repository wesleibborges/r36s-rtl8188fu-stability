#!/bin/sh
set -eu

MODULE=8188fu
DRIVER=rtl8188fu
USB_VENDOR=0bda
USB_PRODUCT=f179
CONF=/etc/modprobe.d/99-r36s-rtl8188fu-stability.conf
STATE_DIR=/var/lib/r36s-rtl8188fu-stability
STATE=$STATE_DIR/original-state
MARKER="# Managed by r36s-rtl8188fu-stability"

fail() {
    echo "Erro: $*" >&2
    exit 1
}

[ "$(id -u)" -eq 0 ] || fail "execute como root: sudo sh install.sh"
[ -d "/sys/module/$MODULE" ] || fail "módulo $MODULE não está carregado"

usb_found=0
for usb in /sys/bus/usb/devices/*; do
    [ -r "$usb/idVendor" ] && [ -r "$usb/idProduct" ] || continue
    [ "$(cat "$usb/idVendor")" = "$USB_VENDOR" ] || continue
    [ "$(cat "$usb/idProduct")" = "$USB_PRODUCT" ] || continue
    usb_found=1
    break
done
[ "$usb_found" -eq 1 ] || fail "adaptador USB $USB_VENDOR:$USB_PRODUCT não encontrado; nenhuma alteração feita"

iface=
for net in /sys/class/net/*; do
    [ -e "$net/device/driver" ] || continue
    bound_driver=$(basename "$(readlink -f "$net/device/driver")")
    if [ "$bound_driver" = "$DRIVER" ]; then
        iface=${net##*/}
        break
    fi
done
[ -n "$iface" ] || fail "adaptador $USB_VENDOR:$USB_PRODUCT sem interface ligada ao driver $DRIVER"

if [ -e "$CONF" ] && ! grep -Fqx "$MARKER" "$CONF"; then
    fail "$CONF já existe e não pertence a este projeto; não será sobrescrito"
fi

mkdir -p "$STATE_DIR" /etc/modprobe.d
chmod 700 "$STATE_DIR"

if [ ! -f "$STATE" ]; then
    profile_uuid=-
    original_powersave=-
    if command -v nmcli >/dev/null 2>&1; then
        profile_uuid=$(nmcli -g GENERAL.CON-UUID device show "$iface" 2>/dev/null | sed -n '1p' || true)
        case "$profile_uuid" in
            ""|"--"|"unknown") profile_uuid=- ;;
        esac
        if [ "$profile_uuid" != "-" ]; then
            original_powersave=$(nmcli -g 802-11-wireless.powersave connection show uuid "$profile_uuid" 2>/dev/null | sed -n '1p' || true)
            case "$original_powersave" in
                ""|"--") profile_uuid=-; original_powersave=- ;;
            esac
        fi
    fi
    state_tmp="$STATE.tmp.$$"
    (umask 077; printf '%s\n%s\n' "$profile_uuid" "$original_powersave" > "$state_tmp")
    mv "$state_tmp" "$STATE"
fi

profile_uuid=$(sed -n '1p' "$STATE")
if [ "$profile_uuid" != "-" ]; then
    command -v nmcli >/dev/null 2>&1 || fail "nmcli não está disponível para ajustar o perfil salvo"
    nmcli connection modify uuid "$profile_uuid" 802-11-wireless.powersave 2
fi

conf_tmp="$CONF.tmp.$$"
{
    printf '%s\n' "$MARKER"
    printf '%s\n' 'options 8188fu rtw_power_mgnt=0 rtw_enusbss=0 rtw_ips_mode=0'
} > "$conf_tmp"
chmod 644 "$conf_tmp"
mv "$conf_tmp" "$CONF"

echo "Configuração salva para o driver $DRIVER, interface $iface."
if [ "$profile_uuid" != "-" ]; then
    echo "Power-save desativado no perfil NetworkManager $profile_uuid."
    echo "Reconecte esse perfil para aplicar a mudança sem reiniciar."
else
    echo "Nenhum perfil NetworkManager ativo foi encontrado; o ajuste do driver ficou instalado."
fi
echo "Reinicie o console para carregar as opções do módulo."
echo "Para reverter: sudo sh remove.sh"
