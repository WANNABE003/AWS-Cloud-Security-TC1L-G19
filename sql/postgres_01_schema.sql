-- PostgreSQL schema migration for SecureStyle Fashion E-Commerce

DROP TABLE IF EXISTS AuditLog CASCADE;
DROP TABLE IF EXISTS OrderItem CASCADE;
DROP TABLE IF EXISTS CustomerOrder CASCADE;
DROP TABLE IF EXISTS Product CASCADE;
DROP TABLE IF EXISTS AppUser CASCADE;

-- Create AppUser Table
CREATE TABLE AppUser (
    UserID VARCHAR(50) PRIMARY KEY,
    Role VARCHAR(30) NOT NULL CHECK (Role IN ('Customer', 'InventoryOfficer', 'Admin')),
    Email VARCHAR(255) NOT NULL UNIQUE,
    FirstName VARCHAR(80) NOT NULL,
    LastName VARCHAR(80) NOT NULL,
    PhoneNumber VARCHAR(20) NULL,
    AddressLine1 VARCHAR(255) NULL,
    City VARCHAR(80) NULL,
    State VARCHAR(80) NULL,
    Postcode VARCHAR(12) NULL,
    PasswordHash VARCHAR(255) NOT NULL,
    IsActive BOOLEAN NOT NULL DEFAULT TRUE,
    CreatedAt TIMESTAMP NOT NULL DEFAULT (NOW() + INTERVAL '8 hours'),
    UpdatedAt TIMESTAMP NULL
);

-- Create Product Table
CREATE TABLE Product (
    ProductID VARCHAR(50) PRIMARY KEY,
    Name VARCHAR(120) NOT NULL,
    SKU VARCHAR(40) NOT NULL UNIQUE,
    Price DECIMAL(18,2) NOT NULL CHECK (Price > 0),
    StockQty INT NOT NULL CHECK (StockQty >= 0),
    Category VARCHAR(80) NOT NULL,
    IsActive BOOLEAN NOT NULL DEFAULT TRUE,
    CreatedBy VARCHAR(50) NOT NULL REFERENCES AppUser(UserID),
    CreatedAt TIMESTAMP NOT NULL DEFAULT (NOW() + INTERVAL '8 hours'),
    UpdatedAt TIMESTAMP NULL
);

-- Create CustomerOrder Table
CREATE TABLE CustomerOrder (
    OrderID VARCHAR(50) PRIMARY KEY,
    UserID VARCHAR(50) NOT NULL REFERENCES AppUser(UserID),
    TotalAmount DECIMAL(18,2) NOT NULL CHECK (TotalAmount >= 0),
    Status VARCHAR(30) NOT NULL CHECK (Status IN ('Pending', 'Paid', 'Shipped', 'Cancelled')),
    ShippingAddress VARCHAR(255) NOT NULL,
    CreatedAt TIMESTAMP NOT NULL DEFAULT (NOW() + INTERVAL '8 hours'),
    UpdatedAt TIMESTAMP NULL
);

-- Create OrderItem Table
CREATE TABLE OrderItem (
    OrderItemID SERIAL PRIMARY KEY,
    OrderID VARCHAR(50) NOT NULL REFERENCES CustomerOrder(OrderID),
    ProductID VARCHAR(50) NOT NULL REFERENCES Product(ProductID),
    Quantity INT NOT NULL CHECK (Quantity > 0),
    UnitPrice DECIMAL(18,2) NOT NULL CHECK (UnitPrice > 0)
);

-- Create AuditLog Table
CREATE TABLE AuditLog (
    AuditID SERIAL PRIMARY KEY,
    EventTime TIMESTAMP NOT NULL DEFAULT (NOW() + INTERVAL '8 hours'),
    ActorID VARCHAR(50) NOT NULL,
    ActorRole VARCHAR(30) NOT NULL,
    Action VARCHAR(100) NOT NULL,
    TargetType VARCHAR(50) NOT NULL,
    TargetID VARCHAR(50) NULL,
    Status VARCHAR(30) NOT NULL,
    IpAddress VARCHAR(64) NULL
);

-- Create Indexes
CREATE INDEX IX_Product_Active_Category ON Product(IsActive, Category);
CREATE INDEX IX_Order_User_CreatedAt ON CustomerOrder(UserID, CreatedAt DESC);
CREATE INDEX IX_Audit_EventTime ON AuditLog(EventTime DESC);
