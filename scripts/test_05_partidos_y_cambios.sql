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
        -- Obtenemos IDs reales de las selecciones
        DECLARE @id_arg INT, @id_pol INT;
        SELECT @id_arg = s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.nombre = 'Argentina';
        SELECT @id_pol = s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.nombre = 'Polonia';

        -- Limpiamos si existiera previamente de una corrida anterior para garantizar éxito
        DELETE FROM partido.Partido WHERE ID_Sede = 1 AND fecha_hora_local = '2026-06-18 17:00:00';

        EXEC partido.sp_CrearPartido 
            @id_sede = 1,                 -- Estadio Azteca (Sede ID 1)
            @id_fase = 1,                 -- Fase de Grupos (Fase ID 1)
            @fecha_hora_local = '2026-06-18 17:00:00',
            @id_local = @id_arg,
            @id_visitante = @id_pol;

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
        DECLARE @id_arg INT;
        SELECT @id_arg = s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.nombre = 'Argentina';

        EXEC partido.sp_CrearPartido 
            @id_sede = 1,
            @id_fase = 1,
            @fecha_hora_local = '2026-06-18 20:00:00',
            @id_local = 9999,             -- Selección inexistente
            @id_visitante = @id_arg;

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
        DECLARE @id_arg INT;
        SELECT @id_arg = s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.nombre = 'Argentina';

        EXEC partido.sp_CrearPartido 
            @id_sede = 1,
            @id_fase = 1,
            @fecha_hora_local = '2026-06-20 18:00:00',
            @id_local = @id_arg,
            @id_visitante = @id_arg;      -- Mismo equipo

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
        DECLARE @id_arg INT, @id_alg INT;
        SELECT @id_arg = s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.nombre = 'Argentina';
        SELECT @id_alg = s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.nombre = 'Argelia';

        EXEC partido.sp_CrearPartido 
            @id_sede = 9999,              -- Sede que no existe
            @id_fase = 1,
            @fecha_hora_local = '2026-06-22 15:00:00',
            @id_local = @id_arg,
            @id_visitante = @id_alg;

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
        DECLARE @id_arg INT, @id_alg INT;
        SELECT @id_arg = s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.nombre = 'Argentina';
        SELECT @id_alg = s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.nombre = 'Argelia';

        EXEC partido.sp_CrearPartido 
            @id_sede = 1,
            @id_fase = 9999,              -- Fase inexistente
            @fecha_hora_local = '2026-06-25 15:00:00',
            @id_local = @id_arg,
            @id_visitante = @id_alg;

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
        DECLARE @id_bra INT, @id_fra INT;
        SELECT @id_bra = s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.nombre = 'Brasil';
        SELECT @id_fra = s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.nombre = 'Francia';

        EXEC partido.sp_CrearPartido 
            @id_sede = 1,                 -- Misma sede (Estadio Azteca) que la prueba EXITO
            @id_fase = 1,
            @fecha_hora_local = '2026-06-18 17:00:00', -- Misma fecha y hora exactas que la Prueba 1
            @id_local = @id_bra,
            @id_visitante = @id_fra;

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
        DECLARE @id_partido_arg INT, @id_sel_arg INT;
        SELECT @id_sel_arg = s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.nombre = 'Argentina';
        SELECT TOP 1 @id_partido_arg = ID FROM partido.Partido WHERE ID_Seleccion_Local = @id_sel_arg OR ID_Seleccion_Visitante = @id_sel_arg;

        EXEC partido.sp_RegistrarFormacion  
            @id_partido = @id_partido_arg,
            @id_seleccion = @id_sel_arg,
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
        DECLARE @id_partido_arg INT, @id_sel_arg INT;
        SELECT @id_sel_arg = s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.nombre = 'Argentina';
        SELECT TOP 1 @id_partido_arg = ID FROM partido.Partido WHERE ID_Seleccion_Local = @id_sel_arg OR ID_Seleccion_Visitante = @id_sel_arg;

        EXEC partido.sp_RegistrarFormacion 
            @id_partido = @id_partido_arg, 
            @id_seleccion = @id_sel_arg, 
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
        DECLARE @id_partido_arg INT, @id_sel_arg INT;
        SELECT @id_sel_arg = s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.nombre = 'Argentina';
        SELECT TOP 1 @id_partido_arg = ID FROM partido.Partido WHERE ID_Seleccion_Local = @id_sel_arg OR ID_Seleccion_Visitante = @id_sel_arg;

        EXEC partido.sp_EliminarFormacion 
            @id_partido = @id_partido_arg, 
            @id_seleccion = @id_sel_arg;

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
        DECLARE @id_partido_arg INT, @id_sel_arg INT;
        SELECT @id_sel_arg = s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.nombre = 'Argentina';
        SELECT TOP 1 @id_partido_arg = ID FROM partido.Partido WHERE ID_Seleccion_Local = @id_sel_arg OR ID_Seleccion_Visitante = @id_sel_arg;

        EXEC partido.sp_EliminarFormacion 
            @id_partido = @id_partido_arg, 
            @id_seleccion = @id_sel_arg; -- Ya la borramos en el paso anterior

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
        DECLARE @id_partido_arg INT, @id_formacion INT, @id_sel_arg INT;
        SELECT @id_sel_arg = s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.nombre = 'Argentina';
        SELECT TOP 1 @id_partido_arg = ID FROM partido.Partido WHERE ID_Seleccion_Local = @id_sel_arg OR ID_Seleccion_Visitante = @id_sel_arg;

        -- Se crea formacion ya que fue eliminada en el test anterior
        EXEC partido.sp_RegistrarFormacion  
            @id_partido = @id_partido_arg,
            @id_seleccion = @id_sel_arg,
            @esquema_tactico = '4-3-3';

        SELECT TOP 1 @id_formacion = ID FROM partido.Formacion_Partido WHERE ID_Partido = @id_partido_arg AND ID_Seleccion = @id_sel_arg;

        EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_formacion, @id_jugador = 1, @es_titular = 1;
        EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_formacion, @id_jugador = 2, @es_titular = 1;
        EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_formacion, @id_jugador = 3, @es_titular = 1;
        EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_formacion, @id_jugador = 4, @es_titular = 1;
        EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_formacion, @id_jugador = 5, @es_titular = 1;
        EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_formacion, @id_jugador = 6, @es_titular = 1;
        EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_formacion, @id_jugador = 7, @es_titular = 1;
        EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_formacion, @id_jugador = 8, @es_titular = 1;
        EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_formacion, @id_jugador = 9, @es_titular = 1;
        EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_formacion, @id_jugador = 10, @es_titular = 1;
        EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_formacion, @id_jugador = 11, @es_titular = 1;
                                                            
        --SUPLENTES                                         
        EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_formacion, @id_jugador = 12, @es_titular = 0; 
        EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_formacion, @id_jugador = 13, @es_titular = 0; 
        EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_formacion, @id_jugador = 14, @es_titular = 0; 
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
        DECLARE @id_formacion INT, @id_sel_arg INT;
        SELECT @id_sel_arg = s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.nombre = 'Argentina';
        SELECT TOP 1 @id_formacion = fp.ID FROM partido.Formacion_Partido fp WHERE fp.ID_Seleccion = @id_sel_arg ORDER BY fp.ID DESC;

        EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_formacion, @id_jugador = 12, @es_titular = 1;

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
        DECLARE @id_formacion INT, @id_sel_arg INT;
        SELECT @id_sel_arg = s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.nombre = 'Argentina';
        SELECT TOP 1 @id_formacion = fp.ID FROM partido.Formacion_Partido fp WHERE fp.ID_Seleccion = @id_sel_arg ORDER BY fp.ID DESC;

        EXEC partido.sp_EliminarAlineacion @id_formacion = @id_formacion, @id_jugador = 11;

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
        DECLARE @id_partido_ventana INT, @id_sel_arg INT;
        SELECT @id_sel_arg = s.ID FROM administracion.Seleccion s JOIN administracion.Pais p ON p.ID = s.ID_Pais WHERE p.nombre = 'Argentina';
        SELECT TOP 1 @id_partido_ventana = ID FROM partido.Partido WHERE ID_Seleccion_Local = @id_sel_arg OR ID_Seleccion_Visitante = @id_sel_arg;

        -- Ventana 1 (Minuto 60)
        BEGIN TRY EXEC partido.sp_RegistrarSustitucion @id_partido_ventana, 1, 13, 60, 'Lesion'; PRINT 'Ventana 1: OK'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;

        -- Ventana 2 (Minuto 70)
        BEGIN TRY EXEC partido.sp_RegistrarSustitucion @id_partido_ventana, 2, 12, 70, 'Tactico'; PRINT 'Ventana 2: OK'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;

        -- Ventana 3 (Minuto 80)
        BEGIN TRY EXEC partido.sp_RegistrarSustitucion @id_partido_ventana, 3, 14, 80, 'Tactico'; PRINT 'Ventana 3: OK'; END TRY BEGIN CATCH PRINT ERROR_MESSAGE(); END CATCH;

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