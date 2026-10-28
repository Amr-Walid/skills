# System Builder Templates

## User story

```markdown
### US-012 — Approve purchase order
As a **Finance Manager** I want to **approve or reject submitted purchase orders**
so that **spending stays within budget**.

**Acceptance criteria**
- Given a PO in `Submitted` state, When I approve it, Then its state becomes `Approved`
  and the requester is notified.
- Given a PO above my approval limit, When I try to approve, Then I get 403 with a clear message.
- Given a PO already approved by someone else, When I approve, Then I get 409 Conflict.

**Priority:** Must · **Module:** Procurement · **Estimate:** 3
```

## ADR (Architecture Decision Record)

```markdown
# ADR-0003: Use SQL Server as the primary OLTP database

- Status: Accepted
- Date: YYYY-MM-DD
- Deciders: <names>

## Context
What forces are at play (requirements, constraints, team skills, cost)?

## Decision
What we decided, stated clearly.

## Alternatives considered
- PostgreSQL — pros/cons
- SQLite — pros/cons

## Consequences
Positive, negative, and follow-up work.
```

## Threat model row (STRIDE)

| ID | Component / Flow | STRIDE | Threat | Likelihood | Impact | Mitigation | Status |
|----|------------------|--------|--------|-----------|--------|------------|--------|
| T-07 | API → SQL Server | Tampering | SQL injection via report filter | Medium | High | Parameterized queries only, Dapper params, SAST rule | Mitigated |

## Runbook

```markdown
# Runbook: API returns 5xx spike

**Alert:** error rate > 2% for 5 min
**Impact:** users cannot submit orders

## Diagnose
1. Check dashboard <link> — which endpoints?
2. Check logs: `level=Error | correlationId=...`
3. Check DB: blocking sessions (`sp_WhoIsActive` / `sys.dm_exec_requests`)

## Mitigate
- Roll back last deploy: `<command>`
- Scale out: `<command>`

## Escalate
<owner / on-call contact>
```

## Non-functional requirements table

| Category | Requirement | Target | How verified |
|----------|-------------|--------|--------------|
| Performance | API p95 latency | < 300 ms at 200 rps | k6 load test |
| Availability | Monthly uptime | 99.9% | Uptime monitor |
| Security | Admin login | MFA required | Config review + test |
| Backup | RPO / RTO | 15 min / 2 h | Quarterly restore drill |
| Accessibility | WCAG | 2.2 AA | axe + manual |
| Localization | Languages | ar (RTL), en | Visual review |
