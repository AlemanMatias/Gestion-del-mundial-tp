/* 
   UNIVERSIDAD NACIONAL DE LA MATANZA (UNLaM)
   Departamento de Ingeniería e Investigaciones Tecnológicas
   Asignatura: Bases de Datos Aplicada (3641) - Comisión: 02-5600
   
   SCRIPT MAESTRO: RECREACIÓN COMPLETA DE BASE DE DATOS (TEARDOWN & BUILD)
   
   Instrucciones de uso en SSMS:
     1. Abrir este archivo en SQL Server Management Studio (SSMS).
     2. En la barra superior de herramientas, ir a:
        Consulta (Query) -> Modo SQLCMD (SQLCMD Mode)  [Debe quedar tildado]
     3. Presionar F5 (Ejecutar).
   
   Orden estricto de dependencias ejecutado:
     - Teardown: Cierre de conexiones activas y eliminación completa (DROP DATABASE).
     - 01: Creación de base de datos física (Mundial2026).
     - 02: Creación de esquemas lógicos (administracion, partido, arbitraje, publicidad).
     - 03: Creación de tablas, claves primarias, foráneas y restricciones CHECK.
     - 04: Compilación de Stored Procedures del Módulo 1 (Administración).
     - 05: Compilación de Stored Procedures del Módulo 2 (Partidos y Cambios).
     - 00: Carga de datos semilla oficiales para pruebas.
*/

:setvar RUTA "G:\UNLaM\Cursando\bases de datos aplicadas\TP_GRUPAL\Gestion-del-mundial-tp\scripts"

PRINT '======================================================================';
PRINT 'INICIANDO RECONSTRUCCIÓN INTEGRAL DESDE CERO: Mundial2026';
PRINT '======================================================================';

-- -------------------------------------------------------------------------
-- PASO 0: TEARDOWN (Eliminar cualquier versión previa de la base)
-- -------------------------------------------------------------------------
PRINT '>> [0/6] Limpiando conexiones y eliminando base de datos previa...';
USE master;
GO

IF DB_ID('Mundial2026') IS NOT NULL
BEGIN
    ALTER DATABASE Mundial2026 SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Mundial2026;
    PRINT '   + Base de datos anterior eliminada correctamente (DROP DATABASE exitoso).';
END
ELSE
BEGIN
    PRINT '   + No existía base previa. Procediendo a crearla en limpio.';
END
GO

-- -------------------------------------------------------------------------
-- PASO 1: CREACIÓN DE BASE DE DATOS
-- -------------------------------------------------------------------------
PRINT '>> [1/6] Creando base de datos limpia (01_creacion_base_de_datos.sql)...';
:r $(RUTA)\01_creacion_base_de_datos.sql
GO

-- -------------------------------------------------------------------------
-- PASO 2: CREACIÓN DE ESQUEMAS
-- -------------------------------------------------------------------------
PRINT '>> [2/6] Creando esquemas de arquitectura (02_creacion_esquemas.sql)...';
:r $(RUTA)\02_creacion_esquemas.sql
GO

-- -------------------------------------------------------------------------
-- PASO 3: CREACIÓN DE TABLAS Y RESTRICCIONES
-- -------------------------------------------------------------------------
PRINT '>> [3/6] Creando tablas, PKs, FKs y CHECKs (03_creacion_tablas.sql)...';
:r $(RUTA)\03_creacion_tablas.sql
GO

-- -------------------------------------------------------------------------
-- PASO 4: STORED PROCEDURES - MÓDULO 1 (ADMINISTRACIÓN)
-- -------------------------------------------------------------------------
PRINT '>> [4/6] Compilando SPs de Administración (04_sp_administracion.sql)...';
:r $(RUTA)\04_sp_administracion.sql
GO

-- -------------------------------------------------------------------------
-- PASO 5: STORED PROCEDURES - MÓDULO 2 (PARTIDOS Y CAMBIOS)
-- -------------------------------------------------------------------------
PRINT '>> [5/6] Compilando SPs de Partidos y Cambios (05_sp_partidos_y_cambios.sql)...';
:r $(RUTA)\05_sp_partidos_y_cambios.sql
GO

/*
-- -------------------------------------------------------------------------
-- PASO 6: CARGA DE DATOS SEMILLA
-- -------------------------------------------------------------------------
PRINT '>> [6/6] Poblando tablas con datos semilla iniciales (00_datos_semilla.sql)...';
:r $(RUTA)\00_datos_semilla.sql
GO
*/

-- -------------------------------------------------------------------------
-- FINALIZACIÓN Y VERIFICACIÓN
-- -------------------------------------------------------------------------
USE Mundial2026;
GO

PRINT '======================================================================';
PRINT 'RECONSTRUCCIÓN FINALIZADA CON ÉXITO: Base Mundial2026 lista y operativa.';
PRINT '======================================================================';
SELECT 
    (SELECT COUNT(*) FROM sys.tables) AS [Total Tablas Creadas],
    (SELECT COUNT(*) FROM sys.procedures) AS [Total SPs Compilados],
    (SELECT COUNT(*) FROM administracion.Seleccion) AS [Selecciones Semilla],
    (SELECT COUNT(*) FROM administracion.Jugador) AS [Jugadores Semilla];
GO