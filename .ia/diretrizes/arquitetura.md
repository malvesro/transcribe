---
doc_name: diretrizes-arquitetura
description: Diretrizes arquiteturais genericas para evolucao segura e consistente.
version: 1.0.0
tags: [architecture, layering, security, testing, migration]
---

# Diretrizes de Arquitetura

## 1. Objetivo e Escopo

Estas diretrizes definem padroes obrigatorios para evolucao do sistema, garantindo seguranca, consistencia de camadas e compatibilidade.

> NOTE: Descreva o tipo de sistema, dominio de negocio e metas de evolucao.

## 2. Stack Atual e Alvo (Opcional)

- **Atual:** Java 1.8, Spring 1.2.8, Hibernate 3.2.6.ga, WebWork 2.2.2, Acegi Security 1.0.0, JSP/Servlet 2.4, MySQL, Prototype.js, DWR 2.0.1
- **Alvo:** [A ser definido com base no `passo-a-passo.md`]

**Regra central:** enquanto a migracao nao for concluida, todo novo codigo deve permanecer compativel com o stack atual.

> NOTE: Preencha com versoes reais e restricoes do ambiente.

### 2.1 Simplicidade Tecnológica

- Cada nova biblioteca, framework ou camada deve ser avaliada criticamente quanto a complexidade que adiciona, impacto na operação e risco de segurança.
- Prefira soluções simples e eficientes que atendam o requisito com menor custo de manutenção.
- Justifique formalmente adoções tecnológicas relevantes (ADR ou log dedicado), demonstrando benefícios concretos versus os custos de integração, suporte e treinamento.

## 3. Camadas e Dependencias (Regra de Ouro)

Fluxo recomendado (ajuste conforme o projeto):

```
Entrada (API/UI) -> Service/Business -> Persistencia -> Banco
```

Regras:
- A camada de entrada nao acessa persistencia diretamente.
- Services concentram regras de negocio e transacoes.
- Persistencia nao depende da camada web.
- Modelos de dominio nao dependem de frameworks web.

## 4. Regras de Compatibilidade

- Evite APIs exclusivas de versoes alvo antes da migracao.
- Mudancas que exigem quebra de compatibilidade devem ser isoladas e aprovadas por ADR.

## 5. Seguranca e Validacao

- Validacao de entradas e sanitizacao sao obrigatorias.
- SQL sempre parametrizado. Sem concatenacao de dados do usuario.
- Dados sensiveis nunca em logs em texto puro.

## 6. Observabilidade e Logs

- Padronize logging, niveis e formato.
- Proibido `System.out.println` (ou equivalente na linguagem alvo).

## 7. Testes e Qualidade

- Atualize testes ao alterar regras de negocio.
- Defina smoke tests para fluxos criticos.

## 8. ADR e Registro

- Decisoes arquiteturais nao triviais devem gerar ADR em `docs/adr/`.
- Use rascunho em `.ia/historico/` quando necessario.

## 9. Checklist de Conformidade

- [ ] Fluxo de camadas respeitado.
- [ ] Inputs validados e sanitizados.
- [ ] Sem dependencias exclusivas do stack alvo.
- [ ] Logs padronizados e seguros.
- [ ] Testes atualizados.
- [ ] ADR criado quando aplicavel.

> NOTE: Ajuste o checklist com criterios do seu time.
