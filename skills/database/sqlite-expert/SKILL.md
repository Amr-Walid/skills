---
name: sqlite-expert
description: Expert guidance for SQLite - when to use it, schema design (STRICT tables, type affinity), PRAGMA configuration (WAL, foreign_keys, busy_timeout), indexing and EXPLAIN QUERY PLAN, concurrency limits, migrations (user_version, table-rebuild pattern), FTS5 full-text search, JSON functions, backups, encryption (SQLCipher), and usage from .NET (Microsoft.Data.Sqlite / EF Core). Use for desktop/mobile/embedded/local-first apps, test databases, small web apps, CLI tools, and caches.
---

# SQLite Expert

## 1. When SQLite is the right choice

✅ Desktop/mobile apps (WPF, WinForms, MAUI, Electron), embedded devices, local-first/offline sync,
CLI tools, automation state, caches, integration tests, low-to-medium traffic web apps with a **single writer node**.

❌ Many concurrent writers across processes/machines, network file shares (NFS/SMB — corruption risk),
need for per-user DB permissions, very large multi-TB OLTP. Use SQL Server instead.

## 2. Always configure the connection (PRAGMAs)

Run on **every** connection open (PRAGMAs are per-connection except `journal_mode=WAL`, which persists):

```sql
PRAGMA journal_mode = WAL;        -- readers don't block writer
PRAGMA synchronous = NORMAL;      -- safe with WAL, much faster than FULL
PRAGMA foreign_keys = ON;         -- OFF by default!
PRAGMA busy_timeout = 5000;       -- wait instead of failing with SQLITE_BUSY
PRAGMA temp_store = MEMORY;
PRAGMA cache_size = -20000;       -- ~20 MB page cache
```

Periodically / on shutdown: `PRAGMA optimize;` and occasionally `PRAGMA wal_checkpoint(TRUNCATE);`.
Integrity check: `PRAGMA integrity_check;` (or `quick_check`).

## 3. Schema design

```sql
CREATE TABLE customer (
    id            INTEGER PRIMARY KEY,                 -- alias of rowid, auto-increments
    public_id     TEXT    NOT NULL UNIQUE,             -- GUID/ULID as TEXT
    code          TEXT    NOT NULL UNIQUE COLLATE NOCASE,
    name          TEXT    NOT NULL,
    email         TEXT,
    credit_limit  INTEGER NOT NULL DEFAULT 0 CHECK (credit_limit >= 0),  -- money in minor units
    status        INTEGER NOT NULL DEFAULT 1 CHECK (status IN (1,2,3)),
    is_deleted    INTEGER NOT NULL DEFAULT 0 CHECK (is_deleted IN (0,1)),
    created_at    TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ','now')),
    updated_at    TEXT,
    version       INTEGER NOT NULL DEFAULT 0            -- optimistic concurrency
) STRICT;

CREATE INDEX ix_customer_status ON customer(status) WHERE is_deleted = 0;
```

- Use **`STRICT` tables** (3.37+) so types are enforced (`INTEGER, REAL, TEXT, BLOB, ANY`).
- `INTEGER PRIMARY KEY` = rowid alias (fastest). `AUTOINCREMENT` only if IDs must never be reused (slower).
- Consider `WITHOUT ROWID` for tables with a composite/text PK and small rows.
- **No native date type**: store ISO-8601 UTC TEXT (`2026-10-28T19:00:00.000Z`) or unix epoch INTEGER — pick one per project.
- **No native decimal**: store money as INTEGER minor units (cents/piasters) or TEXT; never REAL for money.
- Booleans: INTEGER 0/1 with CHECK.
- Case-insensitive text: `COLLATE NOCASE` (ASCII only — for Arabic/Unicode normalize in the app).
- Foreign keys: declare them **and** enable `PRAGMA foreign_keys=ON`; index FK columns.

## 4. Queries & indexing

- Check plans: `EXPLAIN QUERY PLAN SELECT …;` — look for `SCAN` on big tables vs `SEARCH … USING INDEX`.
- Composite indexes: equality columns first, then range/sort column. Covering indexes avoid table lookups.
- Partial indexes (`WHERE is_deleted = 0`) and expression indexes (`ON t(lower(email))`) are supported.
- Run `ANALYZE` / `PRAGMA optimize` so the planner has statistics.
- Always use **parameters** (`?`, `@name`) — never string concatenation.
- Upsert: `INSERT … ON CONFLICT(code) DO UPDATE SET name = excluded.name;`
- `RETURNING` clause (3.35+) to get inserted/updated rows.
- Window functions, CTEs, and JSON (`json_extract`, `->`, `->>`, `json_each`) are available.

## 5. Concurrency & transactions

- **One writer at a time** per database file; WAL allows many concurrent readers.
- Batch writes inside one transaction — 1000 inserts in one transaction is ~100x faster than autocommit.
- Use `BEGIN IMMEDIATE` for write transactions to take the write lock up front and avoid deadlock-style `SQLITE_BUSY` upgrades.
- Keep write transactions short; in web apps, serialize writes through one connection/queue if contention appears.
- Handle `SQLITE_BUSY` with `busy_timeout` + app-level retry.

## 6. Migrations

- Track version with `PRAGMA user_version` (integer) or a `schema_migrations` table.
- `ALTER TABLE` is limited (ADD COLUMN, RENAME COLUMN/TABLE, DROP COLUMN 3.35+). For other changes use the
  **12-step table rebuild**:

```sql
PRAGMA foreign_keys = OFF;
BEGIN;
CREATE TABLE customer_new (... new definition ...) STRICT;
INSERT INTO customer_new (id, code, name /* … */) SELECT id, code, name /* … */ FROM customer;
DROP TABLE customer;
ALTER TABLE customer_new RENAME TO customer;
-- recreate indexes, triggers, views
PRAGMA foreign_key_check;
COMMIT;
PRAGMA foreign_keys = ON;
```

- Ship migrations embedded in the app and run them at startup inside a transaction; back up the file first.

## 7. Full-text search (FTS5)

```sql
CREATE VIRTUAL TABLE product_fts USING fts5(name, description, content='product', content_rowid='id',
                                            tokenize = 'unicode61 remove_diacritics 2');
-- keep in sync with triggers (AFTER INSERT/UPDATE/DELETE on product)
SELECT p.* FROM product_fts f JOIN product p ON p.id = f.rowid
WHERE product_fts MATCH ? ORDER BY rank LIMIT 20;
```

`unicode61` with `remove_diacritics` works reasonably for Arabic (strips tashkeel); normalize alef/yaa/taa-marbuta variants in the app for better matching.

## 8. Backup, security, files

- Online backup: `VACUUM INTO 'backup-2026-10-28.db';` or the backup API (`SqliteConnection.BackupDatabase`). Never copy a live DB file while it's being written (copy `-wal`/`-shm` issues).
- Encryption at rest: **SQLCipher** (`SQLitePCLRaw.bundle_e_sqlcipher` in .NET) — keep the key in OS keychain/DPAPI, not in code.
- File permissions: restrict the DB file to the app user. Never place it on a network share.
- Don't commit `.db` files with real data to git.

## 9. .NET usage

```csharp
// Microsoft.Data.Sqlite
var cs = new SqliteConnectionStringBuilder
{
    DataSource = dbPath,
    Mode = SqliteOpenMode.ReadWriteCreate,
    Cache = SqliteCacheMode.Private,
    Pooling = true,
    ForeignKeys = true,
    DefaultTimeout = 5
}.ToString();

await using var conn = new SqliteConnection(cs);
await conn.OpenAsync(ct);
await using (var cmd = conn.CreateCommand())
{
    cmd.CommandText = "PRAGMA journal_mode=WAL; PRAGMA synchronous=NORMAL; PRAGMA busy_timeout=5000;";
    await cmd.ExecuteNonQueryAsync(ct);
}
```

- EF Core: `UseSqlite(cs)`. Limitations: no `decimal` ordering/aggregation in SQL (use value converters to long/double carefully), limited migrations (EF rebuilds tables automatically for many ops), `DateTimeOffset` ordering issues — convert to UTC ticks or `DateTime` UTC.
- Concurrency token: an `INTEGER version` column incremented on update (`IsConcurrencyToken()`), since there's no ROWVERSION.
- For **integration tests** prefer Testcontainers with the real production DB (SQL Server); SQLite in-memory (`DataSource=:memory:` with an open connection kept alive) is fine for fast unit-ish tests but behaves differently (types, collation, SQL dialect).
- Dapper works great with SQLite for lightweight apps.

## Review checklist

- [ ] WAL + foreign_keys + busy_timeout set on every connection.
- [ ] STRICT tables, CHECK constraints, FK indexes, explicit date/money representation.
- [ ] Writes batched in transactions; `BEGIN IMMEDIATE` for writes under contention.
- [ ] `EXPLAIN QUERY PLAN` checked for hot queries; `PRAGMA optimize` scheduled.
- [ ] Migrations versioned (`user_version`) and tested from empty + from previous version.
- [ ] Backup strategy (`VACUUM INTO` / backup API); encryption if data is sensitive.
- [ ] DB file not on network share and not committed to git.
