---
skill_name: security-audit
description: Auditoria de seguranca generica (OWASP + boas praticas).
version: 1.0.0
tags: [security, owasp, audit, dependency]
---

# Security Audit Skill (Template Generico)

## Objetivo

Auditar codigo e configuracoes para reduzir vulnerabilidades antes do commit.

## Checklist Principal (OWASP)

1. **Validacao de Entrada (Zero Trust)**
   - Sempre validar e normalizar dados de entrada.

2. **Injecao (SQL/NoSQL/Command)**
   - Queries parametrizadas e uso de ORM seguro.

3. **XSS e CSRF**
   - Escapar saidas e usar tokens anti-CSRF quando aplicavel.

4. **Autenticacao e Autorizacao**
   - Verificar acesso por roles e politicas claras.

5. **Segredos e Configuracao**
   - Nunca commitar credenciais. Use variaveis de ambiente/secret manager.

6. **Dependencias e CVEs**
   - Verificar bibliotecas com CVE e recomendar atualizacoes.
   - Sugerir uso de ferramentas como OWASP Dependency-Check.

7. **Logging Seguro**
   - Evitar logar dados sensiveis.
   - Padronizar niveis e formato.

> NOTE: Ajuste o checklist conforme o stack e regulacoes do projeto (LGPD, PCI, etc.).

> **NOTA ESPECIAL PARA O PROJETO 'Sistema Bolao':** A auditoria inicial (`analise-inicial.md`) revelou riscos críticos que devem ser priorizados:
> - **Hashing de Senha:** O sistema usa SHA-1. A migração para bcrypt é **urgente**.
> - **Falta de HTTPS:** As credenciais são transmitidas em texto claro.
> - **Dependências Obsoletas:** A maioria das bibliotecas (Acegi, WebWork, Spring 1.2.8, Hibernate 3) está em fim de vida (EOL) e possui vulnerabilidades conhecidas. A atualização é crítica.
> - **DWR Debug:** O modo debug do DWR está habilitado em produção, representando um risco de vazamento de informações.
> - **Risco de Injeção (SQL/XSS):** Dada a idade do stack, a verificação de todas as entradas de usuário é de alta prioridade.
