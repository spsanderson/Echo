CREATE PROCEDURE dbo.YourProcedureName
AS
BEGIN
    SET NOCOUNT ON;

    -- This should be at the top of your procedure before the main logic
    -- Declare variables to capture start time, end time, and number of records inserted
    DECLARE @StartDateTime DATETIME = GETDATE();
    DECLARE @EndDateTime DATETIME;
    DECLARE @RecordsInserted INT = 0;

    -- Your data manipulation logic here
    -- This is just an example insert operation for to be replaced with your actual logic
    INSERT INTO dbo.YourTargetTable (Col1, Col2)
    SELECT Col1, Col2
    FROM dbo.SourceTable
    WHERE SomeCondition = 1;

    -- This captures the number of rows affected by the last insert operation
    SET @RecordsInserted = @@ROWCOUNT; -- Number of rows inserted

    -- Capture the end time after the operation
    SET @EndDateTime = GETDATE();

    -- Log the procedure run details into the logging table
    INSERT INTO dbo.c_procedure_run_log_tbl (
        ProcedureName,
        RecordsInserted,
        StartDateTime,
        EndDateTime,
        DurationSeconds,
        RunDate,
        RunDayOfWeek
    )
    VALUES (
        OBJECT_NAME(@@PROCID), -- Gets the current procedure name
        @RecordsInserted,
        @StartDateTime,
        @EndDateTime,
        DATEDIFF(SECOND, @StartDateTime, @EndDateTime),
        CAST(@StartDateTime AS DATE),
        DATENAME(WEEKDAY, @StartDateTime)
    );
END
