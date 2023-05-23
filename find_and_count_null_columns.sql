/*
***********************************************************************
File: find_and_count_null_columns.sql

Input Parameters:
	None

Tables/Views:
	None

Creates Table/View:
	None

Functions:
	object_id

Author: Steven P. Sanderson II, MPH

Department: Patient Financial Services

Purpose/Description
	Find and count how many nulls there are per column in a table

Revision History:
Date		Version		Description
----		----		----
2023-05-23	v1			Initial Creation
***********************************************************************
*/

DECLARE @t nvarchar(max)
SET @t = N'SELECT '

SELECT @t = @t + 'sum(case when [' + c.name + '] is null then 1 else 0 end) "Null Values for [' + c.name + ']",
                sum(case when [' + c.name + '] is null then 0 else 1 end) "Non-Null Values for [' + c.name + ']",'
FROM sys.columns c 
WHERE c.object_id = object_id('AccountComments');

SET @t = SUBSTRING(@t, 1, LEN(@t) - 1) + ' FROM AccountComments;'

EXEC sp_executesql @t