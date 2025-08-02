#!/bin/bash
# ============================================================================
# Script para Forçar a Reconstrução Completa do Ambiente Docker
# ============================================================================
# Use este script se a aplicação não estiver se comportando como esperado,
# especialmente após uma atualização do código.
# ============================================================================

# Cores para o terminal
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}⚠️  Este script irá parar e remover os containers e forçar uma reconstrução completa das imagens.${NC}"
read -p "Tem certeza que deseja continuar? (s/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Ss]$ ]]
then
    echo "Operação cancelada."
    exit 1
fi

# Detectar qual comando 'docker compose' usar
if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
else
    echo -e "${RED}❌ ERRO: Nenhum comando 'docker compose' ou 'docker-compose' foi encontrado.${NC}"
    exit 1
fi

# Tentar executar com sudo se o Docker exigir
if ! $COMPOSE_CMD ps >/dev/null 2>&1; then
    echo "ℹ️  Tentando executar com 'sudo'..."
    SUDO_PREFIX="sudo"
fi

echo -e "\n${BLUE}1. Parando e removendo containers existentes...${NC}"
$SUDO_PREFIX $COMPOSE_CMD down

echo -e "\n${BLUE}2. Removendo a imagem antiga do worker (se existir)...${NC}"
# O comando 'docker rmi' pode falhar se a imagem não existir, então ignoramos o erro.
$SUDO_PREFIX docker rmi transcriber-worker:1.1 >/dev/null 2>&1 || true

echo -e "\n${BLUE}3. Forçando a reconstrução completa sem cache...${NC}"
$SUDO_PREFIX $COMPOSE_CMD build --no-cache

echo -e "\n${BLUE}4. Iniciando os novos serviços...${NC}"
$SUDO_PREFIX $COMPOSE_CMD up -d

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}✅ Ambiente reconstruído e iniciado com sucesso!${NC}"
else
    echo -e "\n${RED}❌ Erro durante o processo. Verifique os logs acima.${NC}"
    exit 1
fi
