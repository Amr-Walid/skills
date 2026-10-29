# AGENTS.md — drop-in instructions for any coding agent

> Copy this file to the root of any project (as `AGENTS.md`, `CLAUDE.md` or `GEMINI.md`)
> so every agent works in my style even when skills are not installed.

## Always

1. Read the project README and existing code conventions first; project rules override these.
2. Apply the `my-engineering-style` skill (stack defaults, naming, Definition of Done).
3. **Always work directly on `main`**: DO NOT create feature branches (e.g. `genspark_ai_developer`, `feature/*`), do not create worktrees, and do not create Pull Requests unless explicitly asked. Commit and push directly to `main`.
4. For non-trivial work: restate the goal, list assumptions, write a short plan, then execute in small verified steps.
5. Never claim success without evidence (build/test output, request/response, screenshot).
6. Reply in the language I use (Arabic or English); code, identifiers, comments and commits in English.

## Git & Workflow (Strict)

- **Direct to `main`**: All work, commits, and pushes MUST go directly to the `main` branch.
- **No auxiliary branches**: Never create `genspark_ai_developer`, isolated feature branches, or PRs unless the user explicitly asks for a branch or PR.
- **Conventional Commits**: Use descriptive messages like `feat(scope): ...` or `fix(scope): ...`.

## Pick the right skill

| Task | Skill(s) |
|------|----------|
| New system / big feature across layers | `system-builder` → `writing-plans` → `executing-plans` |
| Any UI / design | `design-direction` + `ui-ux-pro-max` + `frontend-design` |
| .NET / ASP.NET Core | `dotnet-solution-blueprint`, `dotnet-webapi`, `efcore-patterns`, `modern-csharp-coding-standards` |
| SQL Server | `sql-server-expert`, `sql-optimization-patterns` |
| SQLite | `sqlite-expert` |
| Security / before release | `secure-by-default`, `differential-review`, `stride-analysis-patterns` |
| Automations / workflows / scripts | `automation-engineering`, `n8n-workflow-patterns`, `bash-defensive-patterns` |
| Bugs | `systematic-debugging` |
| Tests | `test-driven-development`, `testcontainers-integration-tests`, `webapp-testing` |
| CI/CD & ops | `github-actions-templates`, `deployment-pipeline-design`, `slo-implementation` |

## Definition of Done (short)

- Builds clean, tests pass, security checklist applied, no secrets/PII in code or logs.
- Migrations included; docs/README updated; UI responsive, accessible, RTL-checked when Arabic is used.
- Final message: what changed · how verified · decisions · what's not done.
