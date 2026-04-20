# Plano de Evolução e Modernização - Sistema Bolão

Referências:

* `README.md`
* 

Legenda de status:

* `Pendente`
* `Em Progresso`
* `Concluído`
* `Bloqueado`
* `Cancelado`

Diretriz fixa:

* Definir empacotamento WAR e deploy, se for o caso.
* Definir o que não pode ser usado (exemplo: Não usar spring boot) - **Nota: Esta diretriz pode ser revisada conforme as recomendações de modernização.**

Premissas de compatibilidade (críticas):

* Exemplo: Struts 7 exige Java 17+ e Jakarta Servlet 6+ (jakarta.*). - **Nota: Estas premissas serão definidas com base nas escolhas de tecnologias para a modernização.**

## Fases de Modernização e Atividades (executar em sequência)

### Fase 1: Estabilização e Correções de Infraestrutura (IMEDIATA)

1. **[Concluído] Corrigir Mecanismo de Retentativas do RQ:** Investigar por que o `Worker` não está processando as retentativas mesmo com o objeto `Retry` configurado.
   - Subtarefa: [Concluído] Verificar se o `Worker` precisa ser iniciado com a flag `--with-scheduler`.
   - Subtarefa: [Pendente] Testar se a retentativa funciona com um job simples de erro em ambiente Docker completo.
2. **[Concluído] Refatorar Suíte de Testes:** Ajustar `test_app.py` para mockar corretamente Redis e RQ, removendo dependência do Docker SDK obsoleto.
3. **[Pendente] Validar Dead-Letter Queue (DLQ):** Garantir que jobs que excedam o número de retentativas sejam movidos para a `failed queue` e possam ser inspecionados.
4. **[Em Progresso] Limpeza de Código de Teste:** Remover o erro simulado em `transcriber_web_app/transcribe.py` após validar as retentativas.

### Fase 2: Melhorias de Segurança e UX

1. **[Pendente] Implementar CSRF Protection:** Adicionar proteção contra Cross-Site Request Forgery nas rotas de upload.
2. **[Pendente] Melhorar Feedback de Erro na UI:** Exibir mensagens de erro mais descritivas quando o job falha definitivamente.

## Registro de Avanços

* 2026-04-19: Início da análise da branch `docs-review-and-corrections`. Identificada necessidade de focar na correção do RQ.
* 2026-04-19: Corrigido `worker.py` para ativar scheduler integrado (`with_scheduler=True`). Criado log de sessão e script de teste manual.
