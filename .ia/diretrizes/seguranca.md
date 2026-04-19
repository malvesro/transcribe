# Diretrizes de Segurança do Projeto

Este documento detalha todas as regras e mecanismos de segurança implementados no Sistema Bolão, servindo como guia para desenvolvedores e auditoria.

## 1. Segurança de Infraestrutura e Camada Web

### 1.1. HTTPS Obrigatório
- **Regra:** Todo o tráfego deve ser criptografado via TLS.
- **Implementação:** Configurado `security-constraint` no `web.xml` com `transport-guarantee` definido como `CONFIDENTIAL`.

### 1.2. Cabeçalhos de Segurança (Security Headers)
- **X-Frame-Options:** Configurado como `SAMEORIGIN` via Spring Security para impedir ataques de Clickjacking.
- **HSTS/CSP:** (Planejado) Próximas etapas da Fase 5.

### 1.3. Isolamento de Dependências
- **DWR:** Modo `debug` desabilitado no `web.xml` para evitar exposição de metadados dos serviços.
- **Bibliotecas EOL:** Remoção sistemática de JARs antigos (Acegi, WebWork) para eliminar CVEs conhecidas.

## 2. Autenticação e Gestão de Identidade (Spring Security 6)

### 2.1. Estratégia de Password Hashing
- **Algoritmo Alvo:** **BCrypt** (Forte, resistente a brute-force).
- **Legado:** Uso de `LegacySha1PasswordEncoder` (SHA-1 com Base64) apenas para compatibilidade de migração.
- **Transição:** Implementado `DelegatingPasswordEncoder` que valida o hash antigo e permite a atualização automática para BCrypt no login.

### 2.2. Controle de Acesso (Autorização)
- **Por URL:** Definido no `applicationContext-security.xml` usando `hasRole` e `hasAnyRole`.
    - `/admin/**`: Restrito a `ROLE_ADMIN`.
    - `/seguro/**`: Acessível por `ROLE_USER` e `ROLE_ADMIN`.
- **Por Método:** Habilitado `global-method-security` com `pre-post-annotations` para proteção granular na camada de serviço e Actions.

### 2.3. Gestão de Sessão
- **Fixação de Sessão:** Configurado `migrateSession` para criar uma nova ID de sessão após a autenticação, mitigando ataques de Session Fixation.
- **Invalidação:** O logout limpa explicitamente o contexto de segurança e invalida a sessão HTTP.

## 3. Endurecimento do Struts 7 (Segurança Proativa)

A migração para o Struts 7 trouxe proteções modernas que devem ser rigorosamente seguidas:

### 3.1. Proteção contra Injeção de Parâmetros
- **Regra:** Nenhuma Action deve aceitar parâmetros de requisição sem autorização explícita.
- **Implementação:** Uso obrigatório da anotação `@StrutsParameter` nos métodos `set` das Actions. Campos não anotados são ignorados pelo framework, impedindo a manipulação de objetos internos.

### 3.2. Segurança OGNL (Object-Graph Navigation Language)
- **Allowlisting:** O Struts 7 exige que todas as classes acessíveis via OGNL (em JSPs ou Actions) estejam em uma "lista permitida". Isso mitiga ataques de execução remota de código (RCE).
- **Limites de Expressão:** (Planejado) Configuração de `struts.ognl.expressionMaxLength` para limitar o tamanho das expressões processadas.

### 3.3. Proteção de Visões (JSPs)
- **Regra:** JSPs nunca devem ser acessados diretamente.
- **Implementação:** (Em andamento) Migração de JSPs para dentro de `/WEB-INF/`, forçando o acesso apenas através das Actions do Struts.

## 4. Segurança de Dados e Persistência (Hibernate 6)

### 4.1. SQL Injection
- **Prevenção:** Uso obrigatório de HQL/JPQL ou Criteria API. Consultas nativas devem usar obrigatoriamente parâmetros nomeados (Named Parameters).

### 4.2. Segurança de Conexão
- **Recuperação de Chave Pública:** Limitada ao ambiente de desenvolvimento/container através de `allowPublicKeyRetrieval=true` na URL JDBC.

---
**Última Atualização:** 2026-02-19
**Versão:** 1.0
