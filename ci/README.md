# CI workflow (optional)

`validate-skills.yml` checks every `SKILL.md` (frontmatter + unique names), makes sure
`CATALOG.md` is up to date, and smoke-tests the installer.

It lives here because the automation that created this repo isn't allowed to write to
`.github/workflows/`. To turn it on, move it once from your own machine:

```bash
mkdir -p .github/workflows
git mv ci/validate-skills.yml .github/workflows/validate-skills.yml
git commit -m "ci: enable skills validation workflow" && git push
```
