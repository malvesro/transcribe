# 📋 Requisitos Completos - Whisper Transcriber

Este documento detalha todos os requisitos de sistema, software e hardware necessários para executar o Whisper Transcriber em diferentes cenários de uso.

## 📑 Índice

- [Visão Geral](#-visão-geral)
- [Requisitos por Cenário de Uso](#-requisitos-por-cenário-de-uso)
- [Requisitos de Sistema Operacional](#-requisitos-de-sistema-operacional)
- [Requisitos de Hardware](#-requisitos-de-hardware)
- [Requisitos de Software](#-requisitos-de-software)
- [Requisitos de Rede](#-requisitos-de-rede)
- [Requisitos de Armazenamento](#-requisitos-de-armazenamento)
- [Dependências Python](#-dependências-python)
- [Configurações de Ambiente](#-configurações-de-ambiente)
- [Requisitos de Segurança](#-requisitos-de-segurança)
- [Requisitos de Performance](#-requisitos-de-performance)
- [Troubleshooting](#-troubleshooting)

## 🎯 Visão Geral

O Whisper Transcriber é uma aplicação web containerizada que utiliza Docker para orquestrar dois serviços principais:
- **WebApp (Flask)**: Interface web e API
- **Whisper Worker**: Processamento de transcrição com IA

## 🎭 Requisitos por Cenário de Uso

### 1. 👤 Usuário Final (Instalação Automática)

A forma recomendada de instalação é através dos nossos scripts automáticos. Eles cuidam de todas as dependências complexas para você.

**Requisitos Essenciais:**
- **Sistema Operacional**: Windows 10 (2004+)/11 ou Linux/macOS recente.
- **Memória RAM**: Mínimo de 8GB.
- **Armazenamento**: Mínimo de 50GB de espaço livre.
- **Privilégios**: Acesso de Administrador/sudo durante a instalação.
- **Internet**: Conexão estável para baixar os componentes (~2-5GB).

**O que o Instalador Automático Faz por Você:**
- No **Windows**, configura o ambiente WSL2, Ubuntu e Docker.
- No **Linux/macOS**, instala o Docker e suas dependências.
- Baixa o código da aplicação.
- Constrói e inicia a aplicação.
- Cria scripts de atalho para facilitar o uso (`start.bat`, `stop.bat`, etc.).

### 2. 🧑‍💻 Desenvolvedor (Instalação Manual)

**Cenário**: Desenvolvedor que quer controle total sobre a instalação.

#### Requisitos:
- **Sistema**: Windows 10+, Linux (Ubuntu 20.04+), macOS 10.15+
- **RAM**: 8GB (16GB recomendado para desenvolvimento)
- **Armazenamento**: 50GB livres
- **Docker**: 20.10.0+ com Docker Compose
- **Python**: 3.10+ (para testes locais)
- **Git**: Para clonar o repositório

#### Instalação Manual:
```bash
# 1. Clonar repositório
git clone https://github.com/malvesro/transcribe.git
cd transcribe

# 2. Configurar ambiente
cp .env.example .env
# Editar .env conforme necessário

# 3. Iniciar serviços
docker compose up --build -d
```

### 3. 🏢 Uso Corporativo/Produção

**Cenário**: Organização processando grandes volumes de arquivos.

#### Requisitos Avançados:
- **Sistema**: Linux Server (Ubuntu 22.04 LTS recomendado)
- **RAM**: 32GB+ (para processamento paralelo)
- **CPU**: 16+ cores (Intel Xeon ou AMD EPYC)
- **GPU**: NVIDIA RTX 4090/A100 (para aceleração)
- **Armazenamento**: 1TB+ SSD NVMe
- **Rede**: 1Gbps+ para uploads grandes
- **Backup**: Sistema de backup automatizado

#### Configurações Especiais:
```bash
# Arquivo .env para produção
MAX_FILE_SIZE_GB=100
TRANSCRIPTION_TIMEOUT=14400
FLASK_ENV=production
SECRET_KEY=sua-chave-super-secreta-aqui
```

### 4. 🏢 Usuário Corporativo (Sem Privilégios de Administrador)

**Cenário**: Você está em um ambiente corporativo onde não tem permissões de administrador para instalar softwares.

**Como proceder:**
1.  **Peça ao seu TI**: A instalação das dependências principais (WSL2, Ubuntu, Docker) **deve** ser feita pelo seu departamento de TI ou por um usuário com privilégios de administrador.
2.  **Use o script de verificação**: Após o TI preparar a máquina, execute o script `instalar-windows.bat`. Ele não tentará instalar nada, mas verificará se o ambiente está pronto e configurará o projeto para você.
3.  **Instruções para o TI**: Você pode fornecer as seguintes instruções para o seu administrador de TI:
    > "Para preparar meu computador para o Whisper Transcriber, por favor:
    > 1.  Certifique-se de que a virtualização (Hyper-V) está habilitada na BIOS.
    > 2.  Instale o WSL2 e a distribuição 'Ubuntu' da Microsoft Store.
    > 3.  Dentro do Ubuntu, instale o Docker (`sudo apt-get install docker.io`) e o Docker Compose (`sudo apt-get install docker-compose`).
    > 4.  Adicione meu usuário do Windows ao grupo 'docker' no Ubuntu (`sudo usermod -aG docker $USER`)."

## 💻 Requisitos de Sistema Operacional

### Windows

#### Versões Suportadas:
- ✅ **Windows 11** (todas as versões)
- ✅ **Windows 10** (versão 2004, build 19041 ou superior)

#### O que é WSL2 e por que é necessário?
Para rodar a aplicação de forma segura e isolada, utilizamos o **Docker**. No Windows, a melhor forma de fazer isso é através do **WSL2 (Subsistema Windows para Linux)**.
- O WSL2 é um **recurso oficial da Microsoft** que permite executar um ambiente Linux diretamente no Windows.
- Nosso instalador automatiza a configuração do WSL2 e do Ubuntu (uma distribuição Linux popular) para criar o ambiente perfeito para a aplicação, sem interferir com o resto do seu sistema.

#### Recursos Necessários:
- **Virtualização (Hyper-V)**: Precisa estar habilitada na BIOS/UEFI do seu computador. O script de instalação irá verificar isso para você.
- **WSL2 e Ubuntu**: Serão instalados e configurados automaticamente pelo script `instalar-windows.bat`.

#### Verificação de Compatibilidade:
```powershell
# Verificar versão do Windows
winver

# Verificar se virtualização está habilitada
systeminfo | findstr /i "hyper-v"
```

### Linux

#### Distribuições Testadas:
- ✅ **Ubuntu** 20.04 LTS, 22.04 LTS, 24.04 LTS
- ✅ **Debian** 11 (Bullseye), 12 (Bookworm)
- ✅ **CentOS** 8, 9
- ✅ **RHEL** 8, 9
- ✅ **Fedora** 36, 37, 38
- ✅ **Arch Linux** (rolling release)

#### Kernel Mínimo:
- **Versão**: 4.15+ (5.4+ recomendado)
- **Módulos**: cgroups v2, overlay filesystem

#### Verificação:
```bash
# Verificar versão do kernel
uname -r

# Verificar suporte a containers
docker info
```

### macOS

#### Versões Suportadas:
- ✅ **macOS Monterey** (12.0+)
- ✅ **macOS Big Sur** (11.0+)
- ✅ **macOS Catalina** (10.15+)
- ❌ **macOS Mojave e anteriores** (não suportados)

#### Arquiteturas:
- ✅ **Intel x86_64** (Mac Intel)
- ✅ **Apple Silicon M1/M2** (Mac ARM)

#### Verificação:
```bash
# Verificar versão do macOS
sw_vers

# Verificar arquitetura
uname -m
```

## 🖥️ Requisitos de Hardware

### CPU (Processador)

#### Mínimo:
- **Arquitetura**: x86_64 (AMD64)
- **Cores**: 2 cores físicos
- **Frequência**: 2.0 GHz
- **Suporte**: SSE4.2, AVX (recomendado)

#### Recomendado:
- **Cores**: 8+ cores físicos
- **Frequência**: 3.0+ GHz
- **Arquitetura**: Intel Core i7/i9, AMD Ryzen 7/9

#### Para Produção:
- **Cores**: 16+ cores físicos
- **Processadores**: Intel Xeon, AMD EPYC, AMD Threadripper

### Memória RAM

#### Por Cenário de Uso:

| Cenário | Mínimo | Recomendado | Ideal |
|---------|--------|-------------|-------|
| **Uso Pessoal** | 4GB | 8GB | 16GB |
| **Desenvolvimento** | 8GB | 16GB | 32GB |
| **Produção Pequena** | 16GB | 32GB | 64GB |
| **Produção Grande** | 32GB | 64GB | 128GB+ |

#### Considerações:
- **Docker**: Consome ~2GB base
- **Whisper Small**: ~1GB VRAM/RAM
- **Whisper Large**: ~6GB VRAM/RAM
- **Arquivos Grandes**: RAM adicional para buffering

### GPU (Aceleração - Opcional)

#### NVIDIA (Recomendado):
- **Arquitetura**: Pascal (GTX 10xx) ou superior
- **VRAM**: 4GB+ (8GB+ recomendado)
- **Drivers (Linux/macOS)**: Drivers NVIDIA atualizados e NVIDIA Container Toolkit.
- **Drivers (Windows com WSL2)**: Basta ter o driver NVIDIA mais recente (Game Ready ou Studio) instalado no **Windows**. Não é necessário instalar drivers dentro do ambiente Ubuntu/WSL.

#### Modelos Testados:
- ✅ **RTX 4090** (24GB VRAM) - Excelente
- ✅ **RTX 4080** (16GB VRAM) - Muito bom
- ✅ **RTX 3080** (10GB VRAM) - Bom
- ✅ **RTX 3070** (8GB VRAM) - Adequado
- ⚠️ **GTX 1660** (6GB VRAM) - Limitado para modelos grandes

#### Performance Esperada:
```
Arquivo de 1 hora de áudio:
- CPU apenas: 15-30 minutos
- RTX 3070: 3-5 minutos
- RTX 4090: 1-2 minutos
```

### Armazenamento

#### Tipos Recomendados:
- ✅ **SSD NVMe** (melhor performance)
- ✅ **SSD SATA** (boa performance)
- ⚠️ **HDD 7200 RPM** (performance limitada)
- ❌ **HDD 5400 RPM** (não recomendado)

#### Espaço Necessário:

| Componente | Espaço |
|------------|--------|
| **Sistema Base** | 10GB |
| **Docker Images** | 8GB |
| **Modelos Whisper** | 1-5GB |
| **Arquivos Temporários** | Variável |
| **Logs e Cache** | 1GB |

#### Cálculo para Arquivos:
```bash
# Use o script de estimativa
python transcriber_web_app/manage_config.py estimate-disk --size 25 --jobs 10

# Resultado exemplo para arquivos de 25GB:
# 📁 Arquivos originais (10 jobs): 250.0GB
# 📄 Resultados de transcrição: 0.010GB
# 🧠 Cache de modelos Whisper: 5GB
# 🛡️  Margem de segurança (20%): 51.0GB
# 💽 Total recomendado: 306.0GB
```

## 💾 Requisitos de Software

### Docker Engine

#### Versões Suportadas:
- **Mínimo**: Docker 20.10.0
- **Recomendado**: Docker 24.0.0+
- **Docker Compose**: 2.0.0+ (v2 syntax)

#### Instalação Automática:
```bash
# Os scripts de instalação configuram automaticamente:
# - Docker Engine
# - Docker Compose
# - NVIDIA Container Toolkit (se GPU disponível)
# - Configurações de usuário
```

#### Verificação:
```bash
# Verificar versões
docker --version
docker compose version

# Testar funcionamento
docker run hello-world
```

### Python (Para Desenvolvimento)

#### Versão:
- **Mínimo**: Python 3.10
- **Recomendado**: Python 3.11+
- **Não suportado**: Python 3.9 e anteriores

#### Gerenciadores de Pacote:
- ✅ **pip** (padrão)
- ✅ **conda** (anaconda/miniconda)
- ✅ **poetry** (para desenvolvimento)

#### Verificação:
```bash
# Verificar versão
python --version
python3 --version

# Verificar pip
pip --version
```

### Git (Para Desenvolvimento)

#### Versão:
- **Mínimo**: Git 2.20+
- **Recomendado**: Git 2.40+

#### Configuração:
```bash
# Configuração básica
git config --global user.name "Seu Nome"
git config --global user.email "seu@email.com"

# Verificar configuração
git config --list
```

## 🌐 Requisitos de Rede

### Conectividade de Internet

#### Durante Instalação:
- **Largura de Banda**: 10 Mbps+ recomendado
- **Downloads**: ~2-5GB (Docker images, modelos)
- **Tempo Estimado**: 10-30 minutos (dependendo da conexão)

#### Durante Uso:
- **Uploads**: Dependente do tamanho dos arquivos
- **Largura de Banda**: 1 Mbps mínimo para arquivos pequenos
- **Para arquivos grandes**: 100 Mbps+ recomendado

### Portas de Rede

#### Portas Utilizadas:
- **5000/tcp**: Interface web principal
- **Outras portas**: Apenas comunicação interna entre containers

#### Configuração de Firewall:
```bash
# Linux (ufw)
sudo ufw allow 5000/tcp

# Windows Firewall
# O instalador do WSL e Docker geralmente lida com as regras necessarias.
# Se houver problemas, permita o acesso da porta 5000 para o WSL.
```

### Proxy/Firewall Corporativo

#### Configurações Docker:
```json
// ~/.docker/config.json
{
  "proxies": {
    "default": {
      "httpProxy": "http://proxy.empresa.com:8080",
      "httpsProxy": "http://proxy.empresa.com:8080",
      "noProxy": "localhost,127.0.0.1"
    }
  }
}
```

## 📦 Dependências Python

As dependências do projeto são gerenciadas em dois locais, um para cada container, para manter os ambientes isolados e otimizados.

### Dependências da WebApp (`transcriber_web_app/requirements.txt`)

Estas são as dependências para a interface web e o gerenciamento dos workers.

```
Flask>=2.3.0              # Framework web
python-dotenv>=1.0.0      # Gerenciamento de variáveis de ambiente
requests>=2.31.0          # Cliente HTTP
Werkzeug>=2.3.0          # Utilitários WSGI
docker>=6.1.0            # SDK Python para Docker
pytest>=7.4.0           # Framework de testes
pytest-cov>=4.1.0       # Cobertura de testes
```

### Dependências do Whisper Worker

Estas dependências são definidas diretamente no `Dockerfile.whisper` e incluem a biblioteca do Whisper e o PyTorch para processamento de IA.

```
torch>=2.0.0             # PyTorch (deep learning)
torchvision>=0.15.0      # Visão computacional
torchaudio>=2.0.0        # Processamento de áudio
openai-whisper>=20231117 # Modelo Whisper da OpenAI
```

### Instalação Manual das Dependências:
```bash
# Instalar dependências da webapp
pip install -r transcriber_web_app/requirements.txt

# Para desenvolvimento completo (opcional)
pip install -r transcriber_web_app/requirements.txt
pip install black flake8 mypy  # Ferramentas de desenvolvimento
```

### Verificação das Dependências:
```bash
# Verificar instalação
python -c "import flask, docker, pytest; print('✅ Dependências OK')"

# Listar versões instaladas
pip list | grep -E "(flask|docker|pytest)"
```

## ⚙️ Configurações de Ambiente

### Variáveis de Ambiente Principais

#### Arquivo `.env` (baseado em `.env.example`):
```bash
# Ambiente da aplicação
FLASK_ENV=development                    # ou 'production'

# Identificação do projeto Docker
COMPOSE_PROJECT_NAME=transcribe

# Segurança
SECRET_KEY=sua-chave-secreta-aqui       # OBRIGATÓRIO em produção

# Limites de arquivo
MAX_FILE_SIZE_GB=15                     # Padrão: 15GB

# Timeouts e intervalos
TRANSCRIPTION_TIMEOUT=3600              # 1 hora em segundos
STATUS_POLL_INTERVAL=5000               # 5 segundos em ms
```

### Configurações por Ambiente

#### Desenvolvimento:
```bash
FLASK_ENV=development
MAX_FILE_SIZE_GB=5
TRANSCRIPTION_TIMEOUT=1800
SECRET_KEY=dev-secret-change-in-production
```

#### Produção:
```bash
FLASK_ENV=production
MAX_FILE_SIZE_GB=50
TRANSCRIPTION_TIMEOUT=7200
SECRET_KEY=chave-super-secreta-gerada-aleatoriamente
```

#### Uso Corporativo:
```bash
FLASK_ENV=production
MAX_FILE_SIZE_GB=100
TRANSCRIPTION_TIMEOUT=14400
STATUS_POLL_INTERVAL=10000
SECRET_KEY=chave-corporativa-ultra-secreta
```

### Gerenciamento de Configurações:
```bash
# Ver configurações atuais
python transcriber_web_app/manage_config.py show

# Alterar limite de arquivo
python transcriber_web_app/manage_config.py set-size --size 25

# Estimar espaço necessário
python transcriber_web_app/manage_config.py estimate-disk --size 25 --jobs 10
```

## 🔒 Requisitos de Segurança

### Permissões de Sistema

#### Durante Instalação:
- **Windows**: Privilégios de Administrador
- **Linux/macOS**: Acesso sudo
- **Finalidade**: Instalar Docker e configurar sistema

#### Durante Execução:
- **Usuário normal**: Não requer privilégios elevados
- **Docker**: Usuário deve estar no grupo `docker` (Linux)

### Configurações de Segurança

#### Chave Secreta Flask:
```bash
# Gerar chave segura
python -c "import secrets; print(secrets.token_hex(32))"

# Definir no .env
SECRET_KEY=sua-chave-gerada-aqui
```

#### Isolamento de Containers:
- **Rede isolada**: Containers em rede privada
- **Volumes limitados**: Apenas diretórios necessários
- **Usuário não-root**: Container webapp roda como usuário limitado

#### Validação de Entrada:
- **Extensões de arquivo**: Apenas formatos de mídia permitidos
- **Tamanho de arquivo**: Limites configuráveis
- **Path traversal**: Proteção contra ataques de diretório

### Considerações de Produção:
```bash
# Configurações adicionais recomendadas
# 1. Reverse proxy (nginx/apache)
# 2. SSL/TLS certificates
# 3. Rate limiting
# 4. Monitoring e logging
# 5. Backup automatizado
```

## ⚡ Requisitos de Performance

### Benchmarks de Performance

#### Tempo de Transcrição (arquivo de 1 hora):

| Configuração | Modelo Small | Modelo Medium | Modelo Large |
|--------------|--------------|---------------|--------------|
| **CPU i5 (4 cores)** | 15 min | 25 min | 45 min |
| **CPU i7 (8 cores)** | 8 min | 15 min | 25 min |
| **RTX 3070 + CPU** | 3 min | 5 min | 8 min |
| **RTX 4090 + CPU** | 1 min | 2 min | 3 min |

#### Uso de Recursos:

| Componente | Idle | Processando | Pico |
|------------|------|-------------|------|
| **CPU** | 5% | 80-100% | 100% |
| **RAM** | 2GB | 4-8GB | 12GB |
| **GPU VRAM** | 0GB | 2-6GB | 8GB |
| **Disco I/O** | Baixo | Alto | Muito Alto |

### Otimizações de Performance:

#### Para CPU:
```bash
# Usar modelo menor para arquivos longos
# small: mais rápido, menos preciso
# medium: balanceado
# large: mais lento, mais preciso
```

#### Para GPU:
```bash
# Verificar se GPU está sendo usada
docker compose logs whisper_worker | grep -i cuda

# Monitorar uso da GPU
nvidia-smi -l 1
```

#### Para Armazenamento:
```bash
# Usar SSD para melhor I/O
# Limpar arquivos antigos regularmente
# Monitorar espaço disponível
df -h
```

## 🔧 Troubleshooting

### Problemas Comuns e Soluções

#### 1. Docker não inicia
```bash
# Verificar status do Docker
systemctl status docker  # Linux
# ou verificar Docker Desktop (Windows/macOS)

# Reiniciar Docker
sudo systemctl restart docker  # Linux
```

#### 2. Erro de permissão Docker
```bash
# Adicionar usuário ao grupo docker (Linux)
sudo usermod -aG docker $USER
# Fazer logout/login para aplicar
```

#### 3. Falta de espaço em disco
```bash
# Limpar containers e images não utilizados
docker system prune -a

# Verificar espaço
df -h
docker system df
```

#### 4. GPU não detectada
```bash
# Verificar drivers NVIDIA
nvidia-smi

# Verificar NVIDIA Container Toolkit
docker run --rm --gpus all nvidia/cuda:11.8-base-ubuntu22.04 nvidia-smi
```

#### 5. Arquivo muito grande
```bash
# Aumentar limite no .env
MAX_FILE_SIZE_GB=50

# Reiniciar aplicação
docker compose restart
```

#### 6. Transcrição muito lenta
```bash
# Verificar se GPU está sendo usada
docker compose logs whisper_worker | grep -i gpu

# Usar modelo menor
# small em vez de large para arquivos longos
```

### Logs e Diagnóstico:
```bash
# Ver logs da aplicação
docker compose logs -f

# Ver logs específicos
docker compose logs webapp
docker compose logs whisper_worker

# Verificar saúde dos serviços
python transcriber_web_app/healthcheck.py
```

### Suporte e Comunidade:
- **Issues GitHub**: Para bugs e problemas técnicos
- **Documentação**: TESTING.md, README.md
- **Logs detalhados**: Sempre incluir logs ao reportar problemas

---

## 📊 Resumo de Requisitos por Cenário

### 🏠 Uso Doméstico
- **OS**: Windows 10+, Linux, macOS
- **RAM**: 8GB
- **Storage**: 50GB
- **Internet**: 10 Mbps
- **Instalação**: Automática

### 🧑‍💻 Desenvolvimento
- **OS**: Qualquer suportado
- **RAM**: 16GB
- **Storage**: 100GB SSD
- **Tools**: Docker, Python, Git
- **Instalação**: Manual

### 🏢 Produção
- **OS**: Linux Server
- **RAM**: 32GB+
- **Storage**: 500GB+ SSD
- **GPU**: NVIDIA RTX/Tesla
- **Network**: 1Gbps+
- **Backup**: Obrigatório

---

**Este documento é atualizado regularmente. Para a versão mais recente, consulte o repositório oficial.**
[end of REQUIREMENTS.md]
