#!/bin/bash
# ============================================================================
# Script para Iniciar o Whisper Transcriber
# ============================================================================

# Cores para o terminal
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}🎙️  Iniciando e verificando atualizações do Whisper Transcriber...${NC}"
echo -e "Isso pode levar alguns minutos se houver atualizações nos componentes."

# Navegar para o diretório do script para garantir a execução correta
cd "$(dirname "$0")"

# Detectar qual comando 'docker compose' usar
if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
elif command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
else
    echo -e "${RED}❌ ERRO: Nenhum comando 'docker compose' ou 'docker-compose' foi encontrado.${NC}"
    echo -e "Por favor, instale o Docker e o Docker Compose."
    exit 1
fi

# Tentar executar com sudo se o Docker exigir
if ! $COMPOSE_CMD ps >/dev/null 2>&1; then
    echo "ℹ️  Tentando executar com 'sudo'..."
    SUDO_PREFIX="sudo"
fi

# Iniciar os containers
$SUDO_PREFIX $COMPOSE_CMD up --build -d

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Whisper Transcriber iniciado com sucesso!${NC}"
    echo -e "🌐 Acesse a aplicação em: ${BLUE}http://localhost:5000${NC}"
else
    echo -e "${RED}❌ Erro ao iniciar Whisper Transcriber.${NC}"
    echo -e "Tente verificar os logs com o comando: ${BLUE}$SUDO_PREFIX $COMPOSE_CMD logs -f${NC}"
    exit 1
fi
