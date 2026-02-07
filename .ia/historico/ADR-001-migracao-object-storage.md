# ADR-001: Estratégia de Armazenamento de Mídias e Transcrições (Foco Local e Privacidade)

**Data:** 2026-02-07

**Status:** Decidido

---

#### 1. Contexto

O projeto Transcriber foi concebido com um foco primordial na **execução local na máquina do usuário** e na **privacidade dos dados**. Atualmente, todas as mídias de entrada (`videos/`) e os resultados das transcrições (`results/`) são armazenados diretamente no sistema de arquivos local do usuário, via volumes Docker montados (`./transcriber_web_app/videos` e `./transcriber_web_app/results`).

#### 2. Problema

Foi levantada a proposta de migrar o armazenamento para Object Storage (ex: MinIO) para endereçar questões de escalabilidade e durabilidade geralmente associadas a ambientes de produção ou multi-usuário. No entanto, esta proposta levanta preocupações significativas no contexto do foco principal do produto:

*   **Acessibilidade para o Usuário:** Para uma aplicação local, o acesso direto aos arquivos via sistema de arquivos do usuário é a forma mais intuitiva e simples. Introduzir um Object Storage, mesmo que local (MinIO), adicionaria uma camada de complexidade que pode dificultar o acesso e gerenciamento dos arquivos gerados pelo usuário.
*   **Controle e Expectativa do Usuário:** Usuários de uma aplicação local esperam ter controle direto sobre seus arquivos no disco. Um Object Storage oculta essa simplicidade.
*   **Relevância para o Foco do Produto:** As vantagens primárias de Object Storage (escalabilidade horizontal para múltiplos hosts, alta durabilidade de nuvem) não são o benefício central para um produto com foco estrito em execução local e privacidade.

#### 3. Decisão

**Manter a estratégia atual de armazenamento de mídias de entrada e resultados de transcrição utilizando o sistema de arquivos local do usuário através de volumes Docker montados.**

Caso haja uma evolução futura do produto para um modelo de serviço (nuvem, multi-usuário), uma nova ADR será criada para revisar a estratégia de armazenamento para aquele contexto específico.

#### 4. Argumentação (Justificativa)

A decisão de manter o armazenamento local está diretamente alinhada e é otimizada para os objetivos primários do produto:

*   **Máxima Privacidade:** Os dados do usuário permanecem exclusivamente na sua máquina, sem depender de serviços de terceiros ou componentes de rede adicionais para armazenamento.
*   **Fácil Acessibilidade para o Usuário:** Os arquivos de transcrição são diretamente acessíveis via sistema de arquivos do usuário, permitindo fácil cópia, movimentação, integração com outras ferramentas locais e gerenciamento direto, sem a necessidade de uma interface ou API adicional de Object Storage.
*   **Simplicidade de Setup e Operação Local:** O uso de volumes Docker é uma solução simples e eficaz para persistência de dados em um ambiente containerizado local, com baixa sobrecarga de configuração para o usuário final.
*   **Alinhamento com o Core Business:** Para um produto que visa processamento *local* e *privado*, a complexidade e os benefícios de Object Storage não se traduzem em valor direto para o usuário final no cenário atual.

#### 5. Consequências

*   **Positivas:**
    *   Preservação da privacidade e controle total dos dados pelo usuário.
    *   Simplicidade e intuitividade na acessibilidade dos arquivos gerados.
    *   Baixa complexidade de infraestrutura para o setup e operação local.
    *   Não introdução de dependências de rede (mesmo local, como MinIO) para o armazenamento principal.
*   **Negativas:**
    *   **Limitações para Escala Multi-Instância/Nuvem:** Esta estratégia não suporta naturalmente um modelo de deployment distribuído ou em nuvem sem refatoração.
    *   **Backup e Durabilidade:** A responsabilidade de backup dos arquivos gerados recai totalmente sobre o usuário e as políticas de backup da sua máquina local. O sistema não provê durabilidade intrínseca ou replicação.
    *   **Gerenciamento de Espaço:** O usuário é responsável por gerenciar o espaço em disco ocupado pelos arquivos de mídias e transcrições diretamente em seu sistema de arquivos.