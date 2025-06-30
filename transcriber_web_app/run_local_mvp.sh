#!/bin/bash
# Script para iniciar a aplicação Transcriber Web App com Docker Compose.

LOG_FILE="mvp_compose_setup.log"
PROJECT_DIR_NAME="transcriber_web_app" # Nome do diretório onde estão videos/ e results/

# Funções de log
log_info() { echo "$(date +"%Y-%m-%d %H:%M:%S") [INFO] $1" | tee -a "$LOG_FILE"; }
log_error() { echo "$(date +"%Y-%m-%d %H:%M:%S") [ERROR] $1" | tee -a "$LOG_FILE"; exit 1; }
log_warning() { echo "$(date +"%Y-%m-%d %H:%M:%S") [WARNING] $1" | tee -a "$LOG_FILE"; }

# 0. Navegar para o diretório raiz do projeto (onde está o docker-compose.yml)
# Este script está em transcriber_web_app/, então precisamos subir um nível.
cd "$(dirname "$0")/.." || exit

# Limpar log antigo no início da execução
> "$LOG_FILE"

log_info "Iniciando script run_local_mvp.sh (baseado em Docker Compose)..."

# 1. Verificar Docker e Docker Compose
log_info "Verificando o status do Docker..."
if ! docker info &> /dev/null; then
    log_error "O Docker não está em execução! Por favor, inicie o Docker Desktop/Daemon e tente novamente."
fi
log_info "Docker está em execução."

log_info "Verificando se Docker Compose (v1 ou v2) está instalado..."
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
    log_info "Docker Compose (v1 'docker-compose') encontrado."
elif docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
    log_info "Docker Compose (v2 'docker compose') encontrado."
else
    log_error "Docker Compose não encontrado. Por favor, instale Docker Compose (v1 ou v2) e tente novamente. Consulte: https://docs.docker.com/compose/install/"
fi

# 2. Criar pastas necessárias no host (se não existirem)
# Estas pastas são mapeadas como volumes no docker-compose.yml
# O docker-compose.yml espera que ./transcriber_web_app/videos e ./transcriber_web_app/results existam
# em relação à localização do docker-compose.yml (raiz do projeto).
HOST_VIDEOS_DIR="${PROJECT_DIR_NAME}/videos"
HOST_RESULTS_DIR="${PROJECT_DIR_NAME}/results"

log_info "Verificando/criando pastas no host: '${HOST_VIDEOS_DIR}/' e '${HOST_RESULTS_DIR}/'..."
mkdir -p "${HOST_VIDEOS_DIR}" || log_error "Falha ao criar pasta '${HOST_VIDEOS_DIR}/' no host."
mkdir -p "${HOST_RESULTS_DIR}" || log_error "Falha ao criar pasta '${HOST_RESULTS_DIR}/' no host."
log_info "Pastas do host verificadas/criadas."

# 3. Iniciar os serviços com Docker Compose
log_info "Iniciando serviços definidos em docker-compose.yml (webapp e whisper_worker)..."
log_info "Isso pode levar algum tempo na primeira execução para construir as imagens."

# Usar --build para garantir que as imagens sejam (re)construídas se houver alterações nos Dockerfiles.
# Usar -d para rodar em modo detached (background).
# $COMPOSE_CMD é 'docker-compose' ou 'docker compose'
if $COMPOSE_CMD up --build -d; then
    log_info "Serviços Docker Compose iniciados com sucesso em modo detached."
else
    log_error "Falha ao iniciar os serviços Docker Compose. Verifique os logs acima ou execute '$COMPOSE_CMD up --build' sem '-d' para ver os erros."
fi

log_info "Aplicação web deve estar acessível em http://localhost:5000 em breve."
log_info "Para ver os logs dos containers, use: '$COMPOSE_CMD logs -f'"
log_info "Para parar os serviços, use: '$COMPOSE_CMD down'"
echo ""
echo "--------------------------------------------------------------------"
echo " Aplicação Transcriber Web App iniciada com Docker Compose!"
echo ""
echo " Acesse: http://localhost:5000"
echo ""
echo " Logs dos containers: $COMPOSE_CMD logs -f"
echo " (Use '$COMPOSE_CMD logs -f webapp' para ver apenas os logs da webapp)"
echo ""
echo " Para parar todos os serviços: $COMPOSE_CMD down"
echo " (Execute este comando no diretório que contém o docker-compose.yml)"
echo "--------------------------------------------------------------------"

# O script termina aqui, pois os containers estão rodando em background.
# O usuário pode usar os comandos de log e down conforme instruído.
