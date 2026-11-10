# Diagnóstico Wi-Fi R36S — RTL8188FTV — 10/11/2026

## Ambiente identificado

- Sistema: dArkOS4Clone, Linux `4.4.189`, Cortex-A35.
- Interface: `wlan0`, vinculada ao driver USB `rtl8188fu`.
- Adaptador: Realtek USB `0bda:f179`, produto exibido como `802.11n`.
- Módulo carregado: `8188fu`, versão `v5.15.3-6-g1a2e952f9.20230217`.
- Gerenciamento: NetworkManager + `wpa_supplicant`.
- Antes do teste: `rtw_power_mgnt=2`, `rtw_enusbss=0`, `rtw_ips_mode=1`; `802-11-wireless.powersave=default`.
- A interface reportava qualidade 95–96/100 e zero RX/TX errors no recorte; não foi encontrado processo Body Harvest ativo durante as amostras.

## Indício e testes

O `dmesg` registrava transições repetidas para `WIFI-TRAFFIC_IDLE` / firmware LPS. O upstream `kelebek333/rtl8188fu` recomenda `rtw_power_mgnt=0`, `rtw_enusbss=0`, `rtw_ips_mode=0`; este projeto também usa o valor NetworkManager `2`, que significa desativar power-save Wi-Fi.

Ping Windows → console (40 pacotes por amostra; mesmo AP; valores medidos neste aparelho):

| Estado durante a amostra | Recebidos | Perda | Média | Máximo |
|---|---:|---:|---:|---:|
| Inicial, driver e NetworkManager em padrão | 32/40 | 20% | 136 ms | 2194 ms |
| Parâmetros do módulo escritos em sysfs para `0`, sem reconectar | 34/40 | 15% | 51 ms | 218 ms |
| Perfil NetworkManager alterado para `powersave=2` e reconectado | 38/40 | 5% | 29 ms | 180 ms |
| Perfil em `powersave=2`, teste longo | 104/120 | 13% | 28 ms | 198 ms |

Os parâmetros sysfs de execução não impediram, por si sós, os logs LPS do driver; portanto a configuração do módulo deve ser carregada em uma reativação/reinicialização para validar seu efeito. A amostra curta após reconexão foi melhor, mas o teste de 120 pacotes ainda perdeu 13%; não há evidência suficiente para declarar o problema resolvido. A perda pode envolver driver, rádio/AP ou alimentação OTG.

Como controle adicional, o próprio console enviou 120 pings ao gateway `192.168.0.1`: 120 recebidos, 0% de perda, RTT médio 16,339 ms, máximo 145,866 ms. Esse teste foi unidirecional iniciado no console e confirma resposta do roteador nesse intervalo; não identifica sozinho a origem da perda no teste PC→console.

## Patch

`install.sh` verifica `0bda:f179` e o driver antes de alterar o sistema. Cria um arquivo exclusivo em `/etc/modprobe.d/`, guarda apenas o UUID do perfil e o valor anterior de power-save (não guarda SSID, chave, MAC nem BSSID) e aplica `802-11-wireless.powersave=2`. Não desliga a conexão nem reinicia o console automaticamente.

`remove.sh` restaura o valor salvo e remove apenas o arquivo com o marcador do projeto. Após instalar/remover, reconecte o perfil Wi-Fi; reinicie para carregar/descarregar as opções do módulo.

## Limite físico

O repositório do usuário [`ArkOS-G80CA-MB`](https://github.com/wesleibborges/ArkOS-G80CA-MB) registra que o OTG de certos clones não fornece energia suficiente para alguns adaptadores. Power-save desativado aumenta o consumo do rádio; se houver resets USB ou o dongle desaparecer, reverta e use um hub OTG com alimentação adequada. Software não corrige uma linha de 5 V insuficiente.
