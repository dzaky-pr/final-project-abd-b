-- Membuat tipe data untuk menyimpan detail order
CREATE TYPE dbo.SalesOrderDetailType AS TABLE
(
    ProductID INT,
    OrderQty INT,
    UnitPrice MONEY,
    SpecialOfferID INT,
    UnitPriceDisc MONEY DEFAULT 0
);
GO

-- Membuat fungsi CalculateSubTotal
CREATE OR ALTER FUNCTION dbo.CalculateSubTotal (@SalesOrderID INT)
RETURNS MONEY
AS
BEGIN
    DECLARE @SubTotal MONEY;
    SELECT @SubTotal = SUM(OrderQty * UnitPrice)
    FROM Sales.SalesOrderDetail
    WHERE SalesOrderID = @SalesOrderID;
    RETURN @SubTotal;
END;
GO

-- Membuat fungsi CalculateTax
CREATE OR ALTER FUNCTION dbo.CalculateTax (@SubTotal MONEY)
RETURNS MONEY
AS
BEGIN
    RETURN @SubTotal * 0.08; -- Anggap pajak adalah 8%
END;
GO

-- Membuat fungsi CalculateFreight
CREATE OR ALTER FUNCTION dbo.CalculateFreight (@SubTotal MONEY)
RETURNS MONEY
AS
BEGIN
    RETURN @SubTotal * 0.05; -- Anggap biaya kirim adalah 5%
END;
GO


-- Membuat prosedur untuk memasukkan detail order
CREATE OR ALTER PROCEDURE insertOrderDetails
    @OrderDetails dbo.SalesOrderDetailType READONLY,
    @SalesOrderID INT
AS
BEGIN TRANSACTION;
BEGIN TRY
    INSERT INTO Sales.SalesOrderDetail (
        SalesOrderID,
        ProductID,
        OrderQty,
        UnitPrice,
        SpecialOfferID,
        UnitPriceDiscount,
        rowguid,
        ModifiedDate
    )
    SELECT @SalesOrderID, ProductID, OrderQty, UnitPrice, SpecialOfferID, UnitPriceDisc, NEWID(), GETDATE()
    FROM @OrderDetails;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

CREATE OR ALTER PROCEDURE sales_transaction
    @CustomerID INT,
    @BillToAddressID INT,
    @ShipToAddressID INT,
    @ShipMethodID INT,
    @SalesPersonID INT,
    @OrderDetails dbo.SalesOrderDetailType READONLY,
    @OnlineOrderFlag BIT
AS
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @SalesOrderID INT;
    DECLARE @OrderDate DATETIME = GETDATE();
    DECLARE @DueDate DATETIME = DATEADD(MONTH, 1, GETDATE());
    DECLARE @ShipDate DATETIME = DATEADD(DAY, 4, GETDATE());

    -- Insert ke SalesOrderHeader
    INSERT INTO Sales.SalesOrderHeader (
        OrderDate,
        DueDate,
        ShipDate,
        OnlineOrderFlag,
        CustomerID,
        BillToAddressID,
        ShipToAddressID,
        ShipMethodID,
        SubTotal,
        TaxAmt,
        Freight,
        SalesPersonID,
        TerritoryID,
        RevisionNumber
    )
    VALUES (
        @OrderDate, @DueDate, @ShipDate, @OnlineOrderFlag, @CustomerID,
        @BillToAddressID, @ShipToAddressID, @ShipMethodID, 0, 0, 0, @SalesPersonID,
        (SELECT TerritoryID FROM Sales.Customer WHERE CustomerID = @CustomerID), 0
    );

    SET @SalesOrderID = SCOPE_IDENTITY();

    -- Insert detail pesanan menggunakan prosedur terpisah
    EXEC insertOrderDetails @OrderDetails, @SalesOrderID;

    -- Menggunakan fungsi untuk menghitung SubTotal, Tax, dan Freight
    DECLARE @SubTotal MONEY = dbo.CalculateSubTotal(@SalesOrderID);
    DECLARE @TaxAmt MONEY = dbo.CalculateTax(@SubTotal);
    DECLARE @Freight MONEY = dbo.CalculateFreight(@SubTotal);

    -- Update nilai SubTotal, TaxAmt, dan Freight di SalesOrderHeader
    UPDATE Sales.SalesOrderHeader
    SET SubTotal = @SubTotal, TaxAmt = @TaxAmt, Freight = @Freight
    WHERE SalesOrderID = @SalesOrderID;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
