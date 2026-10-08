/*
  Entrega 5 - Script de Testing: partido.sp_CrearPartido
  Fecha: Octubre 2026
  Integrantes: Aleman Flores Matias, Gamarra Bravo Sidney, Perreira Carlos, Villa Brenda
  Descripción: Script de pruebas para validar el procedimiento de creación de partidos,
                alta/actualizacion/bajas de formacion_tactica y alineacion,
                registro de sustituciones en un partido
               .
*/

USE Mundial2026;
GO

--PRUEBAS DE CREACION DE PARTIDOS - CASO DE EXITO Y DE FALLOS 
    --------------------------------------------------------------------------------
    -- PRUEBA 1: CASO DE ÉXITO
    -- Resultado esperado: El partido se crea correctamente calculando su hora UTC 
    -- y se generan sus espacios publicitarios vinculados.

    --DATO: PARA QUE FUNCIONE DEBE CREARSE Y CARGARSE ANTES LAS TABLAS DE SELECCION, FASE,...ETC. porque se tienen que validar los datos
    --------------------------------------------------------------------------------
    PRINT '--- INICIO PRUEBA 1: Crear partido exitoso ---';
    BEGIN TRY
        EXEC partido.sp_CrearPartido 
            @id_sede = 1,                 -- Estadio Azteca (Sede ID 1)
            @id_fase = 1,                 -- Fase de Grupos (Fase ID 1)
            @fecha_hora_local = '2026-06-16 17:00:00',
            @id_local = 1,                -- Argentina (Selección ID 1)
            @id_visitante = 2;            -- Argelia (Selección ID 2)

        PRINT 'ÉXITO: El partido se creó correctamente y pasó la prueba.';
    END TRY
    BEGIN CATCH
        PRINT 'FALLÓ LA PRUEBA : ' + ERROR_MESSAGE();
    END CATCH
    GO

    select * from partido.Partido
    --------------------------------------------------------------------------------
    -- PRUEBA 2: CASO DE ERROR (50001) - Selecciones que no existen
    -- Resultado esperado: La ejecución falla y captura el error
    --------------------------------------------------------------------------------
    PRINT '--- INICIO PRUEBA 2: Error por selecciones inexistentes ---';
    BEGIN TRY
        EXEC partido.sp_CrearPartido 
            @id_sede = 1,
            @id_fase = 1,
            @fecha_hora_local = '2026-06-18 20:00:00',
            @id_local = 999,              -- Selección inexistente
            @id_visitante = 2;

        PRINT 'FALLO: Debería haber dado error de selección inexistente y no lo dio.';
    END TRY
    BEGIN CATCH
        PRINT 'ÉXITO - Error capturado correctamente: ' + ERROR_MESSAGE();
    END CATCH
    GO

    --------------------------------------------------------------------------------
    -- PRUEBA 3: CASO DE ERROR (50002) - Misma selección local y visitante
    -- Resultado esperado: La ejecución falla y captura el error 
    --------------------------------------------------------------------------------
    PRINT '--- INICIO PRUEBA 3: Error por selecciones idénticas ---';
    BEGIN TRY
        EXEC partido.sp_CrearPartido 
            @id_sede = 1,
            @id_fase = 1,
            @fecha_hora_local = '2026-06-20 18:00:00',
            @id_local = 1,                -- Argentina
            @id_visitante = 1;            -- Argentina (Mismo equipo)

        PRINT 'FALLO: Debería haber dado error por equipos iguales y no lo dio.';
    END TRY
    BEGIN CATCH
        PRINT 'ÉXITO - Error capturado correctamente: ' + ERROR_MESSAGE();
    END CATCH
    GO

    --------------------------------------------------------------------------------
    -- PRUEBA 4: CASO DE ERROR (50003) - Sede inexistente
    -- Resultado esperado: La ejecución falla y captura el error
    --------------------------------------------------------------------------------
    PRINT '--- INICIO PRUEBA 4: Error por sede inexistente ---';
    BEGIN TRY
        EXEC partido.sp_CrearPartido 
            @id_sede = 999,               -- Sede que no existe
            @id_fase = 1,
            @fecha_hora_local = '2026-06-22 15:00:00',
            @id_local = 1,
            @id_visitante = 2;

        PRINT 'FALLO: Debería haber dado error por sede inexistente y no lo dio.';
    END TRY
    BEGIN CATCH
        PRINT 'ÉXITO - Error capturado correctamente: ' + ERROR_MESSAGE();
    END CATCH
    GO

    --------------------------------------------------------------------------------
    -- PRUEBA 5: CASO DE ERROR (50004) - Fase del torneo no válida
    -- Resultado esperado: La ejecución falla y captura el error 
    --------------------------------------------------------------------------------
    PRINT '--- INICIO PRUEBA 5: Error por fase inválida ---';
    BEGIN TRY
        EXEC partido.sp_CrearPartido 
            @id_sede = 1,
            @id_fase = 99,                -- Fase inexistente
            @fecha_hora_local = '2026-06-25 15:00:00',
            @id_local = 1,
            @id_visitante = 2;

        PRINT 'FALLO: Debería haber dado error por fase inválida y no lo dio.';
    END TRY
    BEGIN CATCH
        PRINT 'ÉXITO - Error capturado correctamente: ' + ERROR_MESSAGE();
    END CATCH
    GO

    --------------------------------------------------------------------------------
    -- PRUEBA 6: CASO DE ERROR (50006) - Solapamiento de partidos en la misma sede y hora
    -- Resultado esperado: falla y captura el error indicando que la sede ya tiene un partido en ese horario.
    --------------------------------------------------------------------------------
    PRINT '--- INICIO PRUEBA 6: Error por solapamiento de sede y hora ---';

    -- 2. Intentamos insertar otro partido en la MISMA sede y MISMO horario
    BEGIN TRY
        EXEC partido.sp_CrearPartido 
            @id_sede = 1,                 -- Misma sede (Estadio Azteca) que la prueba EXITO
            @id_fase = 1,
            @fecha_hora_local = '2026-06-30 16:00:00', -- Misa fecha y hora exactas
            @id_local = 5,                -- Otro equipo (ej: Francia)
            @id_visitante = 6;            -- Otro equipo (ej: Alemania)

        PRINT '>> FALLO: Debería haber bloqueado el solapamiento en la sede y no lo hizo.';
    END TRY
    BEGIN CATCH
        PRINT '>> ÉXITO - Error de solapamiento capturado correctamente: ' + ERROR_MESSAGE();
    END CATCH
    GO


--------------------------------------------------------------------------------
-- ALTA/ACTUALIZACION/BAJA FORMACION -CASO DE EXITOS Y FALLO

    --DATO : SE USO DATOS DE TABLAS PARTIDO,SELECCION, CREADAS EN 00_SEMILLAS
    --------------------------------------------------------------------------------
    -- PRUEBA 1: ALTA EXITOSA - Registrar una formación inicial
    --------------------------------------------------------------------------------
    PRINT '--- PRUEBA 1: Registrar formación (Alta) ---';
    BEGIN TRY
        EXEC partido.sp_RegistrarFormacion  
            @id_partido = 2, -- argentina - argelia 
            @id_seleccion = 1, -- seleccion argentina 
            @esquema_tactico = '4-3-3';

        PRINT 'ÉXITO: Formación 4-3-3 registrada correctamente.';
    END TRY
    BEGIN CATCH
        PRINT ' ERROR: ' + ERROR_MESSAGE();
    END CATCH
    GO

    
    SELECT * FROM partido.Formacion_Partido
    SELECT * FROM partido.Partido
    --------------------------------------------------------------------------------
    -- PRUEBA 2: MODIFICACIÓN EXITOSA - modificar la formacion antes del partido
    --------------------------------------------------------------------------------
    PRINT '--- PRUEBA 2: Modificar formación existente (Update automático) ---';
    BEGIN TRY
        EXEC partido.sp_RegistrarFormacion 
            @id_partido = 1, 
            @id_seleccion = 1, 
            @esquema_tactico = '4-4-2';

        PRINT 'ÉXITO: La formación se actualizó a 4-4-2 correctamente.';
    END TRY
    BEGIN CATCH
        PRINT 'ERROR: ' + ERROR_MESSAGE();
    END CATCH
    GO

    SELECT * FROM partido.Formacion_Partido

    --------------------------------------------------------------------------------
    -- PRUEBA 3: BAJA EXITOSA - Eliminar una formación
    --------------------------------------------------------------------------------
    PRINT '--- PRUEBA 3: Eliminar formación (Baja) ---';
    BEGIN TRY
        EXEC partido.sp_EliminarFormacion 
            @id_partido = 1, 
            @id_seleccion = 1;

        PRINT 'ÉXITO: Formación eliminada correctamente de la base de datos.';
    END TRY
    BEGIN CATCH
        PRINT 'ERROR: ' + ERROR_MESSAGE();
    END CATCH
    GO

    SELECT * FROM partido.Formacion_Partido
    --------------------------------------------------------------------------------
    -- PRUEBA 4: CASO DE ERROR (50013) - Intentar eliminar una formación que no existe
    --------------------------------------------------------------------------------
    PRINT '--- PRUEBA 4: Error al intentar eliminar formación inexistente ---';
    BEGIN TRY
        EXEC partido.sp_EliminarFormacion 
            @id_partido = 1, 
            @id_seleccion = 1; -- Ya la borramos en el paso anterior

        PRINT 'FALLO: Debería haber indicado que no existe la formación a borrar.';
    END TRY
    BEGIN CATCH
        PRINT 'ÉXITO - Error capturado correctamente (50013): ' + ERROR_MESSAGE();
    END CATCH
    GO



---ALTA/ACTUALIZACION/BAJA ALINEACION 
    
    --DATO: CREAR ANTES LA TABLA DE FORMACION_TACTICA , es la PRUEBA 1 que esta antes 
    --------------------------------------------------------------------------------
    -- PRUEBAS 1 a 11: Registrar los primeros 11 jugadores como TITULARES
    --------------------------------------------------------------------------------
    PRINT '--- PRUEBAS 1 a 11: Registrando los 11 titulares permitidos ---';
    BEGIN TRY
        EXEC partido.sp_RegistrarAlineacion @id_formacion = 1, @id_jugador = 1, @es_titular = 1;
        EXEC partido.sp_RegistrarAlineacion @id_formacion = 1, @id_jugador = 2, @es_titular = 1;
        EXEC partido.sp_RegistrarAlineacion @id_formacion = 1, @id_jugador = 3, @es_titular = 1;
        EXEC partido.sp_RegistrarAlineacion @id_formacion = 1, @id_jugador = 4, @es_titular = 1;
        EXEC partido.sp_RegistrarAlineacion @id_formacion = 1, @id_jugador = 5, @es_titular = 1;
        EXEC partido.sp_RegistrarAlineacion @id_formacion = 1, @id_jugador = 6, @es_titular = 1;
        EXEC partido.sp_RegistrarAlineacion @id_formacion = 1, @id_jugador = 7, @es_titular = 1;
        EXEC partido.sp_RegistrarAlineacion @id_formacion = 1, @id_jugador = 8, @es_titular = 1;
        EXEC partido.sp_RegistrarAlineacion @id_formacion = 1, @id_jugador = 9, @es_titular = 1;
        EXEC partido.sp_RegistrarAlineacion @id_formacion = 1, @id_jugador = 10, @es_titular = 1;
        EXEC partido.sp_RegistrarAlineacion @id_formacion = 1, @id_jugador = 11, @es_titular = 1;

        --SUPLENTES
        EXEC partido.sp_RegistrarAlineacion @id_formacion = 1, @id_jugador = 12, @es_titular = 0; 
        EXEC partido.sp_RegistrarAlineacion @id_formacion = 1, @id_jugador = 13, @es_titular = 0;
        EXEC partido.sp_RegistrarAlineacion @id_formacion = 1, @id_jugador = 14, @es_titular = 0; 
        PRINT 'ÉXITO: Los 11 primeros titulares se registraron correctamente.';
    END TRY
    BEGIN CATCH
        PRINT 'ERROR EN LAS PRUEBAS 1-11: ' + ERROR_MESSAGE();
    END CATCH
    GO

    select * from partido.Alineacion
    --------------------------------------------------------------------------------
    -- PRUEBA 2: - Intentar registrar el titular 12
    --------------------------------------------------------------------------------
    PRINT '--- PRUEBA 12: Intentar agregar un titular 12 (Debe fallar) ---';
    BEGIN TRY
        EXEC partido.sp_RegistrarAlineacion @id_formacion = 1, @id_jugador = 12, @es_titular = 1;

        PRINT 'FALLO: El sistema permitió registrar más de 11 titulares.';
    END TRY
    BEGIN CATCH
        PRINT 'ÉXITO - Error capturado correctamente (50023): ' + ERROR_MESSAGE();
    END CATCH
    GO

    --------------------------------------------------------------------------------
    -- PRUEBA 3: BAJA - Eliminar a un jugador de la alineación
    --------------------------------------------------------------------------------
    PRINT '--- PRUEBA 13: Eliminar al jugador 11 de la alineación (Baja) ---';
    BEGIN TRY
        EXEC partido.sp_EliminarAlineacion @id_formacion = 1, @id_jugador = 11;

        PRINT 'ÉXITO: Jugador 11 eliminado correctamente de la alineación.';
    END TRY
    BEGIN CATCH
        PRINT 'ERROR EN BAJA: ' + ERROR_MESSAGE();
    END CATCH
    GO

    select * from partido.Alineacion



--REGISTRAR SUSTITUCION 

    -- =========================================================================
    -- PRUEBA 1: Intento de realizar una 4ta ventana de sustitución fallida
    -- Resultado esperado: Hacer cambios en 3 minutos distintos consume las 3 ventanas.
    -- Un 4to cambio en un minuto diferente al de los anteriores debe disparar el THROW 50037.
    -- =========================================================================

    PRINT '--- Probando límite de 3 ventanas ---';
    BEGIN
        -- Limpiamos o usamos un partido nuevo donde se hagan cambios individuales en minutos separados
        DECLARE @id_partido_ventana INT = 2; -- Asumimos otro partido de prueba

        -- Ventana 1 (Minuto 60)
        BEGIN TRY EXEC partido.sp_RegistrarSustitucion @id_partido_ventana, 1, 13, 60, 'Lesion'; PRINT 'Ventana 1: OK'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;

        -- Ventana 2 (Minuto 70)
        BEGIN TRY EXEC partido.sp_RegistrarSustitucion @id_partido_ventana, 2, 12, 70, 'Tactico'; PRINT 'Ventana 2: OK'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;

        -- Ventana 3 (Minuto 80)
        BEGIN TRY EXEC partido.sp_RegistrarSustitucion @id_partido_ventana, 3, 14, 80, 'Tactico'; PRINT 'Ventana 3: OK'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;


        --para probar correctamente la 4ta ventana se debe agregar mas jugadores de la seleccion argentina en 00_semillas
        --ya que si son 14 , hay 11 titulares , 3 suplentes -> no es posible un 4to cambio , una 4ta ventana ( si los 3 cambios 
        --se realizan en ventanas distintas) 

        -- INTENTO DE 4TA VENTANA (Minuto 88 - Minuto distinto a 60, 70 y 80)
        BEGIN TRY 
            EXEC partido.sp_RegistrarSustitucion @id_partido_ventana, 4, 15, 88, 'Tactico'; 
            PRINT '¡Error! La 4ta ventana pasó y debería haber sido bloqueada.'; 
        END TRY 
        BEGIN CATCH 
            PRINT 'EXITO EN LA PRUEBA (4ta ventana bloqueada correctamente): ' + ERROR_MESSAGE(); 
        END CATCH;
    END;
    GO

    PRINT '=== FIN DE PRUEBAS DE SUSTITUCIONES ===';
    GO