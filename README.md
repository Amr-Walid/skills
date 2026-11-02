# 🧠 Amr's Agent Skills

A curated + custom library of **Agent Skills** (`SKILL.md` format) that teaches AI coding
models (Claude Code, Codex, Gemini CLI, Copilot, Cursor…) **how I work**: my engineering style,
building full systems end-to-end, strong UI design & animation, Arabic/English typography, web performance,
mobile apps (Flutter, Android, iOS), security, .NET, SQL Server, SQLite and automation.

**243 skills · 17 categories** — full list in **[CATALOG.md](CATALOG.md)**.

---

## 🇪🇬 بالعربي — الريبو ده فيه إيه؟

مكتبة **Skills** للموديلز بتاعتك عشان تفهم أسلوبك وشغلك. كل Skill عبارة عن فولدر جواه `SKILL.md`
(تعليمات + أمثلة + checklists) والموديل بيحمّله أوتوماتيك لما المهمة تناسبه.

| القسم | فيه إيه |
|------|---------|
| `core` ⭐ | **أسلوبك الشخصي** (`my-engineering-style`) + **بناء سيستم من الصفر للإنتاج** (`system-builder`) |
| `workflow` | التخطيط، TDD، الـ debugging المنهجي، الـ code review، التحقق قبل ما يقول "خلصت" |
| `design` | تصميم قوي ومميز: `design-direction` + `impeccable` + `ui-ux-pro-max` + `emil-design-eng` + `apple-design` + design systems + accessibility |
| `design` (خطوط) ✍️ | **`arabic-typography`** (خطوط عربي: اختيار، دمج مع الإنجليزي، line-height، أرقام، RTL) + **`latin-typography`** (خطوط إنجليزي، type scale، OpenType) |
| `animation` 🎬 | `motion-system` (tokens + اختيار الأداة لكل منصة) + **GSAP الرسمي** (core, timeline, ScrollTrigger, React…) + Emil Kowalski (animate, review, performance) + View Transitions |
| `performance` ⚡ | `performance-engineering` (budgets + ويب + API + موبايل) + `web-font-performance` + Core Web Vitals / web quality / SEO (Addy Osmani) + React best practices (Vercel) |
| `mobile` 📱 | `mobile-app-engineering` (تختار Flutter ولا Native ولا React Native + security + release) + React Native/Expo + PWA |
| `flutter` 💙 | `flutter-expert` + **Skills رسمية من فريق Flutter** + Riverpod/Bloc + Firebase + testing |
| `android` 🤖 | **Skills رسمية من Google** (Compose performance, adaptive, edge-to-edge, Navigation 3, profiler, ANR, R8) + `compose-expert` |
| `ios` 🍎 | SwiftUI expert (AvdLee) + SwiftUI Pro (Paul Hudson) + Dimillian (UI patterns, performance, Liquid Glass, concurrency) + `write-swift` |
| `architecture` | Clean Architecture، API design، microservices، CQRS، sagas، ADRs، auth patterns |
| `security` | `secure-by-default` (OWASP checklist كامل) + أدوات Trail of Bits للـ audit و threat modeling |
| `dotnet` | `dotnet-solution-blueprint` + Skills رسمية من فريق .NET في Microsoft + EF Core و C# standards |
| `database` | `sql-server-expert` و `sqlite-expert` (مكتوبين مخصوص) + SQL optimization و migrations |
| `devops` | GitHub Actions، deployment pipelines، observability، SLOs، runbooks |
| `testing` | Playwright، E2E، property-based testing |
| `automation` | `automation-engineering` + 14 Skill لـ **n8n** + Bash / Python resilience |
| `meta` | إزاي تكتب Skills جديدة بنفسك |

### التسطيب السريع

```bash
git clone https://github.com/Amr-Walid/skills.git
cd skills
./install.sh                    # كل الـ skills لـ Claude Code (~/.claude/skills)
./install.sh --link             # symlinks: أي git pull يحدّث كل حاجة
./install.sh --only core,dotnet,database,security   # أقسام معينة بس
./install.sh --only core,design,animation,performance,mobile,flutter   # تصميم + موبايل
./install.sh --agent codex      # لـ Codex
```

على Windows (PowerShell):

```powershell
git clone https://github.com/Amr-Walid/skills.git; cd skills
.\install.ps1                   # أو: .\install.ps1 -Link  /  .\install.ps1 -Only core,dotnet
```

### أهم خطوة: خصّص أسلوبك ✍️

افتح [`skills/core/my-engineering-style/SKILL.md`](skills/core/my-engineering-style/SKILL.md) وعدّل
الأجزاء المعلّمة بـ `<!-- EDIT -->` (الـ stack، التسمية، قواعد الجودة). ده الملف اللي بيخلّي أي موديل
يشتغل **بطريقتك انت**.

### استخدامه مع موديلات تانية (ChatGPT / Gemini / أي LLM)

لو الأداة مش بتدعم Skills: انسخ محتوى `SKILL.md` المناسب في الـ system prompt / custom instructions،
أو حط [`AGENTS.md`](AGENTS.md) في جذر أي مشروع.

---

## 🇬🇧 English

### Quick start

```bash
git clone https://github.com/Amr-Walid/skills.git && cd skills
./install.sh --list                       # categories and counts
./install.sh                              # all -> ~/.claude/skills
./install.sh --link                       # symlink (stay updated with git pull)
./install.sh --only core,design,security  # selected categories
./install.sh --agent project              # -> ./.claude/skills in the current project
./install.sh --target /any/folder
```

PowerShell: `.\install.ps1 [-Agent claude|codex|gemini|project] [-Target <dir>] [-Only a,b] [-Link] [-List]`

### Original skills (written for this repo)

| Skill | Purpose |
|------|---------|
| [`core/my-engineering-style`](skills/core/my-engineering-style/SKILL.md) | My defaults: stack, structure, naming, Definition of Done, git, summary format |
| [`core/system-builder`](skills/core/system-builder/SKILL.md) | 12-phase playbook from idea → production (requirements, domain, architecture, data, API, security, UI, tests, CI/CD, ops, handover) + templates |
| [`design/design-direction`](skills/design/design-direction/SKILL.md) | Forces deliberate, distinctive design decisions; tokens, all states, Arabic/RTL, self-critique rubric |
| [`design/arabic-typography`](skills/design/arabic-typography/SKILL.md) | Arabic font catalog by job, Arabic+Latin pairing, sizing/line-height, shaping rules, numerals, RTL, Flutter/Android/iOS recipes |
| [`design/latin-typography`](skills/design/latin-typography/SKILL.md) | Latin typeface catalog by personality, fluid type scale, spacing, OpenType features, tokens per platform |
| [`animation/motion-system`](skills/animation/motion-system/SKILL.md) | Motion tokens, tool choice (CSS/View Transitions/Motion/GSAP/Lottie/Rive/Flutter/Compose/SwiftUI), choreography, 60fps rules, reduced motion |
| [`performance/performance-engineering`](skills/performance/performance-engineering/SKILL.md) | Budgets, measure-first workflow, web/API/mobile fixes in priority order, before/after report |
| [`performance/web-font-performance`](skills/performance/web-font-performance/SKILL.md) | WOFF2, subsetting (Arabic-safe), unicode-range, preload, font-display, CLS-free fallbacks, mobile bundling |
| [`mobile/mobile-app-engineering`](skills/mobile/mobile-app-engineering/SKILL.md) | Flutter vs native vs RN decision, shared architecture, platform design, permissions/push/deep links, mobile security, release |
| [`flutter/flutter-expert`](skills/flutter/flutter-expert/SKILL.md) | Flutter house standards (Riverpod, go_router, dio, freezed, drift), structure, UI bar, performance, tests, DoD — routes to all flutter skills |
| [`dotnet/dotnet-solution-blueprint`](skills/dotnet/dotnet-solution-blueprint/SKILL.md) | Production ASP.NET Core layout, Program.cs, errors, auth, EF Core, jobs, tests, Docker, CI |
| [`database/sql-server-expert`](skills/database/sql-server-expert/SKILL.md) | T-SQL standards, schema design, indexing, plans, locking, RLS, encryption, backups + DMV cheat sheet |
| [`database/sqlite-expert`](skills/database/sqlite-expert/SKILL.md) | PRAGMAs, STRICT tables, concurrency, migrations, FTS5, SQLCipher, .NET usage |
| [`security/secure-by-default`](skills/security/secure-by-default/SKILL.md) | OWASP Top 10 + API Top 10 checklist and security review procedure |
| [`automation/automation-engineering`](skills/automation/automation-engineering/SKILL.md) | Tool selection, idempotency, retries, observability, script templates (PowerShell/Bash/Python/Hangfire), n8n standards |

### Curated upstream skills

Copied (unchanged except noted) from the best open-source skill repositories:

| Source | License | Used for |
|--------|---------|----------|
| [obra/superpowers](https://github.com/obra/superpowers) | MIT | workflow (planning, TDD, debugging, review) |
| [anthropics/skills](https://github.com/anthropics/skills) | Apache-2.0 | frontend-design, skill-creator, mcp-builder, webapp-testing… |
| [nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) | MIT | ui-ux-pro-max design intelligence, design-system, brand |
| [wshobson/agents](https://github.com/wshobson/agents) | MIT | architecture, UI design, devops, SQL, security scanning |
| [trailofbits/skills](https://github.com/trailofbits/skills) | CC-BY-SA-4.0 | security auditing (semgrep, codeql, differential review…) |
| [dotnet/skills](https://github.com/dotnet/skills) | MIT | official .NET team skills (Web API, EF Core, perf, upgrades) |
| [Aaronontheweb/dotnet-skills](https://github.com/Aaronontheweb/dotnet-skills) | MIT | C# standards, EF Core, DI, config, Testcontainers, Aspire |
| [czlonkowski/n8n-skills](https://github.com/czlonkowski/n8n-skills) | MIT | n8n automation |
| [greensock/gsap-skills](https://github.com/greensock/gsap-skills) | MIT | official GSAP (core, timeline, ScrollTrigger, plugins, React, performance) |
| [emilkowalski/skill](https://github.com/emilkowalski/skill) | MIT | animation craft, design engineering, Apple-style design, mobile-web feel, Swift |
| [pbakaus/impeccable](https://github.com/pbakaus/impeccable) | Apache-2.0 | `impeccable` design critique/polish/audit command suite |
| [vercel-labs/agent-skills](https://github.com/vercel-labs/agent-skills) | MIT | React/Next perf, React Native, View Transitions, web design guidelines |
| [addyosmani/web-quality-skills](https://github.com/addyosmani/web-quality-skills) | MIT | Core Web Vitals, performance, accessibility, SEO, web quality audit |
| [flutter/skills](https://github.com/flutter/skills) | BSD-3-Clause | official Flutter & Dart team skills |
| [evanca/flutter-ai-rules](https://github.com/evanca/flutter-ai-rules) | MIT (see attribution) | Flutter best practices, Riverpod/Bloc, Firebase, testing |
| [android/skills](https://github.com/android/skills) | Apache-2.0 | official Android skills (Compose perf, adaptive, edge-to-edge, profiler, ANR, R8…) |
| [aldefy/compose-skill](https://github.com/aldefy/compose-skill) | MIT | Jetpack Compose / Compose Multiplatform expert |
| [AvdLee/SwiftUI-Agent-Skill](https://github.com/AvdLee/SwiftUI-Agent-Skill) | MIT | SwiftUI expert |
| [twostraws/SwiftUI-Agent-Skill](https://github.com/twostraws/SwiftUI-Agent-Skill) | MIT | SwiftUI Pro review |
| [Dimillian/Skills](https://github.com/Dimillian/Skills) | MIT | SwiftUI patterns, performance, Liquid Glass, Swift concurrency, iOS debugging |

Exact upstream path + commit for every skill: [`sources.tsv`](sources.tsv). License texts: [`licenses/`](licenses).
Local modifications: `ui-ux-pro-max` script paths made relative; `ui-styling` reuses `canvas-design` fonts;
seven `Aaronontheweb` skill folders renamed to match their `name:` field. To keep names unique after
flattening, some imports were renamed (folder + `name:`): Addy Osmani's `performance/accessibility/seo/best-practices`
→ `web-*` (internal links updated), evanca `testing/accessibility` → `flutter-*`, Android `adaptive` →
`compose-adaptive-layouts`, `testing-setup` → `android-testing-setup`, Vercel skills → `vercel-*`.

### Repository layout

```
skills/<category>/<skill-name>/SKILL.md   # + optional references/, scripts/, assets/
scripts/validate_skills.py                # frontmatter + unique-name checks
scripts/build_catalog.py                  # regenerates CATALOG.md
install.sh / install.ps1                  # flatten & install into an agent folder
AGENTS.md                                 # drop-in project instructions for any agent
ci/validate-skills.yml                    # optional GitHub Actions check (see ci/README.md to enable)
sources.tsv / licenses/                   # attribution
```

### Adding your own skill

1. `mkdir skills/<category>/<my-skill>` and create `SKILL.md`:
   ```markdown
   ---
   name: my-skill
   description: What it does AND when to use it (this text is what triggers the skill).
   ---
   # Instructions…
   ```
2. `python3 scripts/validate_skills.py && python3 scripts/build_catalog.py`
3. Commit. See `meta/writing-skills` and `meta/skill-creator` for best practices.

### License

Original skills: MIT ([LICENSE](LICENSE)). Third-party skills keep their original licenses (see table above).
