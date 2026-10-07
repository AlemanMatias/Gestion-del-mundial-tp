/* 
   UNIVERSIDAD NACIONAL DE LA MATANZA (UNLaM)
   Departamento de Ingeniería e Investigaciones Tecnológicas
   Asignatura: Bases de Datos Aplicada (3641)
   Comisión: 02-5600 (Viernes Tarde)
   
   TRABAJO PRÁCTICO - SISTEMA DE REGISTRO Y GESTIÓN DEL MUNDIAL DE FÚTBOL 2026
   
   Integrantes del Grupo:
     - Aleman Flores, Matias Osvaldo
     - Gamarra Bravo, Sidney Maribel
     - Perreira, Carlos Manuel
     - Villa, Brenda
     
   Script: 02_creacion_esquemas.sql
   Descripción: Validación de existencia y creación de los esquemas lógicos de negocio:
                - administracion : Datos maestros, sedes, selecciones y planteles.
                - partido        : Fixture, alineaciones y eventos en cancha.
                - arbitraje      : Padrón de árbitros, idiomas y designaciones.
                - publicidad     : Anunciantes, campañas, espacios y facturación.
   
   Aclaracion: Se utiliza SQL dinámico (EXEC) de forma estrictamente justificada, debido a que CREATE SCHEMA debe ejecutarse como un lote independiente y no puede incluirse directamente dentro de una estructura condicional como IF. Por este motivo, se encapsula la instrucción CREATE SCHEMA mediante EXEC para poder realizar previamente la validación de existencia del esquema.
*/

USE Mundial2026;
GO

-- 1. Esquema: administracion
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'administracion')
BEGIN
    EXEC('CREATE SCHEMA administracion AUTHORIZATION dbo;');
    PRINT 'OK: Esquema [administracion] creado exitosamente.';
END
ELSE
BEGIN
    PRINT 'INFO: El esquema [administracion] ya existe.';
END
GO

-- 2. Esquema: partido
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'partido')
BEGIN
    EXEC('CREATE SCHEMA partido AUTHORIZATION dbo;');
    PRINT 'OK: Esquema [partido] creado exitosamente.';
END
ELSE
BEGIN
    PRINT 'INFO: El esquema [partido] ya existe.';
END
GO

-- 3. Esquema: arbitraje
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'arbitraje')
BEGIN
    EXEC('CREATE SCHEMA arbitraje AUTHORIZATION dbo;');
    PRINT 'OK: Esquema [arbitraje] creado exitosamente.';
END
ELSE
BEGIN
    PRINT 'INFO: El esquema [arbitraje] ya existe.';
END
GO

-- 4. Esquema: publicidad
IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = 'publicidad')
BEGIN
    EXEC('CREATE SCHEMA publicidad AUTHORIZATION dbo;');
    PRINT 'OK: Esquema [publicidad] creado exitosamente.';
END
ELSE
BEGIN
    PRINT 'INFO: El esquema [publicidad] ya existe.';
END
GO

PRINT 'OK: Proceso de validación y creación de esquemas finalizado con éxito.';
GO