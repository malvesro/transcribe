#!/bin/bash

# --- Configurações ---
IMAGE_NAME="whisper-transcriber" # Escolha um nome para a sua imagem Docker
VIDEOS_DIR="videos"              # Nome da pasta onde os vídeos devem ser colocados
LOG_FILE="setup_whisper.log"     # Nome do arquivo de log

# Cores para saída no terminal
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Função de Logging ---
# log_message agora imprime uma versão formatada para o console e uma versão completa para o log
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    # Imprime no arquivo de log com timestamp e nível
    echo "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE" >/dev/null

    # Imprime no console (opcionalmente com cores e sem timestamp/nível)
    case "$level" in
        "INFO")
            echo -e "${BLUE}>>> ${message}${NC}"
            ;;
        "WARN")
            echo -e "${YELLOW}!!! Atenção: ${message}${NC}"
            ;;
        "ERROR")
            echo -e "${RED}!!! ERRO: ${message}${NC}"
            ;;
        *) # Default para outros níveis, se houver
            echo -e "${message}"
            ;;
    esac
}

# --- Configuração de tratamento de erros global ---
set -e # Aborta o script em caso de erro

# Função para ser executada em caso de erro
cleanup_on_error() {
    log_message "ERROR" "Ocorreu um erro inesperado durante o setup. Verifique o log para mais detalhes: ${LOG_FILE}"
    echo -e "\n${RED}-----------------------------------------------------${NC}"
    echo -e "${RED}🚨 O Setup Falhou! Por favor, revise as mensagens acima e o log.${NC}"
    echo -e "${RED}-----------------------------------------------------${NC}\n"
    exit 1
}

trap 'cleanup_on_error' ERR # Captura o sinal de erro

# --- Função para construir a imagem Docker ---
build_docker_image() {
    log_message "INFO" "Verificando imagem Docker '${IMAGE_NAME}'..."
    if docker image inspect "$IMAGE_NAME" &> /dev/null; then
        log_message "INFO" "${YELLOW}A imagem Docker '${IMAGE_NAME}' já existe localmente. Pulando o build.${NC}"
        return 0 # Sucesso (imagem já existe)
    fi

    log_message "INFO" "Iniciando o build da imagem Docker '${IMAGE_NAME}'. Isso pode levar alguns minutos..."
    if ! docker build -t "$IMAGE_NAME" -f Dockerfile .; then
        log_message "ERROR" "${RED}Falha no build da imagem Docker '${IMAGE_NAME}'. Verifique o Dockerfile.txt e a saída do build.${NC}"
        return 1 # Falha
    fi

    log_message "INFO" "${GREEN}Build da imagem Docker '${IMAGE_NAME}' concluído com sucesso!${NC}"
    return 0 # Sucesso
}

# --- Função para criar a pasta de vídeos ---
create_videos_directory() {
    log_message "INFO" "Verificando a pasta de vídeos '${VIDEOS_DIR}'..."
    if [ ! -d "$VIDEOS_DIR" ]; then
        log_message "INFO" "Criando a pasta '${VIDEOS_DIR}' para seus vídeos..."
        if ! mkdir -p "$VIDEOS_DIR"; then
            log_message "ERROR" "${RED}Erro ao criar a pasta '${VIDEOS_DIR}'. Verifique as permissões.${NC}"
            return 1 # Falha
        fi
        log_message "INFO" "${GREEN}Pasta '${VIDEOS_DIR}' criada com sucesso em $(pwd)/${VIDEOS_DIR}.${NC}"
    else
        log_message "INFO" "Pasta '${VIDEOS_DIR}' já existe em $(pwd)/${VIDEOS_DIR}."
    fi
    return 0 # Sucesso
}

# --- Função para criar os aliases ---
create_aliases() {
    log_message "INFO" "Configurando aliases para a sessão atual..."
    # Alias para execução via CPU
    alias transcribe="docker run --rm -v \"\$(pwd)/$VIDEOS_DIR:/data\" $IMAGE_NAME"
    # Alias para execução via GPU (requer drivers NVIDIA e runtime Docker compatível)
    alias transcribegpu="docker run --rm --gpus all -v \"\$(pwd)/$VIDEOS_DIR:/data\" $IMAGE_NAME"
    log_message "INFO" "${GREEN}Aliases 'transcribe' e 'transcribegpu' definidos!${NC}"
}

# --- Função para exibir o help ---
show_help() {
    # Usar variáveis com aspas duplas para garantir a expansão e cores
    local bashrc_path="${YELLOW}$HOME/.bashrc${NC}"
    local zshrc_path="${YELLOW}$HOME/.zshrc${NC}"
    local source_bashrc="${YELLOW}source $HOME/.bashrc${NC}"
    local source_zshrc="${YELLOW}source $HOME/.zshrc${NC}"
    local model_small_note="${YELLOW}O modelo 'small' será usado por padrão${NC}, pois já está pré-carregado na imagem Docker. Não precisa especificar ${YELLOW}--model small${NC}."
    local transcribe_help_cmd="${YELLOW}\`transcribe --help\`${NC}"

    echo -e "
${CYAN}═══════════════════════════════════════════════════════${NC}
${CYAN}✨ Setup do Whisper Transcriber Concluído com Sucesso! ✨${NC}
${CYAN}═══════════════════════════════════════════════════════${NC}

${GREEN}Os seguintes atalhos (aliases) foram criados para esta sessão do terminal:${NC}

1.  Alias: ${YELLOW}'transcribe'${NC} (para transcrição via CPU)
    ${BLUE}Descrição:${NC} Executa o Whisper usando o processador (CPU). Ideal para sistemas sem placa de vídeo NVIDIA ou quando a velocidade extrema não é o foco principal.
    ${BLUE}Exemplo de uso:${NC}
    ${GREEN}\$ transcribe --video meu_video_aula.mp4${NC}
    (${model_small_note})

2.  Alias: ${YELLOW}'transcribegpu'${NC} (para transcrição via GPU)
    ${BLUE}Descrição:${NC} Tenta executar o Whisper utilizando sua placa de vídeo NVIDIA (GPU) para maior velocidade. ${RED}Requer drivers NVIDIA instalados e o Docker configurado para usar GPUs.${NC}
    ${BLUE}Exemplo de uso:${NC}
    ${GREEN}\$ transcribegpu --video podcast.mp4 --model medium${NC}
    (Você pode especificar outros modelos, como ${YELLOW}'medium'${NC} ou ${YELLOW}'large'${NC}, para maior precisão, se sua GPU suportar.)

${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}
${CYAN}  Dicas Importantes para o Uso:                               ${NC}
${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}

* Substitua '${YELLOW}seu_video.mp4${NC}' pelo nome real do arquivo de vídeo que você quer transcrever.
* ${YELLOW}Coloque seus arquivos de vídeo dentro da pasta '${VIDEOS_DIR}'${NC} que foi criada no mesmo local deste script:
    ${GREEN}Caminho da pasta:${NC} $(pwd)/${VIDEOS_DIR}/
* Para ver todos os modelos disponíveis, use: ${transcribe_help_cmd}
* ${RED}Atenção:${NC} Esses atalhos são ${YELLOW}TEMPORÁRIOS${NC} e funcionarão apenas nesta sessão atual do terminal.
* Para torná-los ${GREEN}PERMANENTES${NC} (disponíveis sempre que você abrir o terminal), ${GREEN}adicione as seguintes linhas${NC} ao final do seu arquivo ${bashrc_path} ou ${zshrc_path} (dependendo do seu shell):
    ${BLUE}alias transcribe='docker run --rm -v \"\$(pwd)/$VIDEOS_DIR:/data\" $IMAGE_NAME'${NC}
    ${BLUE}alias transcribegpu='docker run --rm --gpus all -v \"\$(pwd)/$VIDEOS_DIR:/data\" $IMAGE_NAME'${NC}
    Após adicionar, salve o arquivo e execute: ${source_bashrc} ou ${source_zshrc}

${GREEN}🎉 Tudo pronto para suas transcrições com Whisper! 🎉${NC}
"
}

# --- Execução Principal ---
main() {
    # Limpa o log anterior ao iniciar uma nova execução
    > "$LOG_FILE"
    log_message "INFO" "Iniciando a configuração automatizada do Whisper Transcriber..."
    echo # Quebra de linha para espaçamento visual

    # Verificar se o Docker está em execução
    log_message "INFO" "Verificando o status do Docker..."
    if ! docker info &> /dev/null; then
        log_message "ERROR" "${RED}O Docker não está em execução! Por favor, inicie o Docker Desktop/Daemon e tente novamente.${NC}"
        exit 1
    fi
    log_message "INFO" "${GREEN}Docker está em execução. Ótimo!${NC}"
    echo # Quebra de linha para espaçamento visual

    # Criar a pasta de vídeos antes de tentar o build ou qualquer outra coisa
    if ! create_videos_directory; then
        log_message "ERROR" "${RED}Falha crítica ao criar/verificar a pasta de vídeos. Abortando.${NC}"
        exit 1
    fi
    echo # Quebra de linha para espaçamento visual

    # Tentar construir a imagem (apenas se não existir)
    if ! build_docker_image; then
        log_message "ERROR" "${RED}Falha crítica no build da imagem Docker. Abortando.${NC}"
        exit 1
    fi
    echo # Quebra de linha para espaçamento visual

    create_aliases
    echo # Quebra de linha para espaçamento visual

    show_help # Exibe o help apenas se o build e a criação de aliases forem bem-sucedidos

    log_message "INFO" "Setup do Whisper Transcriber concluído com sucesso."
}

# Chama a função principal
main