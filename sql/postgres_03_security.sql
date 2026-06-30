-- PostgreSQL Security Configuration for SecureStyle Fashion E-Commerce

-- 1. Create Roles
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'customerrole') THEN
        CREATE ROLE customerrole;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'inventoryofficerrole') THEN
        CREATE ROLE inventoryofficerrole;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'adminrole') THEN
        CREATE ROLE adminrole;
    END IF;
END
$$;

-- The web application connects through one non-owner login. Authorization is enforced
-- by Express RBAC and parameterized queries; direct human access uses the narrower roles above.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_service') THEN
        CREATE ROLE app_service LOGIN;
    END IF;
END
$$;

-- 2. Create Views
CREATE OR REPLACE VIEW vw_ActiveProducts
AS
SELECT ProductID, Name, SKU, Price, StockQty, Category
FROM Product
WHERE IsActive = TRUE;

CREATE OR REPLACE VIEW vw_CustomersForStaff
AS
SELECT 
    UserID, 
    Role, 
    Email, 
    FirstName, 
    LastName, 
    CASE 
        WHEN current_setting('session.user_role', true) = 'Admin' THEN PhoneNumber
        WHEN PhoneNumber IS NULL THEN NULL
        ELSE SUBSTRING(PhoneNumber FROM 1 FOR 2) || 'XXXXXX' || SUBSTRING(PhoneNumber FROM GREATEST(LENGTH(PhoneNumber) - 1, 3))
    END AS PhoneNumber,
    CASE 
        WHEN current_setting('session.user_role', true) = 'Admin' THEN AddressLine1
        WHEN AddressLine1 IS NULL THEN NULL
        ELSE SUBSTRING(AddressLine1 FROM 1 FOR 4) || 'XXXXXX'
    END AS AddressLine1,
    City, 
    State, 
    Postcode
FROM AppUser
WHERE Role = 'Customer';

-- 3. Grants and Revokes
-- Revoke standard public permissions on tables
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;

-- Grant permissions to Roles
GRANT SELECT ON vw_ActiveProducts TO customerrole, inventoryofficerrole, adminrole;
GRANT SELECT ON vw_CustomersForStaff TO inventoryofficerrole, adminrole;
GRANT SELECT, INSERT ON CustomerOrder TO customerrole, adminrole;
GRANT SELECT, INSERT ON OrderItem TO customerrole, adminrole;
GRANT SELECT, INSERT, UPDATE ON Product TO inventoryofficerrole, adminrole;
GRANT SELECT ON AuditLog TO adminrole;
GRANT SELECT, INSERT, UPDATE ON AppUser, Product, CustomerOrder, OrderItem, AuditLog TO app_service;

-- Grant usage on sequences (required for INSERTs with SERIAL IDs in PostgreSQL)
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO customerrole, inventoryofficerrole, adminrole;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_service;

-- 4. Triggers for Auditing
-- Product Update Trigger
CREATE OR REPLACE FUNCTION audit_product_update()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO AuditLog (EventTime, ActorID, ActorRole, Action, TargetType, TargetID, Status, IpAddress)
    VALUES (
        NOW() + INTERVAL '8 hours',
        COALESCE(current_setting('session.actor_id', true), 'sql-trigger'),
        COALESCE(current_setting('session.actor_role', true), 'Database'),
        'ProductUpdated',
        'Product',
        NEW.ProductID,
        'Success',
        COALESCE(inet_client_addr()::VARCHAR, '127.0.0.1')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_Product_Audit_Update ON Product;
CREATE TRIGGER trg_Product_Audit_Update
    AFTER UPDATE ON Product
    FOR EACH ROW
    EXECUTE FUNCTION audit_product_update();

-- Customer Order Insert Trigger
CREATE OR REPLACE FUNCTION audit_order_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO AuditLog (EventTime, ActorID, ActorRole, Action, TargetType, TargetID, Status, IpAddress)
    VALUES (
        NOW() + INTERVAL '8 hours',
        NEW.UserID,
        'Customer',
        'OrderInserted',
        'Order',
        NEW.OrderID,
        'Success',
        COALESCE(inet_client_addr()::VARCHAR, '127.0.0.1')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_Order_Audit_Insert ON CustomerOrder;
CREATE TRIGGER trg_Order_Audit_Insert
    AFTER INSERT ON CustomerOrder
    FOR EACH ROW
    EXECUTE FUNCTION audit_order_insert();

-- 5. Row-Level Security (RLS)
ALTER TABLE CustomerOrder ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS order_access_policy ON CustomerOrder;
CREATE POLICY order_access_policy ON CustomerOrder
    FOR ALL
    USING (
        current_user = 'app_service'
        OR UserID = current_setting('session.user_id', true)
        OR current_setting('session.user_role', true) IN ('Admin', 'InventoryOfficer')
    );

-- Note on Transparent Data Encryption (TDE):
-- In PostgreSQL on AWS RDS, TDE is not implemented using SQL Server's database encryption keys.
-- Instead, it is configured at the cloud storage layer via KMS-managed key encryption (enabled in Terraform).
