
/*** TODO: Replace [dbo].[MyTableName] with the name of your specific table ***/


-- step 1: CREATE
-- CREATE hypothetical indexes using the WITH STATISTICS_ONLY clause:

/* TODO: Replace with your own index definitions, but don't forget to use WITH STATISTICS_ONLY */

CREATE NONCLUSTERED INDEX [IX_Hypothetical]
ON [dbo].[MyTableName] ( [column1], [column2] )
WITH STATISTICS_ONLY

GO

-- step 2: AUTOPILOT
-- Generate and run DBCC AUTOPILOT commands to mark ALL hypothetical indexes for AUTOPILOT:

DECLARE @TableName nvarchar(256) = '[dbo].[MyTableName]'

-- DBCC AUTOPILOT (typeid [, dbid [, {maxQueryCost | tabid [, indid [, pages [, flag [, rowcounts]]]]} ]])
DECLARE @cmd nvarchar(max)

DECLARE cmd CURSOR
LOCAL FAST_FORWARD
FOR
SELECT N'DBCC AUTOPILOT(0,' + CONVERT(nvarchar(MAX), DB_ID()) +  N',' + CONVERT(nvarchar(MAX), object_id) + N',' + CONVERT(nvarchar(MAX), index_id) +  N');'
FROM sys.indexes
WHERE is_hypothetical = 1
AND object_id = OBJECT_ID(@TableName)

OPEN cmd

WHILE 1=1
BEGIN
	FETCH NEXT FROM cmd INTO @cmd
	IF @@FETCH_STATUS <> 0 BREAK;

	PRINT @cmd;
	EXEC(@cmd);
END

CLOSE cmd
DEALLOCATE cmd
GO

-- step 3: GENERATE ESTIMATED PLAN
-- run the below to generate an estimated plan assuming the existence of hypothetical indexes marked for autopilot
-- WARNING: This was found to sometimes cause SQL Crash Dumps, specifically when cancelling mid-execution.
GO
SET AUTOPILOT ON;
GO

/* TODO: Add your test query here */

GO
SET AUTOPILOT OFF;
GO

-- step 4: CLEANUP
-- Generate and run DROP commands for ALL hypothetical indexes on the relevant table:

DECLARE @TableName nvarchar(256) = '[dbo].[MyTableName]'

DECLARE @cmd nvarchar(max)

DECLARE cmd CURSOR
LOCAL FAST_FORWARD
FOR
SELECT N'DROP INDEX ' + QUOTENAME(name) + N' ON ' + QUOTENAME(OBJECT_SCHEMA_NAME(object_id)) + N'.' + QUOTENAME(OBJECT_NAME(object_id)) + N';'
FROM sys.indexes
WHERE object_id = OBJECT_ID(@TableName)
AND is_hypothetical = 1

OPEN cmd

WHILE 1=1
BEGIN
	FETCH NEXT FROM cmd INTO @cmd
	IF @@FETCH_STATUS <> 0 BREAK;

	PRINT @cmd;
	EXEC(@cmd);
END

CLOSE cmd
DEALLOCATE cmd
GO
