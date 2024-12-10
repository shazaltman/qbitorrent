#!/bin/bash

# Atualizar pacotes e instalar dependências essenciais
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl apt-transport-https ca-certificates software-properties-common openssh-server build-essential qt5-qmake qtbase5-dev libqt5svg5-dev libboost-dev libboost-system-dev libboost-filesystem-dev

# Verificar se o serviço SSH está em execução e habilitá-lo
sudo systemctl enable --now ssh
sudo systemctl status ssh

# Habilitar login do root via SSH
echo "PermitRootLogin yes" | sudo tee -a /etc/ssh/sshd_config > /dev/null
sudo systemctl restart ssh

# Clonar o repositório qbittorrent-nox
git clone https://github.com/shazaltman/qbittorrent-nox.git
cd qbittorrent-nox

# Construir e instalar o qbittorrent-nox
qmake
make
sudo make install

# Verificar a instalação
qbittorrent-nox --version

# Opcional: Se preferir usar o Docker, siga os comandos abaixo

# Adicionar repositório do Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Atualizar pacotes novamente após adicionar o repositório Docker
sudo apt update

# Instalar Docker e Docker Compose
sudo apt install -y docker-ce docker-ce-cli containerd.io
sudo systemctl enable --now docker
sudo systemctl status docker

# Baixar e configurar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verificar a versão do Docker Compose
docker-compose --version

# Criar diretório qbittorrent e configurar o Docker Compose
mkdir -p ~/qbittorrent
cd ~/qbittorrent

# Criar arquivo docker-compose.yml com a configuração do qbittorrent
cat <<EOF > docker-compose.yml
version: '3'
services:
  qbittorrent-nox:
    image: linuxserver/qbittorrent:latest
    container_name: qbittorrent-nox
    ports:
      - "8080:8080"  # Porta para o acesso web
      - "6881:6881"  # Porta de comunicação do torrent (UDP/TCP)
    environment:
      - PUID=1000  # Usuário (substitua se necessário)
      - PGID=1000  # Grupo (substitua se necessário)
      - WEBUI_PORT=8080
      - TZ=America/Sao_Paulo  # Fuso horário
    volumes:
      - ./config:/config  # Diretório para configurações
      - /path/to/downloads:/downloads  # Caminho para armazenar os downloads
    restart: unless-stopped
EOF

# Iniciar o Docker Compose em segundo plano
sudo docker-compose up -d

# Exibir logs do container
sudo docker-compose logs -f
