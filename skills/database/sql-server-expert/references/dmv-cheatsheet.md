# SQL Server Diagnostic Cheat Sheet

## Currently running requests + blocking

```sql
SELECT r.session_id, r.blocking_session_id, r.status, r.wait_type, r.wait_time,
       r.cpu_time, r.logical_reads, DB_NAME(r.database_id) AS db,
       SUBSTRING(t.text, (r.statement_start_offset/2)+1,
         ((CASE r.statement_end_offset WHEN -1 THEN DATALENGTH(t.text) ELSE r.statement_end_offset END
           - r.statement_start_offset)/2)+1) AS running_statement
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE r.session_id <> @@SPID
ORDER BY r.cpu_time DESC;
```

## Top waits since restart

```sql
SELECT TOP (15) wait_type, wait_time_ms/1000.0 AS wait_s, waiting_tasks_count
FROM sys.dm_os_wait_stats
WHERE wait_type NOT LIKE '%SLEEP%' AND wait_type NOT LIKE 'BROKER%'
  AND wait_type NOT IN ('CLR_AUTO_EVENT','LAZYWRITER_SLEEP','XE_TIMER_EVENT','REQUEST_FOR_DEADLOCK_SEARCH',
                        'SQLTRACE_INCREMENTAL_FLUSH_SLEEP','DIRTY_PAGE_POLL','HADR_FILESTREAM_IOMGR_IOCOMPLETION')
ORDER BY wait_time_ms DESC;
```

## Most expensive cached queries (by logical reads)

```sql
SELECT TOP (20) qs.execution_count, qs.total_logical_reads, qs.total_worker_time/1000 AS cpu_ms,
       qs.total_elapsed_time/1000 AS elapsed_ms, t.text, p.query_plan
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) t
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) p
ORDER BY qs.total_logical_reads DESC;
```

## Missing index suggestions (review, don't blindly apply)

```sql
SELECT TOP (25) d.statement AS table_name, d.equality_columns, d.inequality_columns, d.included_columns,
       s.user_seeks, s.avg_total_user_cost, s.avg_user_impact,
       s.user_seeks * s.avg_total_user_cost * (s.avg_user_impact/100.0) AS score
FROM sys.dm_db_missing_index_details d
JOIN sys.dm_db_missing_index_groups g ON g.index_handle = d.index_handle
JOIN sys.dm_db_missing_index_group_stats s ON s.group_handle = g.index_group_handle
ORDER BY score DESC;
```

## Unused indexes (current DB)

```sql
SELECT OBJECT_NAME(i.object_id) AS table_name, i.name AS index_name,
       us.user_seeks, us.user_scans, us.user_lookups, us.user_updates
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats us
       ON us.object_id = i.object_id AND us.index_id = i.index_id AND us.database_id = DB_ID()
WHERE OBJECTPROPERTY(i.object_id,'IsUserTable') = 1 AND i.type_desc = 'NONCLUSTERED'
  AND i.is_primary_key = 0 AND i.is_unique_constraint = 0
  AND ISNULL(us.user_seeks,0) + ISNULL(us.user_scans,0) + ISNULL(us.user_lookups,0) = 0
ORDER BY us.user_updates DESC;
```

## Index fragmentation

```sql
SELECT OBJECT_NAME(ps.object_id) AS table_name, i.name, ps.avg_fragmentation_in_percent, ps.page_count
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ps
JOIN sys.indexes i ON i.object_id = ps.object_id AND i.index_id = ps.index_id
WHERE ps.page_count > 1000 AND ps.avg_fragmentation_in_percent > 30
ORDER BY ps.avg_fragmentation_in_percent DESC;
```

## Recent deadlocks (system_health)

```sql
SELECT xed.value('@timestamp','datetime2') AS ts, xed.query('.') AS deadlock_graph
FROM (SELECT CAST(target_data AS XML) AS td
      FROM sys.dm_xe_session_targets st
      JOIN sys.dm_xe_sessions s ON s.address = st.event_session_address
      WHERE s.name = 'system_health' AND st.target_name = 'ring_buffer') x
CROSS APPLY td.nodes('//RingBufferTarget/event[@name="xml_deadlock_report"]') AS q(xed)
ORDER BY ts DESC;
```

## Table sizes

```sql
SELECT s.name + '.' + t.name AS table_name, SUM(p.rows) AS row_count,
       SUM(a.total_pages) * 8 / 1024 AS total_mb
FROM sys.tables t
JOIN sys.schemas s ON s.schema_id = t.schema_id
JOIN sys.indexes i ON i.object_id = t.object_id
JOIN sys.partitions p ON p.object_id = i.object_id AND p.index_id = i.index_id
JOIN sys.allocation_units a ON a.container_id = p.partition_id
WHERE i.index_id IN (0,1)
GROUP BY s.name, t.name
ORDER BY total_mb DESC;
```

## Last backups

```sql
SELECT d.name, MAX(CASE WHEN b.type='D' THEN b.backup_finish_date END) AS last_full,
       MAX(CASE WHEN b.type='I' THEN b.backup_finish_date END) AS last_diff,
       MAX(CASE WHEN b.type='L' THEN b.backup_finish_date END) AS last_log
FROM sys.databases d
LEFT JOIN msdb.dbo.backupset b ON b.database_name = d.name
GROUP BY d.name ORDER BY d.name;
```
