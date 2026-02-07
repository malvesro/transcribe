# ADR-002: Implementação de Mecanismo de Retentativas e Dead-Letter Queue para Jobs RQ

**Data:** 2026-02-07

**Status:** Proposto

---

#### 1. Contexto

O projeto Transcriber utiliza `RQ (Redis Queue)` para processar as tarefas de transcrição em segundo plano. Atualmente, quando um job falha (por exemplo, devido a um erro de processamento, indisponibilidade temporária de um recurso, ou um bug), ele é movido para uma fila de falhas (`failed queue`) e notificado. Não há um mecanismo automático para tentar novamente jobs que falham ou para isolar jobs que falham persistentemente.

#### 2. Problema

A ausência de mecanismos de retentativa e de uma "dead-letter queue" (DLQ) no fluxo de trabalho do RQ gera os seguintes problemas:

*   **Perda de Jobs Transitórios:** Jobs que falham devido a problemas temporários (ex: pico de uso da CPU, falha momentânea de rede ao baixar um modelo) não são automaticamente retentados, resultando em jobs "perdidos" que poderiam ter sido concluídos com sucesso. Isso impacta a confiabilidade do sistema.
*   **Acúmulo de Falhas na Fila:** Jobs que falham repetidamente devido a erros persistentes (bugs no código, dados corrompidos) acumulam-se na fila de falhas, dificultando a identificação e tratamento manual dos problemas reais.
*   **Falta de Resiliência:** O sistema é frágil a falhas temporárias, exigindo intervenção manual para re-enfileirar jobs falhos.
*   **Dificuldade na Depuração:** A ausência de um fluxo claro para jobs persistentes com falha dificulta a análise de "causa raiz" e o tratamento de exceções.

#### 3. Decisão

**Implementar um mecanismo de retentativas automáticas para jobs que falham e configurar uma "dead-letter queue" (DLQ) para jobs que excedem o número máximo de retentativas.**

*   **Retentativas:** Os jobs serão configurados para serem retentados um número limitado de vezes. **Propõe-se `max_retries = 3`**. Isso significa que cada job terá até 3 tentativas (1 inicial + 2 retentativas) antes de ser considerado persistentemente falho. Esta quantidade de retentativas é um bom equilíbrio para recuperar-se de falhas transitórias sem desperdiçar recursos em problemas persistentes. Um atraso exponencial (`backoff`) será aplicado entre as retentativas para evitar sobrecarregar o sistema.
*   **Dead-Letter Queue (DLQ):** Uma fila separada será criada para receber jobs que falharam persistentemente após todas as retentativas. Isso permitirá que esses jobs sejam inspecionados manualmente, corrigidos e, se necessário, reenviados.

#### 4. Argumentação (Justificativa)

Esta decisão trará os seguintes benefícios:

*   **Aumento da Resiliência:** O sistema se tornará mais robusto a falhas temporárias, melhorando a taxa de sucesso das transcrições.
*   **Melhoria da Qualidade de Serviço:** Usuários terão uma experiência mais confiável, com menos jobs falhando sem motivo aparente.
*   **Facilidade de Operação:** Operadores poderão focar em problemas persistentes na DLQ, em vez de jobs transitórios que se recuperam sozinhos.
*   **Clareza na Depuração:** A DLQ servirá como um repositório para jobs "problemáticos", facilitando a análise de causa raiz de erros.
*   **Gerenciamento Eficiente da Fila:** Evita o acúmulo de jobs irrecuperáveis na fila de falhas principal, mantendo-a mais limpa e organizada.

#### 5. Consequências

*   **Positivas:**
    *   Maior confiabilidade e robustez do processamento de transcrições.
    *   Redução da necessidade de intervenção manual para jobs falhos.
    *   Melhor visibilidade sobre jobs que falham persistentemente.
*   **Negativas:**
    *   **Aumento da Complexidade na Configuração:** Requer ajustes na forma como os jobs são enfileirados (`max_retries`, `retry_interval`) e gerenciamento da DLQ (monitoreamento, ferramentas para re-enfileirar).
    *   **Consumo de Recursos Adicionais:** Retentativas podem consumir mais recursos computacionais e de Redis (para armazenar o estado das retentativas) se muitos jobs falharem.
    *   **Ferramentas de Monitoramento/Gerenciamento:** Pode ser necessário implementar ou integrar ferramentas para visualizar e gerenciar a DLQ (ex: RQ Dashboard).
