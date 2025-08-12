#!/bin/bash
# ============================================================================
# 🎙️ Whisper Transcriber - Instalação Super Fácil para Linux/macOS
# ============================================================================
# VERSÃO: 3.2 - Corrigida e Final
#
# FUNCIONALIDADES:
# - Instalação automática do Docker e Docker Compose.
# - Detecção do sistema operacional (Ubuntu, Debian, CentOS, Fedora, macOS).
# - Verificação de instalações existentes e opção de atualização.
# - Criação de scripts de conveniência (`start-whisper.sh`, `stop-whisper.sh`).
# - Tratamento de erros e feedback visual para o usuário.
#
# REQUISITOS:
# - Acesso `sudo` para instalar pacotes.
# - Conexão com a internet.
# ============================================================================

set -e  # Parar em caso de erro

# Cores para terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Função para imprimir cabeçalho
print_header() {
    echo -e "\n${CYAN}████████████████████████████████████████████████████████████████████████████${NC}"
    echo -e "${CYAN}                🎙️ Whisper Transcriber - Instalador Super Fácil${NC}"
    echo -e "${CYAN}████████████████████████████████████████████████████████████████████████████${NC}\n"
    echo -e "${GREEN}✨ Este instalador fará TUDO automaticamente para você!${NC}"
    echo -e "${BLUE}📋 Não precisa instalar nada manualmente - deixe conosco!${NC}\n"
}

# Função para verificar se comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Função para detectar sistema operacional
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$NAME
            VER=$VERSION_ID
        else
            OS="Linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macOS"
    else
        OS="Unknown"
    fi
}

# Função para instalar Docker no Ubuntu/Debian
install_docker_ubuntu() {
    echo -e "${BLUE}🔧 Instalando Docker no Ubuntu/Debian...${NC}"
    sudo apt-get update -y
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker $USER
    echo -e "${GREEN}✅ Docker instalado com sucesso!${NC}"
    echo -e "${YELLOW}⚠️  Para usar o Docker sem 'sudo', você precisa fazer logout e login novamente.${NC}"
}

# Função para instalar Docker no CentOS/RHEL/Fedora
install_docker_centos() {
    echo -e "${BLUE}🔧 Instalando Docker no CentOS/RHEL/Fedora...${NC}"
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker $USER
    echo -e "${GREEN}✅ Docker instalado com sucesso!${NC}"
    echo -e "${YELLOW}⚠️  Para usar o Docker sem 'sudo', você precisa fazer logout e login novamente.${NC}"
}

# Função para instalar Docker no macOS
install_docker_macos() {
    echo -e "${BLUE}🔧 Instalando Docker no macOS...${NC}"
    if ! command_exists brew; then
        echo -e "${RED}❌ Homebrew não encontrado!${NC}"
        echo -e "${BLUE}📥 Por favor, instale o Homebrew primeiro:${NC}"
        echo -e "   👉 /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
    brew install --cask docker
    echo -e "${GREEN}✅ Docker instalado com sucesso! Por favor, abra o app Docker Desktop e aguarde ele inicializar.${NC}"
}

# Função para verificar e instalar Docker
check_and_install_docker() {
    if command_exists docker; then
        echo -e "${GREEN}✅ Docker já está instalado.${NC}"
        return
    fi
    
    echo -e "${YELLOW}⚠️  Docker não encontrado, instalando automaticamente...${NC}"
    detect_os
    case "$OS" in
        *"Ubuntu"*|*"Debian"*) install_docker_ubuntu ;;
        *"CentOS"*|*"Red Hat"*|*"Fedora"*) install_docker_centos ;;
        "macOS") install_docker_macos ;;
        *)
            echo -e "${RED}❌ ERRO: Sistema operacional não suportado para instalação automática: $OS${NC}"
            echo -e "${YELLOW}📥 Por favor, instale o Docker manualmente e execute este script novamente.${NC}"
            exit 1
            ;;
    esac
}

# Função para verificar Docker Compose
check_docker_compose() {
    if docker compose version >/dev/null 2>&1; then
        COMPOSE_CMD="docker compose"
        echo -e "${GREEN}✅ Docker Compose v2 encontrado!${NC}"
    elif command_exists docker-compose; then
        COMPOSE_CMD="docker-compose"
        echo -e "${GREEN}✅ Docker Compose v1 encontrado!${NC}"
    else
        echo -e "${RED}❌ ERRO: Docker Compose não foi encontrado, mesmo após a instalação do Docker.${NC}"
        exit 1
    fi
}

# Função para criar scripts de conveniência
create_convenience_scripts() {
    echo -e "\n${BLUE}📝 Criando scripts de conveniência...${NC}"
    
    # Script para iniciar
    cat > start-whisper.sh << EOF
#!/bin/bash
cd "\$(dirname "\$0")"
echo "🎙️ Iniciando e verificando atualizações do Whisper Transcriber..."
sudo $COMPOSE_CMD up --build -d
if [ \$? -eq 0 ]; then
    echo "✅ Whisper Transcriber iniciado com sucesso!"
    echo "🌐 Acesse: http://localhost:5000"
else
    echo "❌ Erro ao iniciar Whisper Transcriber"
fi
EOF

    # Script para parar
    cat > stop-whisper.sh << EOF
#!/bin/bash
cd "\$(dirname "\$0")"
echo "⏹️ Parando Whisper Transcriber..."
sudo $COMPOSE_CMD down
if [ \$? -eq 0 ]; then
    echo "✅ Whisper Transcriber parado com sucesso!"
else
    echo "❌ Erro ao parar Whisper Transcriber"
fi
EOF

    # Script para ver logs
    cat > logs-whisper.sh << EOF
#!/bin/bash
cd "\$(dirname "\$0")"
echo "📜 Mostrando logs do Whisper Transcriber (Pressione Ctrl+C para sair)..."
sudo $COMPOSE_CMD logs -f
EOF

    chmod +x start-whisper.sh stop-whisper.sh logs-whisper.sh
    echo -e "${GREEN}✅ Scripts 'start-whisper.sh', 'stop-whisper.sh', e 'logs-whisper.sh' criados.${NC}"
}

# Função principal
main() {
    print_header

    if [ ! -f "docker-compose.yml" ]; then
        echo -e "${RED}❌ ERRO: Execute este script a partir do diretório raiz do projeto (o que contém 'docker-compose.yml').${NC}"
        exit 1
    fi

    check_and_install_docker
    check_docker_compose

    echo -e "\n${BLUE}📁 Criando diretórios e arquivo .env (se não existirem)...${NC}"
    mkdir -p transcriber_web_app/videos
    mkdir -p transcriber_web_app/results

    echo -e "${BLUE}🔒 Ajustando permissoes dos diretorios de dados...${NC}"
    # UID/GID 1000 e o padrao para o primeiro usuario nao-root em muitas distros Linux
    # e o UID/GID que o appuser tera dentro do container.
    sudo chown -R 1000:1000 transcriber_web_app/videos
    sudo chown -R 1000:1000 transcriber_web_app/results
    # Garante que outros usuarios (appuser) possam ler e executar os diretorios
    sudo chmod -R a+rx transcriber_web_app/videos
    sudo chmod -R a+rx transcriber_web_app/results

    if [ ! -f ".env" ]; then
        echo "MAX_FILE_SIZE_GB=15" > .env
        echo "FLASK_ENV=development" >> .env
        echo "COMPOSE_PROJECT_NAME=transcribe" >> .env
    fi

    create_convenience_scripts

    echo -e "\n${BLUE}🏗️  Construindo e iniciando os serviços pela primeira vez...${NC}"
    echo -e "${YELLOW}⏳ Isso pode levar vários minutos...${NC}"

    sudo $COMPOSE_CMD up --build -d

    echo -e "\n\n${CYAN}                           ✅ INSTALAÇÃO CONCLUÍDA!${NC}"
    echo -e "${GREEN}🎉 O Whisper Transcriber está funcionando!${NC}\n"
    echo -e "${BLUE}🌐 Acesse: http://localhost:5000${NC}"
    echo -e "${BLUE}🔧 Para gerenciar, use os scripts: ./start-whisper.sh, ./stop-whisper.sh, ./logs-whisper.sh${NC}"
}

# Executar função principal
main
