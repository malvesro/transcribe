#!/bin/bash
# ============================================================================
# 🎙️ Whisper Transcriber - Instalação Super Fácil para Linux/macOS
# ============================================================================
# Este script instala TUDO automaticamente - Docker nativo (sem Docker Desktop)
# Muito mais simples e leve!
# Versão: 3.0 - Docker nativo + Configuração automática
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
    echo -e "${BLUE}🔧 O que será instalado:${NC}"
    echo -e "   • Docker (motor de containers)${NC}"
    echo -e "   • Docker Compose (orquestração)${NC}"
    echo -e "   • Whisper Transcriber (nossa ferramenta)${NC}\n"
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
    
    # Atualizar sistema
    echo -e "${BLUE}📦 Atualizando sistema...${NC}"
    sudo apt update -y
    
    # Instalar dependências
    echo -e "${BLUE}🔧 Instalando dependências...${NC}"
    sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    # Adicionar chave GPG do Docker
    echo -e "${BLUE}🔑 Adicionando chave GPG do Docker...${NC}"
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Adicionar repositório do Docker
    echo -e "${BLUE}📦 Adicionando repositório do Docker...${NC}"
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Instalar Docker
    echo -e "${BLUE}🐳 Instalando Docker...${NC}"
    sudo apt update -y
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Configurar Docker
    echo -e "${BLUE}⚙️ Configurando Docker...${NC}"
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker $USER
    
    echo -e "${GREEN}✅ Docker instalado com sucesso!${NC}"
    echo -e "${YELLOW}⚠️  Você precisa fazer logout/login ou executar: newgrp docker${NC}"
}

# Função para instalar Docker no CentOS/RHEL/Fedora
install_docker_centos() {
    echo -e "${BLUE}🔧 Instalando Docker no CentOS/RHEL/Fedora...${NC}"
    
    # Instalar dependências
    sudo yum install -y yum-utils
    
    # Adicionar repositório do Docker
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    
    # Instalar Docker
    sudo yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Configurar Docker
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker $USER
    
    echo -e "${GREEN}✅ Docker instalado com sucesso!${NC}"
    echo -e "${YELLOW}⚠️  Você precisa fazer logout/login ou executar: newgrp docker${NC}"
}

# Função para instalar Docker no macOS
install_docker_macos() {
    echo -e "${BLUE}🔧 Instalando Docker no macOS...${NC}"
    
    if command_exists brew; then
        echo -e "${BLUE}🍺 Usando Homebrew para instalar Docker...${NC}"
        brew install --cask docker
        echo -e "${GREEN}✅ Docker instalado com sucesso!${NC}"
        echo -e "${YELLOW}⚠️  Abra o Docker Desktop e aguarde inicializar${NC}"
    else
        echo -e "${YELLOW}❌ Homebrew não encontrado!${NC}"
        echo -e "${BLUE}📥 Por favor, instale manualmente:${NC}"
        echo -e "   👉 https://docs.docker.com/desktop/mac/install/"
        echo -e "\n${YELLOW}Ou instale o Homebrew primeiro:${NC}"
        echo -e "   👉 /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
}

# Função para verificar e instalar Docker
check_and_install_docker() {
    echo -e "${BLUE}🔍 Verificando Docker...${NC}"
    
    if command_exists docker; then
        echo -e "${GREEN}✅ Docker encontrado!${NC}"
        
        # Verificar se Docker está rodando
        echo -e "${BLUE}🔍 Verificando se Docker está rodando...${NC}"
        if ! docker info >/dev/null 2>&1; then
            echo -e "${YELLOW}⚠️  Docker não está rodando, tentando iniciar...${NC}"
            
            if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
                sudo systemctl start docker
            elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]] || [[ "$OS" == *"Fedora"* ]]; then
                sudo systemctl start docker
            elif [[ "$OS" == "macOS" ]]; then
                echo -e "${YELLOW}⚠️  Abra o Docker Desktop e aguarde inicializar${NC}"
                echo -e "${BLUE}Aguardando Docker inicializar...${NC}"
                for i in {1..30}; do
                    if docker info >/dev/null 2>&1; then
                        break
                    fi
                    sleep 2
                    echo -n "."
                done
                echo ""
            fi
            
            # Verificar novamente
            if ! docker info >/dev/null 2>&1; then
                echo -e "${RED}❌ ERRO: Não foi possível iniciar o Docker${NC}"
                exit 1
            fi
        fi
        
        echo -e "${GREEN}✅ Docker está funcionando!${NC}"
        return
    fi
    
    # Docker não encontrado, instalar automaticamente
    echo -e "${YELLOW}⚠️  Docker não encontrado, instalando automaticamente...${NC}"
    
    detect_os
    
    case "$OS" in
        *"Ubuntu"*|*"Debian"*)
            install_docker_ubuntu
            ;;
        *"CentOS"*|*"Red Hat"*|*"Fedora"*)
            install_docker_centos
            ;;
        "macOS")
            install_docker_macos
            ;;
        *)
            echo -e "${RED}❌ ERRO: Sistema operacional não suportado: $OS${NC}"
            echo -e "${YELLOW}📥 Por favor, instale o Docker manualmente:${NC}"
            echo -e "   👉 https://docs.docker.com/engine/install/"
            exit 1
            ;;
    esac
    
    # Verificar se a instalação foi bem-sucedida
    if ! command_exists docker; then
        echo -e "${RED}❌ ERRO: Falha na instalação do Docker${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ Docker instalado e configurado!${NC}"
}

# Função para verificar Docker Compose
check_docker_compose() {
    echo -e "${BLUE}🔍 Verificando Docker Compose...${NC}"
    
    if docker compose version >/dev/null 2>&1; then
        COMPOSE_CMD="docker compose"
        echo -e "${GREEN}✅ Docker Compose v2 encontrado!${NC}"
    elif command_exists docker-compose; then
        COMPOSE_CMD="docker-compose"
        echo -e "${GREEN}✅ Docker Compose v1 encontrado!${NC}"
    else
        echo -e "\n${RED}❌ ERRO: Docker Compose não encontrado!${NC}\n"
        echo -e "${YELLOW}📥 Por favor, instale o Docker Compose:${NC}"
        echo -e "   👉 https://docs.docker.com/compose/install/\n"
        exit 1
    fi
}

# Função para criar diretórios
create_directories() {
    echo -e "\n${BLUE}📁 Criando diretórios necessários...${NC}"
    
    mkdir -p transcriber_web_app/videos
    mkdir -p transcriber_web_app/results
    
    echo -e "${GREEN}✅ Diretórios criados!${NC}"
}

# Função para configurar arquivo .env
setup_env_file() {
    echo -e "\n${BLUE}⚙️ Configurando limite de arquivo...${NC}"
    
    if [ ! -f ".env" ]; then
        cat > .env << EOF
# Configurações do Whisper Transcriber
MAX_FILE_SIZE_GB=15
FLASK_ENV=development
COMPOSE_PROJECT_NAME=transcribe
EOF
        echo -e "${GREEN}✅ Arquivo .env criado com limite de 15GB${NC}"
    else
        echo -e "${GREEN}✅ Arquivo .env já existe${NC}"
    fi
}

# Função para iniciar serviços
start_services() {
    echo -e "\n${BLUE}🏗️ Construindo e iniciando os serviços...${NC}"
    echo -e "${YELLOW}⏳ Isso pode levar alguns minutos na primeira vez...${NC}\n"
    
    if ! $COMPOSE_CMD up --build -d; then
        echo -e "\n${RED}❌ ERRO: Falha ao iniciar os serviços!${NC}\n"
        echo -e "${YELLOW}🔧 Possíveis soluções:${NC}"
        echo -e "   1. Verifique se o Docker está funcionando"
        echo -e "   2. Execute: $COMPOSE_CMD down"
        echo -e "   3. Tente novamente\n"
        exit 1
    fi
    
    # Aguardar serviços ficarem prontos
    echo -e "\n${BLUE}⏳ Aguardando serviços ficarem prontos...${NC}"
    sleep 10
    
    # Mostrar status dos serviços
    $COMPOSE_CMD ps
}

# Função para mostrar resultado final
show_success() {
    echo -e "\n${CYAN}████████████████████████████████████████████████████████████████████████████${NC}"
    echo -e "${CYAN}                           ✅ INSTALAÇÃO CONCLUÍDA!${NC}"
    echo -e "${CYAN}████████████████████████████████████████████████████████████████████████████${NC}\n"
    
    echo -e "${GREEN}🎉 O Whisper Transcriber está funcionando!${NC}\n"
    
    echo -e "${BLUE}🌐 Acesse: http://localhost:5000${NC}\n"
    
    echo -e "${BLUE}📁 Coloque seus arquivos de vídeo/áudio em:${NC}"
    echo -e "   📂 $(pwd)/transcriber_web_app/videos/\n"
    
    echo -e "${BLUE}📊 Limite atual de arquivo: 15GB${NC}"
    echo -e "   💡 Para alterar: edite o arquivo .env\n"
    
    echo -e "${BLUE}🔧 Comandos úteis:${NC}"
    echo -e "   ▶️  Iniciar:  $COMPOSE_CMD up -d"
    echo -e "   ⏹️  Parar:    $COMPOSE_CMD down"
    echo -e "   📋 Status:   $COMPOSE_CMD ps"
    echo -e "   📜 Logs:     $COMPOSE_CMD logs -f\n"
    
    # Tentar abrir o navegador
    if command_exists open; then
        echo -e "${BLUE}🚀 Abrindo o navegador...${NC}"
        open http://localhost:5000
    elif command_exists xdg-open; then
        echo -e "${BLUE}🚀 Abrindo o navegador...${NC}"
        xdg-open http://localhost:5000
    else
        echo -e "${YELLOW}💡 Abra manualmente: http://localhost:5000${NC}"
    fi
    
    echo -e "\n${GREEN}Pressione Enter para sair...${NC}"
    read
}

# Função para baixar projeto
download_project() {
    echo -e "\n${BLUE}📥 Baixando Whisper Transcriber...${NC}"
    
    if [ -d "transcribe" ]; then
        echo -e "${YELLOW}⚠️  Diretório 'transcribe' já existe, removendo...${NC}"
        rm -rf transcribe
    fi
    
    if command_exists git; then
        git clone https://github.com/malvesro/transcribe.git
        cd transcribe
    else
        echo -e "${YELLOW}⚠️  Git não encontrado, instalando...${NC}"
        if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
            sudo apt install -y git
        elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]] || [[ "$OS" == *"Fedora"* ]]; then
            sudo yum install -y git
        elif [[ "$OS" == "macOS" ]]; then
            if command_exists brew; then
                brew install git
            else
                echo -e "${RED}❌ ERRO: Não foi possível instalar git${NC}"
                exit 1
            fi
        fi
        
        git clone https://github.com/malvesro/transcribe.git
        cd transcribe
    fi
    
    echo -e "${GREEN}✅ Projeto baixado com sucesso!${NC}"
}

# Função para criar scripts de conveniência
create_convenience_scripts() {
    echo -e "\n${BLUE}📝 Criando scripts de conveniência...${NC}"
    
    # Script para iniciar
    cat > start-whisper.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi

echo "🎙️ Iniciando Whisper Transcriber..."
$COMPOSE_CMD up -d

if [ $? -eq 0 ]; then
    echo "✅ Whisper Transcriber iniciado com sucesso!"
    echo "🌐 Acesse: http://localhost:5000"
else
    echo "❌ Erro ao iniciar Whisper Transcriber"
    exit 1
fi
EOF

    # Script para parar
    cat > stop-whisper.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi

echo "⏹️ Parando Whisper Transcriber..."
$COMPOSE_CMD down

if [ $? -eq 0 ]; then
    echo "✅ Whisper Transcriber parado com sucesso!"
else
    echo "❌ Erro ao parar Whisper Transcriber"
    exit 1
fi
EOF

    # Script para ver logs
    cat > logs-whisper.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi

echo "📜 Mostrando logs do Whisper Transcriber..."
echo "Pressione Ctrl+C para sair"
$COMPOSE_CMD logs -f
EOF

    # Tornar scripts executáveis
    chmod +x start-whisper.sh stop-whisper.sh logs-whisper.sh
    
    echo -e "${GREEN}✅ Scripts de conveniência criados!${NC}"
    echo -e "${BLUE}   • start-whisper.sh - Iniciar serviços${NC}"
    echo -e "${BLUE}   • stop-whisper.sh  - Parar serviços${NC}"
    echo -e "${BLUE}   • logs-whisper.sh  - Ver logs${NC}"
}

# Função principal
main() {
    print_header
    detect_os
    check_and_install_docker
    check_docker_compose
    download_project
    create_directories
    setup_env_file
    start_services
    create_convenience_scripts
    show_success
}

# Executar função principal
main