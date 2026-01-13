-- ==========================================================================================
-- Script: 01_Setup_Logins.sql
-- Description: Creates the necessary Windows Authentication Logins and Users.
-- Usage: Replace placeholders <DOMAIN\GROUP> and <DATABASE_NAME> before running.
-- ==========================================================================================

USE [master];
GO

-- 1. Create the Login from Active Directory (Windows Auth)
-- TODO: Replace 'DOMAIN\UserGroup' with your actual AD Group or User (e.g., 'CONTOSO\OT_Operators')
DECLARE @ADLogin NVARCHAR(100) = 'DOMAIN\UserGroup' 

IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = @ADLogin)
BEGIN
    -- Dynamic SQL used here to allow variable usage, but usually manual replacement is safer.
    -- Un-comment the line below after replacing the name manually:
    
    -- CREATE LOGIN [DOMAIN\UserGroup] FROM WINDOWS;
    
    PRINT 'ACTION REQUIRED: Edit this script to set the correct AD Login Name, then uncomment the CREATE LOGIN statement.';
END
ELSE
BEGIN
    PRINT 'Login already exists.';
END
GO

-- 2. Switch to the Production Database
-- TODO: Replace 'TargetDB' with your actual database name
USE [TargetDB]; 
GO

-- 3. Create the Database User mapped to the Login
-- TODO: Replace 'DOMAIN\UserGroup' below
IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = 'DOMAIN\UserGroup')
BEGIN
    -- CREATE USER [DOMAIN\UserGroup] FOR LOGIN [DOMAIN\UserGroup];
    PRINT 'ACTION REQUIRED: Edit this script to set the correct User Name, then uncomment the CREATE USER statement.';
END
GO

-- 4. Assign Permissions
-- TODO: Replace 'DOMAIN\UserGroup' below
-- ALTER ROLE [db_datareader] ADD MEMBER [DOMAIN\UserGroup];
-- ALTER ROLE [db_datawriter] ADD MEMBER [DOMAIN\UserGroup];
PRINT 'Permissions step skipped (requires valid user).';
GO