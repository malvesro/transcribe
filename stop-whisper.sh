#!/bin/bash
# ============================================================================
# Script para Parar o Whisper Transcriber
# ============================================================================

# Cores para o terminal
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}⏹️  Parando o Whisper Transcriber...${NC}"

# Navegar para o diretório do script para garantir a execução correta
cd "$(dirname "$0")"

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

# Parar os containers
$SUDO_PREFIX $COMPOSE_CMD down

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Whisper Transcriber parado com sucesso!${NC}"
else
    echo -e "${RED}❌ Erro ao parar os serviços.${NC}"
    exit 1
fi
