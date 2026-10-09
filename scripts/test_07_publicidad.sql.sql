/*
  Entrega 5 - Script de Testing: Módulo Publicidad
  Fecha: Octubre 2026
  Integrantes: Aleman Flores Matias, Gamarra Bravo Sidney, Perreira Carlos, Villa Brenda
  Descripción: Script de pruebas para validar ABMs de publicidad y generación de espacios,
               demostrando casos de éxito y la agrupación de errores en un único THROW.
*/

USE Mundial2026;
GO

-- =========================================================================================
-- PRUEBAS: sp_GenerarEspaciosPartido
-- =========================================================================================
PRINT '--- PRUEBA 1: Éxito - Generar espacios para un partido válido ---';
BEGIN TRY
    -- Usamos el Partido 3 (Francia vs Alemania) de los datos semilla
    EXEC publicidad.sp_GenerarEspaciosPartido @id_partido = 3;
    PRINT 'ÉXITO: Se generaron los 4 espacios publicitarios para el partido 3.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH
GO

PRINT '--- PRUEBA 2: Error Múltiple - Generar espacios de un partido inexistente ---';
BEGIN TRY
    EXEC publicidad.sp_GenerarEspaciosPartido @id_partido = 999;
    PRINT 'FALLO: El SP permitió generar espacios para un partido fantasma.';
END TRY
BEGIN CATCH
    PRINT 'ÉXITO (Error capturado): ' + ERROR_MESSAGE();
END CATCH
GO

-- =========================================================================================
-- PRUEBAS: sp_RegistrarAnunciante
-- =========================================================================================
PRINT '--- PRUEBA 3: Éxito - Registrar nuevo anunciante ---';
BEGIN TRY
    EXEC publicidad.sp_RegistrarAnunciante @nombre = 'Sony PlayStation';
    PRINT 'ÉXITO: Anunciante registrado correctamente.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH
GO

PRINT '--- PRUEBA 4: Error - Registrar anunciante sin nombre ---';
BEGIN TRY
    EXEC publicidad.sp_RegistrarAnunciante @nombre = '   ';
    PRINT 'FALLO: El SP permitió registrar un anunciante en blanco.';
END TRY
BEGIN CATCH
    PRINT 'ÉXITO (Error capturado): ' + ERROR_MESSAGE();
END CATCH
GO

-- =========================================================================================
-- PRUEBAS: sp_RegistrarCampania
-- =========================================================================================
PRINT '--- PRUEBA 5: Éxito - Registrar nueva campaña ---';
BEGIN TRY
    -- Usamos el anunciante ID 1 (Coca-Cola de los datos semilla)
    EXEC publicidad.sp_RegistrarCampania 
        @nombre = 'Pasión 2026', 
        @fecha_inicio = '2026-05-01', 
        @fecha_fin = '2026-07-30', 
        @id_anunciante = 1;
    PRINT 'ÉXITO: Campaña registrada correctamente.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH
GO

PRINT '--- PRUEBA 6: Error Múltiple - Fechas invertidas y Anunciante inexistente ---';
BEGIN TRY
    -- Acá forzamos DOS errores a la vez para demostrar la validación agrupada
    EXEC publicidad.sp_RegistrarCampania 
        @nombre = 'Campaña Fallida', 
        @fecha_inicio = '2026-12-01', 
        @fecha_fin = '2026-01-01', 
        @id_anunciante = 999;
    PRINT 'FALLO: El SP permitió registrar una campaña con datos inválidos.';
END TRY
BEGIN CATCH
    PRINT 'ÉXITO (Errores agrupados capturados): ' + ERROR_MESSAGE();
END CATCH
GO

-- =========================================================================================
-- PRUEBAS: sp_RegistrarPiezaContenido
-- =========================================================================================
PRINT '--- PRUEBA 7: Éxito - Registrar nueva pieza publicitaria ---';
BEGIN TRY
    -- Usamos la campaña ID 1 de los datos semilla
    EXEC publicidad.sp_RegistrarPiezaContenido 
        @nombre = 'Banner Homepage', 
        @idioma = 'Español', 
        @costo = 15000.00, 
        @id_campania = 1;
    PRINT 'ÉXITO: Pieza registrada correctamente.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH
GO

PRINT '--- PRUEBA 8: Error Múltiple - Costo negativo y Campaña inexistente ---';
BEGIN TRY
    -- Forzamos DOS errores a la vez nuevamente
    EXEC publicidad.sp_RegistrarPiezaContenido 
        @nombre = 'Banner Inválido', 
        @idioma = 'Inglés', 
        @costo = -500.00, 
        @id_campania = 999;
    PRINT 'FALLO: El SP permitió registrar una pieza con costo negativo y sin campaña.';
END TRY
BEGIN CATCH
    PRINT 'ÉXITO (Errores agrupados capturados): ' + ERROR_MESSAGE();
END CATCH
GO

-- =========================================================================================
-- PRUEBAS: sp_AsignarPublicidadPartido (El Algoritmo de Prioridad)
-- =========================================================================================
PRINT '--- PRUEBA 9: Éxito - Asignar publicidad (Partido 1: Argentina vs Argelia) ---';
BEGIN TRY
    -- El Partido 1 ya tiene sus 4 espacios generados por los datos semilla
    EXEC publicidad.sp_AsignarPublicidadPartido @id_partido = 1;
    PRINT 'ÉXITO: Se asignaron las 4 publicidades para el Partido 1 aplicando el algoritmo de prioridad.';
END TRY
BEGIN CATCH
    PRINT 'ERROR INESPERADO: ' + ERROR_MESSAGE();
END CATCH
GO

PRINT '--- PRUEBA 10: Error - Intentar asignar publicidad a un partido sin espacios ---';
BEGIN TRY
    -- Usamos el Partido 2 que no tiene espacios publicitarios generados
    EXEC publicidad.sp_AsignarPublicidadPartido @id_partido = 2;
    PRINT 'FALLO: El SP permitió asignar publicidad a un partido sin slots.';
END TRY
BEGIN CATCH
    PRINT 'ÉXITO (Error capturado): ' + ERROR_MESSAGE();
END CATCH
GO

PRINT '--- PRUEBA 11: Error - Intentar duplicar la asignación (Partido 1) ---';
BEGIN TRY
    -- Volvemos a llamar al SP para el Partido 1 que ya completamos en la Prueba 9
    EXEC publicidad.sp_AsignarPublicidadPartido @id_partido = 1;
    PRINT 'FALLO: El SP permitió asignar la publicidad dos veces al mismo partido.';
END TRY
BEGIN CATCH
    PRINT 'ÉXITO (Error capturado): ' + ERROR_MESSAGE();
END CATCH
GO

-- Verificación final visual:
SELECT ex.ID_espacio, ep.nombre AS slot, pc.nombre AS pieza, ex.orden_prioridad, ex.monto_facturado
FROM publicidad.Exhibicion ex
JOIN publicidad.Espacio_publicitario ep ON ep.ID = ex.ID_espacio
JOIN publicidad.Pieza_Contenido pc ON pc.ID = ex.ID_Pieza;
GO