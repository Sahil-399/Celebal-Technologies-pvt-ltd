-- Dimension Table
CREATE TABLE dim_customer (
    customer_sk INT IDENTITY PRIMARY KEY,
    customer_id INT,
    name VARCHAR(100),
    address VARCHAR(255),
    previous_address VARCHAR(255),
    start_date DATE,
    end_date DATE,
    current_flag CHAR(1)
);

-- Staging Table
CREATE TABLE stg_customer (
    customer_id INT,
    name VARCHAR(100),
    address VARCHAR(255)
);

-- History Table (for SCD Type 4)
CREATE TABLE customer_history (
    customer_id INT,
    name VARCHAR(100),
    address VARCHAR(255),
    archived_at DATETIME DEFAULT GETDATE()
);

INSERT INTO dim_customer (customer_id, name, address, previous_address, start_date, end_date, current_flag)
VALUES
(1, 'Alice', 'Pune', NULL, '2022-01-01', NULL, 'Y'),
(2, 'Bob', 'Delhi', NULL, '2022-01-01', NULL, 'Y'),
(3, 'Charlie', 'Mumbai', NULL, '2022-01-01', NULL, 'Y');

-- Alice: Changed address
-- Bob: No change
-- Charlie: Changed name and address
INSERT INTO stg_customer (customer_id, name, address)
VALUES
(1, 'Alice', 'Bangalore'),
(2, 'Bob', 'Delhi'),
(3, 'Charles', 'Hyderabad');


GO
CREATE PROCEDURE apply_scd_changes
    @scd_type INT
AS
BEGIN
    SET NOCOUNT ON;
    --CLEANING AND DEDUPLICATING STAGING DATA
    ;WITH Cleaned AS(
        SELECT * FROM(
            SELECT *, ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY customer_id) AS rn
            FROM stg_customer) AS t
            WHERE rn=1)
        DELETE FROM stg_customer
        WHERE customer_id NOT IN (SELECT customer_id FROM Cleaned);
   
   --index creation
    IF NOT EXISTS(SELECT 1 FROM sys.indexes WHERE name='idx_customer_id' AND object_id= OBJECT_ID('dim_customer'))
        CREATE NONCLUSTERED INDEX idx_customer_id ON dim_customer(customer_id);
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'idx_current_flag' AND object_id = OBJECT_ID('dim_customer'))
        CREATE NONCLUSTERED INDEX idx_current_flag ON dim_customer(current_flag);
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'idx_start_date' AND object_id = OBJECT_ID('dim_customer'))
        CREATE NONCLUSTERED INDEX idx_start_date ON dim_customer(start_date);
    DECLARE @today DATE=GETDATE();

    --SCD LOGIC
    IF @scd_type=1
    BEGIN 
        PRINT 'SCD TYPE 0: NO CHANGES ALLOWED, NO ACTION PERFORMED.';
    END
    ELSE IF @scd_type=1
    BEGIN
        MERGE dim_customer AS Trget
        USING stg_customer AS Src
        ON Trget.customer_id=Src.customer_id
        WHEN MATCHED AND( 
            Trget.name<> Src.name OR
            Trget.address<> Src.address)
        THEN UPDATE SET
            Trget.name=Src.name,
            Trget.address=Src.address;
        END

        ELSE IF @scd_type=2
        BEGIN
            UPDATE dim_customer
            SET end_date=@today, current_flag='N'
            FROM dim_customer dc
        JOIN stg_customer sc ON dc.customer_id = sc.customer_id
        WHERE dc.current_flag = 'Y'
          AND (dc.name <> sc.name OR dc.address <> sc.address);

        -- Insert new records
        INSERT INTO dim_customer (customer_id, name, address, previous_address, start_date, end_date, current_flag)
        SELECT
            sc.customer_id, sc.name, sc.address, NULL, @today, NULL, 'Y'
        FROM stg_customer sc
        LEFT JOIN dim_customer dc ON dc.customer_id = sc.customer_id AND dc.current_flag = 'Y'
        WHERE dc.customer_id IS NULL
           OR dc.name <> sc.name OR dc.address <> sc.address;
    END

    ELSE IF @scd_type = 3
    BEGIN
        UPDATE dc
        SET dc.previous_address = dc.address,
            dc.address = sc.address
        FROM dim_customer dc
        JOIN stg_customer sc ON dc.customer_id = sc.customer_id
        WHERE dc.address <> sc.address;
    END

    ELSE IF @scd_type = 4
    BEGIN
        -- Archive current
        INSERT INTO customer_history (customer_id, name, address)
        SELECT dc.customer_id, dc.name, dc.address
        FROM dim_customer dc
        JOIN stg_customer sc ON dc.customer_id = sc.customer_id
        WHERE dc.name <> sc.name OR dc.address <> sc.address;

        -- Overwrite dimension
        UPDATE dim_customer
        SET name = sc.name,
            address = sc.address
        FROM dim_customer dc
        JOIN stg_customer sc ON dc.customer_id = sc.customer_id
        WHERE dc.name <> sc.name OR dc.address <> sc.address;
    END

    ELSE IF @scd_type = 6
    BEGIN
        -- Mark old version
        UPDATE dim_customer
        SET end_date = @today,
            current_flag = 'N'
        FROM dim_customer dc
        JOIN stg_customer sc ON dc.customer_id = sc.customer_id
        WHERE dc.current_flag = 'Y'
          AND (dc.name <> sc.name OR dc.address <> sc.address);

        -- Insert new with previous_address = old address
        INSERT INTO dim_customer (customer_id, name, address, previous_address, start_date, end_date, current_flag)
        SELECT
            sc.customer_id, sc.name, sc.address, dc.address,
            @today, NULL, 'Y'
        FROM stg_customer sc
        JOIN dim_customer dc
            ON sc.customer_id = dc.customer_id AND dc.current_flag = 'N'
        WHERE dc.end_date = @today;
    END

    ELSE
    BEGIN
        RAISERROR('Invalid SCD type specified. Please enter a number between 0 and 6.', 16, 1);
    END
END

--testing for scd type 0
EXEC apply_scd_changes @scd_type = 0;
SELECT * FROM dim_customer;

--testing for scd type 1- overwritten data
EXEC apply_scd_changes @scd_type = 1;
SELECT * FROM dim_customer;

--Resetting and reinserting old data for further tests
TRUNCATE TABLE dim_customer;
INSERT INTO dim_customer (customer_id, name, address, previous_address, start_date, end_date, current_flag)
VALUES
(1, 'Alice', 'Pune', NULL, '2022-01-01', NULL, 'Y'),
(2, 'Bob', 'Delhi', NULL, '2022-01-01', NULL, 'Y'),
(3, 'Charlie', 'Mumbai', NULL, '2022-01-01', NULL, 'Y');

TRUNCATE TABLE stg_customer;
INSERT INTO stg_customer (customer_id, name, address)
VALUES
(1, 'Alice', 'Bangalore'),
(2, 'Bob', 'Delhi'),
(3, 'Charles', 'Hyderabad');

--testing for scd type 2 - historical tracking
EXEC apply_scd_changes @scd_type = 2;
SELECT * FROM dim_customer ORDER BY customer_id, start_date;

--testing for scd type 3 - previous value column
TRUNCATE TABLE dim_customer;
INSERT INTO dim_customer (customer_id, name, address, previous_address, start_date, end_date, current_flag)
VALUES
(1, 'Alice', 'Pune', NULL, '2022-01-01', NULL, 'Y'),
(2, 'Bob', 'Delhi', NULL, '2022-01-01', NULL, 'Y'),
(3, 'Charlie', 'Mumbai', NULL, '2022-01-01', NULL, 'Y');

TRUNCATE TABLE stg_customer;
INSERT INTO stg_customer (customer_id, name, address)
VALUES
(1, 'Alice', 'Bangalore'),
(2, 'Bob', 'Delhi'),
(3, 'Charlie', 'Hyderabad');

EXEC apply_scd_changes @scd_type = 3;
SELECT * FROM dim_customer;

--Testing for scd type 4 - archive and overwritting
TRUNCATE TABLE dim_customer;
INSERT INTO dim_customer (customer_id, name, address, previous_address, start_date, end_date, current_flag)
VALUES
(1, 'Alice', 'Pune', NULL, '2022-01-01', NULL, 'Y'),
(2, 'Bob', 'Delhi', NULL, '2022-01-01', NULL, 'Y'),
(3, 'Charlie', 'Mumbai', NULL, '2022-01-01', NULL, 'Y');

TRUNCATE TABLE customer_history;

TRUNCATE TABLE stg_customer;
INSERT INTO stg_customer (customer_id, name, address)
VALUES
(1, 'Alice', 'Bangalore'),
(2, 'Bob', 'Delhi'),
(3, 'Charles', 'Hyderabad');

EXEC apply_scd_changes @scd_type = 4;
SELECT * FROM dim_customer;
SELECT * FROM customer_history;

--Testing for scd type 6 - full hybrid
TRUNCATE TABLE dim_customer;
INSERT INTO dim_customer (customer_id, name, address, previous_address, start_date, end_date, current_flag)
VALUES
(1, 'Alice', 'Pune', NULL, '2022-01-01', NULL, 'Y'),
(2, 'Bob', 'Delhi', NULL, '2022-01-01', NULL, 'Y'),
(3, 'Charlie', 'Mumbai', NULL, '2022-01-01', NULL, 'Y');

TRUNCATE TABLE stg_customer;
INSERT INTO stg_customer (customer_id, name, address)
VALUES
(1, 'Alice', 'Bangalore'),
(2, 'Bob', 'Delhi'),
(3, 'Charles', 'Hyderabad');

EXEC apply_scd_changes @scd_type = 6;
SELECT * FROM dim_customer ORDER BY customer_id, start_date;
          