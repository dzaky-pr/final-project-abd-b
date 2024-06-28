CREATE OR ALTER PROCEDURE addNewVendor
    @BusinessEntityID INT = NULL,
    @Name AS NVARCHAR(50),
    @CreditRating AS TINYINT,
    @PreferredVendorStatus AS TINYINT = 1,
    @ActiveFlag AS BIT = 1,
    @PurchasingWebServiceURL AS NVARCHAR(1024) = NULL
AS
BEGIN TRANSACTION
BEGIN TRY
    -- Validasi @PreferredVendorStatus antara 0 hingga 1
    IF @PreferredVendorStatus NOT IN (0, 1)
    BEGIN
        THROW 51000, '@PreferredVendorStatus harus bernilai 0 atau 1.', 1;
    END

    -- Validasi @ActiveFlag antara 0 hingga 1
    IF @ActiveFlag NOT IN (0, 1)
    BEGIN
        THROW 51000, '@ActiveFlag harus bernilai 0 atau 1.', 1;
    END

    -- Validasi @CreditRating antara 1 hingga 5
    IF @CreditRating < 1 OR @CreditRating > 5
    BEGIN
        THROW 51000, '@CreditRating harus dalam rentang 1 hingga 5.', 1;
    END

    DECLARE @ModifiedDate DATETIME = GETDATE();
    DECLARE @AccountNumber NVARCHAR(15);  
    DECLARE @BaseAccount NVARCHAR(8);
    DECLARE @IncrementedAccount NVARCHAR(15);
    DECLARE @Sequence INT = 1;
    DECLARE @FormattedSequence NVARCHAR(4);

    -- Ambil 8 karakter pertama dari parameter input @Name setelah menghapus spasi dan karakter non-huruf
    SET @BaseAccount = 
        CASE 
            WHEN CHARINDEX(',', REPLACE(@Name, ' ', '')) > 0 THEN LEFT(REPLACE(@Name, ' ', ''), CHARINDEX(',', REPLACE(@Name, ' ', '')) - 1)  -- Ambil sebelum koma
            ELSE LEFT(REPLACE(@Name, ' ', ''), 8) -- Ambil 8 karakter pertama, hilangkan spasi dan karakter non-huruf
        END;

    -- Ubah @BaseAccount menjadi uppercase
    SET @BaseAccount = UPPER(@BaseAccount);

    -- Format sequence number dengan 4 digit
    SET @FormattedSequence = FORMAT(@Sequence, '0000');

    -- Gabungkan BaseAccount dengan sequence number
    SET @IncrementedAccount = @BaseAccount + @FormattedSequence;

    -- Loop untuk menemukan kombinasi unik
    WHILE EXISTS (SELECT 1 FROM Purchasing.Vendor WHERE AccountNumber = @IncrementedAccount)
    BEGIN
        -- Increment sequence number
        SET @Sequence = @Sequence + 1;
        SET @FormattedSequence = FORMAT(@Sequence, '0000');
        SET @IncrementedAccount = @BaseAccount + @FormattedSequence;
    END

    -- Hasil akhir AccountNumber unik
    SET @AccountNumber = @IncrementedAccount;

    -- Memeriksa apakah BusinessEntityID disediakan
    IF @BusinessEntityID IS NOT NULL
    BEGIN
        -- Update data vendor
        UPDATE Purchasing.Vendor
        SET Name = @Name,
            CreditRating = @CreditRating,
            PreferredVendorStatus = @PreferredVendorStatus,
            ActiveFlag = @ActiveFlag,
            PurchasingWebServiceURL = @PurchasingWebServiceURL,
            ModifiedDate = @ModifiedDate
        WHERE BusinessEntityID = @BusinessEntityID;
    END
    ELSE
    BEGIN
        -- Insert data vendor baru ke dalam tabel
        INSERT INTO Person.BusinessEntity(ModifiedDate) VALUES (GETDATE());

        SET @BusinessEntityID = SCOPE_IDENTITY();

        INSERT INTO Purchasing.Vendor (BusinessEntityID, Name, AccountNumber, CreditRating, PreferredVendorStatus, ActiveFlag, PurchasingWebServiceURL, ModifiedDate)
        VALUES (@BusinessEntityID, @Name, @AccountNumber, @CreditRating, @PreferredVendorStatus, @ActiveFlag, @PurchasingWebServiceURL, @ModifiedDate);
    END

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    -- Rollback the transaction on error
    ROLLBACK TRANSACTION;
    -- Raise the original error
    THROW;
END CATCH
GO
