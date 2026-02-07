---
version: 2.0.0
mode: audit
description: "Auditoria OWASP e e-MAG"
---
# Security Audit Skill

## Objetivo
Auditar código por vulnerabilidades antes do commit.

## Checklist
1. **Zero Trust:** Valide todos os inputs.
2. **SQL Injection:** Verifique concatenação em JPQL.
3. **Auth:** Valide `@PreAuthorize` em endpoints públicos.
