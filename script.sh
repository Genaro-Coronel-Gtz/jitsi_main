#!/bin/bash

#cp env.example .env
#mkdir -p jitsi-meet-cfg/{web/letsencrypt,transcripts,prosody/config,prosody/prosody-plugins-custom,jicofo,jvb,jigasi,jibri}
# para desactivar el mensaje de descargar app en movil
docker-compose up -d
sleep 60
docker-compose stop

sudo echo "config.disableDeepLinking = true;" > jitsi-meet-cfg/web/custom-config.js
# para registrar mas servidores stun
sudo echo "config.p2p.stunServers = [{urls: 'stun:meet-jit-si-turnrelay.jitsi.net:443'},{urls: 'stun:stun.l.google.com:19302'},{urls: 'stun:stun1.l.google.com:19302'},{urls: 'stun:stun2.l.google.com:19302'},{urls: 'stun:stun3.l.google.com:19302'},{urls: 'stun:stun4.l.google.com:19302'}];" >> jitsi-meet-cfg/web/custom-config.js
# para desactivar opciones no deseadas
sudo echo "config.toolbarButtons = ['microphone', 'camera', 'desktop', 'hangup', 'chat', 'select-background', 'videobackgroundblur'];" >> jitsi-meet-cfg/web/custom-config.js

# para limitar a una sola conexion
sudo sed -i '1imuc_max_occupants=2\nmuc_access_whitelist= {\n    "focus@auth.meet.jitsi",\n    "jvb@auth.meet.jitsi"\n}' jitsi-meet-cfg/prosody/config/conf.d/jitsi-meet.cfg.lua
sudo sed -i '114i\ \ \ \ \ \ \ \ "muc_max_occupants";\n' jitsi-meet-cfg/prosody/config/conf.d/jitsi-meet.cfg.lua
# hacemos inmutable jitsi-meet.cfg.lua para que no se pierda la configuracion cada que se reinicien los contenedores
# configurar redireccion al terminar la llamada
#sed -i -e '$alocation = / {\n    return 302 https://www.nimbo-x.com/teleconsulta-completada;\n}\n' meet.conf
# hacemos inmutable meet.conf para que no se pierda la configuracion cada que se reinicien los contenedores


#chattr +i /jitsi-meet-cfg/prosody/config/conf.d/jitsi-meet.cfg.lua
#chattr +i meet.conf

