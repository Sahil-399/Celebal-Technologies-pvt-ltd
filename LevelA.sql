USE AdventureWorks2022
GO

--1. List of all customers
SELECT * FROM Sales.Customer;

-- 2. List of all customers where company name ending in N
SELECT * FROM Production.Location WHERE Name LIKE '%N';

-- 3. List of all customers who live in Berlin or London
SELECT * FROM Person.Address WHERE City IN ('Berlin','London');

-- 4. List of all customers who live in UK or USA
SELECT * FROM Person.CountryRegion WHERE CountryRegionCode IN ('UK', 'US');

-- 5. List of all products sorted by product name
SELECT * FROM Production.Product ORDER BY Name;

-- 6. List of all products where product name starts with an A
SELECT * FROM Production.Product WHERE Name LIKE 'A%';

-- 7. List of customers who ever placed an order
SELECT DISTINCT Sales.SalesOrderDetail.* 
FROM Sales.SalesOrderDetail 
JOIN  Production.Product ON Sales.SalesOrderDetail.ProductID = Production.Product.ProductID;

-- 8. List of Customers who live in London and have bought chain
SELECT DISTINCT Customers.*
FROM Customers 
JOIN Orders ON Customers.CustomerID = Orders.CustomerID
JOIN OrderDetails ON Orders.OrderID = OrderDetails.OrderID
JOIN Products ON OrderDetails.ProductID = Products.ProductID
WHERE Customers.City = 'London' AND Products.ProductName = 'Chai';

-- 9. List of customers who never place an order
SELECT * FROM Person.Person 
WHERE BusinessEntityID NOT IN (SELECT DISTINCT BusinessEntityID FROM Sales.Store);

-- 10. List of customers who ordered Tofu
SELECT DISTINCT Customers.*
FROM Customers 
JOIN Orders ON Customers.CustomerID = Orders.CustomerID
JOIN OrderDetails ON Orders.OrderID = OrderDetails.OrderID
JOIN Products ON OrderDetails.ProductID = Products.ProductID
WHERE Products.ProductName = 'Tofu';

-- 11. Details of first order of the system
SELECT TOP 1 * FROM Sales.Store ORDER BY ModifiedDate ASC;

-- 12. Find the details of most expensive order date
SELECT TOP 1 Orders.*, SUM(OrderDetails.UnitPrice * OrderDetails.Quantity) AS OrderTotal
FROM Orders
JOIN OrderDetails ON Orders.OrderID = OrderDetails.OrderID
GROUP BY Orders.OrderID, Orders.OrderDate
ORDER BY OrderTotal DESC;

-- 13. For each order get the OrderID and Average quantity of items in that order
SELECT Sales.SalesOrderDetail.SalesOrderID, AVG(Sales.SalesOrderDetail.OrderQty) AS AverageQuantity
FROM Sales.SalesOrderDetail
GROUP BY Sales.SalesOrderDetail.SalesOrderID;

-- 14. For each order get the OrderID, minimum quantity and maximum quantity for that order
SELECT Sales.SalesOrderDetail.SalesOrderID, MIN(Sales.SalesOrderDetail.OrderQty) AS MinQuantity, MAX(Sales.SalesOrderDetail.OrderQty) AS MaxQuantity
FROM Sales.SalesOrderDetail
GROUP BY Sales.SalesOrderDetail.SalesOrderID;

-- 15. Get a list of all managers and total number of employees who report to them.
SELECT ManagerID, COUNT(EmployeeID) AS NumberOfEmployees
FROM Employees
GROUP BY ManagerID;

-- 16. Get the OrderID and the total quantity for each order that has a total quantity of greater than 300
SELECT Sales.SalesOrderDetail.SalesOrderID, SUM(Sales.SalesOrderDetail.OrderQty) AS TotalQuantity
FROM Sales.SalesOrderDetail
GROUP BY Sales.SalesOrderDetail.SalesOrderID
HAVING SUM(Sales.SalesOrderDetail.OrderQty) > 300;

-- 17. List of all orders placed on or after 1996/12/31
SELECT * FROM Sales.SalesOrderHeader WHERE OrderDate >= '1996-12-31';

-- 18. List of all orders shipped to Canada
SELECT * FROM Sales.SalesTerritory WHERE Name = 'Canada';

-- 19. List of all orders with order total > 200
SELECT Orders.*
FROM Orders
JOIN OrderDetails ON Orders.OrderID = OrderDetails.OrderID
GROUP BY Orders.OrderID
HAVING SUM(OrderDetails.UnitPrice * OrderDetails.Quantity) > 200;

-- 20. List of countries and sales made in each country
SELECT ShipCountry, SUM(OrderDetails.UnitPrice * OrderDetails.Quantity) AS TotalSales
FROM Orders
JOIN OrderDetails ON Orders.OrderID = OrderDetails.OrderID
GROUP BY ShipCountry;

-- 21. List of Customer ContactName and number of orders they placed
SELECT Customers.ContactName, COUNT(Orders.OrderID) AS NumberOfOrders
FROM Customers
JOIN Orders ON Customers.CustomerID = Orders.CustomerID
GROUP BY Customers.ContactName;

-- 22. List of customer contact names who have placed more than 3 orders
SELECT Customers.ContactName
FROM Customers
JOIN Orders ON Customers.CustomerID = Orders.CustomerID
GROUP BY Customers.ContactName
HAVING COUNT(Orders.OrderID) > 3;

-- 23. List of discontinued products which were ordered between 1/1/1997 and 1/1/1998
SELECT DISTINCT Products.*
FROM Products
JOIN OrderDetails ON Products.ProductID = OrderDetails.ProductID
JOIN Orders ON OrderDetails.OrderID = Orders.OrderID
WHERE Products.Discontinued = 1 AND Orders.OrderDate BETWEEN '1997-01-01' AND '1998-01-01';

-- 24. List of employee first name, last name, supervisor first name, last name
SELECT e1.FirstName AS EmployeeFirstName, e1.LastName AS EmployeeLastName, 
       e2.FirstName AS SupervisorFirstName, e2.LastName AS SupervisorLastName
FROM Employees e1
LEFT JOIN Employees e2 ON e1.ReportsTo = e2.EmployeeID;

-- 25. List of EmployeeID and total sales conducted by employee
SELECT Employees.EmployeeID, SUM(OrderDetails.UnitPrice * OrderDetails.Quantity) AS TotalSales
FROM Employees
JOIN Orders ON Employees.EmployeeID = Orders.EmployeeID
JOIN OrderDetails ON Orders.OrderID = OrderDetails.OrderID
GROUP BY Employees.EmployeeID;

-- 26. List of employees whose FirstName contains character a
SELECT * FROM Person.Person WHERE FirstName LIKE '%a%';

-- 27. List of managers who have more than four people reporting to them
SELECT ManagerID
FROM Employees
GROUP BY ManagerID
HAVING COUNT(EmployeeID) > 4;

-- 28. List of Orders and ProductNames
SELECT Orders.OrderID, Products.ProductName
FROM Orders
JOIN OrderDetails ON Orders.OrderID = OrderDetails.OrderID
JOIN Products ON OrderDetails.ProductID = Products.ProductID;

-- 29. List of orders placed by the best customer
SELECT Orders.*
FROM Orders
JOIN Customers ON Orders.CustomerID = Customers.CustomerID
WHERE Customers.CustomerID = (
    SELECT TOP 1 CustomerID
    FROM Orders
    GROUP BY CustomerID
    ORDER BY SUM(OrderDetails.UnitPrice * OrderDetails.Quantity) DESC
);

-- 30. List of orders placed by customers who do not have a Fax number
SELECT Orders.*
FROM Orders
JOIN Customers ON Orders.CustomerID = Customers.CustomerID
WHERE Customers.Fax IS NULL;

-- 31. List of Postal codes where the product Tofu was shipped
SELECT DISTINCT Orders.ShipPostalCode
FROM Orders
JOIN OrderDetails ON Orders.OrderID = OrderDetails.OrderID
JOIN Products ON OrderDetails.ProductID = Products.ProductID
WHERE Products.ProductName = 'Tofu';

-- 32. List of product names that were shipped to France
SELECT DISTINCT Products.ProductName
FROM Products
JOIN OrderDetails ON Products.ProductID = OrderDetails.ProductID
JOIN Orders ON OrderDetails.OrderID = Orders.OrderID
WHERE Orders.ShipCountry = 'France';

-- 33. List of ProductNames and Categories for the supplier 'Specialty Biscuits, Ltd.'
SELECT Products.ProductName, Categories.CategoryName
FROM Products
JOIN Suppliers ON Products.SupplierID = Suppliers.SupplierID
JOIN Categories ON Products.CategoryID = Categories.CategoryID
WHERE Suppliers.CompanyName = 'Specialty Biscuits, Ltd.';

-- 34. List of products that were never ordered
SELECT * FROM Production.Product
WHERE ProductID NOT IN (SELECT DISTINCT ProductID FROM Sales.SalesOrderDetail);

-- 35. List of products where units in stock is less than 10 and units on order are 0.
SELECT * FROM Products
WHERE UnitsInStock < 10 AND UnitsOnOrder = 0;

-- 36. List of top 10 countries by sales
SELECT TOP 10 ShipCountry, SUM(OrderDetails.UnitPrice * OrderDetails.Quantity) AS TotalSales
FROM Orders
JOIN OrderDetails ON Orders.OrderID = OrderDetails.OrderID
GROUP BY ShipCountry
ORDER BY TotalSales DESC;

-- 37. Number of orders each employee has taken for customers with CustomerIDs between A and AO
SELECT Employees.EmployeeID, COUNT(Orders.OrderID) AS NumberOfOrders
FROM Employees
JOIN Orders ON Employees.EmployeeID = Orders.EmployeeID
JOIN Customers ON Orders.CustomerID = Customers.CustomerID
WHERE Customers.CustomerID BETWEEN 'A' AND 'AO'
GROUP BY Employees.EmployeeID;

-- 38. Order date of most expensive order
SELECT TOP 1 Sales.SalesOrderHeader.OrderDate
FROM Sales.SalesOrderHeader
JOIN Sales.SalesOrderDetail ON Sales.SalesOrderHeader.SalesOrderID = Sales.SalesOrderDetail.SalesOrderID
GROUP BY Sales.SalesOrderHeader.OrderDate
ORDER BY SUM(Sales.SalesOrderDetail.UnitPrice * Sales.SalesOrderDetail.OrderQty) DESC;

-- 39. Product name and total revenue from that product
SELECT Production.Product.Name, SUM(Sales.SalesOrderDetail.UnitPrice *  Sales.SalesOrderDetail.OrderQty) AS TotalRevenue
FROM Production.Product
JOIN Sales.SalesOrderDetail ON Production.Product.ProductID = Sales.SalesOrderDetail.ProductID
GROUP BY Production.Product.Name;

-- 40. SupplierID and number of products offered
SELECT SupplierID, COUNT(ProductID) AS NumberOfProducts
FROM Products
GROUP BY SupplierID;

-- 41. Top ten customers based on their business
SELECT TOP 10 Customers.CustomerID, SUM(OrderDetails.UnitPrice * OrderDetails.Quantity) AS TotalSales
FROM Customers
JOIN Orders ON Customers.CustomerID = Orders.CustomerID
JOIN OrderDetails ON Orders.OrderID = OrderDetails.OrderID
GROUP BY Customers.CustomerID
ORDER BY TotalSales DESC;

-- 42. What is the total revenue of the company
SELECT SUM(Sales.SalesOrderDetail.UnitPrice *  Sales.SalesOrderDetail.OrderQty) AS TotalRevenue
FROM Sales.SalesOrderDetail;

