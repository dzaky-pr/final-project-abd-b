EXEC addNewVendor
    @Name = N'Australia Bike Retailer',
    @CreditRating = 4,
    @PreferredVendorStatus = 1,
    @ActiveFlag = 1,
    @PurchasingWebServiceURL = 'http://www.australiabikeretailer.com/ws';

EXEC addNewVendor
    @BusinessEntityID = 1492,
    @Name = N'Australia Bike Retailer Updated',
    @CreditRating = 5,
    @PreferredVendorStatus = 1,
    @ActiveFlag = 1,
    @PurchasingWebServiceURL = 'http://www.australiabikeretailer.com/ws/updated';
