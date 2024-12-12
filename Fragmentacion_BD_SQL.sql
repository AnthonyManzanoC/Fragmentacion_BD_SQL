-- Usar la base de datos especificada
USE [quinto];
GO

-- CREACIÓN DE TABLA CLIENTES SI NO EXISTE
IF OBJECT_ID('Clientes', 'U') IS NULL
BEGIN
    CREATE TABLE Clientes (
        IdCliente INT IDENTITY(1,1) PRIMARY KEY,
        Nombres NVARCHAR(50),
        Apellidos NVARCHAR(50),
        Direccion NVARCHAR(50),
        Telefono NVARCHAR(50),
        Correo NVARCHAR(50)
    );

    -- INSERCIÓN DE DATOS INICIALES PARA VALIDACIÓN
    INSERT INTO Clientes (Nombres, Apellidos, Direccion, Telefono, Correo)
    VALUES 
    ('Carlos', 'Lopez', 'Calle A', '123456789', 'carlos@mail.com'),
    ('Ana', 'Martinez', 'Calle B', '987654321', 'ana@mail.com'),
    ('Luis', 'Gomez', 'Calle C', '456123789', 'luis@mail.com'),
    ('Maria', 'Perez', 'Calle D', '321654987', 'maria@mail.com'),
    ('Jose', 'Garcia', 'Calle E', '789123456', 'jose@mail.com');
END;

-- CREACIÓN DE TABLAS DE FRAGMENTACIÓN VERTICAL SI NO EXISTEN
IF OBJECT_ID('Cliente1Vertical', 'U') IS NULL
BEGIN
    CREATE TABLE Cliente1Vertical (
        id INT PRIMARY KEY,
        nombres NVARCHAR(100),
        apellidos NVARCHAR(100)
    );
END;

IF OBJECT_ID('Cliente2Vertical', 'U') IS NULL
BEGIN
    CREATE TABLE Cliente2Vertical (
        id INT PRIMARY KEY,
        direccion NVARCHAR(200),
        telefono NVARCHAR(20),
        correo NVARCHAR(100)
    );
END;

-- CREACIÓN DE TABLAS DE FRAGMENTACIÓN HORIZONTAL SIMPLIFICADA
IF OBJECT_ID('Cliente3Horizontal', 'U') IS NULL
BEGIN
    CREATE TABLE Cliente3Horizontal (
        id INT PRIMARY KEY,
        nombres NVARCHAR(100),
        apellidos NVARCHAR(100)
    );
END;

IF OBJECT_ID('Cliente4Horizontal', 'U') IS NULL
BEGIN
    CREATE TABLE Cliente4Horizontal (
        id INT PRIMARY KEY,
        direccion NVARCHAR(200),
        telefono NVARCHAR(20),
        correo NVARCHAR(100)
    );
END;

-- INSERCIÓN DE DATOS EN TABLAS VERTICALES (EJEMPLO DE DATOS)
-- Solo ejecuta si las tablas están vacías
IF NOT EXISTS (SELECT 1 FROM Cliente1Vertical)
BEGIN
    INSERT INTO Cliente1Vertical (id, nombres, apellidos)
    SELECT IdCliente, Nombres, Apellidos
    FROM Clientes;
END;

IF NOT EXISTS (SELECT 1 FROM Cliente2Vertical)
BEGIN
    INSERT INTO Cliente2Vertical (id, direccion, telefono, correo)
    SELECT IdCliente, Direccion, Telefono, Correo
    FROM Clientes;
END;

-- INSERCIÓN DE DATOS EN TABLAS HORIZONTALES SIMPLIFICADAS
IF NOT EXISTS (SELECT 1 FROM Cliente3Horizontal)
BEGIN
    INSERT INTO Cliente3Horizontal
    SELECT id, nombres, apellidos
    FROM Cliente1Vertical;
END;

IF NOT EXISTS (SELECT 1 FROM Cliente4Horizontal)
BEGIN
    INSERT INTO Cliente4Horizontal
    SELECT id, direccion, telefono, correo
    FROM Cliente2Vertical;
END;

-- REINSERTAR EN FRAGMENTOS SI LOS NUEVOS DATOS NO ESTÁN YA DISTRIBUIDOS
INSERT INTO Cliente1Vertical (id, nombres, apellidos)
SELECT IdCliente, Nombres, Apellidos
FROM Clientes
WHERE IdCliente NOT IN (SELECT id FROM Cliente1Vertical);

INSERT INTO Cliente2Vertical (id, direccion, telefono, correo)
SELECT IdCliente, Direccion, Telefono, Correo
FROM Clientes
WHERE IdCliente NOT IN (SELECT id FROM Cliente2Vertical);

-- Reinsertar fragmentación horizontal para nuevos IDs
INSERT INTO Cliente3Horizontal
SELECT id, nombres, apellidos
FROM Cliente1Vertical
WHERE id NOT IN (SELECT id FROM Cliente3Horizontal);

INSERT INTO Cliente4Horizontal
SELECT id, direccion, telefono, correo
FROM Cliente2Vertical
WHERE id NOT IN (SELECT id FROM Cliente4Horizontal);

-- CONSULTA FINAL CON INNER JOIN ENTRE FRAGMENTACIONES VERTICAL Y HORIZONTAL
SELECT c1.id, c1.nombres, c1.apellidos,
       c2.direccion, c2.telefono, c2.correo
FROM Cliente3Horizontal c1
INNER JOIN Cliente4Horizontal c2 ON c1.id = c2.id;

-- CONSULTA PARA UNIR TODAS LAS FRAGMENTACIONES
SELECT c1v.id AS ID, 
       c1v.nombres AS Nombres, 
       c1v.apellidos AS Apellidos, 
       c2v.direccion AS Direccion, 
       c2v.telefono AS Telefono, 
       c2v.correo AS Correo
FROM Cliente1Vertical c1v
INNER JOIN Cliente2Vertical c2v ON c1v.id = c2v.id
UNION ALL
SELECT c3h.id AS ID, 
       c3h.nombres AS Nombres, 
       c3h.apellidos AS Apellidos, 
       c4h.direccion AS Direccion, 
       c4h.telefono AS Telefono, 
       c4h.correo AS Correo
FROM Cliente3Horizontal c3h
INNER JOIN Cliente4Horizontal c4h ON c3h.id = c4h.id;
GO
