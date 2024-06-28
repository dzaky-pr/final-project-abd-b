-- Index pada SalesOrderHeader untuk query yang sering melibatkan CustomerID dan OrderDate
CREATE INDEX IX_SalesOrderHeader_CustomerID_OrderDate
ON Sales.SalesOrderHeader (CustomerID, OrderDate);
GO

-- Index pada SalesOrderDetail untuk SalesOrderID
CREATE INDEX IX_SalesOrderDetail_SalesOrderID
ON Sales.SalesOrderDetail (SalesOrderID);
GO

-- Index pada ProductInventory untuk ProductID guna memperbaiki operasi update stok
CREATE INDEX IX_ProductInventory_ProductID
ON Production.ProductInventory (ProductID);
GO

-- Index pada PurchaseOrderDetail untuk PurchaseOrderID
CREATE INDEX IX_PurchaseOrderDetail_PurchaseOrderID
ON Purchasing.PurchaseOrderDetail (PurchaseOrderID);
GO
