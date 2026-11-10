#!/bin/sh
set -eu

CONF=/etc/modprobe.d/99-r36s-rtl8188fu-stability.conf
STATE_DIR=/var/lib/r36s-rtl8188fu-stability
STATE=$STATE_DIR/original-state
MARKER="# Managed by r36s-rtl8188fu-stability"

fail() {
    echo "Erro: $*" >&2
    exit 1
}

[ "$(id -u)" -eq 0 ] || fail "execute como root: sudo sh remove.sh"

if [ -f "$STATE" ]; then
    profile_uuid=$(sed -n '1p' "$STATE")
    original_powersave=$(sed -n '2p' "$STATE")
    if [ "$profile_uuid" != "-" ] && [ "$original_powersave" != "-" ]; then
        command -v nmcli >/dev/null 2>&1 || fail "nmcli necessário para restaurar o perfil $profile_uuid"
        nmcli connection modify uuid "$profile_uuid" 802-11-wireless.powersave "$original_powersave"
    fi
fi

if [ -e "$CONF" ]; then
    grep -Fqx "$MARKER" "$CONF" || fail "$CONF não tem o marcador do projeto; não será removido"
    rm -f "$CONF"
fi

rm -f "$STATE"
rmdir "$STATE_DIR" 2>/dev/null || true
echo "Configuração removida; reconecte o perfil Wi-Fi ou reinicie para aplicar a reversão."
