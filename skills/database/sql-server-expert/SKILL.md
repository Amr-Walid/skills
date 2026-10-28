---
name: sql-server-expert
description: Expert guidance for Microsoft SQL Server / Azure SQL - schema design, T-SQL, indexing, execution plans, query tuning, transactions & isolation, locking/deadlocks, stored procedures, migrations, security (logins, roles, RLS, Always Encrypted, TDE), backup/restore, HA, and monitoring with DMVs/Query Store. Use whenever writing or reviewing T-SQL, designing SQL Server tables, debugging slow queries or deadlocks, or configuring SQL Server for production.
---

# SQL Server Expert

Target: SQL Server 2019+ / 2022 / Azure SQL. Prefer features available in the
project's version; check with `SELECT @@VERSION;` and the DB compatibility level.

## 1. Schema design rules

```sql
CREATE TABLE dbo.Customer
(
    CustomerId     INT IDENTITY(1,1)  NOT NULL CONSTRAINT PK_Customer PRIMARY KEY CLUSTERED,
    PublicId       UNIQUEIDENTIFIER   NOT NULL CONSTRAINT DF_Customer_PublicId DEFAULT NEWSEQUENTIALID(),
    Code           VARCHAR(20)        NOT NULL,
    NameAr         NVARCHAR(200)      NOT NULL,
    NameEn         NVARCHAR(200)      NULL,
    Email          NVARCHAR(320)      NULL,
    CreditLimit    DECIMAL(19,4)      NOT NULL CONSTRAINT DF_Customer_CreditLimit DEFAULT (0),
    Status         TINYINT            NOT NULL CONSTRAINT DF_Customer_Status DEFAULT (1),
    IsDeleted      BIT                NOT NULL CONSTRAINT DF_Customer_IsDeleted DEFAULT (0),
    CreatedAtUtc   DATETIME2(3)       NOT NULL CONSTRAINT DF_Customer_CreatedAtUtc DEFAULT SYSUTCDATETIME(),
    CreatedBy      NVARCHAR(100)      NOT NULL,
    UpdatedAtUtc   DATETIME2(3)       NULL,
    UpdatedBy      NVARCHAR(100)      NULL,
    RowVersion     ROWVERSION         NOT NULL,
    CONSTRAINT UQ_Customer_Code     UNIQUE (Code),
    CONSTRAINT UQ_Customer_PublicId UNIQUE (PublicId),
    CONSTRAINT CK_Customer_CreditLimit CHECK (CreditLimit >= 0),
    CONSTRAINT CK_Customer_Status   CHECK (Status IN (1,2,3))
);
```

- **Always schema-qualify** (`dbo.Customer`), name every constraint (`PK_`, `FK_`, `UQ_`, `CK_`, `DF_`, `IX_`).
- Clustered key: narrow, unique, static, ever-increasing (`INT/BIGINT IDENTITY`). Avoid random `NEWID()` as clustered key (page splits); use `NEWSEQUENTIALID()` or keep GUID as a non-clustered unique column.
- Text: `NVARCHAR` for any human text (Arabic!), `VARCHAR` for codes/ASCII. Never `NVARCHAR(MAX)` by default. Use an Arabic collation (`Arabic_100_CI_AI`) or UTF-8 collation when needed; be consistent with tempdb collation.
- Dates: `DATETIME2(3)` UTC or `DATETIMEOFFSET`; `DATE` for pure dates. Never `DATETIME` for new work.
- Money: `DECIMAL(19,4)`; never `FLOAT`/`REAL` for money; avoid `MONEY` type.
- Booleans: `BIT NOT NULL` with default.
- Enums: `TINYINT` + `CHECK` or a lookup table with FK.
- Every FK column gets an index (SQL Server does not create it automatically).
- Use `ROWVERSION` for optimistic concurrency (maps to EF Core `[Timestamp]`).
- History/audit: **system-versioned temporal tables** for "who changed what when".

```sql
ALTER TABLE dbo.Customer ADD
    ValidFrom DATETIME2(3) GENERATED ALWAYS AS ROW START HIDDEN NOT NULL CONSTRAINT DF_Customer_ValidFrom DEFAULT SYSUTCDATETIME(),
    ValidTo   DATETIME2(3) GENERATED ALWAYS AS ROW END   HIDDEN NOT NULL CONSTRAINT DF_Customer_ValidTo   DEFAULT CONVERT(DATETIME2(3),'9999-12-31 23:59:59.999'),
    PERIOD FOR SYSTEM_TIME (ValidFrom, ValidTo);
ALTER TABLE dbo.Customer SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = history.Customer));
```

## 2. T-SQL coding standards

- `SET NOCOUNT ON; SET XACT_ABORT ON;` at the top of every procedure.
- Explicit column lists — never `SELECT *` in production code, never `INSERT` without column list.
- **Sargable predicates**: no functions on indexed columns.
  - ❌ `WHERE YEAR(OrderDate) = 2026`  ✅ `WHERE OrderDate >= '20260101' AND OrderDate < '20270101'`
  - ❌ `WHERE ISNULL(Status,0) = 1`     ✅ `WHERE Status = 1`
  - ❌ implicit conversions (`NVARCHAR` param vs `VARCHAR` column) — match types exactly.
- Set-based over cursors/loops. If a loop is unavoidable, batch it (`TOP (5000)` + `WHILE @@ROWCOUNT > 0`).
- Use `EXISTS` instead of `COUNT(*) > 0`; `NOT EXISTS` instead of `NOT IN` (NULL trap).
- Avoid scalar UDFs in hot queries (pre-2019) and multi-statement TVFs; prefer inline TVFs.
- Use `OFFSET … FETCH` or keyset pagination (`WHERE Id > @LastId ORDER BY Id`) for large sets.
- Use `MERGE` carefully (known bugs, race conditions); prefer `UPDATE` + `INSERT … WHERE NOT EXISTS` with proper locking hints `WITH (UPDLOCK, HOLDLOCK)` for upsert.
- Dynamic SQL **only** via `sp_executesql` with parameters; whitelist identifiers with `QUOTENAME()`.

### Stored procedure template

```sql
CREATE OR ALTER PROCEDURE dbo.usp_Order_Approve
    @OrderId     INT,
    @ApprovedBy  NVARCHAR(100),
    @RowVersion  BINARY(8)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRAN;

        UPDATE dbo.[Order]
        SET    Status = 3, ApprovedBy = @ApprovedBy, UpdatedAtUtc = SYSUTCDATETIME(), UpdatedBy = @ApprovedBy
        WHERE  OrderId = @OrderId AND Status = 2 AND RowVersion = @RowVersion;

        IF @@ROWCOUNT = 0
            THROW 50409, N'Order not found, not in Submitted state, or modified by another user.', 1;

        INSERT dbo.OrderHistory (OrderId, Action, ActionBy, ActionAtUtc)
        VALUES (@OrderId, N'Approved', @ApprovedBy, SYSUTCDATETIME());

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END;
```

## 3. Indexing

- Start from queries, not tables. Capture top queries via **Query Store**.
- Composite index column order: equality columns → range column → `INCLUDE` the selected columns.
- Covering index example:
  ```sql
  CREATE NONCLUSTERED INDEX IX_Order_CustomerId_OrderDate
      ON dbo.[Order] (CustomerId, OrderDate DESC)
      INCLUDE (Status, TotalAmount)
      WHERE IsDeleted = 0;            -- filtered index
  ```
- Filtered indexes for soft-delete / status subsets; unique filtered index for "unique when not deleted".
- Columnstore for analytics/reporting tables (millions of rows, aggregations).
- Don't blindly create "missing index" DMV suggestions — merge them, check overlap with existing indexes.
- Find unused indexes: `sys.dm_db_index_usage_stats` (since last restart). Find duplicates before adding.
- Maintenance: update statistics regularly; rebuild/reorganize only when fragmentation actually hurts (Ola Hallengren scripts are the standard).

## 4. Performance troubleshooting workflow

1. **Reproduce** with actual parameters; `SET STATISTICS IO, TIME ON;`
2. Get the **actual execution plan**. Look for: scans on big tables, key lookups with high count,
   estimated vs actual row mismatch (stats/parameter sniffing), implicit conversion warnings,
   spills to tempdb, parallelism skew, missing index hints.
3. Check **waits**: `sys.dm_os_wait_stats`, `sys.dm_exec_session_wait_stats`.
4. Check **blocking**: `sys.dm_exec_requests` (`blocking_session_id`), or `sp_WhoIsActive`.
5. **Query Store**: regressed queries, forced plans, plan variation.
6. Fix in order: query rewrite → index → statistics → parameter sniffing fix (`OPTION (RECOMPILE)`, `OPTIMIZE FOR`, PSP in 2022) → schema change → hardware.

```sql
-- Top CPU queries (Query Store)
SELECT TOP (20) q.query_id, qt.query_sql_text,
       SUM(rs.count_executions) AS execs,
       SUM(rs.avg_cpu_time * rs.count_executions)/1000.0 AS total_cpu_ms
FROM sys.query_store_query_text qt
JOIN sys.query_store_query q   ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_plan p    ON p.query_id = q.query_id
JOIN sys.query_store_runtime_stats rs ON rs.plan_id = p.plan_id
GROUP BY q.query_id, qt.query_sql_text
ORDER BY total_cpu_ms DESC;
```

## 5. Transactions, isolation, deadlocks

- Keep transactions **short**; never wait for user input or HTTP calls inside a transaction.
- Enable **RCSI** for OLTP apps to stop readers blocking writers:
  `ALTER DATABASE [App] SET READ_COMMITTED_SNAPSHOT ON WITH ROLLBACK IMMEDIATE;`
- **Never use `NOLOCK`** as a performance fix (dirty/duplicate/missing reads).
- Deadlocks: access tables in a consistent order, index to reduce lock footprint,
  retry on error 1205 in the app (with backoff). Capture graphs from the `system_health` XE session.
- Use `SERIALIZABLE` / `UPDLOCK, HOLDLOCK` only for targeted upsert / uniqueness races.

## 6. Security

- **Least privilege**: app uses a contained DB user or Entra ID managed identity; never `sa`, never `db_owner`.
  ```sql
  CREATE ROLE app_executor;
  GRANT EXECUTE ON SCHEMA::dbo TO app_executor;
  GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO app_executor;   -- only if not proc-only
  ALTER ROLE app_executor ADD MEMBER [app_user];
  ```
- Parameterized queries everywhere (EF Core/Dapper do this — never concatenate strings).
- **Row-Level Security** for multi-tenant isolation:
  ```sql
  CREATE SCHEMA sec;
  GO
  CREATE FUNCTION sec.fn_TenantPredicate(@TenantId INT)
  RETURNS TABLE WITH SCHEMABINDING AS
  RETURN SELECT 1 AS ok WHERE @TenantId = CAST(SESSION_CONTEXT(N'TenantId') AS INT);
  GO
  CREATE SECURITY POLICY sec.TenantPolicy
      ADD FILTER PREDICATE sec.fn_TenantPredicate(TenantId) ON dbo.[Order],
      ADD BLOCK  PREDICATE sec.fn_TenantPredicate(TenantId) ON dbo.[Order]
      WITH (STATE = ON);
  -- App sets per connection: EXEC sp_set_session_context @key=N'TenantId', @value=@tid, @read_only=1;
  ```
- Encryption: TLS (`Encrypt=True; TrustServerCertificate=False` in prod), **TDE** at rest,
  **Always Encrypted** for highly sensitive columns (national ID, card data), Dynamic Data Masking for support users.
- Enable **SQL Server Audit** for logins, permission changes and sensitive table access.
- Disable unused features (`xp_cmdshell`, CLR unless required); patch regularly.

## 7. Migrations & deployments

- Versioned scripts (EF Core migrations, DbUp, Flyway, or SSDT dacpac). One tool per project.
- **Expand → migrate → contract** for zero-downtime: add nullable column → backfill in batches → switch app → enforce NOT NULL / drop old column in a later release.
- Large data changes in batches to avoid log growth and long locks.
- Always back up before prod migrations; test the migration against a prod-size copy.
- Idempotent seed scripts (`IF NOT EXISTS … INSERT`).

## 8. Backup, HA, operations

- Recovery model FULL for prod + log backups (e.g. every 15 min) to meet RPO.
- `BACKUP … WITH CHECKSUM, COMPRESSION`; regularly **test restore** and run `DBCC CHECKDB`.
- HA/DR: Always On Availability Groups / Azure SQL geo-replication / log shipping.
- Monitor: CPU, waits, blocking, log/tempdb growth, failed jobs, backup age, Query Store regressions.
- Set `MAXDOP`, `cost threshold for parallelism` (e.g. 50), `max server memory` explicitly.

## 9. .NET integration notes

- Connection string: `Server=...;Database=...;Encrypt=True;Application Name=MyApp;` + Managed Identity / secret store.
- EF Core: `UseSqlServer(cs, o => o.EnableRetryOnFailure())`, map `RowVersion`, use `AsNoTracking()` for reads,
  `ExecuteUpdate/ExecuteDelete` for bulk; Dapper for heavy reports. See `dotnet/efcore-patterns`, `dotnet/optimizing-ef-core-queries`.
- Bulk insert: `SqlBulkCopy` or TVP (table-valued parameters).
- Handle transient errors (40613, 40501, 1205, -2) with retry policies.

## Review checklist

- [ ] Constraints named; FKs indexed; PK appropriate; correct data types (NVARCHAR, DATETIME2, DECIMAL).
- [ ] No `SELECT *`, no non-sargable predicates, no implicit conversions, no `NOLOCK`.
- [ ] Procedures: `SET NOCOUNT ON; SET XACT_ABORT ON;` + TRY/CATCH + THROW.
- [ ] Dynamic SQL parameterized via `sp_executesql` + `QUOTENAME`.
- [ ] Concurrency handled (`ROWVERSION`) and transaction scope minimal.
- [ ] App account least-privilege; secrets not in code; TLS enforced.
- [ ] Migration is reversible or expand/contract; tested on realistic data volume.

See `references/dmv-cheatsheet.md` for diagnostic queries.
