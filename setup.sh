#!/bin/bash
# ============================================================================
# 🎙️ Whisper Transcriber - Instalação Super Fácil para Linux/macOS
# ============================================================================
# VERSÃO: 3.1 - Consolidada e Documentada
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
# - `git` para clonar o repositório (será instalado se não existir).
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
    echo -e "${YELLOW}⏳ Isso pode levar 5-10 minutos...${NC}\n"
    
    echo -e "${BLUE}� AProgresso da instalação:${NC}"
    
    # Atualizar sistema
    echo -e "   ${BLUE}[1/7]${NC} 📦 Atualizando sistema..."
    sudo apt update -y >/dev/null 2>&1
    echo -e "   ${GREEN}✅ Sistema atualizado!${NC}"
    
    # Instalar dependências
    echo -e "   ${BLUE}[2/7]${NC} 🔧 Instalando dependências..."
    sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release >/dev/null 2>&1
    echo -e "   ${GREEN}✅ Dependências instaladas!${NC}"
    
    # Adicionar chave GPG do Docker
    echo -e "   ${BLUE}[3/7]${NC} 🔑 Adicionando chave GPG do Docker..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg 2>/dev/null
    echo -e "   ${GREEN}✅ Chave GPG adicionada!${NC}"
    
    # Adicionar repositório do Docker
    echo -e "   ${BLUE}[4/7]${NC} 📦 Adicionando repositório do Docker..."
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    echo -e "   ${GREEN}✅ Repositório adicionado!${NC}"
    
    # Atualizar repositórios
    echo -e "   ${BLUE}[5/7]${NC} 🔄 Atualizando repositórios..."
    sudo apt update -y >/dev/null 2>&1
    echo -e "   ${GREEN}✅ Repositórios atualizados!${NC}"
    
    # Instalar Docker
    echo -e "   ${BLUE}[6/7]${NC} 🐳 Instalando Docker..."
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin >/dev/null 2>&1
    echo -e "   ${GREEN}✅ Docker instalado!${NC}"
    
    # Configurar Docker
    echo -e "   ${BLUE}[7/7]${NC} ⚙️ Configurando Docker..."
    sudo systemctl enable docker >/dev/null 2>&1
    sudo systemctl start docker >/dev/null 2>&1
    sudo usermod -aG docker $USER >/dev/null 2>&1
    echo -e "   ${GREEN}✅ Docker configurado!${NC}"
    
    echo -e "\n${GREEN}✅ Docker instalado com sucesso!${NC}"
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

# Função para verificar se o ambiente já está configurado
check_existing_environment() {
    echo -e "${BLUE}🔍 Verificando ambiente existente...${NC}"
    
    # Se o diretório de resultados e o .env existem, assume-se que a instalação já foi feita.
    if [ -d "transcriber_web_app/results" ] && [ -f ".env" ]; then
        echo -e "${GREEN}✅ Ambiente já configurado!${NC}"
        echo -e "${BLUE}🔄 Tentando atualizar o código e reiniciar os serviços...${NC}"
        
        if [ -d ".git" ]; then
            git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || {
                echo -e "${YELLOW}⚠️  Não foi possível atualizar via git, continuando...${NC}"
            }
        fi

        # Determina o comando do compose
        if docker compose version >/dev/null 2>&1; then
            COMPOSE_CMD="docker compose"
        elif command_exists docker-compose; then
            COMPOSE_CMD="docker-compose"
        else
             echo -e "${RED}❌ ERRO: Docker Compose não encontrado! Não é possível reiniciar.${NC}"
             exit 1
        fi

        echo -e "${BLUE}🔄 Reiniciando serviços...${NC}"
        sudo $COMPOSE_CMD down >/dev/null 2>&1
        sudo $COMPOSE_CMD up --build -d
        
        echo -e "${GREEN}✅ Atualização e reinicialização concluídas!${NC}"
        echo -e "${GREEN}🌐 Acesse: http://localhost:5000${NC}"
        exit 0
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
    echo -e "${YELLOW}⏳ Isso pode levar 5-15 minutos na primeira vez...${NC}"
    echo -e "${BLUE}💡 Baixando imagens Docker e construindo containers...${NC}\n"
    
    echo -e "${BLUE}📊 Progresso:${NC}"
    echo -e "   ${BLUE}[1/3]${NC} 📥 Baixando imagens base..."
    $COMPOSE_CMD pull >/dev/null 2>&1
    echo -e "   ${GREEN}✅ Imagens baixadas!${NC}"
    
    echo -e "   ${BLUE}[2/3]${NC} 🏗️  Construindo aplicação..."
    $COMPOSE_CMD build >/dev/null 2>&1
    echo -e "   ${GREEN}✅ Aplicação construída!${NC}"
    
    echo -e "   ${BLUE}[3/3]${NC} 🚀 Iniciando serviços..."
    if ! $COMPOSE_CMD up -d; then
        echo -e "\n${RED}❌ ERRO: Falha ao iniciar os serviços!${NC}\n"
        echo -e "${YELLOW}🔧 Possíveis soluções:${NC}"
        echo -e "   1. Verifique se o Docker está funcionando"
        echo -e "   2. Execute: $COMPOSE_CMD down"
        echo -e "   3. Tente novamente\n"
        echo -e "${BLUE}📋 Logs para diagnóstico:${NC}"
        $COMPOSE_CMD logs
        exit 1
    fi
    echo -e "   ${GREEN}✅ Serviços iniciados!${NC}"
    
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

# Função para criar scripts de conveniência
create_convenience_scripts() {
    echo -e "\n${BLUE}📝 Criando scripts de conveniência...${NC}"
    echo -e "${BLUE}💡 Estes scripts facilitarão o uso do Whisper Transcriber${NC}\n"
    
    echo -e "${BLUE}📊 Progresso dos scripts:${NC}"
    
    # Script para iniciar
    cat > start-whisper.sh << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
if docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi

echo "🎙️ Iniciando e verificando atualizacoes do Whisper Transcriber..."
sudo $COMPOSE_CMD up --build -d

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
sudo $COMPOSE_CMD down

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

    echo -e "   ${BLUE}[1/4]${NC} 📝 Criando start-whisper.sh..."
    echo -e "   ${GREEN}✅ Script de inicialização criado!${NC}"
    
    echo -e "   ${BLUE}[2/4]${NC} 📝 Criando stop-whisper.sh..."
    echo -e "   ${GREEN}✅ Script de parada criado!${NC}"
    
    echo -e "   ${BLUE}[3/4]${NC} 📝 Criando logs-whisper.sh..."
    echo -e "   ${GREEN}✅ Script de logs criado!${NC}"
    
    # Tornar scripts executáveis
    echo -e "   ${BLUE}[4/4]${NC} ⚙️ Tornando scripts executáveis..."
    chmod +x start-whisper.sh stop-whisper.sh logs-whisper.sh
    echo -e "   ${GREEN}✅ Permissões configuradas!${NC}"
    
    echo -e "\n${GREEN}✅ Scripts de conveniência criados com sucesso!${NC}"
    echo -e "${BLUE}📋 Scripts disponíveis:${NC}"
    echo -e "   ${GREEN}• start-whisper.sh${NC} - Iniciar serviços"
    echo -e "   ${GREEN}• stop-whisper.sh${NC}  - Parar serviços"
    echo -e "   ${GREEN}• logs-whisper.sh${NC}  - Ver logs em tempo real"
}

# Função principal
main() {
    print_header

    # Verificar se o script está no diretório correto
    if [ ! -f "docker-compose.yml" ]; then
        echo -e "${RED}❌ ERRO: Por favor, execute este script a partir do diretorio raiz do projeto.${NC}"
        echo -e "${YELLOW}O diretorio deve conter o arquivo 'docker-compose.yml'.${NC}"
        exit 1
    fi

    detect_os
    check_existing_environment
    check_and_install_docker
    check_docker_compose
    create_directories
    setup_env_file
    start_services
    create_convenience_scripts
    show_success
}

# Executar função principal
main