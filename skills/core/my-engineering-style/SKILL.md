---
name: my-engineering-style
description: The owner's personal engineering style, defaults and non-negotiables. Use at the START of every coding, design, architecture or automation task in any of the owner's projects, before writing code, so output matches how the owner works (stack choices, naming, structure, communication, quality bar). Also use when unsure which convention to follow.
---

# My Engineering Style

This skill describes how I (the repository owner) build software. Treat it as the
default contract for every project unless the project's own `AGENTS.md` / `CLAUDE.md`
/ README says otherwise. Project-level instructions always win over this file.

> **Customize me:** sections marked `<!-- EDIT -->` are meant to be tuned by the owner.
> The defaults below are a strong, opinionated baseline.

## 1. How to work with me

- **Understand before building.** For anything non-trivial, restate the goal in 2–4
  lines, list assumptions, and ask only the questions that truly block progress.
  For small/obvious tasks, just do it.
- **Plan, then execute.** Multi-step work gets a short numbered plan first
  (see `workflow/writing-plans`). Keep the plan updated as you go.
- **Small, verifiable steps.** Each step must compile, run, and be tested before the next.
- **Evidence over claims.** Never say "done" or "fixed" without showing proof:
  build output, test results, a curl response, a screenshot (see
  `workflow/verification-before-completion`).
- **Explain decisions briefly.** One line of *why* for each meaningful choice. No essays.
- **Communication language:** reply in the language I write in (Arabic — Egyptian
  dialect is fine — or English). Code, identifiers, commits and code comments are
  always in **English**.
- **Never silently cut scope.** If something is skipped, mocked or left as TODO, say so
  explicitly in the final summary.

## 2. Default stack <!-- EDIT -->

| Layer | Default | When to deviate |
|------|---------|-----------------|
| Backend | **.NET (latest LTS / current) + ASP.NET Core** (Minimal APIs or Controllers) | Small scripts → Python/PowerShell; edge/serverless → TypeScript |
| Data access | **EF Core** for CRUD, **Dapper** / raw SQL for hot paths & reports | — |
| Main DB | **SQL Server** | Embedded/desktop/mobile/local-first/tests → **SQLite** |
| Frontend | React + TypeScript + Tailwind (or Blazor when the team is all-.NET) | Static content → plain HTML/Tailwind |
| Auth | ASP.NET Core Identity / OpenID Connect (Entra ID, Keycloak, Auth0) | Never roll your own crypto or password storage |
| Background jobs | Hosted services / Hangfire / Quartz.NET | Cross-system workflows → n8n |
| Automation | n8n, PowerShell, Bash, Python, GitHub Actions | — |
| Observability | Serilog (structured) + OpenTelemetry + health checks | — |
| Tests | xUnit + FluentAssertions/Shouldly + Testcontainers; Playwright for E2E | — |
| CI/CD | GitHub Actions | — |
| Containers | Docker (multi-stage, non-root) | — |

## 3. Architecture defaults

- **Start as a modular monolith** with clear module boundaries (vertical slices or
  Clean Architecture). Split into services only with a proven reason (scale, team, deploy cadence).
- Layering for .NET: `Domain` → `Application` → `Infrastructure` → `Api/Web`
  (see `dotnet/dotnet-solution-blueprint`). Dependencies point inward only.
- **Configuration via options pattern**, secrets never in source control.
- **Every external call** has a timeout, retry with backoff (idempotent ops only) and logging.
- **Database migrations are code** (EF migrations or versioned SQL scripts), reviewed like code.
- Write an **ADR** (`docs/adr/NNNN-title.md`) for every decision that is expensive to reverse.

## 4. Code style

- Clear names over comments. Comments explain **why**, never **what**.
- Functions do one thing; prefer early returns over deep nesting.
- No magic numbers/strings → constants, enums or options.
- Nullable reference types **on**; warnings treated as errors in CI.
- Async all the way down; pass `CancellationToken`; never `.Result` / `.Wait()`.
- Fail fast at boundaries: validate input at the edge (FluentValidation / DataAnnotations).
- Consistent error contract: **RFC 9457 ProblemDetails** for every API error.
- Dates: store **UTC** (`datetime2` / `DateTimeOffset`), convert at the UI.
- Money: `decimal(19,4)` – never float.
- IDs: `int/bigint` identity internally; expose GUID/ULID publicly when IDs must not be guessable.
- Naming <!-- EDIT -->: C# PascalCase types/methods, camelCase locals, `_camelCase` private
  fields; SQL tables PascalCase singular (`Customer`), columns PascalCase; JSON camelCase;
  URLs kebab-case plural (`/api/v1/purchase-orders`).

## 5. Quality bar (Definition of Done)

A task is done only when **all** apply:

- [ ] Builds with zero warnings; linters/analyzers clean.
- [ ] Unit tests for business logic; integration tests for DB/API paths touched.
- [ ] Security checklist passed (see `security/secure-by-default`).
- [ ] No secrets, keys, connection strings or PII in code, logs or commits.
- [ ] Errors handled and logged with context (no swallowed exceptions).
- [ ] Migrations included and reversible (or documented as forward-only).
- [ ] README / docs updated (how to run, env vars, decisions).
- [ ] UI work: responsive, accessible (WCAG 2.2 AA), RTL checked if Arabic is supported.
- [ ] Verified by actually running it, with evidence in the summary.

## 6. Git conventions

- **Direct to `main`**: Always work and push directly to `main`. Do NOT create feature branches (e.g. `genspark_ai_developer`, `feature/*`), do NOT create worktrees, and do NOT open PRs unless explicitly requested by the user.
- **Conventional Commits**: `feat(orders): add bulk cancel endpoint`.
- One logical change per commit with a clear description and test notes.
- Never commit `bin/`, `obj/`, `node_modules/`, `.env`, `*.db` with real data, or secrets.

## 7. Final summary format

End every task with:

```
## Summary
- What changed (files / features)
- How it was verified (commands + results)
- Decisions & trade-offs
- Not done / follow-ups / risks
```

## 8. Related skills

- Building a whole system: `core/system-builder`
- Design work: `design/design-direction`, `design/impeccable`, `design/ui-ux-pro-max`, `design/frontend-design`
- Typography: `design/arabic-typography`, `design/latin-typography`, `performance/web-font-performance`
- Animation: `animation/motion-system` + `animation/gsap-*`, `animation/animate`, `animation/review-animations`
- Performance: `performance/performance-engineering` → `core-web-vitals`, `web-quality-audit`, `vercel-react-best-practices`
- Mobile: `mobile/mobile-app-engineering` → `flutter/flutter-expert`, `android/compose-expert`, `ios/swiftui-expert-skill`
- .NET: `dotnet/dotnet-solution-blueprint` + other `dotnet/*`
- SQL Server: `database/sql-server-expert` · SQLite: `database/sqlite-expert`
- Security: `security/secure-by-default` + other `security/*`
- Automation: `automation/automation-engineering` + `automation/n8n-*`
