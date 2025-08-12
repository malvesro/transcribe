# 🧪 Estratégia de Testes - Whisper Transcriber

Este documento detalha a estratégia de testes do projeto Whisper Transcriber, como executar os testes existentes e como contribuir com novos testes.

## 🎯 Visão Geral

O projeto utiliza `pytest` como seu principal framework de testes, com foco em garantir a corretude e a qualidade do código. A suíte de testes é executada em um ambiente Python isolado, mas pode interagir com o ambiente Docker para testes de integração.

## 💻 Ambiente de Testes

Para a maioria dos usuários, o cenário de teste mais comum será:

*   **Sistema Operacional:** Windows (com WSL2) ou Linux.
*   **Docker:** O daemon Docker rodando *dentro* do ambiente Linux (WSL2 Ubuntu ou distribuição Linux nativa), e não necessariamente o Docker Desktop no Windows.

Isso significa que o `docker` SDK para Python (usado pela `webapp`) se conectará ao daemon Docker do Linux. Os testes são projetados para serem compatíveis com essa configuração.

## ▶️ Como Executar os Testes

Para executar todos os testes do projeto, siga os passos abaixo:

1.  **Pré-requisitos:**
    *   Python 3.10+ instalado.
    *   `pip` (gerenciador de pacotes Python).
    *   **Docker** e **Docker Compose** instalados e funcionando no seu ambiente Linux (WSL2 ou nativo).

2.  **Instalar Dependências de Teste:**
    Navegue até o diretório `transcriber_web_app` e instale as dependências listadas no `requirements.txt`. Isso inclui `pytest` e `pytest-cov`.
    ```bash
    cd transcriber_web_app
    pip install -r requirements.txt
    cd .. # Voltar para a raiz do projeto
    ```

3.  **Executar Todos os Testes:**
    A partir da raiz do projeto, execute o script `run_tests.py`:
    ```bash
    python run_tests.py
    ```
    Este script irá:
    *   Descobrir e executar todos os testes nos diretórios configurados (atualmente `transcriber_web_app`).
    *   Gerar um relatório de cobertura de código no console, mostrando quais partes do código foram testadas.

    **Saída Esperada:** Uma série de pontos (`.`) para testes que passaram, `F` para falhas, e um resumo final com a cobertura de código.

## 📂 Estrutura dos Testes

Os testes são organizados da seguinte forma:

*   `transcriber_web_app/test_app.py`:
    *   Contém testes unitários e de integração para a aplicação Flask (`app.py`).
    *   Inclui testes para validação de arquivos (`allowed_file`), rotas da API (`upload_and_transcribe`, `stream_status`, `serve_result_file`, `config`), e tratamento de erros.
    *   Utiliza mocks para simular interações com o sistema de arquivos e a API Docker, garantindo que os testes sejam rápidos e isolados.

*   `transcriber_web_app/test_local.py`:
    *   Contém testes unitários para a lógica de transcrição principal em `transcribe.py`.
    *   Foca em testar a manipulação de argumentos, a chamada ao modelo Whisper (mockada), a escrita de arquivos de saída e a atualização do arquivo de progresso (`_progress.json`).

## 📊 Cobertura de Código

O script `run_tests.py` utiliza `pytest-cov` para gerar um relatório de cobertura de código. Uma alta cobertura indica que uma grande parte do código foi exercitada pelos testes, reduzindo a chance de bugs não detectados.

## ✅ Boas Práticas ao Escrever Testes

Ao adicionar novos testes, considere as seguintes diretrizes:

*   **Clareza:** Testes devem ser fáceis de ler e entender. Use nomes descritivos para as funções de teste.
*   **Isolamento:** Cada teste deve ser independente dos outros. Use fixtures para configurar um ambiente limpo para cada teste.
*   **Mocks:** Para testes unitários, use mocks para isolar a unidade de código sob teste de suas dependências externas (ex: sistema de arquivos, chamadas de rede, API Docker, modelos de IA).
*   **Assertividade:** Testes devem ter asserções claras que verificam o comportamento esperado.
*   **Pequenos e Rápidos:** Testes unitários devem ser rápidos para permitir feedback contínuo.

## 🚀 Próximos Passos e Melhorias Futuras

Embora a suíte de testes atual cubra as funcionalidades principais, há sempre espaço para melhorias:

*   **Testes de Integração Abrangentes:** Desenvolver testes que iniciem containers Docker reais (ou um subconjunto deles) para verificar a comunicação e o fluxo de dados entre `webapp` e `whisper_worker` em um ambiente mais próximo da produção.
*   **Testes End-to-End (E2E):** Implementar testes que simulem a interação completa do usuário com a interface web (upload, acompanhamento de progresso, download) usando ferramentas como [Playwright](https://playwright.dev/) ou [Selenium](https://www.selenium.dev/).
*   **Testes de Performance:** Criar benchmarks para medir o tempo de transcrição e o uso de recursos sob diferentes condições e cargas.
*   **Testes de Segurança:** Explorar ferramentas e metodologias para identificar vulnerabilidades de segurança na aplicação.
*   **Testes de Resiliência:** Verificar como o sistema se comporta sob falhas (ex: worker falha no meio da transcrição, rede instável).

Ao seguir estas diretrizes e continuar expandindo a suíte de testes, podemos garantir a alta qualidade e confiabilidade do Whisper Transcriber.
