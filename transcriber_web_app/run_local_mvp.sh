#!/bin/bash
# Script simplificado para iniciar o MVP local

LOG_FILE="mvp_setup.log"
IMAGE_NAME="whisper-transcriber" # Nome da imagem do seu Dockerfile

# Funções de log simplificadas para este script
log_info() { echo "$(date +"%Y-%m-%d %H:%M:%S") [INFO] $1" | tee -a "$LOG_FILE"; }
log_error() { echo "$(date +"%Y-%m-%d %H:%M:%S") [ERROR] $1" | tee -a "$LOG_FILE"; exit 1; }
log_warning() { echo "$(date +"%Y-%m-%d %H:%M:%S") [WARNING] $1" | tee -a "$LOG_FILE"; }

# 0. Navegar para o diretório do script
# Isso garante que os caminhos relativos (Dockerfile, requirements.txt) funcionem
cd "$(dirname "$0")" || exit

# Limpar log antigo no início da execução
> "$LOG_FILE"

log_info "Iniciando script run_local_mvp.sh..."

# 1. Verificar Docker
log_info "Verificando o status do Docker..."
if ! docker info &> /dev/null; then
    log_error "O Docker não está em execução! Por favor, inicie o Docker Desktop/Daemon e tente novamente."
fi
log_info "Docker está em execução. Ótimo!"

# 2. Criar pastas necessárias (se não existirem dentro de transcriber_web_app)
log_info "Verificando/criando pastas 'videos/' e 'results/'..."
mkdir -p videos || log_error "Falha ao criar pasta 'videos/'."
mkdir -p results || log_error "Falha ao criar pasta 'results/'."
log_info "Pastas criadas."

# 3. Construir a imagem Docker do Whisper (se não existir)
log_info "Verificando a imagem Docker '${IMAGE_NAME}'..."
if ! docker image inspect "$IMAGE_NAME" &> /dev/null; then
    log_info "Imagem '${IMAGE_NAME}' não encontrada. Construindo agora (pode levar alguns minutos)..."
    # Assume que Dockerfile está no mesmo diretório que este script
    if ! docker build -t "$IMAGE_NAME" -f Dockerfile .; then
        log_error "Falha no build da imagem Docker '${IMAGE_NAME}'. Verifique o Dockerfile e a conexão com a internet."
    fi
    log_info "Imagem Docker '${IMAGE_NAME}' construída com sucesso."
else
    log_info "Imagem Docker '${IMAGE_NAME}' já existe. Pulando build."
fi

# 4. Verificar e instalar Python3 e Pip3
log_info "Verificando instalação do Python3 e Pip3..."

# Verificar Python3
if ! command -v python3 &> /dev/null; then
    log_error "Python3 não encontrado. Por favor, instale o Python3 primeiro. Em sistemas baseados em Debian/Ubuntu, use: sudo apt update && sudo apt install python3"
fi
log_info "Python3 encontrado."

# Verificar Pip3
if ! command -v pip3 &> /dev/null; then
    log_warning "Pip3 não encontrado. Tentando instalar python3-pip..."
    # Tentar instalar python3-pip (comum para Debian/Ubuntu)
    if sudo apt update && sudo apt install -y python3-pip; then
        log_info "python3-pip instalado com sucesso."
        # Verifica novamente se pip3 agora está disponível
        if ! command -v pip3 &> /dev/null; then
             log_error "Pip3 ainda não foi encontrado após a tentativa de instalação. Verifique a instalação do python3-pip ou instale pip manualmente."
        fi
    else
        log_error "Falha ao instalar python3-pip. Por favor, instale pip3 manualmente e tente novamente."
    fi
else
    log_info "Pip3 encontrado."
fi

# 5. Instalar dependências Python para o backend
log_info "Instalando dependências Python para o servidor web usando pip3..."
# Assume que requirements.txt está no mesmo diretório que este script
if [ -f "requirements.txt" ]; then
    pip3 install -r requirements.txt || log_error "Falha ao instalar dependências Python de requirements.txt usando pip3."
else
    log_error "Arquivo requirements.txt não encontrado no diretório do script."
fi
log_info "Dependências Python instaladas."

# 6. Iniciar o servidor Flask
log_info "Iniciando o servidor web Flask em http://localhost:5000..."
# Define FLASK_APP para o Flask encontrar o ponto de entrada (app.py no mesmo diretório)
export FLASK_APP=app.py
# Executa o Flask no modo de desenvolvimento para logs detalhados
# Redirecionar stdout e stderr do Flask para o arquivo de log principal e para o terminal
flask run --host=0.0.0.0 --port=5000 >> "$LOG_FILE" 2>&1 &
FLASK_PID=$! # Captura o PID do processo Flask

log_info "Servidor Flask iniciado (PID: $FLASK_PID). Verifique os logs em ${LOG_FILE}."
log_info "Abrindo navegador em 3 segundos..."

# Espera um pouco para o servidor Flask iniciar antes de tentar abrir o navegador
sleep 3

# Abrir o navegador automaticamente (funciona na maioria dos SOs)
if command -v xdg-open >/dev/null 2>&1; then
    xdg-open http://localhost:5000
elif command -v open >/dev/null 2>&1; then # macOS
    open http://localhost:5000
elif command -v start >/dev/null 2>&1; then # Windows (via cmd.exe no Git Bash/WSL)
    start http://localhost:5000
else
    log_info "Não foi possível abrir o navegador automaticamente. Acesse http://localhost:5000 manualmente."
fi

log_info "Setup do MVP concluído. O servidor Flask está rodando com PID: $FLASK_PID."
echo "O servidor Flask está em execução. Logs disponíveis em: $(pwd)/${LOG_FILE}"
echo "Pressione [Ctrl+C] neste terminal para parar o servidor Flask."

# Mantém o script em execução para que o usuário possa ver os logs do Flask e parar com Ctrl+C
# O 'wait' aguarda o processo Flask terminar, o que só acontecerá se for morto externamente
# ou se o flask run falhar.
wait "$FLASK_PID"
log_info "Servidor Flask (PID: $FLASK_PID) foi parado."
