# 🧪 Guia Completo de Testes - Whisper Transcriber

Este guia fornece instruções detalhadas sobre como executar, entender e contribuir com os testes do projeto Whisper Transcriber.

## 📋 Índice

- [Visão Geral](#-visão-geral)
- [Tipos de Testes](#-tipos-de-testes)
- [Configuração do Ambiente](#-configuração-do-ambiente)
- [Executando os Testes](#-executando-os-testes)
- [Estrutura dos Testes](#-estrutura-dos-testes)
- [Categorias de Teste](#-categorias-de-teste)
- [Troubleshooting](#-troubleshooting)
- [Contribuindo com Testes](#-contribuindo-com-testes)

## 🎯 Visão Geral

O projeto possui uma suíte abrangente de testes que garante a qualidade e segurança da aplicação. Os testes são organizados para funcionar tanto em ambientes com Docker quanto sem Docker, proporcionando flexibilidade para diferentes cenários de desenvolvimento.

### Por que Testes Separados?

- **Testes Locais**: Executam rapidamente sem dependências externas
- **Testes Completos**: Validam integração real com Docker
- **Flexibilidade**: Desenvolvedores podem testar mesmo sem Docker configurado

## 🔧 Tipos de Testes

### 1. 🏠 Testes Locais (`test_local.py`)
**Executam sem Docker** - Ideais para desenvolvimento rápido

- ✅ Validação de arquivos e extensões
- ✅ Testes de rotas básicas (index, config)
- ✅ Validação de segurança (path traversal)
- ✅ Testes de configuração
- ⚡ **Vantagem**: Execução rápida, sem dependências

### 2. 🐳 Testes Completos (`test_app.py`)
**Requerem Docker** - Validam funcionalidade completa

- ✅ Todos os testes locais +
- ✅ Integração com Docker API
- ✅ Upload real de arquivos
- ✅ Comunicação entre containers
- 🎯 **Vantagem**: Testa cenário real de produção

### 3. 💊 Testes de Saúde (`healthcheck.py`)
**Monitoramento de serviços**

- ✅ Status da aplicação Flask
- ✅ Conectividade com Docker
- ✅ Disponibilidade de recursos

## ⚙️ Configuração do Ambiente

### Pré-requisitos Mínimos
```bash
# Python 3.10+ (obrigatório)
python --version

# Git (para clonar o projeto)
git --version
```

### Instalação das Dependências
```bash
# 1. Navegar para o diretório do projeto
cd transcribe

# 2. Instalar dependências Python
pip install -r transcriber_web_app/requirements.txt

# 3. Instalar ferramentas de teste (se não estiverem incluídas)
pip install pytest pytest-cov

# 4. Verificar instalação
python -c "import flask, docker, pytest; print('✅ Dependências OK')"
```

### Configuração Opcional do Docker
```bash
# Para testes completos (opcional)
docker --version
docker compose --version

# Verificar se Docker está rodando
docker info
```

## 🚀 Executando os Testes

### Método Recomendado: Script Inteligente

O script `run_tests.py` detecta automaticamente seu ambiente e executa os testes apropriados:

```bash
# Execução automática (recomendado)
python run_tests.py
```

**O que acontece:**
- 🔍 Verifica dependências Python
- 🐳 Detecta se Docker está disponível
- 🧪 Executa testes locais OU completos automaticamente
- 📊 Mostra relatório de resultados

### Execução Manual por Tipo

#### Apenas Testes Locais (Sem Docker)
```bash
# Opção 1: Via script
python run_tests.py --local

# Opção 2: Direto
cd transcriber_web_app
python test_local.py

# Opção 3: Com pytest
python -m pytest transcriber_web_app/test_local.py -v
```

#### Todos os Testes (Com Docker)
```bash
# Opção 1: Via script (recomendado)
python run_tests.py --full

# Opção 2: Com pytest
python -m pytest transcriber_web_app/test_app.py -v

# Opção 3: Direto
cd transcriber_web_app
python test_app.py
```

### Testes Específicos

#### Por Categoria
```bash
# Apenas testes de validação de arquivos
python -m pytest transcriber_web_app/test_app.py::TestFileValidation -v

# Apenas testes de segurança
python -m pytest transcriber_web_app/test_app.py::TestSecurity -v

# Apenas testes de rotas
python -m pytest transcriber_web_app/test_app.py::TestRoutes -v
```

#### Por Função Específica
```bash
# Teste específico de extensões válidas
python -m pytest transcriber_web_app/test_app.py::TestFileValidation::test_allowed_file_valid_extensions -v

# Teste específico de path traversal
python -m pytest transcriber_web_app/test_app.py::TestSecurity::test_path_traversal_in_results -v
```

### Testes com Cobertura de Código
```bash
# Gerar relatório de cobertura
python -m pytest transcriber_web_app/test_app.py --cov=transcriber_web_app --cov-report=html

# Ver cobertura no terminal
python -m pytest transcriber_web_app/test_app.py --cov=transcriber_web_app --cov-report=term-missing
```

### Verificação de Saúde dos Serviços
```bash
# Verificar saúde da aplicação
python transcriber_web_app/healthcheck.py

# Com Docker rodando
docker compose up -d
python transcriber_web_app/healthcheck.py
```

## 📁 Estrutura dos Testes

```
transcribe/
├── run_tests.py                    # 🎯 Script principal de testes
├── TESTING.md                      # 📖 Esta documentação
└── transcriber_web_app/
    ├── test_app.py                # 🐳 Testes completos (com Docker)
    ├── test_local.py              # 🏠 Testes locais (sem Docker)
    ├── healthcheck.py             # 💊 Verificação de saúde
    └── requirements.txt           # 📦 Dependências
```

### Arquivos de Teste Detalhados

#### `test_app.py` - Testes Completos
```python
# Classes principais:
- TranscriberTestCase      # Base para todos os testes
- TestFileValidation       # Validação de arquivos
- TestRoutes              # Testes de rotas/endpoints
- TestUpload              # Upload e processamento
- TestSecurity            # Segurança e validação
- TestConfiguration       # Configurações da aplicação
```

#### `test_local.py` - Testes Locais
```python
# Classes principais:
- LocalTranscriberTestCase # Base para testes locais
- TestFileValidation       # Validação (sem Docker)
- TestRoutes              # Rotas básicas
- TestUploadWithoutDocker # Upload sem integração Docker
- TestSecurity            # Segurança básica
```

#### `run_tests.py` - Script Inteligente
```python
# Funções principais:
- check_dependencies()     # Verifica dependências Python
- check_docker()          # Verifica disponibilidade Docker
- run_local_tests()       # Executa testes locais
- run_full_tests()        # Executa testes completos
```

## 🎯 Categorias de Teste

### 1. 📄 Validação de Arquivos
**O que testa:**
- Extensões permitidas (mp4, mp3, wav, etc.)
- Extensões bloqueadas (exe, py, pdf, etc.)
- Nomes de arquivo válidos/inválidos
- Tamanhos de arquivo
- Caracteres especiais

**Exemplo de execução:**
```bash
python -m pytest transcriber_web_app/test_app.py::TestFileValidation -v
```

### 2. 🌐 Rotas e API
**O que testa:**
- Endpoint principal (`/`)
- Rota de configuração (`/config`)
- Status de jobs (`/status/<job_id>`)
- Download de resultados (`/results/<job_id>/<filename>`)
- Códigos de status HTTP corretos

**Exemplo de execução:**
```bash
python -m pytest transcriber_web_app/test_app.py::TestRoutes -v
```

### 3. 🔒 Segurança
**O que testa:**
- Path traversal attacks (`../../../etc/passwd`)
- Validação de Job IDs (formato UUID)
- Sanitização de nomes de arquivo
- Acesso a arquivos não autorizados
- Validação de entrada

**Exemplo de execução:**
```bash
python -m pytest transcriber_web_app/test_app.py::TestSecurity -v
```

### 4. 📤 Upload e Processamento
**O que testa:**
- Upload sem arquivo
- Upload com arquivo vazio
- Upload com extensão inválida
- Integração com Docker (testes completos)
- Processamento de jobs

**Exemplo de execução:**
```bash
python -m pytest transcriber_web_app/test_app.py::TestUpload -v
```

### 5. ⚙️ Configuração
**O que testa:**
- Variáveis de ambiente
- Limites de tamanho de arquivo
- Configurações de diretório
- Parâmetros da aplicação

**Exemplo de execução:**
```bash
python -m pytest transcriber_web_app/test_app.py::TestConfiguration -v
```

## 🔧 Troubleshooting

### Problemas Comuns e Soluções

#### ❌ "ModuleNotFoundError: No module named 'flask'"
```bash
# Solução: Instalar dependências
pip install -r transcriber_web_app/requirements.txt
```

#### ❌ "Docker daemon is not running"
```bash
# Solução 1: Usar apenas testes locais
python run_tests.py --local

# Solução 2: Iniciar Docker
# Windows: Abrir Docker Desktop
# Linux: sudo systemctl start docker
# macOS: Abrir Docker Desktop
```

#### ❌ "Permission denied" ao executar testes
```bash
# Solução: Verificar permissões
chmod +x run_tests.py
python run_tests.py
```

#### ❌ Testes falham com "Container not found"
```bash
# Solução: Verificar se containers estão rodando
docker compose up -d
python run_tests.py --full
```

### Logs de Debug

#### Habilitar logs detalhados
```bash
# Com pytest
python -m pytest transcriber_web_app/test_app.py -v -s

# Com script personalizado
PYTHONPATH=. python run_tests.py --full
```

#### Verificar configuração
```bash
# Verificar configurações da aplicação
python -c "from transcriber_web_app.config import Config; print(vars(Config()))"

# Verificar Docker
docker compose ps
docker compose logs webapp
```

## 🤝 Contribuindo com Testes

### Adicionando Novos Testes

#### 1. Para Funcionalidade Sem Docker
Adicione em `test_local.py`:
```python
class TestMinhaNovaFuncionalidade(LocalTranscriberTestCase):
    def test_minha_funcionalidade(self):
        """Testa minha nova funcionalidade"""
        # Seu código de teste aqui
        self.assertTrue(True)
```

#### 2. Para Funcionalidade Com Docker
Adicione em `test_app.py`:
```python
class TestMinhaIntegracao(TranscriberTestCase):
    @patch('app.docker.from_env')
    def test_integracao_docker(self, mock_docker):
        """Testa integração com Docker"""
        # Mock do Docker
        mock_client = MagicMock()
        mock_docker.return_value = mock_client
        
        # Seu teste aqui
        self.assertTrue(True)
```

### Boas Práticas para Testes

#### ✅ Fazer
- Usar nomes descritivos para testes
- Testar casos extremos (edge cases)
- Incluir docstrings explicativas
- Usar mocks para dependências externas
- Limpar recursos após testes

#### ❌ Evitar
- Testes que dependem de ordem de execução
- Hardcoding de valores específicos
- Testes muito longos ou complexos
- Dependências de arquivos externos
- Modificar estado global

### Executar Testes Antes de Commit
```bash
# Script rápido para validação
python run_tests.py --local && echo "✅ Pronto para commit!"
```

## 📊 Relatórios e Métricas

### Cobertura de Código
```bash
# Gerar relatório HTML
python -m pytest transcriber_web_app/test_app.py --cov=transcriber_web_app --cov-report=html

# Abrir relatório (será criado em htmlcov/index.html)
# Windows: start htmlcov/index.html
# Linux/macOS: open htmlcov/index.html
```

### Relatório de Performance
```bash
# Medir tempo de execução dos testes
python -m pytest transcriber_web_app/test_app.py --durations=10
```

### Integração Contínua
Para CI/CD, use:
```bash
# Comando para pipelines automatizados
python run_tests.py --local || exit 1
```

---

## 🎉 Conclusão

Este guia fornece tudo que você precisa para executar, entender e contribuir com os testes do Whisper Transcriber. Os testes são uma parte fundamental para manter a qualidade e confiabilidade da aplicação.

### Comandos Essenciais para Memorizar
```bash
# Execução rápida (recomendado)
python run_tests.py

# Apenas testes locais
python run_tests.py --local

# Testes completos
python run_tests.py --full

# Verificação de saúde
python transcriber_web_app/healthcheck.py
```

**Dúvidas?** Consulte a seção de [Troubleshooting](#-troubleshooting) ou abra uma issue no repositório.