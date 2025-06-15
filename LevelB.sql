USE AdventureWorks2022
GO

-- Creating Tables and Inserting Data
-- Creating the Products table
CREATE TABLE Products (
    ProductID INT PRIMARY KEY,
    Name NVARCHAR(50),
    UnitPrice DECIMAL(18, 2),
    UnitsInStock INT,
    ReorderLevel INT
);

-- Creating the Order Details table
CREATE TABLE [Order Details] (
    OrderDetailID INT PRIMARY KEY,
    OrderID INT,
    ProductID INT,
    UnitPrice DECIMAL(18, 2),
    Quantity INT,
    Discount DECIMAL(4, 2)
);

-- Creating Orders table
CREATE TABLE Orders (
    OrderID INT PRIMARY KEY,
    OrderDate DATETIME,
    CustomerID INT
);

-- Inserting sample data into Products table
INSERT INTO Products (ProductID, Name, UnitPrice, UnitsInStock, ReorderLevel)
VALUES
(1, 'Product A', 10.00, 100, 20),
(2, 'Product B', 20.00, 50, 10),
(3, 'Product C', 30.00, 30, 5),
(4, 'Product D', 40.00, 50, 6);

-- Inserting sample data into Order Details table
INSERT INTO [Order Details] (OrderID, ProductID, UnitPrice, Quantity, Discount)
VALUES
(1, 1, 10.00, 5, 0),
(1, 2, 20.00, 2, 0),
(2, 3, 30.00, 1, 0),
(2, 4, 60.00, 5, 0);

-- Inserting sample data into Order table
INSERT INTO Orders (OrderID, OrderDate, CustomerID) VALUES
(1, '2022-01-01', 101),
(2, '2022-01-02', 102),
(3, '2022-01-03', 103);

--Adding foreign key constraint to order details table for triggers
ALTER TABLE [Order Details] ADD FOREIGN KEY (OrderID) REFERENCES Orders(OrderID);
ALTER TABLE [Order Details] ADD FOREIGN KEY (ProductID) REFERENCES Products(ProductID);

-----------------------------------------------------'
-----------------------------------------------------
-----------------------------------------------------


-- STORED PROCEDURES
-- Creating the Stored Procedure 1
-- Ensuring previous procedure is dropped before creating a new one
IF OBJECT_ID('InsertOrderDetails', 'P') IS NOT NULL
    DROP PROCEDURE InsertOrderDetails;
GO
CREATE PROCEDURE InsertOrderDetails
    @OrderID INT,
    @ProductID INT,
    @UnitPrice DECIMAL(18, 2) = NULL,
    @Quantity INT,
    @Discount DECIMAL(4, 2) = 0
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CurrentUnitPrice DECIMAL(18, 2);
    DECLARE @UnitsInStock INT;
    DECLARE @ReorderLevel INT;

    -- Get the current UnitPrice from the Products table if not provided
    IF @UnitPrice IS NULL
    BEGIN
        SELECT @CurrentUnitPrice = UnitPrice
        FROM Products
        WHERE ProductID = @ProductID;

        IF @CurrentUnitPrice IS NULL
        BEGIN
            PRINT 'Invalid ProductID. No such product exists.';
            RETURN;
        END
    END
    ELSE
    BEGIN
        SET @CurrentUnitPrice = @UnitPrice;
    END

    -- Get the current stock and reorder level
    SELECT @UnitsInStock = UnitsInStock, @ReorderLevel = ReorderLevel
    FROM Products
    WHERE ProductID = @ProductID;

    IF @UnitsInStock IS NULL
    BEGIN
        PRINT 'Invalid ProductID. No such product exists.';
        RETURN;
    END

    -- Checking if there is enough stock
    IF @UnitsInStock < @Quantity
    BEGIN
        PRINT 'Not enough stock available to fulfill the order.';
        RETURN;
    END

    -- Inserting the order details
    INSERT INTO [Order Details] (OrderID, ProductID, UnitPrice, Quantity, Discount)
    VALUES (@OrderID, @ProductID, @CurrentUnitPrice, @Quantity, @Discount);

    -- Checking if the order was inserted successfully
    IF @@ROWCOUNT = 0
    BEGIN
        PRINT 'Failed to place the order. Please try again.';
        RETURN;
    END

    -- Updating the stock quantity
    UPDATE Products
    SET UnitsInStock = UnitsInStock - @Quantity
    WHERE ProductID = @ProductID;

    -- Checking if the stock quantity has dropped below the reorder level
    IF @UnitsInStock - @Quantity < @ReorderLevel
    BEGIN
        PRINT 'The quantity in stock of this product has dropped below its reorder level.';
    END
END;
GO


-----------------------------------------------------


-- Testing the Stored Procedure
-- Testing with sufficient stock
EXEC InsertOrderDetails @OrderID = 3, @ProductID = 1, @Quantity = 10;
SELECT * FROM [Order Details]

-- Testing with insufficient stock
EXEC InsertOrderDetails @OrderID = 3, @ProductID = 2, @Quantity = 60;

-- Test with default UnitPrice and Discount
EXEC InsertOrderDetails @OrderID = 3, @ProductID = 3, @Quantity = 5;
SELECT * FROM [Order Details]

-----------------------------------------------------
-----------------------------------------------------

--Creating Stored Procedure 2

-- Ensuring previous procedure is dropped before creating a new one
IF OBJECT_ID('UpdateOrderDetails', 'P') IS NOT NULL
    DROP PROCEDURE UpdateOrderDetails;
GO

CREATE PROCEDURE UpdateOrderDetails
    @OrderID INT,
    @ProductID INT,
    @UnitPrice DECIMAL(18, 2) = NULL,
    @Quantity INT = NULL,
    @Discount DECIMAL(4, 2) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OldQuantity INT;
    DECLARE @OldUnitPrice DECIMAL(18, 2);
    DECLARE @OldDiscount DECIMAL(4, 2);
    DECLARE @NewUnitPrice DECIMAL(18, 2);
    DECLARE @NewQuantity INT;
    DECLARE @NewDiscount DECIMAL(4, 2);

    -- Retrieving the existing order details
    SELECT @OldQuantity = Quantity, 
           @OldUnitPrice = UnitPrice, 
           @OldDiscount = Discount
    FROM [Order Details]
    WHERE OrderID = @OrderID AND ProductID = @ProductID;

    -- Ensuring the order detail exists
    IF @OldQuantity IS NULL
    BEGIN
        PRINT 'Invalid OrderID or ProductID. No such order detail exists.';
        RETURN;
    END

    -- Set new values, retaining old ones if NULL is provided
    SET @NewUnitPrice = ISNULL(@UnitPrice, @OldUnitPrice);
    SET @NewQuantity = ISNULL(@Quantity, @OldQuantity);
    SET @NewDiscount = ISNULL(@Discount, @OldDiscount);

    -- Updating the order details
    UPDATE [Order Details]
    SET UnitPrice = @NewUnitPrice,
        Quantity = @NewQuantity,
        Discount = @NewDiscount
    WHERE OrderID = @OrderID AND ProductID = @ProductID;

    -- Adjusting the UnitsInStock in the Products table
    DECLARE @StockAdjustment INT;
    SET @StockAdjustment = @OldQuantity - @NewQuantity;

    UPDATE Products
    SET UnitsInStock = UnitsInStock + @StockAdjustment
    WHERE ProductID = @ProductID;

    PRINT 'Order details updated successfully.';
END;
GO


------------------------------------------------------


-- Testing the Stored Procedure
-- Testing updating only Quantity
EXEC UpdateOrderDetails @OrderID = 1, @ProductID = 1, @Quantity = 10;
SELECT Quantity FROM [Order Details];

-- Testing updating UnitPrice and Discount while keeping original Quantity
EXEC UpdateOrderDetails @OrderID = 1, @ProductID = 1, @UnitPrice = 15.00, @Discount = 0.05;
SELECT * FROM [Order Details];

-- Testing updating all parameters
EXEC UpdateOrderDetails @OrderID = 1, @ProductID = 1, @UnitPrice = 12.00, @Quantity = 8, @Discount = 0.1;
SELECT * FROM [Order Details];

-- Testing updating with no changes
EXEC UpdateOrderDetails @OrderID = 1, @ProductID = 1;
SELECT * FROM [Order Details];

-----------------------------------------------------
-----------------------------------------------------

--Creating Stored Procedure 3
-- Creating the GetOrderDetails Stored Procedure
-- Ensuring previous procedure is dropped before creating a new one
IF OBJECT_ID('GetOrderDetails', 'P') IS NOT NULL
    DROP PROCEDURE GetOrderDetails;
GO

CREATE PROCEDURE GetOrderDetails
    @OrderID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Checking if there are any records for the given OrderID
    IF NOT EXISTS (SELECT 1 FROM Sales.SalesOrderDetail WHERE SalesOrderID = @OrderID)
    BEGIN
        PRINT 'The OrderID ' + CAST(@OrderID AS VARCHAR(10)) + ' does not exist.';
        RETURN 1;
    END

    -- Returning the order details for the given OrderID
    SELECT SalesOrderID AS OrderID,
           ProductID,
           UnitPrice,
           OrderQty AS Quantity,
           UnitPriceDiscount AS Discount
    FROM Sales.SalesOrderDetail
    WHERE SalesOrderID = @OrderID;
END;
GO


---------------------------------------------------


-- Testing the Stored Procedure
-- Testing with an existing OrderID
EXEC GetOrderDetails @OrderID = 43659;
SELECT * FROM Sales.SalesOrderDetail;

-- Testing with a non-existing OrderID
EXEC GetOrderDetails @OrderID = 99;

----------------------------------------------------
----------------------------------------------------

--Creating Stored Procedure 4
--Creating the DeleteOrderDetails Stored Procedure
IF OBJECT_ID('DeleteOrderDetails', 'P') IS NOT NULL
DROP PROCEDURE DeleteOrderDetails;
GO

CREATE PROCEDURE DeleteOrderDetails
    @SalesOrderID INT,
    @ProductID INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Checking if the OrderID exists in the table
    IF NOT EXISTS (SELECT 1 FROM [Order Details] WHERE OrderID = @SalesOrderID)
    BEGIN
        PRINT 'Error: OrderID does not exist.';
        RETURN -1;
    END

    -- Checking if the ProductID exists for the given OrderID
    IF NOT EXISTS (SELECT 1 FROM [Order Details] WHERE OrderID  = @SalesOrderID AND ProductID = @ProductID)
    BEGIN
        PRINT 'Error: ProductID does not exist for the given OrderID.';
        RETURN -1;
    END

    -- Deleting the record if both SalesOrderID and ProductID are valid
    DELETE FROM [Order Details]
    WHERE OrderID = @SalesOrderID AND ProductID = @ProductID;

    PRINT 'Order details deleted successfully.';
    RETURN 0;
END;
GO


---------------------------------------------------


-- Step 3: Testing the Stored Procedure
EXEC DeleteOrderDetails @SalesOrderID = 1, @ProductID = 1;
SELECT * FROM [Order Details];

---------------------------------------------------
---------------------------------------------------
---------------------------------------------------

-- FUNCTIONS
-- Creating Function 1
-- Ensuring previous function is dropped before creating a new one
IF OBJECT_ID('dbo.FormatDate','FN') IS NOT NULL
    DROP FUNCTION dbo.FormatDate;
GO

CREATE FUNCTION dbo.FormatDate(@InputDate DATETIME)
RETURNS VARCHAR(10)
AS
BEGIN
    DECLARE @FormattedDate VARCHAR(10);
    SET @FormattedDate=CONVERT(VARCHAR(10), @InputDate, 101);
    RETURN @FormattedDate;
END;
GO

-- Testing the Function
-- Testing the FormatDate function with a sample datetime
SELECT dbo.FormatDate('2006-11-21 23:34:05.920') AS FormattedDate;

---------------------------------------------------
---------------------------------------------------

-- Creating Function 2
-- Ensuring previous function is dropped before creating a new one
IF OBJECT_ID('dbo.FormatDateYMD','FN') IS NOT NULL
    DROP FUNCTION dbo.FormatDateYMD;
GO

CREATE FUNCTION dbo.FormatDateYMD(@InputDate DATETIME)
RETURNS VARCHAR(8)
AS
BEGIN
    DECLARE @FormattedDate VARCHAR(8);
    SET @FormattedDate=CONVERT(VARCHAR(8), @InputDate, 112);
    RETURN @FormattedDate;
END;
GO

-- Testing the Function
-- Testing the FormatDate function with a sample datetime
SELECT dbo.FormatDateYMD('2006-11-21 23:34:05.920') AS FormattedDate;

---------------------------------------------------
---------------------------------------------------
---------------------------------------------------

-- VIEWS
-- Creating the View vwCustomerOrders
-- Ensuring the view does not already exist before creating it
IF OBJECT_ID('Sales.vwCustomerOrders','V') IS NOT NULL
    DROP VIEW Sales.vwCustomerOrders;
GO

CREATE VIEW Sales.vwCustomerOrders AS
SELECT
    soh.AccountNumber AS CompanyName,
    soh.SalesOrderID AS OrderID,
    soh.OrderDate, p.ProductID, 
    p.Name AS ProductName,
    sod.OrderQty AS Quantity,
    sod.UnitPrice,
    sod.OrderQty * sod.UnitPrice As Total
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID=sod.SalesOrderID
JOIN Production.Product p ON sod.ProductID=p.ProductID
JOIN Sales.Customer c ON soh.CustomerID=c.CustomerID;
GO

SELECT * FROM Sales.vwCustomerOrders;
-------------------------------------------------
-------------------------------------------------

-- Creating the View vwCustomerOrdersYesterday
-- Ensuring the view does not already exist before creating it
IF OBJECT_ID('Sales.vwCustomerOrdersYesterday', 'V') IS NOT NULL
    DROP VIEW Sales.vwCustomerOrdersYesterday;
GO

CREATE VIEW Sales.vwCustomerOrdersYesterday AS
SELECT 
    c.AccountNumber AS CompanyName, -- Placeholder for actual company name field
    soh.SalesOrderID AS OrderID,
    soh.OrderDate,
    sod.ProductID,
    p.Name AS ProductName,
    sod.OrderQty AS Quantity,
    sod.UnitPrice,
    sod.OrderQty * sod.UnitPrice AS TotalPrice
FROM 
    Sales.SalesOrderHeader soh
JOIN 
    Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN 
    Production.Product p ON sod.ProductID = p.ProductID
JOIN 
    Sales.Customer c ON soh.CustomerID = c.CustomerID
WHERE 
    soh.OrderDate = CAST(GETDATE() - 1 AS DATE);
GO

SELECT * FROM Sales.vwCustomerOrdersYesterday;
--------------------------------------------------------
--------------------------------------------------------


-- Creating the View MyProducts
-- Ensuring the view does not already exist before creating it
IF OBJECT_ID('Production.MyProducts', 'V') IS NOT NULL
    DROP VIEW Production.MyProducts;
GO

CREATE VIEW Production.MyProducts AS
SELECT 
    p.ProductID,
    p.Name AS ProductName,
    p.Size AS QuantityPerUnit, 
    p.ListPrice AS UnitPrice, 
    v.Name AS CompanyName,  
    c.Name AS CategoryName
FROM 
    Production.Product p
JOIN 
    Purchasing.ProductVendor pv ON p.ProductID = pv.ProductID
JOIN 
    Purchasing.Vendor v ON pv.BusinessEntityID = v.BusinessEntityID
JOIN 
    Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN 
    Production.ProductCategory c ON ps.ProductCategoryID = c.ProductCategoryID
WHERE 
    p.DiscontinuedDate IS NULL;
GO

SELECT * FROM Production.MyProducts;
GO
---------------------------------------------------
---------------------------------------------------
---------------------------------------------------

--TRIGGERS
--Creating trigger 1 for Instead of Delete Trigger


CREATE TRIGGER insteadOfDeleteOrder
ON Orders
INSTEAD OF DELETE
AS 
BEGIN
    SET NOCOUNT ON;

     -- Deleting corresponding records from Order Details
    DELETE FROM [Order Details]
    WHERE OrderID IN (SELECT OrderID FROM DELETED);

    -- Deleting the order from Orders table
    DELETE FROM Orders
    WHERE OrderID IN(SELECT OrderID FROM DELETED);

    PRINT 'Order and its details deleted successfully.';
END;;
GO

--Testing the INSTEAD OF DELETE trigger by attempting to delete an order
DELETE FROM Orders WHERE OrderID=2;
SELECT * FROM [Order Details];
SELECT * FROM Orders;
GO

---------------------------------------------------
---------------------------------------------------

--Creating trigger 2 for INSTEAD OF INSERT trigger on the OrderDetails table

CREATE TRIGGER trgCheckStockBeforeInsert
ON [Order Details]
INSTEAD OF INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ProductID INT, @Quantity INT, @UnitsInStock INT;

    -- Looping through each row in the inserted pseudo table
    DECLARE order_cursor CURSOR FOR
    SELECT ProductID, Quantity
    FROM inserted;

    OPEN order_cursor;

    FETCH NEXT FROM order_cursor INTO @ProductID, @Quantity;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Checking the stock
        SELECT @UnitsInStock = UnitsInStock
        FROM Products
        WHERE ProductID = @ProductID;

        -- If sufficient stock exists
        IF @UnitsInStock >= @Quantity
        BEGIN
            -- Inserting the order detail
            INSERT INTO [Order Details] (OrderDetailID, OrderID, ProductID, Quantity)
            SELECT OrderDetailID, OrderID, ProductID, Quantity
            FROM inserted;

            -- Decrementing the stock
            UPDATE Products
            SET UnitsInStock = UnitsInStock - @Quantity
            WHERE ProductID = @ProductID;
        END
        ELSE
        BEGIN
            -- Notifying the user that the order could not be filled
            RAISERROR ('Order could not be filled because of insufficient stock for ProductID %d.', 16, 1, @ProductID);
        END

        FETCH NEXT FROM order_cursor INTO @ProductID, @Quantity;
    END

    CLOSE order_cursor;
    DEALLOCATE order_cursor;
END;
GO


----------------------------------------------------------------


--  Testing the Trigger
-- Attempting to insert an order detail with sufficient stock
INSERT INTO [Order Details] (OrderDetailID, OrderID, ProductID, Quantity)
VALUES (5, 5, 100, 10); -- This should succeed

-- Attempting to insert an order detail with insufficient stock
INSERT INTO [Order Details] (OrderDetailID, OrderID, ProductID, Quantity)
VALUES (6, 6, 102, 10); -- This should fail and raise an error

-- Checking the results
SELECT * FROM [Order Details];
SELECT * FROM Products;