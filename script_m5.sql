-- creacion de bd
DROP DATABASE IF EXISTS EVALUACION_M5;
CREATE DATABASE EVALUACION_M5;
USE EVALUACION_M5;
-- creacion de tablas
CREATE TABLE IF NOT EXISTS Productos(
	idProducto INT PRIMARY KEY AUTO_INCREMENT,
	nombre VARCHAR(100) NOT NULL,
	descripcion TEXT NOT NULL,
	precio DECIMAL(10,2) NOT NULL CHECK (precio > 0),
    cantidadEnInventario INT NOT NULL CHECK (cantidadEnInventario>=0)
    
);

CREATE TABLE IF NOT EXISTS Proveedores(
	idProveedor INT PRIMARY KEY AUTO_INCREMENT,
	nombre VARCHAR(100) NOT NULL,
	direccion VARCHAR(250) NOT NULL,
	telefono VARCHAR(20) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS Transacciones(
	idTransacciones INT PRIMARY KEY AUTO_INCREMENT,
    idProducto INT NOT NULL,
    idProveedor INT NOT NULL,
	tipo ENUM('compra', 'venta') NOT NULL, 
	fechaHora DATETIME NOT NULL,
	FOREIGN KEY (idProducto) REFERENCES productos(idProducto)
    ON UPDATE CASCADE
    -- se supone que el ON DELETE RESTRICT es el comportamiento por defecto de mysql
    -- asi que no deberia ser necesario ponerlo pero sirve para ser explícito
    ON DELETE RESTRICT,
    FOREIGN KEY (idProveedor) REFERENCES Proveedores(idProveedor)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
);
-- modificación de tablas productos y proveedores para agregar columna activo para poder
-- manipular los productos y proveedores que ya no esten en uso sin tener que eliminarlos
-- por integridad referencial para no perder datos historicos importantes
ALTER TABLE Productos
ADD COLUMN activo BOOLEAN NOT NULL DEFAULT'1';
ALTER TABLE Proveedores
ADD COLUMN activo BOOLEAN NOT NULL DEFAULT'1';
-- se agrega una columna cantidad para transaccion ademas de columna precio_unitario que seria
-- el precio del producto al momento de la transacción (historico) ademas de una columna margen
-- para poder agregar margenes de venta para los productos de reventa
-- se decidio usar margen entre 1 y 1,99 para que no haya margen 0 al intentar calcular
-- el precio total con margen de ganancia por lo que el margen se ingresa 1,(margen esperado)
-- siendo el margen = 1 el que no genera ganancia extra 
ALTER TABLE Transacciones
ADD COLUMN cantidad INT NOT NULL CHECK (cantidad > 0);
ALTER TABLE Transacciones
ADD COLUMN precioUnitario DECIMAL(10,2) NOT NULL CHECK (precioUnitario > 0);
ALTER TABLE Transacciones
ADD COLUMN margen DECIMAL(3,2) DEFAULT'1.00' CHECK (margen >= 1.00 AND margen <= 1.99);

-- Manipulacion de datos(DML) inserción de datos
INSERT INTO Productos (nombre, descripcion, precio, cantidadEnInventario) VALUES
('Detergente', 'Detergente de ropa ecologico formato retornable 3L', '17000.00',30),
('Lavalozas', 'lavalozas ecologico formato retornable 1L', '6500.00', 30),
('Lufa', 'esponja vegetal biodegradable grande', '2000.00', 0),
('Betadet', 'Tensoactivo anfótero', '600000.00', 0);
-- se agregaran 2 pruebas solo para mostrar como funciona la restricción CHECK en mysql
-- prueba para ver que no se puedan insertar precios menores a 0
INSERT INTO Productos (nombre, descripcion, precio, cantidadEnInventario) VALUES
('prueba1', 'producto de prueba', '-1.00',30);
-- prueba para comprobar que no pueda ingresar cantidades en inventario menores a 0
INSERT INTO Productos (nombre, descripcion, precio, cantidadEnInventario) VALUES
('prueba2', 'producto de prueba', '1000',-1);

INSERT INTO Proveedores (nombre, direccion, telefono, email) VALUES
-- se agrega la propia empresa como proveedor para los casos de venta para evitar nulls
('WeCanCompany', 'Av. Marathon', '+569 3090 4398', 'wecan@wecancompany.cl'),
('Proveedor1', 'calle incognita 123', '+569 8765 4321', 'contacto@proveedor1.cl'),
('Proveedor2', 'calle incognita 321', '+569 4321 8765', 'contacto@proveedor2.cl');
INSERT INTO Transacciones (idProducto, idProveedor, tipo, fechaHora, cantidad, precioUnitario) VALUES
(3, 2, 'compra', '2025-08-02 12:00:00', 100, 2000.00);
UPDATE Productos
SET cantidadEnInventario = cantidadEnInventario+100
WHERE idProducto = 3;  
INSERT INTO Transacciones (idProducto, idProveedor, tipo, fechaHora, cantidad, precioUnitario) VALUES
(4, 3, 'compra', '2025-01-03 12:00:00', 1, 600000.00);
UPDATE Productos
SET cantidadEnInventario = cantidadEnInventario+1
WHERE idProducto = 4; 

-- consultas basicas
SELECT * FROM Productos
WHERE cantidadEnInventario >0 AND activo=1;

SELECT p.nombre, p.email, p.telefono
FROM proveedores p 
JOIN transacciones t ON p.idProveedor=t.idProveedor
WHERE t.idProducto=3;

SELECT * FROM transacciones 
WHERE CAST(fechaHora AS DATE) = '2025-01-02';

SELECT SUM(t.cantidad * t.precioUnitario) AS totalCompras
FROM transacciones t
WHERE t.tipo='compra';
 /*
por la logica que definí para la base de datos la parte de eliminar un producto como
requiere la tarea no se realizara sino que se cambiara el campo activo a False(0),
eliminar un producto no se llevara la cantidad del inventario a 0 sino que se dejara inactivo 
como si por desición comercial se sacó ese producto del catalogo
*/
UPDATE Productos
SET activo=0
WHERE idProducto=3;
-- transaccion con commit manual
SET AUTOCOMMIT = 0;
START TRANSACTION;
INSERT INTO transacciones(idProducto, idProveedor, tipo, fechaHora, cantidad, precioUnitario) VALUES
(1, 1, 'venta', '2025-08-04 12:00:00', 10, 17000.00);
UPDATE productos
SET CantidadEnInventario = CantidadEnInventario - 10
WHERE idProducto=1;

COMMIT;

START TRANSACTION;
INSERT INTO transacciones(idProducto, idProveedor, tipo, fechaHora, cantidad, precioUnitario) VALUES
(2, 1, 'venta', '2025-08-04 12:10:00', 10, 6500.00);
UPDATE productos
SET CantidadEnInventario = CantidadEnInventario - 10
WHERE idProducto=2;

SET AUTOCOMMIT = 1;

START TRANSACTION;
INSERT INTO transacciones(idProducto, idProveedor, tipo, fechaHora, cantidad, precioUnitario) VALUES
(2, 1, 'venta', '2025-08-04 12:10:00', 10, 6500.00);
UPDATE productos
SET CantidadEnInventario = CantidadEnInventario - 10
WHERE idProducto=2;

ROLLBACK;






-- bloque de transaccion automatizado
DELIMITER $$

CREATE PROCEDURE registrarTransaccion(
    IN p_idProducto INT,
    IN p_idProveedor INT,
    IN p_tipo ENUM('compra','venta'),
    IN p_cantidad INT,
    IN p_precioUnitario DECIMAL(10,2), -- precio histórico
    IN p_margen DECIMAL(3,2) -- en compras se usará 1.00
)
BEGIN
    DECLARE v_stock INT;
    DECLARE v_activoProd BOOLEAN;
    DECLARE v_activoProv BOOLEAN;

    START TRANSACTION;

    -- Verificar si el producto está activo
    SELECT activo, cantidadEnInventario
    INTO v_activoProd, v_stock
    FROM Productos
    WHERE idProducto = p_idProducto
    FOR UPDATE;

    IF v_activoProd = 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Producto inactivo.';
    END IF;

    -- Verificar si el proveedor está activo
    SELECT activo INTO v_activoProv
    FROM Proveedores
    WHERE idProveedor = p_idProveedor;

    IF v_activoProv = 0 THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error: Proveedor inactivo.';
    END IF;

    -- Validaciones según el tipo de transacción
    IF p_tipo = 'venta' THEN
        -- Stock suficiente
        IF v_stock < p_cantidad THEN
            ROLLBACK;
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: Stock insuficiente para la venta.';
        END IF;

        -- Insertar transacción (venta con margen)
        INSERT INTO Transacciones(idProducto, idProveedor, tipo, fechaHora, cantidad, precioUnitario, margen)
        VALUES (p_idProducto, p_idProveedor, 'venta', NOW(), p_cantidad, p_precioUnitario, p_margen);

        -- Actualizar inventario (restar)
        UPDATE Productos
        SET cantidadEnInventario = cantidadEnInventario - p_cantidad
        WHERE idProducto = p_idProducto;

    ELSEIF p_tipo = 'compra' THEN
        -- Insertar transacción (compra con margen 1.00)
        INSERT INTO Transacciones(idProducto, idProveedor, tipo, fechaHora, cantidad, precioUnitario, margen)
        VALUES (p_idProducto, p_idProveedor, 'compra', NOW(), p_cantidad, p_precioUnitario, 1.00);

        -- Actualizar inventario (sumar)
        UPDATE Productos
        SET cantidadEnInventario = cantidadEnInventario + p_cantidad
        WHERE idProducto = p_idProducto;
    END IF;

    COMMIT;
END$$
DELIMITER ;
/*	
el segundo codigo para transacciones fue realizado con ayuda de IA dada la complejidad de lo
requerido para cumplir con expectativas propias de usabilidad
se creo para permitir manejar las transacciones como un CALL y que automaticamente 
haga revisiones como que la cantidad a vender no sea mayor que la cantidad en inventario
que productos y proveedores se encuentren activos y si todo se cumple modifica el inventario.
si algo no se cumple el error indica el problema, si producto o proveedor inactivo o falta de stock
*/
CALL registrarTransaccion(1, 1, 'venta', 10, 17000.00, 1.00);
-- prueba con un producto inactivo
CALL registrarTransaccion(3, 2, 'compra', 20, 2000.00, 1.00);
-- la diferencia de utilizad entre la transaccion manual y la full automatizada es tremenda
SELECT ROUND(SUM(t.cantidad * t.precioUnitario * t.margen),2) AS totalVentas
FROM transacciones t
WHERE t.tipo='venta';

SELECT * FROM productos;

SELECT p.idProducto, p.nombre AS producto, ROUND(SUM(t.cantidad * t.precioUnitario * t.margen),2) AS totalVentas, pr.nombre AS Proveedor
FROM transacciones t
JOIN productos p ON t.idProducto=p.idProducto
JOIN proveedores pr ON t.idProveedor=pr.idProveedor
WHERE t.tipo='venta'
	AND MONTH(t.fechaHora)=MONTH(CURDATE()- INTERVAL 1 MONTH)
GROUP BY p.idProducto, p.nombre, pr.idProveedor;
-- consulta para revisar productos vendidos en un rango deseado, se puede modifica
-- la fecha deseada o t.tipo para poder ver las compras en ves de las ventas
SELECT p.idProducto, p.nombre FROM productos p
WHERE p.idProducto NOT IN(
	SELECT DISTINCT t.idProducto FROM transacciones t
    WHERE t.tipo = 'venta'
		AND t.fechaHora BETWEEN '2025-01-01' AND  CURDATE()
);
-- el subquery se hizo para cumplir requisitos de la tarea pero se puede hacer lo mismo con el 
-- join que hize arriba para obtener en una consulta informacion producto proveedor y 
-- transaccion que tambien se pide en la tarea

/*
REVISION DEL MODELO EN BASE A 3NF
1NF: TODAS LAS TABLAS TIENEN VALORES ATÓMICOS, NO HAY LISTAS NI ATRIBUTOS REPETIDOS
2NF: EN TODAS LAS TABLAS SUS ATRIBUTOS RESPECTIVOS DEPENDEN EXCLUSIVAMENTE DE LA PRIMARY KEY 
DE LA TABLA
3NF UNA DEPENDENCIA TRANSITIVA SE PRODUCE CUANDO UN ATRIBUTO NO CLAVE DEPENDE DE OTRO ATRIBUTO
NO CLAVE QUE A SU VEZ DEPENDE DE UNA PRIMARY KEY LO CUAL TAMBIEN SE CUMPLE PUES PRECIOUNITARIO
AUNQUE PUEDA PARECER QUE DEPENDE DE PRECIO REALMENTE SOLO DEPENDE DE LA IDTRANSACCION POR QUE
ES UN DATO HISTORICO UNIDO A LA FECHA DE TRANSACCIÓN LO QUE PERMITE QUE SE PUEDA MODIFICAR 
EL PRECIO DE LOS PRODUCTOS SEGUN DETERMINE EL AREA COMERCIAL SIN QUE SE AFECTE LA INTEGRIDAD
DE LOS DATOS
SE SUPONE QUE PODRIA TENER SENTIDO DESNORMALIZAR EN EL CASO DE QUE SE USE DEMASIADO EL REPORTE
DE VENTAS Y SE DECIDIERA AGREGAR UNA COLUMNA PRECIOTOTAL EN TRANSACCIONS QUE DEPENDA DE CANTIDAD
PRECIOUNITARIO Y MARGEN 

*/

