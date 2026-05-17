USE SecureECommerce;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'CustomerRole')
    CREATE ROLE CustomerRole;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'InventoryOfficerRole')
    CREATE ROLE InventoryOfficerRole;
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'AdminRole')
    CREATE ROLE AdminRole;
GO

CREATE OR ALTER VIEW vw_ActiveProducts
AS
SELECT ProductID, Name, SKU, Price, StockQty, Category
FROM dbo.Product
WHERE IsActive = 1;
GO

CREATE OR ALTER VIEW vw_CustomersForStaff
AS
SELECT UserID, Role, Email, FirstName, LastName, PhoneNumber, AddressLine1, City, State, Postcode
FROM dbo.AppUser
WHERE Role = 'Customer';
GO

GRANT SELECT ON dbo.vw_ActiveProducts TO CustomerRole, InventoryOfficerRole, AdminRole;
GRANT SELECT ON dbo.vw_CustomersForStaff TO InventoryOfficerRole, AdminRole;
GRANT SELECT, INSERT ON dbo.CustomerOrder TO CustomerRole, AdminRole;
GRANT SELECT, INSERT ON dbo.OrderItem TO CustomerRole, AdminRole;
GRANT SELECT, INSERT, UPDATE ON dbo.Product TO InventoryOfficerRole, AdminRole;
GRANT SELECT ON dbo.AuditLog TO AdminRole;

DENY SELECT, INSERT, UPDATE, DELETE ON dbo.AppUser TO CustomerRole, InventoryOfficerRole;
DENY SELECT ON dbo.AuditLog TO CustomerRole, InventoryOfficerRole;
DENY DELETE ON dbo.Product TO CustomerRole, InventoryOfficerRole, AdminRole;
GO

CREATE OR ALTER TRIGGER trg_Product_Audit_Update
ON dbo.Product
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.AuditLog (ActorID, ActorRole, Action, TargetType, TargetID, Status, IpAddress)
    SELECT
        COALESCE(CONVERT(NVARCHAR(50), SESSION_CONTEXT(N'actor_id')), 'sql-trigger'),
        COALESCE(CONVERT(NVARCHAR(30), SESSION_CONTEXT(N'actor_role')), 'Database'),
        'ProductUpdated',
        'Product',
        inserted.ProductID,
        'Success',
        CONVERT(NVARCHAR(64), CONNECTIONPROPERTY('client_net_address'))
    FROM inserted;
END;
GO

CREATE OR ALTER TRIGGER trg_Order_Audit_Insert
ON dbo.CustomerOrder
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.AuditLog (ActorID, ActorRole, Action, TargetType, TargetID, Status, IpAddress)
    SELECT
        inserted.UserID,
        'Customer',
        'OrderInserted',
        'Order',
        inserted.OrderID,
        'Success',
        CONVERT(NVARCHAR(64), CONNECTIONPROPERTY('client_net_address'))
    FROM inserted;
END;
GO

-- Row-level security example for report demonstration.
-- The app also enforces this at API level; this SQL predicate shows database-side defence in depth.
IF SCHEMA_ID('Security') IS NULL
    EXEC('CREATE SCHEMA Security');
GO

CREATE OR ALTER FUNCTION Security.fn_order_access(@UserID NVARCHAR(50))
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
    SELECT 1 AS fn_result
    WHERE @UserID = CONVERT(NVARCHAR(50), SESSION_CONTEXT(N'user_id'))
       OR CONVERT(NVARCHAR(30), SESSION_CONTEXT(N'user_role')) = 'Admin';
GO

DROP SECURITY POLICY IF EXISTS Security.OrderAccessPolicy;
GO

CREATE SECURITY POLICY Security.OrderAccessPolicy
ADD FILTER PREDICATE Security.fn_order_access(UserID) ON dbo.CustomerOrder
WITH (STATE = ON);
GO

-- Transparent Data Encryption notes for a real server:
-- 1. Create master key in master database.
-- 2. Create certificate protected by the master key.
-- 3. Create database encryption key in SecureECommerce.
-- 4. ALTER DATABASE SecureECommerce SET ENCRYPTION ON.
-- Keep the certificate backup offline; losing it can make backups unrecoverable.

BACKUP DATABASE SecureECommerce
TO DISK = '/var/opt/mssql/data/SecureECommerce_full.bak'
WITH INIT, COMPRESSION, CHECKSUM;
GO
