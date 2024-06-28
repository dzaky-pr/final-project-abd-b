DECLARE @OrderDetails dbo.SalesOrderDetailType;
INSERT INTO @OrderDetails (ProductID, OrderQty, UnitPrice, SpecialOfferID) VALUES (680, 2, 100.00, 1);

EXEC sales_transaction 
    @CustomerID = 1, 
    @BillToAddressID = 1, 
    @ShipToAddressID = 1, 
    @ShipMethodID = 1, 
    @SalesPersonID = 274, 
    @OrderDetails = @OrderDetails,
    @OnlineOrderFlag = 1;
