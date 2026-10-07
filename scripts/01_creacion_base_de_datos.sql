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
     
   Script: 01_creacion_base_de_datos.sql
   Descripcion: Creación limpia de la Base de Datos 'Mundial2026'
             utilizando el Collation oficial 'Modern_Spanish_CI_AS'.
*/

USE master;
GO

-- 1. Si la base no existe, la creamos
IF NOT EXISTS (SELECT 1 FROM sys.databases WHERE name = 'Mundial2026')
    CREATE DATABASE Mundial2026 COLLATE Modern_Spanish_CI_AS;
GO

-- 2. Confirmación
USE Mundial2026;
GO
PRINT 'OK: Base de datos [Mundial2026] lista y seleccionada.';
GO