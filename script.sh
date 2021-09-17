#!/bin/bash

#Ejecutar como super usuario (root)

USER=ec2-user
PUBLIC_IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)


yum update -y

# Instalar Docker
yum install -y docker
service docker start
usermod -a -G docker $USER
chkconfig docker on

# Instalar Git
yum install -y git

# Instalar Docker-Compose
sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Descargar repo modificado de jitsi
wget https://github.com/Genaro-Coronel-Gtz/jitsi_main/archive/refs/heads/main.zip -P /home/$USER
unzip /home/$USER/main.zip -d /home/$USER
mv /home/$USER/jitsi_main-main /home/$USER/jitsi_main
cd /home/$USER/jitsi_main

cp env.example .env

# Setear configuraciones para poder utilizar mas instancias de jitsi video bridge
sed -i "s/DOCKER_HOST_ADDRESS=192.168.0.10/DOCKER_HOST_ADDRESS=$PUBLIC_IP/" .env
sed -i "s/XMPP_SERVER=192.168.0.10/XMPP_SERVER=$PRIVATE_IP/" .env
sed -i "s#XMPP_BOSH_URL_BASE=http://192.168.0.10:5280#XMPP_BOSH_URL_BASE=http://$PRIVATE_IP:5280#g" .env


mkdir -p /home/$USER/jitsi_main/jitsi-meet-cfg/{web/letsencrypt,transcripts,prosody/config,prosody/prosody-plugins-custom,jicofo,jvb,jigasi,jibri}

#Setear ip publica e ip privada en xmpp_Server, docker_host ,xmpp_bosh
./gen-passwords.sh

sudo -u $USER /usr/local/bin/docker-compose pull
sudo -u $USER /usr/local/bin/docker-compose up -d
sleep 60
sudo -u $USER /usr/local/bin/docker-compose stop


echo "config.disableDeepLinking = true;" > jitsi-meet-cfg/web/custom-config.js
# para registrar mas servidores stun
echo "config.p2p.stunServers = [{urls: 'stun:meet-jit-si-turnrelay.jitsi.net:443'},{urls: 'stun:stun.l.google.com:19302'},{urls: 'stun:stun1.l.google.com:19302'},{urls: 'stun:stun2.l.google.com:19302'},{urls: 'stun:stun3.l.google.com:19302'},{urls: 'stun:stun4.l.google.com:19302'}];" >> jitsi-meet-cfg/web/custom-config.js
# para desactivar opciones no deseadas
echo "config.toolbarButtons = ['microphone', 'camera', 'desktop', 'hangup', 'chat', 'select-background', 'videobackgroundblur'];" >> jitsi-meet-cfg/web/custom-config.js

# para limitar a una sola conexion
sed -i '1imuc_max_occupants=2\nmuc_access_whitelist= {\n    "focus@auth.meet.jitsi",\n    "jvb@auth.meet.jitsi"\n}' jitsi-meet-cfg/prosody/config/conf.d/jitsi-meet.cfg.lua
sed -i '114i\ \ \ \ \ \ \ \ "muc_max_occupants";\n' jitsi-meet-cfg/prosody/config/conf.d/jitsi-meet.cfg.lua
# configurar redireccion al terminar la llamada
sed -i -e '$alocation = / {\n    return 302 https://www.nimbo-x.com/teleconsulta-completada;\n}\n' jitsi-meet-cfg/web/nginx/meet.conf

# Hacemos inmutable meet.conf para que no se pierda la configuracion cada que se reinicien los contenedores

chattr +i /home/$USER/jitsi_main/jitsi-meet-cfg/prosody/config/conf.d/jitsi-meet.cfg.lua
chattr +i /home/$USER/jitsi_main/jitsi-meet-cfg/web/nginx/meet.conf

# Levantar los containers de jitsi
cd /home/$USER/jitsi_main
sudo -u $USER /usr/local/bin/docker-compose start

# Eliminar el archivo zip del repo de jitsi_main
rm /home/$USER/main.zip
