# R36S RTL8188FTV Wi-Fi Stability

Configuração reversível para adaptadores USB Realtek RTL8188FTV (`0bda:f179`) no R36S/dArkOS com o módulo `8188fu` e NetworkManager.

O projeto **não substitui nem recompila o driver**. Ele aplica opções documentadas pelo projeto upstream do `rtl8188fu` e desativa o power-save no perfil Wi-Fi ativo. A instalação é específica para o adaptador confirmado neste console.

## Evidência no aparelho

- Adaptador USB: Realtek `0bda:f179`, nome exibido `802.11n`.
- Driver: `rtl8188fu`; módulo `8188fu`, versão `v5.15.3-6-g1a2e952f9.20230217`.
- Console: kernel `4.4.189`, dArkOS4Clone, interface `wlan0`.
- Antes: `rtw_power_mgnt=2`, `rtw_enusbss=0`, `rtw_ips_mode=1`; perfil NetworkManager em `default`.
- Em amostras do PC ao console, a perda observada foi 20% antes, 15% após apenas mudar parâmetros em memória, 5% numa amostra curta após desativar power-save no perfil e reconectar, e 13% num teste posterior de 120 pacotes. A latência média da amostra longa foi 28 ms. O resultado é inconclusivo; o patch deve ser tratado como ajuste experimental, não como correção comprovada.
- Em teste isolado feito pelo próprio console para o gateway, foram recebidas 120/120 respostas (0% de perda; média 16,3 ms; máximo 145,9 ms). Isso indica que o enlace console→roteador estava estável durante esse recorte; não prova estabilidade em tráfego bidirecional nem elimina falhas intermitentes.
- O repositório do próprio usuário [`ArkOS-G80CA-MB`](https://github.com/wesleibborges/ArkOS-G80CA-MB) relata que a porta OTG pode não fornecer energia suficiente a alguns adaptadores. Economia de energia desativada aumenta o consumo do rádio; se houver resets USB, quedas do adaptador ou piora, desfaça o patch e teste um hub OTG alimentado.

Registro completo e limites: [`evidencias/diagnostico_2026-11-10.md`](evidencias/diagnostico_2026-11-10.md).

## Instalar

Copie o projeto para o console (ou execute a partir de um diretório montado) e rode como root:

```sh
sudo sh install.sh
```

O instalador verifica USB ID e driver antes de alterar arquivos. Ele cria uma configuração própria em `/etc/modprobe.d/`, grava o valor anterior do perfil NetworkManager em `/var/lib/r36s-rtl8188fu-stability/` e define `802-11-wireless.powersave=2` apenas para o perfil Wi-Fi ativo. Não armazena SSID, senha, MAC ou BSSID.

O perfil precisa ser reconectado para aplicar a opção do NetworkManager. Para aplicar as opções do módulo, reinicie o console. O instalador não interrompe a conexão SSH e não reinicia o aparelho sozinho.

## Remover / reverter

```sh
sudo sh remove.sh
```

O removedor apaga apenas a configuração criada por este projeto e restaura o valor anterior de power-save no perfil salvo. Reconecte o perfil ou reinicie para aplicar a reversão.

## Configuração aplicada

[`patches/8188fu-r36s-stability.conf`](patches/8188fu-r36s-stability.conf):

```conf
options 8188fu rtw_power_mgnt=0 rtw_enusbss=0 rtw_ips_mode=0
```

Os três parâmetros seguem as instruções do mantenedor do driver. O valor NetworkManager `2` significa “desativar economia de energia Wi-Fi”, conforme a documentação oficial.

## Referências consultadas

- [kelebek333/rtl8188fu — configuração para desativar power management](https://github.com/kelebek333/rtl8188fu#configuration)
- [XNLFutureTechnologies/R36_RTL8188FU — fork específico para ArkOS/R36S](https://github.com/XNLFutureTechnologies/R36_RTL8188FU) — seu README alerta que o fork ainda está em preparação; este projeto não copia nem instala seu código.
- [NetworkManager — propriedade `802-11-wireless.powersave`](https://networkmanager.dev/docs/api/latest/settings-802-11-wireless.html)
- [ArkOS-G80CA-MB — observação de energia insuficiente na OTG](https://github.com/wesleibborges/ArkOS-G80CA-MB)

O projeto contém somente scripts, configuração e documentação; nenhum driver, firmware, ROM, save ou outro asset é distribuído.
