CREATE TYPE dbo.PurchaseItemType AS TABLE(
    ProductID INT,
    OrderQty SMALLINT,
    UnitPrice MONEY
);

-- Calculate Purchase Sub Total Function
CREATE OR ALTER FUNCTION dbo.CalculatePurchaseSubTotal (@PurchaseOrderID INT)
RETURNS MONEY
AS
BEGIN
    DECLARE @SubTotal MONEY;
    
    SELECT @SubTotal = SUM(OrderQty * UnitPrice)
    FROM Purchasing.PurchaseOrderDetail
    WHERE PurchaseOrderID = @PurchaseOrderID;
    
    RETURN @SubTotal;
END;
GO

-- Calculate Tax Function
CREATE OR ALTER FUNCTION dbo.CalculateTax (@SubTotal MONEY)
RETURNS MONEY
AS
BEGIN
    DECLARE @TaxRate DECIMAL(5, 2) = 0.1;  -- Asumsi tarif pajak 10%
    RETURN @SubTotal * @TaxRate;
END;
GO


CREATE OR ALTER PROCEDURE purchaseOrder
    @EmployeeID INT,
    @VendorID INT,
    @ShipMethodID INT,
    @ItemDetails dbo.PurchaseItemType READONLY
AS
BEGIN
    BEGIN TRANSACTION
    BEGIN TRY
        -- Insert ke PurchaseOrderHeader
        DECLARE @OrderDate DATETIME = GETDATE();
        DECLARE @ShipDate DATETIME = DATEADD(DAY, 14, @OrderDate);
        
        INSERT INTO Purchasing.PurchaseOrderHeader
            (RevisionNumber, Status, EmployeeID, VendorID, ShipMethodID, OrderDate, ShipDate, SubTotal, TaxAmt, Freight)
        VALUES
            (0, 1, @EmployeeID, @VendorID, @ShipMethodID, @OrderDate, @ShipDate, 0, 0, 0);
        
        DECLARE @PurchaseOrderID INT = SCOPE_IDENTITY();

        -- Insert ke PurchaseOrderDetail menggunakan table type yang diberikan
        INSERT INTO Purchasing.PurchaseOrderDetail
            (PurchaseOrderID, ProductID, DueDate, OrderQty, UnitPrice, ReceivedQty, RejectedQty)
        SELECT @PurchaseOrderID, ProductID, DATEADD(DAY, 7, @OrderDate), OrderQty, UnitPrice, OrderQty, 0
        FROM @ItemDetails;
        
        -- Menggunakan fungsi untuk menghitung SubTotal, Tax, dan Freight
        DECLARE @SubTotal MONEY = dbo.CalculatePurchaseSubTotal(@PurchaseOrderID);
        DECLARE @TaxAmt MONEY = dbo.CalculateTax(@SubTotal);
        DECLARE @Freight MONEY = (SELECT ShipRate FROM Purchasing.ShipMethod WHERE ShipMethodID = @ShipMethodID);

        -- Update nilai SubTotal, TaxAmt, dan Freight di PurchaseOrderHeader
        UPDATE Purchasing.PurchaseOrderHeader
        SET SubTotal = @SubTotal, TaxAmt = @TaxAmt, Freight = @Freight
        WHERE PurchaseOrderID = @PurchaseOrderID;

        -- Update Product Inventory
        UPDATE Production.ProductInventory
        SET Quantity = Quantity + d.OrderQty
        FROM Production.ProductInventory i
        JOIN @ItemDetails d ON i.ProductID = d.ProductID
        WHERE i.ProductID = d.ProductID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER TRIGGER trgReorderOnLowStock
ON Production.ProductInventory
AFTER UPDATE
AS
BEGIN
    BEGIN TRY
        DECLARE @ProductID INT;
        DECLARE @CurrentStock INT;
        DECLARE @ReorderPoint INT;

        -- Check the updated inventory
        SELECT @ProductID = ProductID, @CurrentStock = Quantity
        FROM inserted;
        
        -- Get the reorder point for the product
        SELECT @ReorderPoint = ReorderPoint
        FROM Production.Product
        WHERE ProductID = @ProductID;
        
        -- If current stock is below reorder point, create a purchase order
        IF @CurrentStock < @ReorderPoint
        BEGIN
            DECLARE @EmployeeID INT = (SELECT TOP 1 BusinessEntityID FROM HumanResources.Employee ORDER BY NEWID());
            DECLARE @VendorID INT = (SELECT TOP 1 BusinessEntityID FROM Purchasing.ProductVendor WHERE ProductID = @ProductID ORDER BY NEWID());
            DECLARE @ShipMethodID INT = (SELECT TOP 1 ShipMethodID FROM Purchasing.ShipMethod ORDER BY NEWID());
            DECLARE @UnitPrice MONEY = (SELECT StandardPrice FROM Purchasing.ProductVendor WHERE BusinessEntityID = @VendorID AND ProductID = @ProductID);
            
            DECLARE @ItemDetails dbo.PurchaseItemType;
            INSERT INTO @ItemDetails (ProductID, OrderQty, UnitPrice)
            VALUES (@ProductID, @ReorderPoint - @CurrentStock, @UnitPrice);
            
            EXEC purchaseOrder @EmployeeID, @VendorID, @ShipMethodID, @ItemDetails;
        END
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO
