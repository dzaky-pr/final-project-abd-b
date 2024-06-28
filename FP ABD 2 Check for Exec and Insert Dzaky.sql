-- Mendapatkan sample ProductID dan UnitPrice dari tabel ProductVendor
SELECT TOP 10 pv.ProductID, p.Name, pv.StandardPrice AS UnitPrice
FROM Purchasing.ProductVendor pv
JOIN Production.Product p ON pv.ProductID = p.ProductID;

-- Contoh OrderQty, misalnya kita ambil nilai konstan untuk order quantity
DECLARE @OrderQty INT = 10;

-- Mendapatkan sample EmployeeID dari tabel Employee
SELECT TOP 10 BusinessEntityID AS EmployeeID, JobTitle
FROM HumanResources.Employee;

-- Mendapatkan sample VendorID dari tabel Vendor
SELECT TOP 10 BusinessEntityID AS VendorID, Name
FROM Purchasing.Vendor;

-- Mendapatkan sample ShipMethodID dari tabel ShipMethod
SELECT TOP 10 ShipMethodID, Name
FROM Purchasing.ShipMethod;
