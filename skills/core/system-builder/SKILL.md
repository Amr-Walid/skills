---
name: system-builder
description: End-to-end playbook for building a complete software system from zero to production - discovery, requirements, domain modeling, architecture, data design, API design, security, UI, testing, CI/CD, deployment, observability and handover. Use when asked to "build a system", "start a new project", "design an app from scratch", plan an MVP, or when a task spans multiple layers (DB + API + UI + deploy).
---

# System Builder — From Idea to Production

Follow the phases **in order**. Each phase has an output (artifact) and a gate.
Do not skip a gate; if information is missing, make an explicit, written assumption
and keep going. Scale the depth to the project: a weekend tool needs a paragraph per
phase, an enterprise system needs full documents.

Always apply `core/my-engineering-style` alongside this skill.

```
0 Discovery → 1 Requirements → 2 Domain → 3 Architecture → 4 Data → 5 API
→ 6 Security → 7 UI/UX → 8 Implementation → 9 Testing → 10 CI/CD & Deploy
→ 11 Observability & Ops → 12 Handover
```

---

## Phase 0 — Discovery (output: `docs/00-vision.md`)

Answer in writing:
1. **Problem**: what pain, for whom? What happens today without the system?
2. **Users & roles**: list personas (e.g. Admin, Manager, Employee, Customer, Auditor).
3. **Success metrics**: how will we know it works? (time saved, error rate, revenue…)
4. **Constraints**: budget, deadline, team skills, hosting (cloud / on-prem), compliance
   (GDPR, PCI, local data laws), languages (Arabic/RTL?), devices, offline needs.
5. **Integrations**: ERP, payment gateway, SMS/email/WhatsApp, SSO, legacy DBs, files.
6. **Scale estimate**: users, requests/sec at peak, data growth per year, file storage.

Gate: one-paragraph vision statement + list of assumptions approved (or stated).

## Phase 1 — Requirements (output: `docs/01-requirements.md`)

- **Functional**: user stories `As a <role> I want <capability> so that <benefit>`
  with **acceptance criteria** (Given/When/Then). Group into epics.
- **Non-functional** (always cover each): performance (p95 latency target),
  availability (SLO), security, privacy, auditability, backup/RPO/RTO, accessibility,
  localization, browser/device support, maintainability.
- **Prioritize** with MoSCoW. Define the **MVP** = smallest set of Musts that delivers value.
- **Out of scope** list — just as important as scope.

Gate: MVP scope fits the timeline; every Must has acceptance criteria.

## Phase 2 — Domain Modeling (output: `docs/02-domain.md`)

- Ubiquitous language glossary (Arabic ↔ English terms if relevant).
- Identify **bounded contexts / modules** (e.g. Identity, Catalog, Orders, Billing, Reporting).
- For each module: entities, value objects, aggregates, invariants, domain events.
- **State machines** for anything with a lifecycle (Order: Draft → Submitted → Approved → Fulfilled → Closed / Cancelled). Write allowed transitions and who can trigger them.
- Draw an ER sketch (Mermaid `erDiagram`).

Gate: every user story maps to a module; every lifecycle has a state machine.

## Phase 3 — Architecture (output: `docs/03-architecture.md` + ADRs)

Decide and record (ADR for each):
- **Style**: modular monolith (default) vs microservices vs serverless. Justify.
- **Code structure**: Clean Architecture or Vertical Slices (see `architecture/architecture-patterns`, `dotnet/dotnet-solution-blueprint`).
- **Data stores**: SQL Server (default OLTP), SQLite (embedded/edge/local), Redis (cache/locks), blob storage (files), search engine only if needed.
- **Communication**: sync REST/gRPC inside, async messages (outbox + queue) for cross-module side effects.
- **Background processing**: hosted services / Hangfire / Quartz; long workflows → saga/orchestration.
- **Hosting**: containers (Docker) on cloud/VM/K8s; environments: dev, staging, prod.
- Diagrams: C4 Context + Container (Mermaid).
- Cross-cutting: logging, config, feature flags, caching, localization, time zones, multi-tenancy strategy (shared DB + `TenantId` + row filters, or DB-per-tenant).

Gate: an engineer new to the project can explain the system from the diagrams.

## Phase 4 — Data Design (output: migrations + `docs/04-data.md`)

- Normalize to 3NF for OLTP; denormalize deliberately for reads (views, projections).
- Every table: PK, `CreatedAtUtc`, `CreatedBy`, `UpdatedAtUtc`, `UpdatedBy`, `RowVersion` (optimistic concurrency); soft-delete (`IsDeleted`, `DeletedAtUtc`) only where business needs it.
- Constraints in the DB, not just the app: FK, UNIQUE, CHECK, NOT NULL, defaults.
- Indexes from real query patterns (FK columns, filters, sort keys); avoid over-indexing.
- Audit trail table or temporal tables for sensitive data.
- Seed data (lookups, roles, admin) via migration/seed scripts — idempotent.
- Backup, retention and archival policy.
- See `database/sql-server-expert`, `database/sqlite-expert`, `database/sql-optimization-patterns`.

Gate: schema reviewed against every acceptance criterion; migrations apply on empty DB from scratch.

## Phase 5 — API Design (output: OpenAPI spec)

- Resource-oriented REST, versioned (`/api/v1/...`), plural kebab-case nouns.
- Standard verbs/status codes; `201 + Location` on create; `204` on delete; `409` on conflict; `422`/`400` on validation with **ProblemDetails**.
- Pagination (`page`/`pageSize` or cursor), filtering, sorting, field limits; max page size enforced.
- Idempotency keys for POSTs that create money/side effects.
- Concurrency: ETag / `If-Match` or `RowVersion`.
- Consistent DTOs — never expose EF entities directly.
- See `architecture/api-design-principles`, `architecture/openapi-spec-generation`, `dotnet/dotnet-webapi`.

Gate: OpenAPI spec covers every story; error contract documented.

## Phase 6 — Security (output: `docs/06-security.md` threat model)

Run `security/secure-by-default` fully. Minimum:
- STRIDE threat model of the container diagram (`security/stride-analysis-patterns`).
- AuthN (OIDC / Identity, MFA for admins), AuthZ (role + policy + resource-based; deny by default).
- OWASP Top 10 / API Top 10 mitigations mapped to concrete controls.
- Secrets in a vault / user-secrets / env; rotation plan.
- Encryption in transit (TLS 1.2+, HSTS) and at rest (TDE / disk / column-level for PII).
- Rate limiting, input validation, output encoding, CSP and security headers.
- Audit log for security-relevant actions; PII minimization & retention.
- Dependency + container scanning in CI.

Gate: each threat has a mitigation or an accepted-risk note.

## Phase 7 — UI/UX (output: design system + screens)

- Use `design/design-direction` to pick a deliberate visual direction (not generic).
- Generate a design system with `design/ui-ux-pro-max` (palette, typography, spacing, components).
- Information architecture: sitemap + navigation per role.
- Key flows wireframed first (happy path + empty, loading, error, permission-denied states).
- Accessibility WCAG 2.2 AA, keyboard nav, focus states, contrast.
- RTL + Arabic typography if Arabic is supported; locale-aware dates/numbers/currency.
- Responsive breakpoints; dashboards: data density with clear hierarchy.

Gate: every story has a screen/state; design tokens defined.

## Phase 8 — Implementation

- Scaffold the solution skeleton first (build + run + health endpoint + CI green) — "walking skeleton".
- Then deliver **vertical slices**: one story end-to-end (DB → API → UI → test) at a time.
- Follow `workflow/test-driven-development` for business logic.
- Keep `README.md` runnable at all times (`clone → configure → run` in < 10 minutes).
- Use `workflow/subagent-driven-development` / `workflow/executing-plans` for big plans.

## Phase 9 — Testing (test pyramid)

| Level | What | Tools (.NET default) |
|------|------|------|
| Unit | domain rules, validators, mappers | xUnit, FluentAssertions |
| Integration | DB, repositories, API endpoints | WebApplicationFactory, Testcontainers (SQL Server), SQLite in-memory for fast cases |
| Contract | API schema stays compatible | OpenAPI diff, snapshot tests |
| E2E | critical user journeys only | Playwright |
| Non-functional | load, security | k6, OWASP ZAP baseline |

Gate: critical paths covered; CI runs all non-E2E tests on every PR.

## Phase 10 — CI/CD & Deployment

- GitHub Actions: restore → build → test → scan (SAST, deps, secrets) → publish artifact/image → deploy staging → smoke test → manual approval → prod.
- Infrastructure as code (Bicep/Terraform/compose). Environment config via env vars/secret store.
- DB migrations run as a controlled step (migration bundle / script), with backup first.
- Zero-downtime strategy: expand/contract migrations, rolling or blue-green deploys.
- Rollback plan written **before** first prod deploy.
- See `devops/github-actions-templates`, `devops/deployment-pipeline-design`, `dotnet/sdk-container-publishing`.

## Phase 11 — Observability & Operations

- Structured logs with correlation IDs; no secrets/PII in logs.
- Metrics (RED: rate, errors, duration) + business KPIs; traces via OpenTelemetry.
- Health checks: `/health/live`, `/health/ready` (DB, cache, external deps).
- Alerts on SLO burn, error spikes, queue backlog, disk/DB growth.
- Runbooks for top incidents; backups tested by actual restore.
- See `devops/slo-implementation`, `devops/incident-runbook-templates`.

## Phase 12 — Handover

- README (setup, env vars, scripts), architecture docs, ADRs, API docs, runbooks.
- Admin guide + user guide (Arabic/English as needed).
- Known limitations & roadmap.
- Credentials handed over securely; least-privilege accounts created.

---

## Deliverables checklist (copy into the project)

```
docs/
  00-vision.md
  01-requirements.md
  02-domain.md
  03-architecture.md
  04-data.md
  06-security.md
  adr/0001-record-architecture-decisions.md
  runbooks/
src/  tests/  .github/workflows/  docker/ (or deploy/)
README.md  AGENTS.md  .editorconfig  .gitignore
```

See `references/templates.md` for ready-to-fill templates (user story, ADR, threat model row, runbook).
