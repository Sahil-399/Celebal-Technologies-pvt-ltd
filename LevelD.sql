USE celebalTech;

CREATE TABLE Date_Dimension (
    SKDate INT PRIMARY KEY,
    KeyDate DATE,
    Date DATE,
    CalendarDay INT,
    CalendarMonth INT,
    CalendarMonthName VARCHAR(20),
    CalendarYear INT,
    DayName VARCHAR(20),
    DayNameShort VARCHAR(5),
    DayOfWeek INT,
    DayOfYear INT,
    DaySuffix VARCHAR(5),
    FiscalWeek INT,
    FiscalPeriod INT,
    FiscalQuarter INT,
    FiscalYear INT,
    FiscalYearPeriod INT
);

INSERT INTO Date_Dimension (
    SKDate, KeyDate, Date, CalendarDay, CalendarMonth, CalendarMonthName,
    CalendarYear, DayName, DayNameShort, DayOfWeek, DayOfYear, DaySuffix,
    FiscalWeek, FiscalPeriod, FiscalQuarter, FiscalYear, FiscalYearPeriod
)
VALUES 
(20030129, '2003-01-29', '2003-01-29', 29, 1, 'January', 2003, 'Wednesday', 'Wed', 4, 29, '29th', 5, 1, NULL, 2003, 20031),
(20030315, '2003-03-15', '2003-03-15', 15, 3, 'March',    2003, 'Saturday',  'Sat', 7, 74, '15th', 11, 3, NULL, 2003, 20033),
(20030429, '2003-04-29', '2003-04-29', 29, 4, 'April',     2003, 'Tuesday',   'Tue', 3, 119, '29th', 18, 4, NULL, 2003, 20034),
(20030613, '2003-06-13', '2003-06-13', 13, 6, 'June',      2003, 'Friday',    'Fri', 6, 164, '13th', 24, 6, NULL, 2003, 20036),
(20030728, '2003-07-28', '2003-07-28', 28, 7, 'July',      2003, 'Monday',    'Mon', 2, 209, '28th', 31, 7, NULL, 2003, 20037),
(20030911, '2003-09-11', '2003-09-11', 11, 9, 'September', 2003, 'Thursday',  'Thu', 5, 254, '11th', 37, 9, NULL, 2003, 20039),
(20031026, '2003-10-26', '2003-10-26', 26, 10,'October',   2003, 'Sunday',    'Sun', 1, 299, '26th', 44, 10, NULL, 2003, 200310);

GO;

CREATE PROCEDURE Populate_Date_Dimension (@InputDate DATE)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @StartDate DATE = DATEFROMPARTS(YEAR(@InputDate), 1, 1);
    DECLARE @EndDate DATE = DATEFROMPARTS(YEAR(@InputDate), 12, 31);

    ;WITH DateCTE AS (
        SELECT @StartDate AS DateValue
        UNION ALL
        SELECT DATEADD(DAY, 1, DateValue)
        FROM DateCTE
        WHERE DateValue < @EndDate
    )
    INSERT INTO Date_Dimension (
        SKDate, KeyDate, Date, CalendarDay, CalendarMonth, CalendarMonthName,
        CalendarYear, DayName, DayNameShort, DayOfWeek, DayOfYear, DaySuffix,
        FiscalWeek, FiscalPeriod, FiscalQuarter, FiscalYear, FiscalYearPeriod
    )
    SELECT
        CONVERT(INT, FORMAT(DateValue, 'yyyyMMdd')) AS SKDate,
        DateValue AS KeyDate,
        DateValue AS Date,
        DAY(DateValue) AS CalendarDay,
        MONTH(DateValue) AS CalendarMonth,
        DATENAME(MONTH, DateValue) AS CalendarMonthName,
        YEAR(DateValue) AS CalendarYear,
        DATENAME(WEEKDAY, DateValue) AS DayName,
        LEFT(DATENAME(WEEKDAY, DateValue), 3) AS DayNameShort,
        DATEPART(WEEKDAY, DateValue) AS DayOfWeek,
        DATEPART(DAYOFYEAR, DateValue) AS DayOfYear,
        -- Suffix logic
        CAST(DAY(DateValue) AS VARCHAR) + 
        CASE 
            WHEN DAY(DateValue) IN (11,12,13) THEN 'th'
            WHEN RIGHT(CAST(DAY(DateValue) AS VARCHAR),1) = '1' THEN 'st'
            WHEN RIGHT(CAST(DAY(DateValue) AS VARCHAR),1) = '2' THEN 'nd'
            WHEN RIGHT(CAST(DAY(DateValue) AS VARCHAR),1) = '3' THEN 'rd'
            ELSE 'th'
        END AS DaySuffix,
        DATEPART(WEEK, DateValue) AS FiscalWeek, -- Approximate
        MONTH(DateValue) AS FiscalPeriod,        -- Assuming fiscal = calendar
        DATEPART(QUARTER, DateValue) AS FiscalQuarter,
        YEAR(DateValue) AS FiscalYear,
        YEAR(DateValue) * 100 + MONTH(DateValue) AS FiscalYearPeriod
    FROM DateCTE
    OPTION (MAXRECURSION 366);
END;

EXEC Populate_Date_Dimension '2020-07-14';

SELECT * FROM Date_Dimension;