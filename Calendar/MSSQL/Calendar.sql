-- Schemas
CREATE SCHEMA Reference;
GO

-------------
-- Numbers --
-------------
CREATE TABLE Reference.Numbers
(
	Number INT NOT NULL PRIMARY KEY
);

-- Populate with 65536 integers
WITH Level0
AS (   SELECT	1 AS constant
	   UNION ALL
	   SELECT	1),
	 Level1
AS (   SELECT	1 AS constant
	   FROM		Level0			  AS A
				CROSS JOIN Level0 AS B),
	 Level2
AS (   SELECT	1 AS constant
	   FROM		Level1			  AS A
				CROSS JOIN Level1 AS B),
	 Level3
AS (   SELECT	1 AS constant
	   FROM		Level2			  AS A
				CROSS JOIN Level2 AS B),
	 Level4
AS (   SELECT	1 AS constant
	   FROM		Level3			  AS A
				CROSS JOIN Level3 AS B),
	 Sequential_Integers
AS (   SELECT	ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Number
	   FROM		Level4)
INSERT INTO Reference.Numbers (Number)
			SELECT	Sequential_Integers.Number
			FROM	Sequential_Integers;

---------------
-- Reference --
---------------

-- Variable declaration
DECLARE @Min_Date_Calendar DATE = '20100101'; -- Calendar start date
DECLARE @Max_Date_Calendar DATE = '20500101'; -- Calendar end date

-- Fixed federal holidays
-- Source: https://en.wikipedia.org/wiki/Federal_holidays_in_the_United_States
CREATE TABLE Reference.Federal_Holidays_Fixed
(
	Holiday		 VARCHAR(50) NOT NULL PRIMARY KEY,
	Month		 TINYINT	 NOT NULL,
	Day_of_Month TINYINT	 NOT NULL
);

INSERT INTO Reference.Federal_Holidays_Fixed (Holiday, Month, Day_of_Month)
VALUES
('New Year''s Day', 1, 1),
('Independence Day', 7, 4),
('Veterans Day', 11, 11),
('Christmas Day', 12, 25),
('Juneteenth', 6, 19);

-- Floating federal holidays
-- Source: https://en.wikipedia.org/wiki/Federal_holidays_in_the_United_States
CREATE TABLE Reference.Federal_Holidays_Floating
(
	Holiday		VARCHAR(50) NOT NULL PRIMARY KEY,
	Month		TINYINT		NOT NULL,
	Date_Min	TINYINT		NOT NULL,
	Date_Max	TINYINT		NOT NULL,
	Day_of_Week TINYINT		NOT NULL,
);

INSERT INTO Reference.Federal_Holidays_Floating (Holiday, Month, Date_Min, Date_Max, Day_of_Week)
VALUES
('Birthday of Martin Luther King Jr.', 1, 15, 21, 2),
('Washington''s Birthday', 2, 15, 21, 2),
('Memorial Day', 5, 25, 31, 2),
('Labor Day', 9, 1, 7, 2),
('Columbus Day', 10, 8, 14, 2),
('Thanksgiving Day', 11, 22, 28, 5);

-- Calendar
CREATE TABLE Reference.Calendar
(
	Date			    DATE		    NOT NULL PRIMARY KEY,
	Year			    SMALLINT	  NOT NULL,
	Month			    TINYINT	    NOT NULL,
	Month_Name	  VARCHAR(10) NOT NULL,
	Day				    TINYINT	    NOT NULL,
	Day_Name		  VARCHAR(10) NOT NULL,
	Day_of_Year		SMALLINT	  NOT NULL,
	Weekday			  TINYINT	    NOT NULL,
	Year_Week		  TINYINT	    NOT NULL,
	US_Federal_Holiday VARCHAR(50) NULL,
);

-- Populate Calendar with dates between @Min_Date_Calendar and @Max_Date_Calendar
INSERT	Reference.Calendar (Date, Year, Month, Month_Name, Day, Day_Name, Day_of_Year, Weekday, Year_Week)
		SELECT	DATEADD(DAY, Number - 1, @Min_Date_Calendar),
				YEAR(DATEADD(DAY, Number - 1, @Min_Date_Calendar)),
				MONTH(DATEADD(DAY, Number - 1, @Min_Date_Calendar)),
				DATENAME(MONTH, (DATEADD(DAY, Number - 1, @Min_Date_Calendar))),
				DAY((DATEADD(DAY, Number - 1, @Min_Date_Calendar))),
				DATENAME(WEEKDAY, (DATEADD(DAY, Number - 1, @Min_Date_Calendar))),
				DATEPART(DAYOFYEAR, (DATEADD(DAY, Number - 1, @Min_Date_Calendar))),
				DATEPART(WEEKDAY, (DATEADD(DAY, Number - 1, @Min_Date_Calendar))),
				DATEPART(WEEK, (DATEADD(DAY, Number - 1, @Min_Date_Calendar)))
		FROM	Reference.Integers
		WHERE	Number <= 1 + DATEDIFF(DAY, @Min_Date_Calendar, @Max_Date_Calendar);

-- Update fixed holidays
WITH Calendar_Holidays
AS (   SELECT	C.Date, C.US_Federal_Holiday, FHF.Holiday
	   FROM		Reference.Calendar				 AS C
				INNER JOIN
				Reference.Federal_Holidays_Fixed AS FHF
					ON C.Month	  = FHF.Month
					   AND	C.Day = FHF.Day_of_Month)
UPDATE	Calendar_Holidays
SET		Calendar_Holidays.US_Federal_Holiday = Calendar_Holidays.Holiday;

-- Update floating holidays
WITH Calendar_Holidays
AS (   SELECT	C.Date, C.US_Federal_Holiday, FHF.Holiday
	   FROM		Reference.Calendar					AS C
				INNER JOIN
				Reference.Federal_Holidays_Floating AS FHF
					ON C.Month				= FHF.Month
					   AND	C.Day
					   BETWEEN FHF.Date_Min AND FHF.Date_Max
					   AND	FHF.Day_of_Week = C.Weekday)
UPDATE	Calendar_Holidays
SET		Calendar_Holidays.US_Federal_Holiday = Calendar_Holidays.Holiday;

SELECT TOP 100 * FROM Reference.Calendar;

---------
-- EOF --
---------
