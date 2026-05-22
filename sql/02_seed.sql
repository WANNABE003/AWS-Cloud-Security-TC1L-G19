USE SecureECommerce;
GO

-- Demo password for all users after running npm install:
-- Generate a replacement hash with:
-- node -e "require('bcryptjs').hash('Password@123',10).then(console.log)"
DECLARE @DemoPasswordHash NVARCHAR(255) = '$2a$10$VUkpRGYNXTKhhj9yFjsnReB8mYDGAU0F8B/jzf2HYiiyWT5rdRH4.';

INSERT INTO AppUser (UserID, Role, Email, FirstName, LastName, PhoneNumber, AddressLine1, City, State, Postcode, PasswordHash)
VALUES
('USR-ADMIN-001', 'Admin', 'admin@securecart.local', 'Willie Teoh', 'Chin Wei', '0123456789', 'Cyberjaya Office, Persiaran Multimedia', 'Cyberjaya', 'Selangor', '63000', @DemoPasswordHash),
('USR-OFFICER-001', 'InventoryOfficer', 'officer@securecart.local', 'Lam', 'Rong Yi', '0132223344', 'Warehouse A, Jalan Teknologi', 'Petaling Jaya', 'Selangor', '47810', @DemoPasswordHash),
('USR-CUST-001', 'Customer', 'customer@securecart.local', 'Lee', 'Yu Jie', '0145556677', '12 Jalan Harmoni', 'Kuala Lumpur', 'WP Kuala Lumpur', '50480', @DemoPasswordHash);

INSERT INTO Product (ProductID, Name, SKU, Price, StockQty, Category, CreatedBy)
VALUES
('PRD-DRESS-001', 'Satin Evening Slip Dress', 'SKU-DRS-001', 229.90, 20, 'Dresses', 'USR-OFFICER-001'),
('PRD-BLAZER-001', 'Tailored Linen Blazer', 'SKU-BLZ-001', 269.90, 14, 'Outerwear', 'USR-OFFICER-001'),
('PRD-BAG-001', 'Quilted Mini Crossbody Bag', 'SKU-BAG-001', 159.00, 25, 'Bags', 'USR-OFFICER-001');

INSERT INTO CustomerOrder (OrderID, UserID, TotalAmount, Status, ShippingAddress)
VALUES
('ORD-SAMPLE-001', 'USR-CUST-001', 229.90, 'Paid', '12 Jalan Harmoni, Kuala Lumpur');

INSERT INTO OrderItem (OrderID, ProductID, Quantity, UnitPrice)
VALUES
('ORD-SAMPLE-001', 'PRD-DRESS-001', 1, 229.90);

INSERT INTO AuditLog (ActorID, ActorRole, Action, TargetType, TargetID, Status, IpAddress)
VALUES
('USR-OFFICER-001', 'InventoryOfficer', 'SeedProductCreated', 'Product', 'PRD-DRESS-001', 'Success', '127.0.0.1'),
('USR-CUST-001', 'Customer', 'SeedOrderCreated', 'Order', 'ORD-SAMPLE-001', 'Success', '127.0.0.1');
GO
