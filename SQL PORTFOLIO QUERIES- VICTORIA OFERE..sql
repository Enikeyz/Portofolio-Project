--JOINS.

--1). Retrieve all sales order details alongside the Customer's first and last name. 
SELECT 
    C.FirstName, C.LastName, SOH.SalesOrderID, SOH.OrderDate
FROM 
    Sales.SalesOrderHeader SOH
INNER JOIN 
    Person.Person C ON SOH.CustomerID = C.BusinessEntityID;

--2) Find the top 5 products with the highest average order quantity.
SELECT 
    P.ProductID, 
    P.Name AS ProductName, 
    AVG(SOD.OrderQty) AS AverageOrderQuantity
FROM 
    Sales.SalesOrderDetail SOD
JOIN 
    Production.Product P ON SOD.ProductID = P.ProductID
GROUP BY 
    P.ProductID, P.Name
ORDER BY 
    AverageOrderQuantity DESC;

--3) Retrieve all employees and their associated department names.
SELECT 
    E.BusinessEntityID, E.JobTitle, D.Name AS DepartmentName
FROM 
    HumanResources.Employee E
LEFT JOIN 
    HumanResources.EmployeeDepartmentHistory EDH ON E.BusinessEntityID = EDH.BusinessEntityID
LEFT JOIN 
    HumanResources.Department D ON EDH.DepartmentID = D.DepartmentID;

--4) Get the list of customers who have placed orders with a total value exceeding $10,000.
SELECT 
    C.CustomerID, 
    P.FirstName, 
    P.LastName, 
    SUM(SOD.LineTotal) AS TotalOrderValue
FROM 
    Sales.Customer C
JOIN 
    Sales.SalesOrderHeader SOH ON C.CustomerID = SOH.CustomerID
JOIN 
    Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
JOIN 
    Person.Person P ON C.PersonID = P.BusinessEntityID
GROUP BY 
    C.CustomerID, P.FirstName, P.LastName
HAVING 
    SUM(SOD.LineTotal) > 10000
ORDER BY 
    TotalOrderValue DESC;

--5) List the products that are subcomponents of other products.
SELECT 
    P1.ProductID AS SubcomponentProductID, 
    P1.Name AS SubcomponentProductName, 
    P2.ProductID AS ParentProductID, 
    P2.Name AS ParentProductName
FROM 
    Production.BillOfMaterials BOM
JOIN 
    Production.Product P1 ON BOM.ComponentID = P1.ProductID
JOIN 
    Production.Product P2 ON BOM.ProductAssemblyID = P2.ProductID
WHERE 
    BOM.ProductAssemblyID IS NOT NULL
ORDER BY 
    P1.Name;

--SUBQUERIES.
--6) Retrieve top 5 highest selling products.
SELECT 
    P.Name, P.ProductID, 
    (SELECT SUM(SOD.LineTotal) 
     FROM Sales.SalesOrderDetail SOD 
     WHERE SOD.ProductID = P.ProductID) AS TotalSales
FROM 
    Production.Product P
ORDER BY 
    TotalSales DESC;

--7) List employees who have placed at least one sales order.
SELECT 
    E.BusinessEntityID, E.JobTitle
FROM 
    HumanResources.Employee E
WHERE 
    EXISTS (
        SELECT 1 
        FROM Sales.SalesOrderHeader SOH 
        WHERE SOH.SalesPersonID = E.BusinessEntityID
    );

--8) List the orders with a total value greater than the average order value.
WITH OrderTotals AS (
    SELECT 
        SOH.SalesOrderID, 
        SUM(SOD.LineTotal) AS TotalOrderValue
    FROM 
        Sales.SalesOrderHeader SOH
    JOIN 
        Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
    GROUP BY 
        SOH.SalesOrderID
),
AverageOrderValue AS (
    SELECT 
        AVG(TotalOrderValue) AS AvgOrderValue
    FROM 
        OrderTotals
)
SELECT 
    OT.SalesOrderID, 
    OT.TotalOrderValue
FROM 
    OrderTotals OT, AverageOrderValue AOV
WHERE 
    OT.TotalOrderValue > AOV.AvgOrderValue
ORDER BY 
    OT.TotalOrderValue DESC;

--9) Find the top 3 customers with the highest total order value.
SELECT 
    C.CustomerID, 
    P.FirstName, 
    P.LastName, 
    SUM(SOD.LineTotal) AS TotalOrderValue
FROM 
    Sales.Customer C
JOIN 
    Sales.SalesOrderHeader SOH ON C.CustomerID = SOH.CustomerID
JOIN 
    Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
JOIN 
    Person.Person P ON C.PersonID = P.BusinessEntityID
GROUP BY 
    C.CustomerID, P.FirstName, P.LastName
ORDER BY 
    TotalOrderValue DESC;

--COMMON TABLE EXPRESSION (CTE).

--10)  Rank customers by the number of orders they’ve placed.
WITH CustomerOrderCount AS (
    SELECT 
        SOH.CustomerID, COUNT(SOH.SalesOrderID) AS OrderCount
    FROM 
        Sales.SalesOrderHeader SOH
    GROUP BY 
        SOH.CustomerID
)
SELECT 
    C.FirstName, C.LastName, CO.OrderCount,
    RANK() OVER (ORDER BY CO.OrderCount DESC) AS CustomerRank
FROM 
    CustomerOrderCount CO
JOIN 
    Person.Person C ON CO.CustomerID = C.BusinessEntityID;

--11) Find sales employees with their total sales
WITH SalesEmployees AS (
    SELECT 
        E.BusinessEntityID, E.JobTitle
    FROM 
        HumanResources.Employee E
    WHERE 
        E.JobTitle LIKE '%Sales%'
), EmployeeSales AS (
    SELECT 
        SOH.SalesPersonID, SUM(SOD.LineTotal) AS TotalSales
    FROM 
        Sales.SalesOrderHeader SOH
    JOIN 
        Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
    GROUP BY 
        SOH.SalesPersonID
)
SELECT 
    SE.BusinessEntityID, SE.JobTitle, ES.TotalSales
FROM 
    SalesEmployees SE
LEFT JOIN 
    EmployeeSales ES ON SE.BusinessEntityID = ES.SalesPersonID;

--12) list all products that are not associated with any orders.
SELECT 
    P.ProductID, 
    P.Name AS ProductName
FROM 
    Production.Product P
LEFT JOIN 
    Sales.SalesOrderDetail SOD ON P.ProductID = SOD.ProductID
WHERE 
    SOD.ProductID IS NULL
ORDER BY 
    P.Name;

--13) Rank customers by the number of orders they’ve placed.
WITH CustomerOrderCount AS (
    SELECT 
        SOH.CustomerID, COUNT(SOH.SalesOrderID) AS OrderCount
    FROM 
        Sales.SalesOrderHeader SOH
    GROUP BY 
        SOH.CustomerID
)
SELECT 
    C.FirstName, C.LastName, CO.OrderCount,
    RANK() OVER (ORDER BY CO.OrderCount DESC) AS CustomerRank
FROM 
    CustomerOrderCount CO
JOIN 
    Person.Person C ON CO.CustomerID = C.BusinessEntityID;

--14) Get the list of employees who have sold products with a total value exceeding $50,000 in the 'Clothing' category.
WITH ClothingProducts AS (
    SELECT 
        P.ProductID
    FROM 
        Production.Product P
    JOIN 
        Production.ProductSubcategory PSC ON P.ProductSubcategoryID = PSC.ProductSubcategoryID
    JOIN 
        Production.ProductCategory PC ON PSC.ProductCategoryID = PC.ProductCategoryID
    WHERE 
        PC.Name = 'Clothing'
),
EmployeeSales AS (
    SELECT 
        SOH.SalesPersonID, 
        SUM(SOD.LineTotal) AS TotalSalesValue
    FROM 
        Sales.SalesOrderHeader SOH
    JOIN 
        Sales.SalesOrderDetail SOD ON SOH.SalesOrderID = SOD.SalesOrderID
    JOIN 
        ClothingProducts CP ON SOD.ProductID = CP.ProductID
    WHERE 
        SOH.SalesPersonID IS NOT NULL
    GROUP BY 
        SOH.SalesPersonID
)
SELECT 
    E.BusinessEntityID AS EmployeeID, 
    P.FirstName, 
    P.LastName, 
    ES.TotalSalesValue
FROM 
    EmployeeSales ES
JOIN 
    HumanResources.Employee E ON ES.SalesPersonID = E.BusinessEntityID
JOIN 
    Person.Person P ON E.BusinessEntityID = P.BusinessEntityID
WHERE 
    ES.TotalSalesValue > 50000
ORDER BY 
    ES.TotalSalesValue DESC;

--15) Retrieve employees with their department names.
WITH EmployeeDepartments AS (
    SELECT 
        E.BusinessEntityID, E.JobTitle, D.Name AS DepartmentName
    FROM 
        HumanResources.Employee E
    JOIN 
        HumanResources.EmployeeDepartmentHistory EDH ON E.BusinessEntityID = EDH.BusinessEntityID
    JOIN 
        HumanResources.Department D ON EDH.DepartmentID = D.DepartmentID
)
SELECT 
    * 
FROM 
    EmployeeDepartments;










