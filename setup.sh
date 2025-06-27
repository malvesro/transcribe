#!/bin/bash
set -euxo pipefail # Adicionamos flags de debug e segurança aqui

# --- Configurações ---
IMAGE_NAME="whisper-transcriber" # Nome da imagem Docker
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
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    echo "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE" >/dev/null

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
# set -e # Já está no shebang com -euxo pipefail

# Função para ser executada em caso de erro
cleanup_on_error() {
    log_message "ERROR" "Ocorreu um erro inesperado durante o setup. Verifique o log para mais detalhes: ${LOG_FILE}"
    echo -e "\n${RED}-----------------------------------------------------${NC}"
    echo -e "${RED}🚨 O Setup Falhou! Por favor, revise as mensagens acima e o log.${NC}"
    echo -e "${RED}-----------------------------------------------------${NC}\n"
    exit 1
}

trap 'cleanup_on_error' ERR # Captura o sinal de erro

# --- Função para determinar o shell do usuário ---
get_user_shell_config_file() {
    local shell_name=$(basename "$SHELL")
    if [ "$shell_name" = "bash" ]; then
        echo "$HOME/.bashrc"
    elif [ "$shell_name" = "zsh" ]; then
        echo "$HOME/.zshrc"
    else
        log_message "WARN" "Shell '$shell_name' não reconhecido. Os aliases podem não ser permanentes."
        echo "" # Retorna vazio se o shell não for suportado
    fi
}

# --- Função para avisar sobre sudo e executar um comando ---
run_sudo_command() {
    local command_description="$1"
    shift # Remove o primeiro argumento (descrição)
    local command_to_execute="$@"

    log_message "INFO" "Será necessário privilégios de superusuário (sudo) para: ${command_description}"
    log_message "INFO" "Por favor, insira sua senha, se solicitado."
    if ! sudo bash -c "${command_to_execute}"; then # Usamos 'bash -c' para passar o comando como uma string
        log_message "ERROR" "Falha ao executar o comando com sudo para: ${command_description}"
        return 1
    fi
    return 0
}


# --- Função para instalar pré-requisitos do sistema (curl, lsb-release para NVIDIA, e packages para Docker) ---
install_prerequisites() {
    log_message "INFO" "Instalando pré-requisitos do sistema: curl, lsb-release, ca-certificates, gnupg..."

    if ! run_sudo_command "atualizar o índice de pacotes APT" "apt-get update"; then
        log_message "ERROR" "Falha ao atualizar o índice de pacotes. Verifique sua conexão com a internet ou as fontes do apt."
        return 1
    fi

    if ! run_sudo_command "instalar pacotes essenciais (curl, lsb-release, ca-certificates, gnupg)" "apt-get install -y curl lsb-release ca-certificates gnupg"; then
        log_message "ERROR" "Falha ao instalar pré-requisitos. Verifique a saída do apt."
        return 1
    fi
    log_message "INFO" "${GREEN}Pré-requisitos instalados com sucesso!${NC}"
    return 0
}

# --- Função para instalar o Docker Engine no Ubuntu WSL ---
install_docker_engine() {
    log_message "INFO" "Verificando instalação do Docker Engine no Ubuntu WSL..."

    if command -v docker &> /dev/null && docker info &> /dev/null; then
        log_message "INFO" "${YELLOW}Docker Engine já está instalado e em execução no Ubuntu WSL. Pulando a instalação.${NC}"
        return 0
    fi

    log_message "INFO" "Instalando Docker Engine no Ubuntu WSL..."

    # Adicionar chave GPG oficial do Docker
    log_message "INFO" "Adicionando chave GPG oficial do Docker..."
    if ! run_sudo_command "criar o diretório para keyrings GPG do Docker" "install -m 0755 -d /etc/apt/keyrings"; then
        return 1
    fi
    if ! curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg; then
        log_message "ERROR" "Falha ao baixar ou instalar a chave GPG do Docker."
        return 1
    fi
    if ! run_sudo_command "alterar permissões da chave GPG do Docker" "chmod a+r /etc/apt/keyrings/docker.gpg"; then
        return 1
    fi
    log_message "INFO" "${GREEN}Chave GPG do Docker adicionada.${NC}"

    # Adicionar repositório Docker ao APT sources
    log_message "INFO" "Adicionando repositório Docker ao APT sources..."
    local os_release_codename
    os_release_codename=$(. /etc/os-release && echo "$VERSION_CODENAME")
    if [ -z "$os_release_codename" ]; then
        log_message "ERROR" "Não foi possível determinar o codinome da sua distribuição Ubuntu."
        return 1
    fi
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${os_release_codename} stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    if [ $? -ne 0 ]; then
        log_message "ERROR" "Falha ao adicionar o repositório Docker. Verifique sua conexão ou a sintaxe."
        return 1
    fi
    log_message "INFO" "${GREEN}Repositório Docker adicionado.${NC}"

    # Instalar pacotes do Docker
    log_message "INFO" "Atualizando índice de pacotes APT e instalando pacotes Docker..."
    if ! run_sudo_command "atualizar índice de pacotes APT" "apt-get update"; then
        log_message "ERROR" "Falha ao atualizar o índice de pacotes após adicionar repositório Docker."
        return 1
    fi
    if ! run_sudo_command "instalar Docker Engine" "apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"; then
        log_message "ERROR" "Falha ao instalar pacotes do Docker Engine."
        return 1
    fi
    log_message "INFO" "${GREEN}Docker Engine instalado com sucesso!${NC}"

    # Adicionar usuário atual ao grupo 'docker'
    log_message "INFO" "Adicionando o usuário atual ('$USER') ao grupo 'docker'..."
    if ! groups "$USER" | grep -q '\bdocker\b'; then
        if ! run_sudo_command "adicionar usuário '$USER' ao grupo 'docker'" "usermod -aG docker $USER"; then
            log_message "ERROR" "Falha ao adicionar o usuário '$USER' ao grupo 'docker'."
            log_message "ERROR" "Você precisará fazer isso manualmente e reiniciar seu terminal para que as alterações tenham efeito."
            return 1
        fi
        log_message "INFO" "${GREEN}Usuário '$USER' adicionado ao grupo 'docker'.${NC}"
        log_message "WARN" "${YELLOW}Para que as permissões do Docker tenham efeito sem 'sudo', você precisará REINICIAR seu terminal WSL ou executar 'newgrp docker'.${NC}"
    else
        log_message "INFO" "Usuário '$USER' já está no grupo 'docker'."
    fi

    # Iniciar o serviço Docker
    log_message "INFO" "Iniciando o serviço Docker..."
    if command -v systemctl &> /dev/null && systemctl is-system-running &> /dev/null; then
        if ! run_sudo_command "iniciar serviço Docker via systemctl" "systemctl start docker"; then
            log_message "ERROR" "Falha ao iniciar o Docker via systemctl."
            return 1
        fi
    elif command -v service &> /dev/null; then
        if ! run_sudo_command "iniciar serviço Docker via service" "service docker start"; then
            log_message "ERROR" "Falha ao iniciar o Docker via service. Por favor, tente iniciar manualmente ('sudo service docker start')."
            return 1
        fi
    else
        log_message "WARN" "Não foi possível iniciar o serviço Docker automaticamente (systemctl ou service não encontrados). Por favor, inicie-o manualmente (ex: 'sudo systemctl start docker')."
    fi
    log_message "INFO" "${GREEN}Serviço Docker iniciado.${NC}"

    return 0
}


# --- Funções de Configuração NVIDIA/CUDA ---
configure_nvidia_repo() {
    log_message "INFO" "Configurando o repositório do NVIDIA Container Toolkit..."

    # Adicionar a chave GPG da NVIDIA
    log_message "INFO" "Adicionando a chave GPG da NVIDIA..."
    local keyring_path="/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg"

    # Verificar se a chave GPG já existe E se o fingerprint corresponde
    if [ -f "$keyring_path" ] && sudo gpg --list-keys --with-fingerprint --with-colons 2>/dev/null | grep -q "0EAEAD74CC00E654"; then
        log_message "INFO" "${YELLOW}Chave GPG da NVIDIA já existe em '${keyring_path}' e é válida. Pulando download e instalação.${NC}"
    else
        log_message "INFO" "Chave GPG da NVIDIA não encontrada ou inválida. Baixando e instalando..."
        if ! run_sudo_command "criar o diretório para keyrings GPG" "install -m 0755 -d /usr/share/keyrings"; then # Garante que o diretório existe
            return 1
        fi
        # Adiciona --yes para sobrescrever se o arquivo existir, suprimindo o prompt
        if ! curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor --yes -o "$keyring_path"; then
            log_message "ERROR" "Falha ao baixar ou instalar a chave GPG da NVIDIA."
            return 1
        fi
        log_message "INFO" "${GREEN}Chave GPG da NVIDIA adicionada.${NC}"
    fi

    log_message "INFO" "Adicionando a linha do repositório NVIDIA Container Toolkit (stable/deb/)..."
    local os_release_codename
    os_release_codename=$(. /etc/os-release && echo "$VERSION_CODENAME")
    if ! curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
        sudo sed "s#deb https://#deb [signed-by=${keyring_path}] https://#g" | \
        sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list > /dev/null; then
        log_message "ERROR" "Falha ao adicionar o repositório da NVIDIA 'stable/deb/'. Verifique sua conexão com a internet ou a URL."
        return 1
    fi
    log_message "INFO" "${GREEN}Repositório da NVIDIA 'stable/deb/' adicionado.${NC}"
    return 0
}

install_nvidia_packages() {
    log_message "INFO" "Atualizando índice de pacotes APT após configurações de repositório NVIDIA..."
    if ! run_sudo_command "atualizar o índice de pacotes APT após adicionar repositórios" "apt update"; then
        log_message "ERROR" "Falha ao atualizar o índice de pacotes após adicionar repositório NVIDIA. Verifique as configurações do repositório."
        return 1
    fi
    log_message "INFO" "${GREEN}Índice de pacotes atualizado.${NC}"

    log_message "INFO" "Procurando o pacote nvidia-utils-55x..."
    # Buscar a versão mais recente da série 55x
    NVIDIA_UTILS_PACKAGE=$(apt-cache search nvidia-utils-55 | grep -Eo 'nvidia-utils-55[0-9]+' | head -n 1)

    if [ -z "$NVIDIA_UTILS_PACKAGE" ]; then
        log_message "WARN" "Pacote 'nvidia-utils-55x' não encontrado. Tentando 'nvidia-utils' genérico."
        NVIDIA_UTILS_PACKAGE="nvidia-utils" # Fallback para o pacote genérico
    fi

    log_message "INFO" "Instalando ${NVIDIA_UTILS_PACKAGE} e nvidia-container-toolkit..."
    if ! run_sudo_command "instalar pacotes NVIDIA (${NVIDIA_UTILS_PACKAGE} e nvidia-container-toolkit)" "apt install -y ${NVIDIA_UTILS_PACKAGE} nvidia-container-toolkit"; then
        log_message "ERROR" "Falha ao instalar pacotes NVIDIA (${NVIDIA_UTILS_PACKAGE} e nvidia-container-toolkit)."
        log_message "ERROR" "Verifique se seus drivers NVIDIA no Windows estão atualizados e se o WSL2 está configurado para GPU."
        return 1
    fi
    log_message "INFO" "${GREEN}Pacotes NVIDIA (${NVIDIA_UTILS_PACKAGE} e nvidia-container-toolkit) instalados com sucesso!${NC}"
    return 0
}

configure_docker_gpu_runtime() {
    log_message "INFO" "Configurando o Docker Daemon para usar o NVIDIA Runtime..."
    local docker_ctk_cmd="nvidia-ctk"

    # Se o nvidia-ctk não estiver no PATH ou necessitar de sudo, ajusta o comando
    if ! command -v "$docker_ctk_cmd" &> /dev/null || ! "$docker_ctk_cmd" runtime configure --runtime=docker &> /dev/null; then
        log_message "WARN" "Comando 'nvidia-ctk' não acessível diretamente ou requer sudo. Tentando com 'sudo nvidia-ctk'."
        docker_ctk_cmd="sudo nvidia-ctk"
    fi

    if ! ${docker_ctk_cmd} runtime configure --runtime=docker; then
        log_message "ERROR" "Falha ao configurar o Docker Daemon para o NVIDIA Runtime."
        return 1
    fi
    log_message "INFO" "${GREEN}Docker Daemon configurado para usar o NVIDIA Runtime.${NC}"
    return 0
}

restart_docker_service() {
    log_message "INFO" "Reiniciando o serviço Docker..."
    local docker_restart_cmd=""

    if command -v systemctl &> /dev/null && systemctl is-system-running &> /dev/null; then
        docker_restart_cmd="systemctl restart docker"
    elif command -v service &> /dev/null; then
        docker_restart_cmd="service docker restart"
    fi

    if [ -n "$docker_restart_cmd" ]; then
        if ! run_sudo_command "reiniciar o serviço Docker" "$docker_restart_cmd"; then
            log_message "ERROR" "Falha ao reiniciar o Docker automaticamente. Por favor, reinicie o WSL manualmente ou o Docker Desktop se estiver usando."
            return 1
        fi
    else
        log_message "WARN" "systemctl ou service não encontrados. Você precisará reiniciar o Docker manualmente."
        return 1 # Indica que o serviço não pôde ser reiniciado automaticamente
    fi
    log_message "INFO" "${GREEN}Serviço Docker reiniciado com sucesso!${NC}"
    return 0
}

verify_nvidia_smi() {
    log_message "INFO" "Verificando a instalação do NVIDIA-SMI..."
    if ! nvidia-smi; then
        log_message "ERROR" "O comando 'nvidia-smi' falhou. A configuração do CUDA pode estar incompleta ou incorreta."
        log_message "ERROR" "Isso pode ser resolvido com um 'wsl --shutdown' no PowerShell do Windows, ou reinstalando os drivers NVIDIA no Windows."
        return 1
    fi
    log_message "INFO" "${GREEN}NVIDIA-SMI funcionando corretamente!${NC}"
    return 0
}

# --- Função para construir a imagem Docker ---
build_docker_image() {
    local docker_cmd="docker"
    # Adicionamos uma verificação aqui para decidir se usamos 'sudo docker'
    # Esta é uma proteção para a sessão atual, caso o 'usermod -aG docker' ainda não tenha efeito
    if ! groups | grep -q '\bdocker\b'; then # Se o usuário não está no grupo docker na sessão atual
        log_message "WARN" "O usuário atual não está no grupo 'docker' nesta sessão. Tentando executar comandos docker com 'sudo'."
        docker_cmd="sudo docker"
    elif ! docker info &> /dev/null; then # Se o docker não estiver acessível sem sudo mesmo estando no grupo
         log_message "WARN" "O comando 'docker' não está acessível sem 'sudo' nesta sessão. Tentando com 'sudo docker'."
         docker_cmd="sudo docker"
    fi


    log_message "INFO" "Verificando imagem Docker '${IMAGE_NAME}'..."
    if ${docker_cmd} image inspect "$IMAGE_NAME" &> /dev/null; then
        log_message "INFO" "${YELLOW}A imagem Docker '${IMAGE_NAME}' já existe localmente. Pulando o build.${NC}"
        return 0 # Sucesso (imagem já existe)
    fi

    log_message "INFO" "Iniciando o build da imagem Docker '${IMAGE_NAME}'. Isso pode levar alguns minutos..."
    if [ ! -f "Dockerfile" ]; then
        log_message "ERROR" "${RED}Arquivo 'Dockerfile' não encontrado no diretório atual. Certifique-se de que ele está presente.${NC}"
        return 1
    fi
    if ! ${docker_cmd} build -t "$IMAGE_NAME" -f Dockerfile .; then
        log_message "ERROR" "${RED}Falha no build da imagem Docker '${IMAGE_NAME}'. Verifique o Dockerfile e a saída do build.${NC}"
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

# --- Função para criar os aliases permanentes ---
create_persistent_aliases() {
    log_message "INFO" "Configurando aliases permanentes..."
    local shell_config_file=$(get_user_shell_config_file)

    if [ -z "$shell_config_file" ]; then
        log_message "WARN" "Não foi possível identificar o arquivo de configuração do shell. Os aliases podem não ser permanentes automaticamente."
        log_message "WARN" "Por favor, adicione as linhas abaixo manualmente ao seu arquivo de configuração do shell e execute 'source <seu_arquivo_de_config>'."
        echo "alias transcribe='docker run --rm -v \"\$(pwd)/$VIDEOS_DIR:/data\" $IMAGE_NAME'"
        echo "alias transcribegpu='docker run --rm --gpus all -v \"\$(pwd)/$VIDEOS_DIR:/data\" $IMAGE_NAME'"
        return 0 # Não é uma falha fatal
    fi

    local alias_lines=(
        "alias transcribe='docker run --rm -v \"\$(pwd)/$VIDEOS_DIR:/data\" $IMAGE_NAME'"
        "alias transcribegpu='docker run --rm --gpus all -v \"\$(pwd)/$VIDEOS_DIR:/data\" $IMAGE_NAME'"
    )

    local needs_update=false
    for line in "${alias_lines[@]}"; do
        if ! grep -qxF "$line" "$shell_config_file"; then
            needs_update=true
            break
        fi
    done

    if [ "$needs_update" = true ]; then
        log_message "INFO" "Adicionando aliases ao '${shell_config_file}'..."

        # Adicionar cabeçalho usando um here-document (mais robusto para strings multilinhas)
        log_message "INFO" "Será necessário privilégios de superusuário (sudo) para adicionar o cabeçalho dos aliases."
        log_message "INFO" "Por favor, insira sua senha, se solicitado."
        if ! sudo tee -a "$shell_config_file" > /dev/null <<EOF_ALIASES_HEADER
# Aliases para Whisper Transcriber (Adicionado por setup.sh)
EOF_ALIASES_HEADER
        then
            log_message "ERROR" "Falha ao adicionar o cabeçalho dos aliases ao '${shell_config_file}'."
            return 1
        fi

        for line in "${alias_lines[@]}"; do
            if ! run_sudo_command "adicionar alias: $line" "echo \"$line\" | tee -a \"$shell_config_file\" > /dev/null"; then return 1; fi
        done
        log_message "INFO" "${GREEN}Aliases 'transcribe' e 'transcribegpu' adicionados a '${shell_config_file}'.${NC}"
    else
        log_message "INFO" "Aliases 'transcribe' e 'transcribegpu' já existem em '${shell_config_file}'. Pulando adição."
    fi

    # Adiciona os aliases para a sessão atual também
    eval "${alias_lines[0]}"
    eval "${alias_lines[1]}"

    log_message "INFO" "${GREEN}Aliases 'transcribe' e 'transcribegpu' definidos para a sessão atual!${NC}"
    return 0
}


# --- Função para exibir o help ---
show_help() {
    local bashrc_path="${YELLOW}$HOME/.bashrc${NC}"
    local zshrc_path="${YELLOW}$HOME/.zshrc${NC}"
    local source_bashrc="${YELLOW}source $HOME/.bashrc${NC}"
    local source_zshrc="${YELLOW}$HOME/.zshrc${NC}"
    local model_small_note="${YELLOW}O modelo 'small' será usado por padrão${NC}, pois já está pré-carregado na imagem Docker. Não precisa especificar ${YELLOW}--model small${NC}."
    local transcribe_help_cmd="${YELLOW}\`transcribe --help\`${NC}"

    local shell_config_file=$(get_user_shell_config_file)
    local source_command=""
    if [ "$shell_config_file" = "$HOME/.bashrc" ]; then
        source_command="$source_bashrc"
    elif [ "$shell_config_file" = "$HOME/.zshrc" ]; then
        source_command="$source_zshrc"
    fi

    echo -e "
${CYAN}═══════════════════════════════════════════════════════${NC}
${CYAN}✨ Setup do Whisper Transcriber Concluído com Sucesso! ✨${NC}
${CYAN}═══════════════════════════════════════════════════════${NC}

${GREEN}Os seguintes atalhos (aliases) estão disponíveis:${NC}

1.  Alias: ${YELLOW}'transcribe'${NC} (para transcrição via CPU)
    ${BLUE}Descrição:${NC} Executa o Whisper usando o processador (CPU). Ideal para sistemas sem placa de vídeo NVIDIA ou quando a velocidade extrema não é o foco principal.
    ${BLUE}Exemplo de uso:${NC}
    ${GREEN}\$ transcribe --video meu_video_aula.mp4${NC}
    (${model_small_note})

2.  Alias: ${YELLOW}'transcribegpu'${NC} (para transcrição via GPU)
    ${BLUE}Descrição:${NC} Tenta executar o Whisper utilizando sua placa de vídeo NVIDIA (GPU) para maior velocidade. ${GREEN}Configurado para usar sua GPU!${NC}
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

${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}
${CYAN}  Passos Finais Importantes:                                  ${NC}
${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}

* ${RED}Para que os aliases 'transcribe' e 'transcribegpu' funcionem em ${YELLOW}novas sessões${NC} do terminal, você precisa reiniciar o seu shell (fechar e abrir o terminal) ou executar:
    ${GREEN}${source_command}${NC}
    (ou o comando equivalente para o seu shell, se ${shell_config_file} for diferente)

* ${RED}Para que o Docker funcione sem 'sudo' na sua sessão atual (após ser adicionado ao grupo 'docker'), você DEVE REINICIAR seu terminal WSL completamente ou executar 'newgrp docker'.${NC}

* ${RED}Para garantir que o Docker e o suporte à GPU estejam totalmente operacionais no WSL2, é ALTAMENTE RECOMENDADO reiniciar sua instância WSL2 completamente:${NC}
    1.
