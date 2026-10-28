---
name: automation-engineering
description: Playbook for designing and building reliable automations - choosing the right tool (n8n, Power Automate, GitHub Actions, PowerShell, Bash, Python, .NET Worker/Hangfire, Windows Task Scheduler/cron), idempotency, retries, error handling, secrets, logging, scheduling, webhooks, file/email/Excel/DB/API integrations, browser automation (Playwright), and AI agent workflows. Use when asked to automate any process, build a workflow, write a script/job/bot, integrate two systems, or schedule recurring work.
---

# Automation Engineering

An automation is production software that runs unattended. It must be **safe to re-run,
observable, and recoverable**. For n8n specifics use `automation/n8n-*` skills; for scripts use
`automation/bash-defensive-patterns`, `automation/python-resilience`, `automation/python-background-jobs`.

## 1. Before building — answer these

1. **Trigger**: schedule (cron), event (webhook, file drop, new email, DB row, queue message), or manual?
2. **Inputs/outputs**: systems, formats (JSON, CSV, Excel, PDF), volumes, frequency.
3. **Failure impact**: what if it runs twice? doesn't run? half-runs? → defines idempotency & alerting needs.
4. **Credentials**: which accounts, least privilege, where stored.
5. **Owner & alerting**: who gets notified on failure, via what (email, Teams/Slack, WhatsApp/Telegram)?
6. **Manual fallback**: how is the task done if the automation is down?

## 2. Choosing the tool

| Need | Best choice |
|------|-------------|
| Connect SaaS/APIs visually, webhooks, approvals, AI agents, quick iteration | **n8n** (self-hosted) |
| Microsoft 365 heavy (SharePoint, Outlook, Teams, Excel Online) | Power Automate (or n8n with MS Graph) |
| Repo/CI tasks, scheduled jobs close to code, releases | **GitHub Actions** |
| Windows servers, AD, Exchange, file servers, SQL Server admin | **PowerShell** (+ Task Scheduler) |
| Linux servers, glue scripts, cron | **Bash** (with `set -euo pipefail`) |
| Data processing, scraping, Excel/PDF, ML | **Python** |
| Business-critical jobs inside a .NET system, needs transactions/DB | **.NET Worker Service / Hangfire / Quartz.NET** |
| UI-only legacy systems with no API | **Playwright** browser automation (last resort; RPA) |

Rule: if it's part of the product's domain logic → keep it in the app (.NET jobs). If it's glue between systems → n8n/scripts.

## 3. Reliability rules (non-negotiable)

- **Idempotent**: re-running produces the same result. Use natural keys / external IDs, upserts, "processed" markers, idempotency keys on APIs.
- **Checkpointing**: record progress (last processed ID/timestamp) so a crash resumes instead of restarting.
- **Retries with exponential backoff + jitter** for transient errors (timeouts, 429, 5xx) only; never retry validation errors (4xx).
- **Timeouts** on every network call.
- **Dead-letter**: items that fail after N retries go to an error table/folder/queue with the reason — the rest continue.
- **Batching**: process in chunks (e.g. 100–1000) to bound memory and API limits; respect rate limits.
- **Locking**: prevent overlapping runs (lock file, DB lock `sp_getapplock`, n8n single execution, `concurrency:` in GitHub Actions).
- **Dry-run mode** for anything destructive (delete, send email, pay) — log what *would* happen.
- **Validate inputs** (schema, required fields) before acting; fail loudly with context.

## 4. Observability

- Structured logs per run: run ID, start/end, counts (read/processed/skipped/failed), duration.
- Alert on: failure, zero items when items were expected, run longer than normal, backlog growth.
- Daily/weekly summary message for business owners when useful.
- Keep an execution history (n8n executions, job table, Actions logs) with a retention policy.

## 5. Secrets & security

- Credentials in n8n Credentials / GitHub Secrets / Windows Credential Manager / Key Vault / env vars — never inline in scripts or workflow JSON exported to git.
- Service accounts with least privilege; separate accounts per environment.
- Verify webhook signatures (HMAC) and use secret paths/tokens on inbound webhooks.
- Sanitize data passed to shells/SQL (parameters, argument arrays).
- Log no secrets or PII.

## 6. Script templates

### PowerShell

```powershell
#Requires -Version 7
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)] [string] $SourcePath,
    [switch] $DryRun
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$runId = [guid]::NewGuid().ToString('N').Substring(0,8)
Start-Transcript -Path "logs/run-$(Get-Date -Format yyyyMMdd-HHmmss)-$runId.log" | Out-Null
try {
    $files = Get-ChildItem -Path $SourcePath -Filter *.csv -File
    $ok = 0; $failed = 0
    foreach ($f in $files) {
        try {
            if ($PSCmdlet.ShouldProcess($f.FullName, 'Import') -and -not $DryRun) {
                # ... process file ...
            }
            $ok++
        } catch {
            $failed++
            Write-Warning "[$runId] Failed $($f.Name): $($_.Exception.Message)"
            Move-Item $f.FullName -Destination (Join-Path $SourcePath 'failed') -Force
        }
    }
    Write-Information "[$runId] Done. ok=$ok failed=$failed" -InformationAction Continue
    if ($failed -gt 0) { exit 2 }
} finally { Stop-Transcript | Out-Null }
```

### Bash

```bash
#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'
trap 'echo "ERROR line $LINENO: $BASH_COMMAND" >&2' ERR
LOCK=/tmp/$(basename "$0").lock
exec 9>"$LOCK"; flock -n 9 || { echo "Already running"; exit 0; }
DRY_RUN="${DRY_RUN:-0}"
log() { printf '%s [%s] %s\n' "$(date -u +%FT%TZ)" "$1" "$2"; }
# ... work ...
log INFO "done"
```

### Python

```python
import logging, time, random, httpx

log = logging.getLogger("job")

def with_retry(fn, attempts=5, base=1.0):
    for i in range(attempts):
        try:
            return fn()
        except (httpx.TimeoutException, httpx.HTTPStatusError) as e:
            transient = isinstance(e, httpx.TimeoutException) or e.response.status_code in (429, 500, 502, 503, 504)
            if not transient or i == attempts - 1:
                raise
            delay = base * 2 ** i + random.uniform(0, 0.5)
            log.warning("retry %s in %.1fs: %s", i + 1, delay, e)
            time.sleep(delay)
```

### .NET scheduled job (Hangfire)

```csharp
RecurringJob.AddOrUpdate<InvoiceSyncJob>("invoice-sync", j => j.RunAsync(CancellationToken.None), "*/15 * * * *");

[DisableConcurrentExecution(timeoutInSeconds: 600)]
[AutomaticRetry(Attempts = 3)]
public sealed class InvoiceSyncJob(IInvoiceSource src, AppDbContext db, ILogger<InvoiceSyncJob> log)
{
    public async Task RunAsync(CancellationToken ct)
    {
        var since = await db.SyncState.Where(s => s.Name == "invoices").Select(s => s.LastSyncedUtc).SingleAsync(ct);
        await foreach (var batch in src.GetChangedSinceAsync(since, batchSize: 500, ct))
        {
            // upsert by ExternalId (idempotent), then advance checkpoint inside the same transaction
        }
    }
}
```

## 7. Common integrations — tips

- **Excel/CSV**: validate headers, trim/normalize Arabic text (unify أ/إ/آ → ا if matching), parse dates with explicit culture, never trust row counts.
- **Email**: use MS Graph / Gmail API over IMAP where possible; mark processed messages (label/category) for idempotency.
- **WhatsApp/SMS/Telegram**: use official APIs; rate-limit; template approval for WhatsApp Business.
- **Databases**: use parameterized queries; dedicated least-privilege automation account; avoid long transactions.
- **Files/SFTP**: write to temp name then rename (atomic); move processed files to `archive/`, failed to `failed/`.
- **PDF**: generate from HTML templates; extract with proper libraries; OCR only when needed.
- **AI steps (LLM)**: deterministic structure (JSON schema output), validate model output, human-in-the-loop for high-impact actions, log prompts/responses without PII, cap cost/tokens.

## 8. n8n workflow standards (summary)

- One workflow = one business process; reusable parts in sub-workflows (`automation/n8n-subworkflows`).
- Name nodes by intent ("Get unpaid invoices", not "HTTP Request1").
- Error Trigger workflow → alert channel with workflow name, execution URL, error (`automation/n8n-error-handling`).
- Use `Continue On Fail` + IF for per-item error routing; collect failures into a report.
- Pin test data while developing; validate with `automation/n8n-validation-expert`.
- Export workflows to git (without credentials) for versioning.

## 9. Delivery checklist

- [ ] Trigger, schedule (with timezone!) and overlap protection defined
- [ ] Idempotent + checkpointed; dry-run mode for destructive steps
- [ ] Retries/backoff on transient errors; dead-letter for bad items
- [ ] Secrets in a secret store; least-privilege accounts
- [ ] Logs with run ID + counts; failure alerts reach a human
- [ ] Tested with: empty input, one item, large batch, malformed item, downstream outage, re-run
- [ ] README: what it does, trigger, owner, how to run manually, how to recover
