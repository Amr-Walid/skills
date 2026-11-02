# AGENTS.md — Master Instructions for Any Coding Agent

> Copy this file to the root of ANY project (as `AGENTS.md`, `CLAUDE.md`, or `GEMINI.md`)
> so every agent works in my exact style, follows strict Git rules, and draws from my skills library.

---

## 🧠 Skills Library Source & Sandbox Setup

- **Remote Library**: [https://github.com/Amr-Walid/skills](https://github.com/Amr-Walid/skills)
- **Catalog**: [CATALOG.md](https://github.com/Amr-Walid/skills/blob/main/CATALOG.md) (243 skills across 17 categories)

### ⚡ Mandatory Rule for Sandbox Environments (Genspark, Cloud VMs, Remote Containers):
If you are running in a sandbox where local skills are not pre-installed:
1. **Fetch the library**:
   ```bash
   git clone --depth 1 https://github.com/Amr-Walid/skills.git /tmp/skills
   cd /tmp/skills && ./install.sh || true
   ```
2. **Before starting ANY non-trivial task**:
   - Check the table below or `/tmp/skills/CATALOG.md`.
   - Read the relevant `SKILL.md` (e.g. `/tmp/skills/skills/<category>/<skill>/SKILL.md` or via `https://raw.githubusercontent.com/Amr-Walid/skills/main/skills/<category>/<skill>/SKILL.md`).
   - Adhere strictly to the guidelines, checklists, and anti-patterns defined in that skill.

---

## 🚨 Git & Workflow Rules (Strict & Non-Negotiable)

1. **Always Work and Push Directly to `main`**:
   - **DO NOT** create feature branches (e.g., `genspark_ai_developer`, `feature/*`, `dev`).
   - **DO NOT** create Git worktrees.
   - **DO NOT** open Pull Requests unless the user explicitly commands you in chat to do so.
   - Commit directly to `main` and push directly to `origin main` (or the tracking branch).
2. **Conventional Commits**:
   - Format: `feat(scope): concise description` or `fix(scope): concise description`.
   - One logical change per commit; clean, atomic commits.
3. **Evidence Over Claims**:
   - Never say "done" or "fixed" without showing concrete verification proof (terminal output, build log, test pass, curl response).
4. **Communication Language**:
   - Reply in the language the user writes in (Arabic / Egyptian dialect or English).
   - Code, identifiers, comments, and commit messages are **always in English**.

---

## 🎯 Pick the Right Skill (Always Consult Before Execution)

| Task / Domain | Mandatory Skill(s) in [Amr-Walid/skills](https://github.com/Amr-Walid/skills) | Path in Repo |
| :--- | :--- | :--- |
| **Owner Style & Standards** | `my-engineering-style` *(Defaults, stack, quality)* | `skills/core/my-engineering-style/SKILL.md` |
| **New System / Big Feature** | `system-builder` → `writing-plans` → `executing-plans` | `skills/core/system-builder/SKILL.md` |
| **UI & Visual Design** | `design-direction`, `impeccable`, `ui-ux-pro-max`, `frontend-design` | `skills/design/` |
| **Arabic / Bilingual UI & Fonts** | `arabic-typography`, `latin-typography`, `web-font-performance` | `skills/design/` & `skills/performance/` |
| **Animations & Motion** | `motion-system`, `animate`, `gsap-core`, `gsap-scrolltrigger`, `review-animations` | `skills/animation/` |
| **Web Performance & SEO** | `performance-engineering`, `core-web-vitals`, `web-quality-audit`, `vercel-react-best-practices` | `skills/performance/` |
| **Flutter Applications** | `flutter-expert`, `flutter-apply-architecture-best-practices`, `riverpod` / `bloc` | `skills/flutter/` |
| **Android (Kotlin / Compose)** | `compose-expert`, `jetpack-compose-performance`, `compose-adaptive-layouts`, `edge-to-edge` | `skills/android/` |
| **iOS (Swift / SwiftUI)** | `swiftui-expert-skill`, `swiftui-pro`, `swiftui-ui-patterns`, `swift-concurrency-expert` | `skills/ios/` |
| **React Native / Expo** | `vercel-react-native-skills`, `animate-expo` | `skills/mobile/` & `skills/animation/` |
| **.NET / ASP.NET Core** | `dotnet-solution-blueprint`, `dotnet-webapi`, `efcore-patterns`, `modern-csharp-coding-standards` | `skills/dotnet/` |
| **SQL Server** | `sql-server-expert`, `sql-optimization-patterns` | `skills/database/` |
| **SQLite** | `sqlite-expert` | `skills/database/` |
| **Security & Audits** | `secure-by-default`, `differential-review`, `stride-analysis-patterns` | `skills/security/` |
| **Automation & n8n** | `automation-engineering`, `n8n-workflow-patterns`, `bash-defensive-patterns` | `skills/automation/` |
| **Bugs & Failures** | `systematic-debugging` *(Root-cause tracing, no guessing)* | `skills/workflow/systematic-debugging/SKILL.md` |
| **Testing** | `test-driven-development`, `testcontainers-integration-tests`, `webapp-testing` | `skills/testing/` & `skills/workflow/` |
| **CI/CD & DevOps** | `github-actions-templates`, `deployment-pipeline-design`, `slo-implementation` | `skills/devops/` |

---

## ✅ Definition of Done (Quality Gate)

A task is complete **only** when all of the following are satisfied:
- [ ] Code compiles clean with zero warnings or linter errors.
- [ ] Unit/Integration tests pass for any touched logic.
- [ ] Direct commit and push to `main` (no branches, no PRs).
- [ ] Security standards verified (no hardcoded secrets, connection strings, or sensitive keys).
- [ ] UI is fully responsive, accessible, and verified for RTL if Arabic is supported.
- [ ] Final response contains: **What changed** · **Verification evidence** · **Key decisions made**.
