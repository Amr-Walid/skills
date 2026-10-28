---
name: secure-by-default
description: Mandatory application security baseline and review checklist covering OWASP Top 10 (2025) and OWASP API Security Top 10 - authentication, authorization, input validation, injection, XSS/CSRF, secrets, crypto, session/JWT handling, file uploads, SSRF, security headers, logging, rate limiting, dependency/supply-chain, containers, cloud and database hardening. Use whenever building or reviewing any feature that touches users, data, auth, files, external calls, or deployment - and before every release.
---

# Secure by Default

Security is a feature of every task, not a phase. Apply this checklist while writing code,
and run it fully before a release or PR. For deeper work use: `security/stride-analysis-patterns`
(threat modeling), `security/differential-review` (reviewing diffs), `security/semgrep` /
`security/codeql` (SAST), `security/supply-chain-risk-auditor`, `security/secrets-management`,
`security/sharp-edges`.

## 0. Principles

1. **Deny by default** — every endpoint requires auth unless explicitly public.
2. **Least privilege** — users, services, DB accounts, CI tokens, cloud roles.
3. **Validate input, encode output** — at every trust boundary.
4. **Never trust the client** — prices, roles, IDs, totals are recomputed/verified server-side.
5. **Defense in depth** — app checks + DB constraints + network rules.
6. **Secure failure** — errors fail closed and leak nothing.
7. **No secrets in code, logs, URLs or git history.**
8. **Use proven libraries** — never invent crypto, password hashing, or token formats.

## 1. Authentication

- [ ] Use a standard: ASP.NET Core Identity, OpenID Connect (Entra ID, Keycloak, Auth0), or passkeys/WebAuthn.
- [ ] Passwords: min 12 chars, check against breached lists, hash with Identity's PBKDF2 / Argon2id / bcrypt. Never MD5/SHA1/plain SHA256.
- [ ] MFA for admins and sensitive roles (TOTP / WebAuthn).
- [ ] Account lockout / throttling on login, reset, OTP endpoints. Generic error messages ("invalid credentials").
- [ ] Password reset tokens: single-use, short expiry, sent only to verified channel.
- [ ] Sessions: cookies `Secure; HttpOnly; SameSite=Lax/Strict`; rotate session ID on login; idle + absolute timeout; server-side logout.
- [ ] JWT: validate issuer, audience, lifetime, signature (RS256/ES256 or strong HS256 key from vault); short-lived access tokens (5–15 min) + rotating refresh tokens stored server-side; never put secrets/PII in JWT payload; reject `alg: none`.
- [ ] Store tokens in HttpOnly cookies for browser apps (BFF pattern) rather than localStorage.

## 2. Authorization (most common real-world bug!)

- [ ] Every endpoint has an explicit policy; fallback policy = authenticated user.
- [ ] **Object-level checks (BOLA/IDOR)**: verify the current user may access *this* record (`order.CustomerId == currentUser.CustomerId` or tenant match) — not just that they're logged in.
- [ ] **Function-level checks**: admin actions require admin policy server-side (hidden buttons ≠ security).
- [ ] **Property-level**: no mass assignment — bind to explicit DTOs; never bind request directly to entities (`IsAdmin`, `Price`, `TenantId` can't be set by client).
- [ ] Multi-tenancy: tenant ID from the authenticated principal, never from the request body/query; global query filters / SQL Server RLS.
- [ ] Use non-guessable public IDs where enumeration matters.

## 3. Input validation & injection

- [ ] Validate type, length, range, format, allow-lists (FluentValidation / DataAnnotations) on every input, including headers, query, route, files, webhooks.
- [ ] **SQL**: parameterized queries only (EF Core LINQ, Dapper params, `sp_executesql`). Never concatenate. Dynamic identifiers through allow-list + `QUOTENAME`. `FromSqlRaw` with interpolation is forbidden — use `FromSql($"...")` (parameterized).
- [ ] **Command injection**: avoid shelling out; if necessary use argument arrays (`ProcessStartInfo.ArgumentList`), never string concatenation.
- [ ] **Path traversal**: never build file paths from user input; use generated names + `Path.GetFullPath` check under a base dir.
- [ ] **Deserialization**: no `BinaryFormatter`; System.Text.Json with known types; no `TypeNameHandling.All` in Newtonsoft.
- [ ] **XML**: disable DTD/external entities (XXE).
- [ ] **Regex**: set timeouts (ReDoS).
- [ ] **LDAP / NoSQL / template injection**: use library escaping/parameterization.
- [ ] **LLM / prompt injection** (if AI features): treat model output as untrusted input; no direct tool execution of model output without allow-lists; don't put secrets in prompts.

## 4. Output & browser security

- [ ] Context-aware output encoding (Razor/React encode by default — avoid `Html.Raw`, `dangerouslySetInnerHTML`, `v-html`; sanitize with a proven HTML sanitizer if rich text is required).
- [ ] CSRF protection for cookie-authenticated state-changing requests (antiforgery tokens / SameSite + custom header).
- [ ] Security headers:
  ```
  Strict-Transport-Security: max-age=31536000; includeSubDomains
  Content-Security-Policy: default-src 'self'; frame-ancestors 'none'; object-src 'none'; base-uri 'self'
  X-Content-Type-Options: nosniff
  Referrer-Policy: strict-origin-when-cross-origin
  Permissions-Policy: camera=(), microphone=(), geolocation=()
  ```
- [ ] CORS: explicit origin allow-list; never `*` with credentials.
- [ ] Open redirects: only redirect to relative/allow-listed URLs (`Url.IsLocalUrl`).

## 5. Files & external calls

- [ ] Uploads: size limits, allow-list extensions **and** check magic bytes, random server-side names, store outside web root / in blob storage, serve with `Content-Disposition: attachment` where relevant, malware scan if user-facing.
- [ ] Image processing in sandboxed/limited libraries; strip EXIF if privacy matters.
- [ ] **SSRF**: when fetching user-supplied URLs, allow-list hosts/schemes, block private/link-local/metadata IPs (169.254.169.254), resolve DNS then check IP, disable redirects or re-validate.
- [ ] Webhooks in: verify HMAC signatures + timestamp (replay protection); idempotency.
- [ ] Outgoing calls: timeouts, TLS validation on (never disable certificate validation).

## 6. Secrets & crypto

- [ ] Secrets in Key Vault / AWS Secrets Manager / Doppler / GitHub Encrypted Secrets / `dotnet user-secrets` for dev. `.env` is git-ignored; ship `.env.example`.
- [ ] Rotate keys; separate per environment; least-privilege API keys.
- [ ] Scan for secrets in CI (gitleaks / GitHub secret scanning + push protection). If a secret was committed: **rotate it first**, then purge history.
- [ ] TLS 1.2+ everywhere, including DB connections (`Encrypt=True`).
- [ ] At rest: TDE / disk encryption; column-level encryption (Always Encrypted / ASP.NET Data Protection) for national IDs, health, financial data.
- [ ] Use `RandomNumberGenerator` for tokens; AES-GCM for symmetric encryption; never ECB; never hardcoded IVs/keys.
- [ ] ASP.NET Data Protection keys persisted & protected in multi-instance deployments.

## 7. Abuse prevention

- [ ] Rate limiting per user/IP on auth, OTP, search, export, and expensive endpoints.
- [ ] Pagination with max page size; request body size limits; query complexity limits (GraphQL).
- [ ] Business-logic abuse: coupon reuse, negative quantities, race conditions on balances (use DB transactions + concurrency tokens + unique constraints), idempotency keys on payments.
- [ ] CAPTCHA / bot protection on public forms if abused.

## 8. Logging, monitoring, privacy

- [ ] Log security events: logins (success/fail), MFA changes, permission changes, admin actions, access denied, data exports.
- [ ] Never log passwords, tokens, full card numbers, national IDs, secrets, or full request bodies with PII. Mask.
- [ ] Correlation IDs; centralized logs; alerts on anomalies (many 401/403, spikes).
- [ ] Error responses: ProblemDetails without stack traces in production.
- [ ] PII minimization, retention & deletion policy; consent where required (GDPR / local law).

## 9. Dependencies & supply chain

- [ ] Lock files committed; Central Package Management for .NET; pin GitHub Actions to SHA for third-party actions.
- [ ] `dotnet list package --vulnerable --include-transitive`, `npm audit`, Dependabot/Renovate enabled.
- [ ] Review new dependencies (maintenance, popularity, typosquatting) — see `security/supply-chain-risk-auditor`.
- [ ] SAST (CodeQL/Semgrep) on PRs; DAST (OWASP ZAP baseline) on staging.

## 10. Infrastructure, containers, database

- [ ] Containers: minimal base images, non-root user, read-only filesystem where possible, no secrets in image layers, scan images (Trivy).
- [ ] Only necessary ports exposed; DB not publicly reachable; admin panels behind VPN/SSO.
- [ ] DB: app account least privilege (no `sa`/`db_owner`), separate migration account, auditing on, backups encrypted and restore-tested.
- [ ] CI/CD: least-privilege tokens, OIDC to cloud instead of long-lived keys, protected branches, required reviews, environment approvals for prod.
- [ ] Debug features off in prod (developer exception page, Swagger UI unless protected, verbose errors, default credentials). See `security/sharp-edges`.

## 11. Security review procedure (for a PR or feature)

1. List entry points touched (endpoints, jobs, webhooks, UI forms) — `security/entry-point-analyzer`.
2. For each: who can call it? what data does it read/write? what's the trust boundary?
3. Walk sections 1–10 for those entry points only.
4. Check the diff for dangerous APIs (`FromSqlRaw`, `Html.Raw`, `Process.Start`, `BinaryFormatter`, `AllowAnyOrigin`, `ServerCertificateCustomValidationCallback`, `[AllowAnonymous]`, disabled validation).
5. Write findings as: **Severity · Location · Issue · Exploit scenario · Fix**. Verify each finding is real before reporting (`security/fp-check`).
6. Add tests for every fixed vulnerability (authz tests especially: user A can't read user B's data).

## Severity guide

| Severity | Example |
|---------|---------|
| Critical | SQLi, auth bypass, RCE, exposed secrets with prod access, IDOR on sensitive data at scale |
| High | Stored XSS, missing object-level authz, SSRF to internal network, weak JWT validation |
| Medium | Missing rate limiting on login, CSRF on non-critical action, verbose errors |
| Low | Missing security header, information disclosure of versions |
