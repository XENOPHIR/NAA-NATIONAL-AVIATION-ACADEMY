CREATE DATABASE HOLDEM;
USE HOLDEM;
GO

-- TABLES
CREATE TABLE Users (
    UserID INT IDENTITY PRIMARY KEY,
    Username NVARCHAR(50) NOT NULL UNIQUE,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(255) NOT NULL,
    IsActive BIT DEFAULT 1,
    IsVerified BIT DEFAULT 0,
    VerificationCode NVARCHAR(6),
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

CREATE TABLE Roles (
    RoleID INT IDENTITY PRIMARY KEY,
    RoleName NVARCHAR(50) NOT NULL UNIQUE,
    Description NVARCHAR(255),
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

CREATE TABLE Permissions (
    PermissionID INT IDENTITY PRIMARY KEY,
    PermissionName NVARCHAR(50) NOT NULL UNIQUE,
    Description NVARCHAR(255),
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

CREATE TABLE RolePermissions (
    RolePermissionID INT IDENTITY PRIMARY KEY,
    RoleID INT NOT NULL FOREIGN KEY REFERENCES Roles(RoleID),
    PermissionID INT NOT NULL FOREIGN KEY REFERENCES Permissions(PermissionID),
    CreatedAt DATETIME DEFAULT GETDATE()
);

CREATE TABLE UserRoles (
    UserRoleID INT IDENTITY PRIMARY KEY,
    UserID INT NOT NULL FOREIGN KEY REFERENCES Users(UserID),
    RoleID INT NOT NULL FOREIGN KEY REFERENCES Roles(RoleID),
    CreatedAt DATETIME DEFAULT GETDATE()
);

CREATE TABLE Products (
    ProductID INT IDENTITY PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(MAX),
    BasePrice DECIMAL(10, 2) NOT NULL,
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

ALTER TABLE Products ADD ImagePath NVARCHAR(MAX);

CREATE TABLE Categories (
    CategoryID INT IDENTITY PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL UNIQUE,
    Description NVARCHAR(MAX),
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

CREATE TABLE ProductCategories (
    ProductCategoryID INT IDENTITY PRIMARY KEY,
    ProductID INT NOT NULL FOREIGN KEY REFERENCES Products(ProductID),
    CategoryID INT NOT NULL FOREIGN KEY REFERENCES Categories(CategoryID),
    CreatedAt DATETIME DEFAULT GETDATE()
);

CREATE TABLE Orders (
    OrderID INT IDENTITY PRIMARY KEY,
    UserID INT NOT NULL FOREIGN KEY REFERENCES Users(UserID),
    TotalAmount DECIMAL(10, 2) NOT NULL,
    Status NVARCHAR(50) DEFAULT 'Pending',
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

CREATE TABLE OrderDetails (
    OrderDetailID INT IDENTITY PRIMARY KEY,
    OrderID INT NOT NULL FOREIGN KEY REFERENCES Orders(OrderID),
    ProductID INT NOT NULL FOREIGN KEY REFERENCES Products(ProductID),
    Quantity INT NOT NULL,
    Price DECIMAL(10, 2) NOT NULL,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

CREATE TABLE Reviews (
    ReviewID INT IDENTITY PRIMARY KEY,
    UserID INT NOT NULL FOREIGN KEY REFERENCES Users(UserID),
    ProductID INT NOT NULL FOREIGN KEY REFERENCES Products(ProductID),
    Rating INT NOT NULL CHECK (Rating BETWEEN 1 AND 5),
    Comment NVARCHAR(MAX),
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME DEFAULT GETDATE()
);

CREATE TABLE Inventory (
    InventoryID INT IDENTITY PRIMARY KEY,
    ProductID INT NOT NULL FOREIGN KEY REFERENCES Products(ProductID),
    Stock INT DEFAULT 0,
    Reserved INT DEFAULT 0,
    IsActive BIT DEFAULT 1,
    UpdatedAt DATETIME DEFAULT GETDATE()
);

CREATE TABLE PaymentCards (
    CardID INT IDENTITY PRIMARY KEY,
    UserID INT NOT NULL FOREIGN KEY REFERENCES Users(UserID),
    CardNumber NVARCHAR(16) NOT NULL,
    ExpiryDate NVARCHAR(5) NOT NULL,
    CardHolderName NVARCHAR(100) NOT NULL,
    IsDefault BIT DEFAULT 0,
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME DEFAULT GETDATE()
);

CREATE TABLE Transactions (
    TransactionID INT IDENTITY PRIMARY KEY,
    OrderID INT NOT NULL FOREIGN KEY REFERENCES Orders(OrderID),
    PaymentMethod NVARCHAR(50) NOT NULL,
    TransactionStatus NVARCHAR(50) DEFAULT 'Pending',
    TransactionDate DATETIME DEFAULT GETDATE(),
    Amount DECIMAL(10, 2) NOT NULL,
    CardID INT NULL FOREIGN KEY REFERENCES PaymentCards(CardID),
    PaymentGateway NVARCHAR(50),
    GatewayTransactionID NVARCHAR(100),
    IsActive BIT DEFAULT 1
);

CREATE TABLE Logs (
    LogID INT IDENTITY PRIMARY KEY,
    UserID INT NULL FOREIGN KEY REFERENCES Users(UserID),
    Action NVARCHAR(255) NOT NULL,
    Details NVARCHAR(MAX),
    CreatedAt DATETIME DEFAULT GETDATE(),
    IsActive BIT DEFAULT 1
);

CREATE TABLE Favorites (
    FavoriteID INT IDENTITY PRIMARY KEY,
    UserID INT NOT NULL FOREIGN KEY REFERENCES Users(UserID),
    ProductID INT NOT NULL FOREIGN KEY REFERENCES Products(ProductID),
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME DEFAULT GETDATE()
);

CREATE TABLE Cart (
    CartID INT IDENTITY PRIMARY KEY,
    UserID INT NOT NULL FOREIGN KEY REFERENCES Users(UserID),
    ProductID INT NOT NULL FOREIGN KEY REFERENCES Products(ProductID),
    Quantity INT DEFAULT 1,
    CardID INT NULL FOREIGN KEY REFERENCES PaymentCards(CardID),
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

CREATE TABLE Brands (
    BrandID INT IDENTITY PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL UNIQUE,
    Description NVARCHAR(MAX),
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

CREATE TABLE Tags (
    TagID INT IDENTITY PRIMARY KEY,
    Name NVARCHAR(100) NOT NULL UNIQUE,
    Description NVARCHAR(MAX),
    IsActive BIT DEFAULT 1,
    CreatedAt DATETIME DEFAULT GETDATE(),
    UpdatedAt DATETIME DEFAULT GETDATE()
);

CREATE TABLE ProductBrands (
    ProductBrandID INT IDENTITY PRIMARY KEY,
    ProductID INT NOT NULL FOREIGN KEY REFERENCES Products(ProductID),
    BrandID INT NOT NULL FOREIGN KEY REFERENCES Brands(BrandID),
    CreatedAt DATETIME DEFAULT GETDATE()
);

CREATE TABLE ProductTags (
    ProductTagID INT IDENTITY PRIMARY KEY,
    ProductID INT NOT NULL FOREIGN KEY REFERENCES Products(ProductID),
    TagID INT NOT NULL FOREIGN KEY REFERENCES Tags(TagID),
    CreatedAt DATETIME DEFAULT GETDATE()
);

INSERT INTO Roles (RoleName, Description) VALUES
('User', 'Regular user with limited access'),
('Admin', 'Administrator with full access');

INSERT INTO Permissions (PermissionName, Description) VALUES
('ViewDashboard', 'Permission to view the admin dashboard'),
('ManageUsers', 'Permission to create, edit, or delete users'),
('ManageProducts', 'Permission to manage products'),
('ViewReports', 'Permission to view reports');

-- PERMISSION DECLARATION
DECLARE @AdminRoleID INT = (SELECT RoleID FROM Roles WHERE RoleName = 'Admin');
DECLARE @UserRoleID INT = (SELECT RoleID FROM Roles WHERE RoleName = 'User');

-- ROLE PERMISSION
INSERT INTO RolePermissions (RoleID, PermissionID)
SELECT @AdminRoleID, PermissionID FROM Permissions
WHERE NOT EXISTS (
    SELECT 1
    FROM RolePermissions
    WHERE RoleID = @AdminRoleID AND PermissionID = Permissions.PermissionID
);

-- USERROLE DECLARATION
DECLARE @FirstUserID INT = (SELECT MIN(UserID) FROM Users WHERE Username != 'Admin');
DECLARE @AdminUserID INT = (SELECT UserID FROM Users WHERE Email = 'admin@example.com');

IF @AdminUserID IS NULL
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Users WHERE Username = 'Admin')
    BEGIN
        INSERT INTO Users (Username, Email, PasswordHash, IsActive, IsVerified)
        VALUES ('Admin', 'admin@example.com', 'admin_password_hash', 1, 1);

        SET @AdminUserID = SCOPE_IDENTITY();
    END
    ELSE
    BEGIN
        SELECT @AdminUserID = UserID FROM Users WHERE Username = 'Admin';
    END
END;

IF @FirstUserID IS NOT NULL AND @AdminUserID IS NOT NULL
BEGIN
    INSERT INTO UserRoles (UserID, RoleID)
    SELECT UserID, RoleID
    FROM (
        SELECT @FirstUserID AS UserID, @UserRoleID AS RoleID
        UNION ALL
        SELECT @AdminUserID AS UserID, @AdminRoleID AS RoleID
    ) AS RolesToInsert
    WHERE NOT EXISTS (
        SELECT 1
        FROM UserRoles
        WHERE UserID = RolesToInsert.UserID AND RoleID = RolesToInsert.RoleID
    );
END;
GO







-- PROCEDURES

-- LOGS
CREATE PROCEDURE GetLogs
AS
BEGIN
    SELECT 
        LogID, 
        UserID, 
        Action, 
        Details, 
        CreatedAt, 
        IsActive 
    FROM Logs
    ORDER BY CreatedAt DESC;
END;
GO

--USERS PROCEDURES
CREATE PROCEDURE UpdateUser
    @UserID INT,
    @Username NVARCHAR(50),
    @Email NVARCHAR(100),
    @IsActive BIT
AS
BEGIN
    UPDATE Users
    SET Username = @Username,
        Email = @Email,
        IsActive = @IsActive,
        UpdatedAt = GETDATE()
    WHERE UserID = @UserID;
END;
GO

CREATE PROCEDURE DeleteUser
    @UserID INT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM Users WHERE UserID = @UserID)
    BEGIN
        UPDATE Users
        SET IsActive = 0
        WHERE UserID = @UserID;

        INSERT INTO Logs (UserID, Action, Details, CreatedAt)
        VALUES (@UserID, 'SoftDelete', 'User marked as inactive', GETDATE());
    END
    ELSE
    BEGIN
        RAISERROR ('User does not exist', 16, 1);
    END
END;
GO

CREATE PROCEDURE RegisterUser
    @Username NVARCHAR(50),
    @Email NVARCHAR(100),
    @PasswordHash NVARCHAR(255),
    @VerificationCode NVARCHAR(6)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        INSERT INTO Users (Username, Email, PasswordHash, VerificationCode, IsActive, IsVerified)
        VALUES (@Username, @Email, @PasswordHash, @VerificationCode, 0, 0);

        DECLARE @UserID INT = SCOPE_IDENTITY();
        INSERT INTO Logs (UserID, Action, Details, CreatedAt)
        VALUES (@UserID, 'Register', 'New user registered', GETDATE());
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END;
GO

CREATE PROCEDURE CheckUserLogin
    @Email NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        SELECT UserID, Username, PasswordHash, IsVerified
        FROM Users
        WHERE Email = @Email AND IsActive = 1;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE VerifyUserEmail
    @Email NVARCHAR(100),
    @VerificationCode NVARCHAR(6)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Users WHERE Email = @Email)
        BEGIN
            SELECT 'NOT_FOUND' AS Status;
            RETURN;
        END

        IF EXISTS (SELECT 1 FROM Users WHERE Email = @Email AND VerificationCode = @VerificationCode)
        BEGIN
            UPDATE Users
            SET IsVerified = 1, IsActive = 1, VerificationCode = NULL
            WHERE Email = @Email;

            COMMIT;
            SELECT 'SUCCESS' AS Status;
        END
        ELSE
        BEGIN
            SELECT 'INVALID_CODE' AS Status;
        END
    END TRY
    BEGIN CATCH
        ROLLBACK;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END;
GO

CREATE OR ALTER PROCEDURE GetAllUsers
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        UserID, 
        Username, 
        Email, 
        IsActive
    FROM Users;
END;
GO

EXEC GetAllUsers;
GO

-- PRODUCT PROCEDURES
CREATE PROCEDURE AddProduct
    @Name NVARCHAR(100),
    @Description NVARCHAR(MAX),
    @BasePrice DECIMAL(10, 2),
    @IsActive BIT,
    @CategoryID INT,
    @BrandID INT = NULL,
    @TagIDs NVARCHAR(MAX) = NULL,
    @ImagePath NVARCHAR(MAX) = NULL,
    @Stock INT = NULL 
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @ProductID INT;

        INSERT INTO Products (Name, Description, BasePrice, IsActive, ImagePath, CreatedAt, UpdatedAt)
        VALUES (@Name, @Description, @BasePrice, @IsActive, @ImagePath, GETDATE(), GETDATE());

        SET @ProductID = SCOPE_IDENTITY(); 

        INSERT INTO ProductCategories (ProductID, CategoryID)
        VALUES (@ProductID, @CategoryID);

        IF @BrandID IS NOT NULL
        BEGIN
            INSERT INTO ProductBrands (ProductID, BrandID)
            VALUES (@ProductID, @BrandID);
        END

        IF @TagIDs IS NOT NULL
        BEGIN
            DECLARE @TagID NVARCHAR(10);
            WHILE LEN(@TagIDs) > 0
            BEGIN
                SET @TagID = LEFT(@TagIDs, CHARINDEX(',', @TagIDs + ',') - 1);
                INSERT INTO ProductTags (ProductID, TagID)
                VALUES (@ProductID, CAST(@TagID AS INT));
                SET @TagIDs = STUFF(@TagIDs, 1, CHARINDEX(',', @TagIDs + ','), '');
            END
        END

        IF @Stock IS NOT NULL
        BEGIN
            INSERT INTO Inventory (ProductID, Stock, Reserved, UpdatedAt)
            VALUES (@ProductID, @Stock, 0, GETDATE());
        END

        COMMIT TRANSACTION;

        SELECT @ProductID AS ProductID;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

ALTER PROCEDURE AddProduct
    @Name NVARCHAR(100),
    @Description NVARCHAR(MAX),
    @BasePrice DECIMAL(10, 2),
    @IsActive BIT,
    @CategoryID INT,
    @BrandID INT = NULL,
    @TagIDs NVARCHAR(MAX) = NULL,
    @ImagePath NVARCHAR(MAX) = NULL,
    @Stock INT = NULL 
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @ProductID INT;

        INSERT INTO Products (Name, Description, BasePrice, IsActive, ImagePath, CreatedAt, UpdatedAt)
        VALUES (@Name, @Description, @BasePrice, @IsActive, @ImagePath, GETDATE(), GETDATE());

        SET @ProductID = SCOPE_IDENTITY();

        INSERT INTO ProductCategories (ProductID, CategoryID)
        VALUES (@ProductID, @CategoryID);

        IF @BrandID IS NOT NULL
        BEGIN
            INSERT INTO ProductBrands (ProductID, BrandID)
            VALUES (@ProductID, @BrandID);
        END

        IF @TagIDs IS NOT NULL
        BEGIN
            DECLARE @TagID NVARCHAR(10);
            WHILE LEN(@TagIDs) > 0
            BEGIN
                SET @TagID = LEFT(@TagIDs, CHARINDEX(',', @TagIDs + ',') - 1);
                INSERT INTO ProductTags (ProductID, TagID)
                VALUES (@ProductID, CAST(@TagID AS INT));
                SET @TagIDs = STUFF(@TagIDs, 1, CHARINDEX(',', @TagIDs + ','), '');
            END
        END

        IF @Stock IS NOT NULL
        BEGIN
            INSERT INTO Inventory (ProductID, Stock, Reserved, UpdatedAt)
            VALUES (@ProductID, @Stock, 0, GETDATE());
        END

        COMMIT TRANSACTION;

        SELECT @ProductID AS ProductID;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

ALTER PROCEDURE UpdateProductWithDetails
    @ProductID INT,
    @Name NVARCHAR(100),
    @Description NVARCHAR(MAX),
    @BasePrice DECIMAL(10, 2),
    @IsActive BIT,
    @CategoryID INT,
    @BrandID INT = NULL,
    @TagIDs NVARCHAR(MAX) = NULL
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        UPDATE Products
        SET Name = @Name, 
            Description = @Description, 
            BasePrice = @BasePrice, 
            IsActive = @IsActive, 
            UpdatedAt = GETDATE()
        WHERE ProductID = @ProductID;

        IF NOT EXISTS (SELECT 1 FROM Products WHERE ProductID = @ProductID)
        BEGIN
            THROW 50001, 'ProductID does not exist in Products table.', 1;
        END

        DELETE FROM ProductCategories WHERE ProductID = @ProductID;
        INSERT INTO ProductCategories (ProductID, CategoryID)
        VALUES (@ProductID, @CategoryID);

        DELETE FROM ProductBrands WHERE ProductID = @ProductID;
        IF @BrandID IS NOT NULL
        BEGIN
            INSERT INTO ProductBrands (ProductID, BrandID)
            VALUES (@ProductID, @BrandID);
        END

        DELETE FROM ProductTags WHERE ProductID = @ProductID;
        IF @TagIDs IS NOT NULL
        BEGIN
            DECLARE @TagID NVARCHAR(10);
            WHILE LEN(@TagIDs) > 0
            BEGIN
                SET @TagID = LEFT(@TagIDs, CHARINDEX(',', @TagIDs + ',') - 1);
                INSERT INTO ProductTags (ProductID, TagID)
                VALUES (@ProductID, CAST(@TagID AS INT));
                SET @TagIDs = STUFF(@TagIDs, 1, CHARINDEX(',', @TagIDs + ','), '');
            END
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

ALTER PROCEDURE GetProductDetails
    @ProductID INT
AS
BEGIN
    SELECT 
        p.ProductID, 
        p.Name, 
        p.Description, 
        p.BasePrice, 
        p.ImagePath, 
        p.IsActive,
        c.Name AS CategoryName,
        b.Name AS BrandName,
        STRING_AGG(t.Name, ', ') AS Tags,
        STRING_AGG(CAST(pt.TagID AS NVARCHAR), ',') AS TagIDs,
        i.Stock,
        i.Reserved
    FROM Products p
    LEFT JOIN ProductCategories pc ON p.ProductID = pc.ProductID
    LEFT JOIN Categories c ON pc.CategoryID = c.CategoryID
    LEFT JOIN ProductBrands pb ON p.ProductID = pb.ProductID
    LEFT JOIN Brands b ON pb.BrandID = b.BrandID
    LEFT JOIN ProductTags pt ON p.ProductID = pt.ProductID
    LEFT JOIN Tags t ON pt.TagID = t.TagID
    LEFT JOIN Inventory i ON p.ProductID = i.ProductID 
    WHERE p.ProductID = @ProductID
    GROUP BY 
        p.ProductID, 
        p.Name, 
        p.Description, 
        p.BasePrice, 
        p.ImagePath, 
        p.IsActive, 
        c.Name, 
        b.Name, 
        i.Stock, 
        i.Reserved;
END;
GO

ALTER PROCEDURE DeleteProductWithDetails
    @ProductID INT
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY

        DELETE FROM Inventory WHERE ProductID = @ProductID;
        DELETE FROM ProductTags WHERE ProductID = @ProductID;
        DELETE FROM ProductBrands WHERE ProductID = @ProductID;
        DELETE FROM ProductCategories WHERE ProductID = @ProductID;
        DELETE FROM Products WHERE ProductID = @ProductID;

        COMMIT TRANSACTION;

        PRINT 'Product and related details deleted successfully.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

ALTER PROCEDURE DeleteProductWithDetails
    @ProductID INT
AS
BEGIN
    BEGIN TRANSACTION;
    BEGIN TRY
        DELETE FROM Inventory WHERE ProductID = @ProductID;

        DELETE FROM ProductTags WHERE ProductID = @ProductID;
        DELETE FROM ProductBrands WHERE ProductID = @ProductID;
        DELETE FROM ProductCategories WHERE ProductID = @ProductID;

        DELETE FROM Products WHERE ProductID = @ProductID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

CREATE PROCEDURE GetAllProducts
AS
BEGIN
    SELECT 
        p.ProductID,
        p.Name,
        p.Description,
        p.BasePrice,
        p.IsActive,
        c.Name AS CategoryName,
        b.Name AS BrandName
    FROM Products p
    LEFT JOIN ProductCategories pc ON p.ProductID = pc.ProductID
    LEFT JOIN Categories c ON pc.CategoryID = c.CategoryID
    LEFT JOIN ProductBrands pb ON p.ProductID = pb.ProductID
    LEFT JOIN Brands b ON pb.BrandID = b.BrandID;
END;
GO

CREATE PROCEDURE GetProducts
AS
BEGIN
    SELECT 
        p.ProductID, 
        p.Name, 
        p.Description, 
        p.BasePrice, 
        p.ImagePath, 
        p.IsActive,
        c.Name AS CategoryName,
        b.Name AS BrandName,
        STRING_AGG(t.Name, ', ') AS Tags
    FROM Products p
    LEFT JOIN ProductCategories pc ON p.ProductID = pc.ProductID
    LEFT JOIN Categories c ON pc.CategoryID = c.CategoryID
    LEFT JOIN ProductBrands pb ON p.ProductID = pb.ProductID
    LEFT JOIN Brands b ON pb.BrandID = b.BrandID
    LEFT JOIN ProductTags pt ON p.ProductID = pt.ProductID
    LEFT JOIN Tags t ON pt.TagID = t.TagID
    WHERE p.IsActive = 1
    GROUP BY p.ProductID, p.Name, p.Description, p.BasePrice, p.ImagePath, p.IsActive, c.Name, b.Name;
END;
GO

CREATE PROCEDURE GetProductDetails
    @ProductID INT
AS
BEGIN
    SELECT 
        p.ProductID, 
        p.Name, 
        p.Description, 
        p.BasePrice, 
        p.ImagePath, 
        p.IsActive,
        c.Name AS CategoryName,
        b.Name AS BrandName,
        STRING_AGG(t.Name, ', ') AS Tags,
        STRING_AGG(CAST(pt.TagID AS NVARCHAR), ',') AS TagIDs
    FROM Products p
    LEFT JOIN ProductCategories pc ON p.ProductID = pc.ProductID
    LEFT JOIN Categories c ON pc.CategoryID = c.CategoryID
    LEFT JOIN ProductBrands pb ON p.ProductID = pb.ProductID
    LEFT JOIN Brands b ON pb.BrandID = b.BrandID
    LEFT JOIN ProductTags pt ON p.ProductID = pt.ProductID
    LEFT JOIN Tags t ON pt.TagID = t.TagID
    WHERE p.ProductID = @ProductID
    GROUP BY 
        p.ProductID, 
        p.Name, 
        p.Description, 
        p.BasePrice, 
        p.ImagePath, 
        p.IsActive, 
        c.Name, 
        b.Name;
END;
GO

ALTER PROCEDURE GetProductDetails
    @ProductID INT
AS
BEGIN
    SELECT 
        p.ProductID, 
        p.Name, 
        p.Description, 
        p.BasePrice, 
        p.ImagePath, 
        p.IsActive,
        c.Name AS CategoryName,
        b.Name AS BrandName,
        STRING_AGG(t.Name, ', ') AS Tags,
        STRING_AGG(CAST(pt.TagID AS NVARCHAR), ',') AS TagIDs,
        i.Stock,
        i.Reserved
    FROM Products p
    LEFT JOIN ProductCategories pc ON p.ProductID = pc.ProductID
    LEFT JOIN Categories c ON pc.CategoryID = c.CategoryID
    LEFT JOIN ProductBrands pb ON p.ProductID = pb.ProductID
    LEFT JOIN Brands b ON pb.BrandID = b.BrandID
    LEFT JOIN ProductTags pt ON p.ProductID = pt.ProductID
    LEFT JOIN Tags t ON pt.TagID = t.TagID
    LEFT JOIN Inventory i ON p.ProductID = i.ProductID
    WHERE p.ProductID = @ProductID
    GROUP BY 
        p.ProductID, 
        p.Name, 
        p.Description, 
        p.BasePrice, 
        p.ImagePath, 
        p.IsActive, 
        c.Name, 
        b.Name, 
        i.Stock, 
        i.Reserved;
END;
GO

CREATE PROCEDURE GetTotalProducts
    @Categories NVARCHAR(MAX),
    @Brands NVARCHAR(MAX),
    @Tags NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT COUNT(DISTINCT p.ProductID)
    FROM Products p
    LEFT JOIN ProductCategories pc ON p.ProductID = pc.ProductID
    LEFT JOIN Categories c ON pc.CategoryID = c.CategoryID
    LEFT JOIN ProductBrands pb ON p.ProductID = pb.ProductID
    LEFT JOIN Brands b ON pb.BrandID = b.BrandID
    LEFT JOIN ProductTags pt ON p.ProductID = pt.ProductID
    LEFT JOIN Tags t ON pt.TagID = t.TagID
    WHERE 
        (@Categories IS NULL OR c.CategoryID IN (SELECT value FROM STRING_SPLIT(@Categories, ',')))
        AND (@Brands IS NULL OR b.BrandID IN (SELECT value FROM STRING_SPLIT(@Brands, ',')))
        AND (@Tags IS NULL OR t.TagID IN (SELECT value FROM STRING_SPLIT(@Tags, ',')));
END;
GO

CREATE PROCEDURE GetFilteredProducts
    @Categories NVARCHAR(MAX) = NULL,
    @Brands NVARCHAR(MAX) = NULL,
    @Tags NVARCHAR(MAX) = NULL,
    @Page INT,
    @PerPage INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@Page - 1) * @PerPage;

    SELECT 
        p.ProductID, p.Name, p.Description, p.BasePrice, p.ImagePath,
        c.Name AS CategoryName, b.Name AS BrandName,
        STRING_AGG(t.Name, ', ') AS Tags
    FROM Products p
    LEFT JOIN ProductCategories pc ON p.ProductID = pc.ProductID
    LEFT JOIN Categories c ON pc.CategoryID = c.CategoryID
    LEFT JOIN ProductBrands pb ON p.ProductID = pb.ProductID
    LEFT JOIN Brands b ON pb.BrandID = b.BrandID
    LEFT JOIN ProductTags pt ON p.ProductID = pt.ProductID
    LEFT JOIN Tags t ON pt.TagID = t.TagID
    WHERE 
        (@Categories IS NULL OR c.CategoryID IN (SELECT value FROM STRING_SPLIT(@Categories, ',')))
        AND (@Brands IS NULL OR b.BrandID IN (SELECT value FROM STRING_SPLIT(@Brands, ',')))
        AND (@Tags IS NULL OR t.TagID IN (SELECT value FROM STRING_SPLIT(@Tags, ',')))
    GROUP BY p.ProductID, p.Name, p.Description, p.BasePrice, p.ImagePath, c.Name, b.Name
    ORDER BY p.Name
    OFFSET @Offset ROWS FETCH NEXT @PerPage ROWS ONLY;
END;
GO

CREATE PROCEDURE GetTotalProducts
    @Categories NVARCHAR(MAX) = NULL,
    @Brands NVARCHAR(MAX) = NULL,
    @Tags NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT COUNT(DISTINCT p.ProductID)
    FROM Products p
    LEFT JOIN ProductCategories pc ON p.ProductID = pc.ProductID
    LEFT JOIN Categories c ON pc.CategoryID = c.CategoryID
    LEFT JOIN ProductBrands pb ON p.ProductID = pb.ProductID
    LEFT JOIN Brands b ON pb.BrandID = b.BrandID
    LEFT JOIN ProductTags pt ON p.ProductID = pt.ProductID
    LEFT JOIN Tags t ON pt.TagID = t.TagID
    WHERE 
        (@Categories IS NULL OR c.CategoryID IN (SELECT value FROM STRING_SPLIT(@Categories, ',')))
        OR (@Brands IS NULL OR b.BrandID IN (SELECT value FROM STRING_SPLIT(@Brands, ',')))
        OR (@Tags IS NULL OR t.TagID IN (SELECT value FROM STRING_SPLIT(@Tags, ',')));
END;
GO

CREATE PROCEDURE SearchProducts
    @Query NVARCHAR(MAX),
    @Page INT,
    @PerPage INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Offset INT = (@Page - 1) * @PerPage;

    SELECT 
        p.ProductID, 
        p.Name, 
        p.Description, 
        p.BasePrice, 
        p.ImagePath,
        c.Name AS CategoryName, 
        b.Name AS BrandName,
        STRING_AGG(t.Name, ', ') AS Tags
    FROM Products p
    LEFT JOIN ProductCategories pc ON p.ProductID = pc.ProductID
    LEFT JOIN Categories c ON pc.CategoryID = c.CategoryID
    LEFT JOIN ProductBrands pb ON p.ProductID = pb.ProductID
    LEFT JOIN Brands b ON pb.BrandID = b.BrandID
    LEFT JOIN ProductTags pt ON p.ProductID = pt.ProductID
    LEFT JOIN Tags t ON pt.TagID = t.TagID
    WHERE 
        p.Name LIKE '%' + @Query + '%'
        OR t.Name LIKE '%' + @Query + '%'
        OR c.Name LIKE '%' + @Query + '%'
        OR b.Name LIKE '%' + @Query + '%'
    GROUP BY 
        p.ProductID, 
        p.Name, 
        p.Description, 
        p.BasePrice, 
        p.ImagePath, 
        c.Name, 
        b.Name
    ORDER BY p.Name
    OFFSET @Offset ROWS FETCH NEXT @PerPage ROWS ONLY;
END;
GO

CREATE PROCEDURE GetTotalSearchProducts
    @Query NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT COUNT(DISTINCT p.ProductID)
    FROM Products p
    LEFT JOIN ProductCategories pc ON p.ProductID = pc.ProductID
    LEFT JOIN Categories c ON pc.CategoryID = c.CategoryID
    LEFT JOIN ProductTags pt ON p.ProductID = pt.ProductID
    LEFT JOIN Tags t ON pt.TagID = t.TagID
    LEFT JOIN ProductBrands pb ON p.ProductID = pb.ProductID
    LEFT JOIN Brands b ON pb.BrandID = b.BrandID
    WHERE 
        p.Name LIKE '%' + @Query + '%'
        OR t.Name LIKE '%' + @Query + '%'
        OR c.Name LIKE '%' + @Query + '%'
        OR b.Name LIKE '%' + @Query + '%';
END;
GO

-- CATEGORIES
DROP PROCEDURE IF EXISTS AddCategory;
GO

CREATE PROCEDURE AddCategory
    @Name NVARCHAR(100),
    @Description NVARCHAR(MAX),
    @IsActive BIT
AS
BEGIN
    INSERT INTO Categories (Name, Description, IsActive)
    VALUES (@Name, @Description, @IsActive);
END;
GO

DROP PROCEDURE IF EXISTS UpdateCategory;
GO

CREATE PROCEDURE UpdateCategory
    @CategoryID INT,
    @Name NVARCHAR(100),
    @Description NVARCHAR(MAX),
    @IsActive BIT
AS
BEGIN
    UPDATE Categories
    SET Name = @Name,
        Description = @Description,
        IsActive = @IsActive,
        UpdatedAt = GETDATE()
    WHERE CategoryID = @CategoryID;
END;
GO

DROP PROCEDURE IF EXISTS DeleteCategory;
GO

CREATE PROCEDURE DeleteCategory
    @CategoryID INT
AS
BEGIN
    DELETE FROM Categories WHERE CategoryID = @CategoryID;
END;
GO

DROP PROCEDURE IF EXISTS GetCategories;
GO

CREATE PROCEDURE GetCategories
AS
BEGIN
    SELECT CategoryID, Name, Description, IsActive
    FROM Categories;
END;
GO

DROP PROCEDURE IF EXISTS GetCategoryByID;
GO

CREATE PROCEDURE GetCategoryByID
    @CategoryID INT
AS
BEGIN
    SELECT CategoryID, Name, Description, IsActive
    FROM Categories
    WHERE CategoryID = @CategoryID;
END;
GO

-- TAGS
CREATE PROCEDURE AddTag
    @Name NVARCHAR(100),
    @Description NVARCHAR(MAX) = NULL,
    @IsActive BIT = 1
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Tags WHERE Name = @Name)
    BEGIN
        THROW 50001, 'Tag with this name already exists.', 1;
    END

    INSERT INTO Tags (Name, Description, IsActive)
    VALUES (@Name, @Description, @IsActive);
END;
GO

CREATE PROCEDURE UpdateTag
    @TagID INT,
    @Name NVARCHAR(100),
    @Description NVARCHAR(MAX) = NULL,
    @IsActive BIT
AS
BEGIN
    UPDATE Tags
    SET Name = @Name,
        Description = @Description,
        IsActive = @IsActive,
        UpdatedAt = GETDATE()
    WHERE TagID = @TagID;
END;
GO

CREATE PROCEDURE DeleteTag
    @TagID INT
AS
BEGIN
    DELETE FROM Tags WHERE TagID = @TagID;
END;
GO

CREATE PROCEDURE GetTags
AS
BEGIN
    SELECT TagID, Name, Description, IsActive
    FROM Tags;
END;
GO

-- BRANDS
CREATE PROCEDURE AddBrand
    @Name NVARCHAR(100),
    @Description NVARCHAR(MAX) = NULL,
    @IsActive BIT = 1
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Brands WHERE Name = @Name)
    BEGIN
        THROW 50002, 'Brand with this name already exists.', 1;
    END

    INSERT INTO Brands (Name, Description, IsActive)
    VALUES (@Name, @Description, @IsActive);
END;
GO

CREATE PROCEDURE UpdateBrand
    @BrandID INT,
    @Name NVARCHAR(100),
    @Description NVARCHAR(MAX) = NULL,
    @IsActive BIT
AS
BEGIN
    UPDATE Brands
    SET Name = @Name,
        Description = @Description,
        IsActive = @IsActive,
        UpdatedAt = GETDATE()
    WHERE BrandID = @BrandID;
END;
GO

CREATE PROCEDURE DeleteBrand
    @BrandID INT
AS
BEGIN
    DELETE FROM Brands WHERE BrandID = @BrandID;
END;
GO

CREATE PROCEDURE GetBrands
AS
BEGIN
    SELECT BrandID, Name, Description, IsActive
    FROM Brands;
END;
GO

CREATE PROCEDURE AddReview
    @UserID INT,
    @ProductID INT,
    @Rating INT,
    @Comment NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Reviews (UserID, ProductID, Rating, Comment, CreatedAt)
    VALUES (@UserID, @ProductID, @Rating, @Comment, GETDATE());
END;
GO

CREATE PROCEDURE GetProductReviews
    @ProductID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        r.ReviewID,
        r.Comment,
        r.Rating,
        r.CreatedAt,
        u.Username
    FROM Reviews r
    JOIN Users u ON r.UserID = u.UserID
    WHERE r.ProductID = @ProductID AND r.IsActive = 1
    ORDER BY r.CreatedAt DESC;
END;
GO

CREATE PROCEDURE AddFavorite
    @UserID INT,
    @ProductID INT
AS
BEGIN
    INSERT INTO Favorites (UserID, ProductID, CreatedAt)
    VALUES (@UserID, @ProductID, GETDATE());
END;
GO

CREATE PROCEDURE AddToCart
    @UserID INT,
    @ProductID INT,
    @Quantity INT
AS
BEGIN
    IF EXISTS (SELECT 1 FROM Cart WHERE UserID = @UserID AND ProductID = @ProductID)
    BEGIN
        UPDATE Cart
        SET Quantity = Quantity + @Quantity, UpdatedAt = GETDATE()
        WHERE UserID = @UserID AND ProductID = @ProductID;
    END
    ELSE
    BEGIN
        INSERT INTO Cart (UserID, ProductID, Quantity, CreatedAt)
        VALUES (@UserID, @ProductID, @Quantity, GETDATE());
    END
END;
GO

CREATE PROCEDURE CreateOrder
    @UserID INT,
    @PaymentCard INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OrderID INT;

    INSERT INTO Orders (UserID, TotalAmount, Status, CreatedAt)
    VALUES (
        @UserID, 
        (SELECT SUM(c.Quantity * p.BasePrice)
         FROM Cart c
         JOIN Products p ON c.ProductID = p.ProductID
         WHERE c.UserID = @UserID), 
        'Pending', 
        GETDATE()
    );

    SET @OrderID = SCOPE_IDENTITY();

    INSERT INTO OrderDetails (OrderID, ProductID, Quantity, Price)
    SELECT 
        @OrderID, 
        c.ProductID, 
        c.Quantity, 
        p.BasePrice
    FROM Cart c
    JOIN Products p ON c.ProductID = p.ProductID
    WHERE c.UserID = @UserID;

    DELETE FROM Cart WHERE UserID = @UserID;
END;
GO

ALTER PROCEDURE CreateOrder
    @UserID INT,
    @PaymentCard INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @OrderID INT;

    INSERT INTO Orders (UserID, TotalAmount, Status, CreatedAt)
    SELECT 
        @UserID,
        SUM(c.Quantity * p.BasePrice),
        'Pending',
        GETDATE()
    FROM Cart c
    JOIN Products p ON c.ProductID = p.ProductID
    WHERE c.UserID = @UserID;

    SET @OrderID = SCOPE_IDENTITY();

    INSERT INTO OrderDetails (OrderID, ProductID, Quantity, Price)
    SELECT 
        @OrderID, 
        c.ProductID, 
        c.Quantity, 
        p.BasePrice
    FROM Cart c
    JOIN Products p ON c.ProductID = p.ProductID
    WHERE c.UserID = @UserID;

    DECLARE @ProductID INT, @Quantity INT;
    DECLARE cur CURSOR FOR
        SELECT ProductID, Quantity
        FROM Cart
        WHERE UserID = @UserID;

    OPEN cur;
    FETCH NEXT FROM cur INTO @ProductID, @Quantity;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            EXEC UpdateInventoryOnOrder @ProductID, @Quantity;
        END TRY
        BEGIN CATCH
            PRINT 'Error updating inventory for ProductID: ' + CAST(@ProductID AS NVARCHAR) + 
                  ', Quantity: ' + CAST(@Quantity AS NVARCHAR);
        END CATCH;

        FETCH NEXT FROM cur INTO @ProductID, @Quantity;
    END;

    CLOSE cur;
    DEALLOCATE cur;

    DELETE FROM Cart WHERE UserID = @UserID;

    UPDATE Orders
    SET Status = 'Completed',
        UpdatedAt = GETDATE()
    WHERE OrderID = @OrderID;
END;
GO


CREATE PROCEDURE GetUserCart
    @UserID INT
AS
BEGIN
    SELECT 
        c.CartID,
        c.Quantity,
        p.ProductID,
        p.Name,
        p.Description,
        p.BasePrice,
        p.ImagePath
    FROM Cart c
    INNER JOIN Products p ON c.ProductID = p.ProductID
    WHERE c.UserID = @UserID AND c.IsActive = 1
    ORDER BY c.CreatedAt DESC;
END;
GO

CREATE PROCEDURE ReleaseInventory
    @ProductID INT,
    @Quantity INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Inventory
    SET Stock = Stock + @Quantity,
        Reserved = Reserved - @Quantity,
        UpdatedAt = GETDATE()
    WHERE ProductID = @ProductID AND Reserved >= @Quantity;

    IF @@ROWCOUNT = 0
    BEGIN
        THROW 50002, 'Invalid release operation', 1;
    END
END;
GO

CREATE PROCEDURE CheckInventory
    @ProductID INT,
    @Quantity INT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM Inventory
        WHERE ProductID = @ProductID AND Stock >= @Quantity
    )
    BEGIN
        SELECT 1 AS IsAvailable;
    END
    ELSE
    BEGIN
        SELECT 0 AS IsAvailable;
    END
END;
GO

CREATE PROCEDURE UpdateInventoryOnOrder
    @ProductID INT,
    @Quantity INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Inventory
    SET Stock = Stock - @Quantity,
        Reserved = Reserved + @Quantity,
        UpdatedAt = GETDATE()
    WHERE ProductID = @ProductID AND Stock >= @Quantity;

    IF @@ROWCOUNT = 0
    BEGIN
        THROW 50001, 'Not enough stock available', 1;
    END
END;
GO

CREATE PROCEDURE GetPaymentCards
    @UserID INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        CardID,
        CardNumber,
        ExpiryDate,
        CardHolderName,
        IsDefault
    FROM PaymentCards
    WHERE UserID = @UserID AND IsActive = 1;
END;
GO

--INSERT INTO PaymentCards (UserID, CardNumber, ExpiryDate, CardHolderName, IsDefault, IsActive)
--VALUES 
--(1, '1234567812345678', '12/25', 'John Doe', 1, 1),
--(1, '8765432187654321', '11/24', 'John Doe', 0, 1),
--(2, '1111222233334444', '05/26', 'Jane Smith', 1, 1);

CREATE PROCEDURE UpdateInventoryOnOrderForUser
    @UserID INT
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE Inventory
    SET 
        Stock = Stock - c.Quantity,
        UpdatedAt = GETDATE()
    FROM Inventory i
    INNER JOIN Cart c ON i.ProductID = c.ProductID
    WHERE c.UserID = @UserID AND i.Stock >= c.Quantity;

    DELETE FROM Cart WHERE UserID = @UserID;
END;
GO








-- TRIGGERS
-- CATEGORY LOGS
CREATE TRIGGER LogCategoryChanges
ON Categories
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Log INSERT actions
    INSERT INTO Logs (Action, Details, CreatedAt)
    SELECT 
        'INSERT',
        CONCAT('New category added: Name=', inserted.Name, ', Description=', ISNULL(inserted.Description, 'NULL'), 
               ', IsActive=', CAST(inserted.IsActive AS NVARCHAR)),
        GETDATE()
    FROM inserted
    LEFT JOIN deleted ON inserted.CategoryID = deleted.CategoryID
    WHERE deleted.CategoryID IS NULL;

    -- Log UPDATE actions
    INSERT INTO Logs (Action, Details, CreatedAt)
    SELECT 
        'UPDATE',
        CONCAT('Category updated: Name=', inserted.Name, ', IsActive changed to=', CAST(inserted.IsActive AS NVARCHAR)),
        GETDATE()
    FROM inserted
    INNER JOIN deleted ON inserted.CategoryID = deleted.CategoryID;

    -- Log DELETE actions
    INSERT INTO Logs (Action, Details, CreatedAt)
    SELECT 
        'DELETE',
        CONCAT('Category deleted: Name=', deleted.Name, ', Description=', ISNULL(deleted.Description, 'NULL')),
        GETDATE()
    FROM deleted
    LEFT JOIN inserted ON deleted.CategoryID = inserted.CategoryID
    WHERE inserted.CategoryID IS NULL;
END;
GO

-- BRAND LOGS
CREATE TRIGGER LogBrandChanges
ON Brands
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Log INSERT actions
    INSERT INTO Logs (Action, Details, CreatedAt)
    SELECT 
        'INSERT',
        CONCAT('New brand added: Name=', inserted.Name, ', Description=', ISNULL(inserted.Description, 'NULL'), 
               ', IsActive=', CAST(inserted.IsActive AS NVARCHAR)),
        GETDATE()
    FROM inserted
    LEFT JOIN deleted ON inserted.BrandID = deleted.BrandID
    WHERE deleted.BrandID IS NULL;

    -- Log UPDATE actions
    INSERT INTO Logs (Action, Details, CreatedAt)
    SELECT 
        'UPDATE',
        CONCAT('Brand updated: Name=', inserted.Name, ', IsActive changed to=', CAST(inserted.IsActive AS NVARCHAR)),
        GETDATE()
    FROM inserted
    INNER JOIN deleted ON inserted.BrandID = deleted.BrandID;

    -- Log DELETE actions
    INSERT INTO Logs (Action, Details, CreatedAt)
    SELECT 
        'DELETE',
        CONCAT('Brand deleted: Name=', deleted.Name, ', Description=', ISNULL(deleted.Description, 'NULL')),
        GETDATE()
    FROM deleted
    LEFT JOIN inserted ON deleted.BrandID = inserted.BrandID
    WHERE inserted.BrandID IS NULL;
END;
GO

--TAGS LOGS
CREATE TRIGGER LogTagChanges
ON Tags
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Log INSERT actions
    INSERT INTO Logs (Action, Details, CreatedAt)
    SELECT 
        'INSERT',
        CONCAT('Tag added: Name=', inserted.Name, ', IsActive=', CAST(inserted.IsActive AS NVARCHAR)),
        GETDATE()
    FROM inserted;

    -- Log UPDATE actions
    INSERT INTO Logs (Action, Details, CreatedAt)
    SELECT 
        'UPDATE',
        CONCAT('Tag updated: Name=', inserted.Name, ', IsActive changed to=', CAST(inserted.IsActive AS NVARCHAR)),
        GETDATE()
    FROM inserted
    INNER JOIN deleted ON inserted.TagID = deleted.TagID;

    -- Log DELETE actions
    INSERT INTO Logs (Action, Details, CreatedAt)
    SELECT 
        'DELETE',
        CONCAT('Tag deleted: Name=', deleted.Name),
        GETDATE()
    FROM deleted;
END;
GO

-- PRODUCT CATEGORY LOGS
CREATE TRIGGER LogProductCategoryChanges
ON ProductCategories
AFTER INSERT, DELETE
AS
BEGIN
    -- Log INSERT actions
    INSERT INTO Logs (Action, Details, CreatedAt)
    SELECT 
        'INSERT',
        CONCAT('Category linked to product: ProductID=', inserted.ProductID, ', CategoryID=', inserted.CategoryID),
        GETDATE()
    FROM inserted;

    -- Log DELETE actions
    INSERT INTO Logs (Action, Details, CreatedAt)
    SELECT 
        'DELETE',
        CONCAT('Category unlinked from product: ProductID=', deleted.ProductID, ', CategoryID=', deleted.CategoryID),
        GETDATE()
    FROM deleted;
END;
GO

-- PRODUCT BRAND LOGS
CREATE TRIGGER LogProductBrandChanges
ON ProductBrands
AFTER INSERT, DELETE
AS
BEGIN
    -- Log INSERT actions
    INSERT INTO Logs (Action, Details, CreatedAt)
    SELECT 
        'INSERT',
        CONCAT('Brand linked to product: ProductID=', inserted.ProductID, ', BrandID=', inserted.BrandID),
        GETDATE()
    FROM inserted;

    -- Log DELETE actions
    INSERT INTO Logs (Action, Details, CreatedAt)
    SELECT 
        'DELETE',
        CONCAT('Brand unlinked from product: ProductID=', deleted.ProductID, ', BrandID=', deleted.BrandID),
        GETDATE()
    FROM deleted;
END;
GO

-- PRODUCT TAG LOGS
CREATE TRIGGER LogProductTagChanges
ON ProductTags
AFTER INSERT, DELETE
AS
BEGIN
    -- Log INSERT actions
    INSERT INTO Logs (Action, Details, CreatedAt)
    SELECT 
        'INSERT',
        CONCAT('Tag linked to product: ProductID=', inserted.ProductID, ', TagID=', inserted.TagID),
        GETDATE()
    FROM inserted;

    -- Log DELETE actions
    INSERT INTO Logs (Action, Details, CreatedAt)
    SELECT 
        'DELETE',
        CONCAT('Tag unlinked from product: ProductID=', deleted.ProductID, ', TagID=', deleted.TagID),
        GETDATE()
    FROM deleted;
END;
GO

-- TRIGGERS

-- USER TIME UPDATE
CREATE TRIGGER UpdateTimestamp
ON Users
AFTER UPDATE
AS
BEGIN
    UPDATE Users
    SET UpdatedAt = GETDATE()
    WHERE UserID IN (SELECT UserID FROM inserted);
END;
GO

-- LOGS FOR USERS
CREATE TRIGGER LogUserChanges
ON Users
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Log INSERT actions
    INSERT INTO Logs (UserID, Action, Details, CreatedAt)
    SELECT 
        inserted.UserID,
        'INSERT',
        CONCAT('New user created: Username=', inserted.Username, ', Email=', inserted.Email),
        GETDATE()
    FROM inserted
    LEFT JOIN deleted ON inserted.UserID = deleted.UserID
    WHERE deleted.UserID IS NULL;

    -- Log UPDATE actions
    INSERT INTO Logs (UserID, Action, Details, CreatedAt)
    SELECT 
        inserted.UserID,
        'UPDATE',
        CONCAT('User updated: Username=', inserted.Username, ', Email=', inserted.Email, 
               ', IsActive changed to=', CAST(inserted.IsActive AS NVARCHAR)),
        GETDATE()
    FROM inserted
    INNER JOIN deleted ON inserted.UserID = deleted.UserID;

    -- Log DELETE actions
    INSERT INTO Logs (UserID, Action, Details, CreatedAt)
    SELECT 
        deleted.UserID,
        'DELETE',
        CONCAT('User deleted: Username=', deleted.Username, ', Email=', deleted.Email),
        GETDATE()
    FROM deleted
    LEFT JOIN inserted ON deleted.UserID = inserted.UserID
    WHERE inserted.UserID IS NULL;
END;
GO

ALTER TABLE Logs
DROP CONSTRAINT FK__Logs__UserID__57DD0BE4;

ALTER TABLE Logs
ADD CONSTRAINT FK__Logs__UserID__57DD0BE4
FOREIGN KEY (UserID) REFERENCES Users(UserID)
ON DELETE CASCADE;
GO

-- LOGS FOR PRODUCTS
CREATE TRIGGER LogProductChanges
ON Products
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    -- Log INSERT actions
    INSERT INTO Logs (Action, Details, CreatedAt)
    SELECT 
        'INSERT',
        CONCAT('New product added: Name=', inserted.Name, ', BasePrice=', CAST(inserted.BasePrice AS NVARCHAR)),
        GETDATE()
    FROM inserted
    LEFT JOIN deleted ON inserted.ProductID = deleted.ProductID
    WHERE deleted.ProductID IS NULL;

    -- Log UPDATE actions
    INSERT INTO Logs (Action, Details, CreatedAt)
    SELECT 
        'UPDATE',
        CONCAT('Product updated: Name=', inserted.Name, ', BasePrice changed to=', CAST(inserted.BasePrice AS NVARCHAR), 
               ', IsActive changed to=', CAST(inserted.IsActive AS NVARCHAR)),
        GETDATE()
    FROM inserted
    INNER JOIN deleted ON inserted.ProductID = deleted.ProductID;

    -- Log DELETE actions
    INSERT INTO Logs (Action, Details, CreatedAt)
    SELECT 
        'DELETE',
        CONCAT('Product deleted: Name=', deleted.Name, ', BasePrice=', CAST(deleted.BasePrice AS NVARCHAR)),
        GETDATE()
    FROM deleted
    LEFT JOIN inserted ON deleted.ProductID = inserted.ProductID
    WHERE inserted.ProductID IS NULL;
END;
GO

-- LOGS FOR TAGS CHANGES
CREATE TRIGGER LogTagChanges
ON Tags
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    INSERT INTO Logs (Action, Details, CreatedAt)
    SELECT 
        CASE 
            WHEN EXISTS (SELECT * FROM inserted) AND EXISTS (SELECT * FROM deleted) THEN 'Update Tag'
            WHEN EXISTS (SELECT * FROM inserted) THEN 'Insert Tag'
            ELSE 'Delete Tag'
        END,
        CONCAT('TagID: ', ISNULL(INSERTED.TagID, DELETED.TagID), ', Name: ', ISNULL(INSERTED.Name, DELETED.Name)),
        GETDATE()
    FROM inserted
    FULL OUTER JOIN deleted ON inserted.TagID = deleted.TagID;
END;
GO

CREATE PROCEDURE GetInactiveUsers
AS
BEGIN
    SELECT UserID, Email, Username
    FROM Users
    WHERE IsVerified = 0
    AND DATEDIFF(MINUTE, CreatedAt, GETDATE()) > 5;
END;
GO

CREATE OR ALTER FUNCTION GetUserRoleName (@UserID INT)
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @RoleName NVARCHAR(50);

    SELECT TOP 1 @RoleName = r.RoleName
    FROM UserRoles ur
    JOIN Roles r ON ur.RoleID = r.RoleID
    WHERE ur.UserID = @UserID;

    RETURN @RoleName;
END;
GO