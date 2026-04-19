---
skill_name: modernization-java-migration
description: Guia especializado para migração de aplicações Java legadas (J2EE) para stack moderno (Spring Boot 3, Jakarta EE).
version: 1.0.0
tags: [migration, spring-boot-3, jakarta-ee, struts-6, hibernate-6]
---

# Guia de Modernização e Migração Java

Este skill fornece diretrizes específicas para migrar aplicações de stacks legados (Spring 1.x, Hibernate 3, WebWork) para a modernidade (Spring Boot 3, Hibernate 6, Struts 6).

## 1. Princípios da Migração "Big Bang" (Jakarta EE)

A migração para Spring Boot 3 implica na mudança do namespace `javax.*` para `jakarta.*`. Isso quebra compatibilidade com bibliotecas antigas.

- **Regra de Ouro:** Não tente misturar dependências J2EE (Servlet 2.5) com Jakarta EE (Servlet 6.0). O classpath vira um inferno.
- **Estratégia:** Atualize o `pom.xml` para excluir TODAS as dependências antigas e inclua apenas as novas versões compatíveis com Jakarta.

## 2. Upgrade do Stack Web (WebWork -> Struts 6)

O WebWork (base do Struts 2) morreu. O Struts 6 é a versão moderna compatível com Jakarta EE.

### Mapeamento de Conceitos
| WebWork / Struts Legado | Struts 6 Moderno | Ação Necessária |
| :--- | :--- | :--- |
| `com.opensymphony.xwork.ActionSupport` | `com.opensymphony.xwork2.ActionSupport` | Alterar import. O pacote mudou ligeiramente em versões interinas, mas Struts 6 mantém `xwork2`. |
| `ServletActionContext` | `org.apache.struts2.ServletActionContext` | Alterar import. |
| `xwork.xml` | `struts.xml` | Renomear arquivo. A estrutura DTD/XSD muda. |
| Tags `<ww:*>` | Tags `<s:*>` | Global replace nos JSPs. |

### Configuração do Filtro
No Spring Boot, não usamos `web.xml`. Registre o filtro do Struts via `@Bean`:

```java
@Bean
public FilterRegistrationBean<StrutsPrepareAndExecuteFilter> strutsFilter() {
    FilterRegistrationBean<StrutsPrepareAndExecuteFilter> registration = new FilterRegistrationBean<>();
    registration.setFilter(new StrutsPrepareAndExecuteFilter());
    registration.addUrlPatterns("/*");
    registration.setOrder(1); // Garantir ordem correta
    return registration;
}
```

## 3. Persistência (Hibernate 3 -> 6)

- **Sessão:** `SessionFactory` ainda existe, mas `HibernateTemplate` (Spring) foi removido há muito tempo.
- **Ação:** Reescreva DAOs que usam `HibernateTemplate` para usar `SessionFactory.getCurrentSession()` ou migre para Spring Data JPA (`interface Repository`).
- **Transações:** `@Transactional` do Spring funciona perfeitamente. Remova configurações manuais de transação em XML.

## 4. Segurança (Acegi -> Spring Security 6)

O Acegi é o avô do Spring Security. A configuração XML é totalmente incompatível.

- **Ação:** Apague o `applicationContext-security.xml`.
- **Substituição:** Crie uma classe `SecurityConfig` com `@EnableWebSecurity` e defina um `SecurityFilterChain`.
- **Senha:** O encoder `ShaPasswordEncoder` legado deve ser configurado temporariamente ou migrado para `BCrypt` (conforme já definido na Fase 1).

## 5. Passos Táticos

1.  **Limpeza do POM:** Remova tudo que for versão < 2015.
2.  **Compilação:** O projeto VAI quebrar. Corrija imports em massa (`javax.servlet` -> `jakarta.servlet`).
3.  **Configuração:** Crie a classe `Application` do Spring Boot.
4.  **XML Bridge:** Use `@ImportResource` para carregar XMLs de beans de serviço/DAO que ainda não foram migrados para anotações, mas com cuidado para não carregar configs conflitantes de infraestrutura.
