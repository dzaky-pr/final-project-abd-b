-- Melihat data di SalesOrderHeader yang terbaru untuk CustomerID tertentu
SELECT *
FROM Sales.SalesOrderHeader
WHERE CustomerID = 1
ORDER BY OrderDate DESC;

-- Mendapatkan SalesOrderID terbaru untuk CustomerID tertentu
DECLARE @LatestSalesOrderID INT;
SELECT @LatestSalesOrderID = SalesOrderID
FROM Sales.SalesOrderHeader
WHERE CustomerID = 1
ORDER BY OrderDate DESC;

-- Melihat data di SalesOrderDetail untuk SalesOrderID yang terbaru
SELECT *
FROM Sales.SalesOrderDetail
WHERE SalesOrderID = @LatestSalesOrderID;
