-- Deklarasikan variabel tabel untuk ItemDetails
DECLARE @ItemDetails dbo.PurchaseItemType;

-- Menambahkan contoh data ke dalam variabel tabel
INSERT INTO @ItemDetails (ProductID, OrderQty, UnitPrice)
VALUES 
    (1, 10, 47.87),  -- ProductID 1, OrderQty 10, UnitPrice 47.87
    (1, 5, 47.87);   -- ProductID 1, OrderQty 5, UnitPrice 47.87

-- Menjalankan prosedur tersimpan dengan parameter yang diperoleh
EXEC purchaseOrder
    @EmployeeID = 1,         -- EmployeeID yang diperoleh: 1
    @VendorID = 1492,        -- VendorID yang diperoleh: 1492
    @ShipMethodID = 5,       -- ShipMethodID yang diperoleh: 5
    @ItemDetails = @ItemDetails;
