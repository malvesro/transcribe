#!/bin/bash
# ============================================================================
# Script para Configurar Suporte a GPU NVIDIA no Docker (WSL2)
# ============================================================================

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🔧 Iniciando configuração do NVIDIA Container Toolkit...${NC}"

# 1. Configurar repositório e chave GPG
echo -e "\n${BLUE}1. Adicionando repositórios da NVIDIA...${NC}"
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Falha ao adicionar repositórios.${NC}"
    exit 1
fi

# 2. Atualizar e Instalar
echo -e "\n${BLUE}2. Instalando nvidia-container-toolkit...${NC}"
sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Falha na instalação.${NC}"
    exit 1
fi

# 3. Configurar Docker
echo -e "\n${BLUE}3. Configurando runtime do Docker...${NC}"
sudo nvidia-ctk runtime configure --runtime=docker

# 4. Reiniciar Docker
echo -e "\n${BLUE}4. Reiniciando serviço Docker...${NC}"
sudo service docker restart

echo -e "\n${GREEN}✅ Instalação concluída!${NC}"
echo -e "${BLUE}Executando teste de verificação (nvidia-smi dentro do container)...${NC}"

# 5. Teste
docker run --rm --gpus all nvidia/cuda:12.1.1-base-ubuntu22.04 nvidia-smi

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}🎉 SUCESSO! O Docker agora pode acessar sua GPU NVIDIA.${NC}"
    echo -e "Você pode reiniciar o Transcriber agora para usar a aceleração de GPU."
else
    echo -e "\n${RED}⚠️  O teste falhou. Verifique se os drivers NVIDIA estão instalados no WINDOWS.${NC}"
fi
