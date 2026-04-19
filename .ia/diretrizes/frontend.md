# Diretrizes de Frontend do Sistema Bolão

Este documento consolida os padrões atuais para desenvolvimento e manutenção do frontend do projeto, alinhado às migrações realizadas até 20/02/2026. Ele deve ser lido em conjunto com `.ia/diretrizes/arquitetura.md`, o `passo-a-passo.md` e as ADRs listadas ao final.

## 1. Visão Geral e Objetivos
- **Stack atual:** JSP/Struts 7, Spring 6, HTMX 1.9+, JavaScript modular (ESM) empacotado com Vite 5, CSS organizado em `webapp/css/estilo.css`.
- **Navegadores alvo:** Chrome, Firefox, Edge e Safari (versões evergreen). Suporte a navegadores legados (IE / engines antigos) não é mais obrigatório.
- **Metas principais:**
  - Remover/evitar bibliotecas legadas (Prototype, Scriptaculous, DWR, Overlib, jQuery alfa).
  - Garantir acessibilidade (WCAG 2.1 AA) e responsividade.
  - Preparar o frontend para CSP rígida, hashes e empacotamento com versionamento.

## 2. Estrutura de Pastas e Empacotamento
- **Fonte dos módulos:** `src/frontend/`
  - `main.js` inicializa tooltips (`modules/tooltips.js`) e a página de jogos (`pages/jogos.js`).
  - Módulos adicionais devem ser colocados sob `modules/` (componentes compartilhados) ou `pages/` (comportamento específico de página).
- **Saída do Vite:** `webapp/assets/`
  - Manifesto em `webapp/assets/.vite/manifest.json` (hashes de bundle).
  - Bundle versionado `webapp/assets/js/main-<hash>.js` e fallback `webapp/assets/js/app-bundle.js` (emitido via plugin custom).
- **Loader de assets:** `webapp/template/cabecalho.jspf` consome o manifest dinamicamente e mantém fallback seguro.
- **Comandos principais:**
  - `npm install` — instalar dependências (executar sempre que `package.json` mudar).
  - `npm run build` — gerar bundles antes do `mvn package`.
  - `mvn package -Dfrontend.skip=false` — build completo (instala Node/Vite pelo `frontend-maven-plugin`).
  - Em ambientes offline use `-Dfrontend.skip=true` e mantenha `app-bundle.js` atualizado manualmente.

## 3. Padrões de JavaScript
- Escrever módulos como ES Modules (import/export). Evitar scripts globais e funções em JSP.
- Interações assíncronas devem usar **HTMX** ou `fetch` padrão. Não reintroduzir DWR/Prototype/jQuery.
- Arquivos HTMX devem expor elementos com atributos `data-*` para scripts de página (`pages/*.js`).
- Seguir exemplos de acessibilidade em `src/frontend/pages/jogos.js` (gestão de foco, `aria-hidden`, interação por teclado).
- Agrupar utilitários compartilhados em `modules/` e referenciar via import relativo.
- Nunca concatenar HTML via strings sem sanitização; preferir templates Struts/JSP ou atualizações HTMX.

## 4. Padrões de HTML e CSS
- CSS centralizado em `webapp/css/estilo.css` com variáveis CSS e utilitários (`dashboard-section`, `.table`, `.notice-card`, etc.).
- Adotar layout responsivo (flex/grid) e classes utilitárias já criadas; evitar estilos inline.
- Componentes chave:
  - `skip-link` e `sr-only` para navegação acessível.
  - Classes de portlets (`opendev:portlet`) e tabelas (`.table`, `.table-responsive`).
  - Dialogs e balões devem receber classes `.dialog`, `.balao-*` e atributos ARIA adequados.
- **Fragments HTMX + Preludes:** Os includes globais `cabecalho.jspf`/`rodape.jspf` devem apenas condicionar a renderização do HTML envoltório com uma flag do request (`skipTemplate`) e nunca fazer `return;` direto. O fluxo correto é:
  1. A action detecta uma chamada HTMX e seta `request.setAttribute("skipTemplate", Boolean.TRUE)`.
  2. O prelude avalia `Boolean.TRUE.equals(request.getAttribute("skipTemplate"))` e, caso verdadeiro, omite apenas o wrapper `<html>…`, mantendo o corpo JSP disponível.
  3. O coda reutiliza a mesma flag (sem redeclarar variáveis) para pular o fechamento global.
  4. O fragmento específico (`*.jspf`) continua sendo processado normalmente, garantindo que apenas o `<tbody>` ou bloco parcial seja retornado, evitando que o swap HTMX substitua toda a página.
  Essa abordagem impede erros de compilação Jasper (variáveis duplicadas) e bloqueia o vazamento do markup completo nas respostas HTMX.
- Ao internacionalizar títulos/atributos em JSP (ex.: `opendev:portlet`), sempre use `fmt:message` com `var="..."` e referencie a variável no atributo (`title="${rulesTitle}"`). Evita que o texto traduzido seja injetado de forma incorreta dentro do markup.
- Fragmentos JSP (`*.jspf`) não devem declarar `<%@taglib%>` ou outras diretivas; deixe apenas o markup. O host que inclui o fragmento deve declarar as taglibs (`c`, `fmt`, etc.) antes do `include` estático. Isso impede que diretivas escapem para o HTML final quando o fragmento é processado via `@ include` e mantém as respostas HTMX válidas.
- Imagens relevantes (bandeiras/ícones de ação) precisam de `alt` descritivo; ícones puramente decorativos devem usar `aria-hidden="true"`.

## 5. Acessibilidade
- **Baseline:** correções aplicadas em 20/02/2026 (alt text, diálogos com `role="dialog"`, mensagens com `aria-live`, skip-link em todas as páginas).
- **Checklist mínimo para novos recursos:**
  - Associação `label` ↔ `input` (`for` / `id` únicos).
  - Foco visível e restauração ao fechar diálogos.
  - Mensagens dinâmicas anunciadas via `role="status"` / `aria-live`.
  - Testes manuais com teclado (Sem mouse) nas principais interações.
- **Auditoria automatizada:** rodar `scripts/run-axe-audit.sh` em ambiente com Chrome headless. A execução está adiada no momento devido a restrições do ambiente atual (ver logs `.ia/logs/session-20260220-axe-cli-bloqueio.md`).

## 6. Segurança e Performance
- Nenhum script inline deve ser introduzido nas JSPs (facilita futura CSP). Use módulos e o loader do Vite.
- Compressão/minificação: bundles do Vite (<10 KB) e CSS (~19 KB) são suficientes no momento; qualquer crescimento relevante deve desencadear nova análise (ver ADR `.ia/historico/ADR-20260220-otimizacao-minima-assets.md`).
- Evitar carregar bibliotecas externas via CDN. Se indispensável, documentar e considerar subresource integrity (SRI).
- CSRF (HX/fetch): não reescrever manualmente o cookie `XSRF-TOKEN`. Utilize o valor fornecido pelo `CookieCsrfTokenRepository` nas meta tags `_csrf*`, propague-o via campo hidden global (`#csrfTokenField`) e injete cabeçalhos em `fetch`/HTMX. Quando a resposta incluir cabeçalhos `X-CSRF-*`, atualize meta tags, campo hidden e formulários, preservando o handler `XorCsrfTokenRequestAttributeHandler`.

## 7. Build, QA e Ferramentas
- **Sequência recomendada antes de merge:**
  1. `npm install`
  2. `npm run build`
  3. `mvn test`
  4. (Ambiente com permissão) `./scripts/run-axe-audit.sh "<BASE_URL>" "<CHROME_PATH>" "<FLAGS>"`
- Testes visuais manuais devem focar em telas de login, principal, jogos, classificações e painéis admin.
- Registrar qualquer ajuste significativo em `.ia/logs/` usando o template padrão.

## 8. Pendências e Próximos Passos
- **Auditoria axe:** depende de ambiente com Chrome headless liberado.
- **Testes cross-browser:** retomar após a auditoria automatizada (Tarefa 8 marcada como adiada).
- **Documentação contínua:** manter este arquivo atualizado ao introduzir novos componentes, diretrizes de CSS ou decisões relevantes.

## 9. Referências
- `passo-a-passo.md` (Fase 2.5)
- `.ia/logs/session-20260220-acessibilidade-correcoes.md`
- `.ia/logs/session-20260220-bundler-*.md`
- `.ia/logs/session-20260220-axe-cli-bloqueio.md`
- ADRs em `.ia/historico/`, especialmente:
  - `ADR-20260217-arquitetura-frontend-modernizacao.md`
  - `ADR-20260219-jquery-remocao-gradual.md`
  - `ADR-20260220-otimizacao-minima-assets.md`
