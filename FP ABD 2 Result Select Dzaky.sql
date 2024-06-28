SELECT *
FROM Purchasing.PurchaseOrderHeader
WHERE EmployeeID = 1
ORDER BY OrderDate DESC;

SELECT *
FROM Purchasing.PurchaseOrderDetail
WHERE PurchaseOrderID IN (
    SELECT PurchaseOrderID
    FROM Purchasing.PurchaseOrderHeader
    WHERE EmployeeID = 1
)
ORDER BY DueDate DESC;
