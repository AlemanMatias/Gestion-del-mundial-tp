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
     
   Script: test_04_administracion.sql
   Descripción: Lote de pruebas unitarias para los Stored Procedures de 04_sp_administracion.sql.
                Valida casos de éxito y captura de excepciones.
                Ejecuta de forma aislada (ROLLBACK) y consolida un reporte visual en la grilla de Resultados.
*/

USE Mundial2026;
GO

SET NOCOUNT ON;

-- Tabla en memoria para consolidar el reporte visual final (inmune a ROLLBACK)
DECLARE @Reporte TABLE (
    ID INT IDENTITY(1,1),
    Procedimiento VARCHAR(50),
    Escenario VARCHAR(60),
    Tipo_Prueba VARCHAR(25),
    Resultado VARCHAR(10),
    Detalle VARCHAR(255)
);

PRINT '======================================================================';
PRINT 'INICIANDO LOTE DE PRUEBAS 1:1 - MÓDULO ADMINISTRACIÓN (04)';
PRINT '======================================================================';

-- =========================================================================================
-- 1. PRUEBAS: administracion.Pais (Alta, Modificación, Baja)
-- =========================================================================================
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @id_pais_test INT;

    -- 1.A. Inserción exitosa
    EXEC administracion.sp_InsertarPais
        @nombre = 'País Prueba Test',
        @pbi_percapita = 45000.50,
        @huso_horario = '+02:00',
        @id_generado = @id_pais_test OUTPUT;

    INSERT INTO @Reporte VALUES ('sp_InsertarPais', 'Alta exitosa con PBI y huso', 'Caso de Éxito', 'OK', 'Generó ID: ' + CAST(@id_pais_test AS VARCHAR(10)));

    -- 1.B. Error: Nombre duplicado
    BEGIN TRY
        EXEC administracion.sp_InsertarPais
            @nombre = 'País Prueba Test',
            @id_generado = @id_pais_test OUTPUT;
        INSERT INTO @Reporte VALUES ('sp_InsertarPais', 'Bloqueo por nombre duplicado', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50002');
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_InsertarPais', 'Bloqueo por nombre duplicado', 'Validación THROW', 'OK', 'Capturado 50002: ' + ERROR_MESSAGE());
    END CATCH;

    -- 1.C. Modificación exitosa
    EXEC administracion.sp_ModificarPais
        @id = @id_pais_test,
        @nombre = 'País Prueba Modificado',
        @pbi_percapita = 50000.00,
        @huso_horario = '+03:00';
    INSERT INTO @Reporte VALUES ('sp_ModificarPais', 'Actualización correcta de datos', 'Caso de Éxito', 'OK', 'Modificado ID: ' + CAST(@id_pais_test AS VARCHAR(10)));

    -- 1.D. Eliminación exitosa
    EXEC administracion.sp_EliminarPais @id = @id_pais_test;
    INSERT INTO @Reporte VALUES ('sp_EliminarPais', 'Baja física de país sin relaciones', 'Caso de Éxito', 'OK', 'Eliminado correctamente');

END TRY
BEGIN CATCH
    INSERT INTO @Reporte VALUES ('Pais', 'Fallo general en bloque', 'Error', 'FALLÓ', ERROR_MESSAGE());
END CATCH;
ROLLBACK TRANSACTION;


-- =========================================================================================
-- 1.BIS. PRUEBAS: administracion.Sede (Alta, Modificación, Baja)
-- =========================================================================================
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @id_pais_sede INT, @id_sede_test INT;
    EXEC administracion.sp_InsertarPais @nombre = 'País Sede Test', @id_generado = @id_pais_sede OUTPUT;

    -- Sede Alta exitosa
    EXEC administracion.sp_InsertarSede
        @nombre = 'Estadio Prueba Central',
        @ciudad = 'Ciudad Deportiva',
        @capacidad = 60000,
        @huso_horario = '-03:00',
        @id_pais = @id_pais_sede,
        @id_generado = @id_sede_test OUTPUT;
    INSERT INTO @Reporte VALUES ('sp_InsertarSede', 'Alta de estadio reglamentario', 'Caso de Éxito', 'OK', 'Sede ID: ' + CAST(@id_sede_test AS VARCHAR(10)));

    -- Sede Error: Formato de huso horario incorrecto
    BEGIN TRY
        EXEC administracion.sp_InsertarSede
            @nombre = 'Estadio Fallido',
            @ciudad = 'Ciudad Deportiva',
            @capacidad = 50000,
            @huso_horario = 'GMT-3', -- inválido
            @id_pais = @id_pais_sede,
            @id_generado = @id_sede_test OUTPUT;
        INSERT INTO @Reporte VALUES ('sp_InsertarSede', 'Bloqueo por huso horario fuera de formato', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50033');
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_InsertarSede', 'Bloqueo por huso horario fuera de formato', 'Validación THROW', 'OK', 'Capturado 50033: ' + ERROR_MESSAGE());
    END CATCH;

    -- Sede Modificación exitosa
    EXEC administracion.sp_ModificarSede
        @id = @id_sede_test,
        @nombre = 'Estadio Prueba Remodelado',
        @ciudad = 'Ciudad Deportiva',
        @capacidad = 65000,
        @huso_horario = '-03:00',
        @id_pais = @id_pais_sede;
    INSERT INTO @Reporte VALUES ('sp_ModificarSede', 'Ampliación de capacidad de estadio', 'Caso de Éxito', 'OK', 'Modificado ID: ' + CAST(@id_sede_test AS VARCHAR(10)));

    -- Sede Baja exitosa
    EXEC administracion.sp_EliminarSede @id = @id_sede_test;
    INSERT INTO @Reporte VALUES ('sp_EliminarSede', 'Baja de estadio sin partidos', 'Caso de Éxito', 'OK', 'Eliminado correctamente');

END TRY
BEGIN CATCH
    INSERT INTO @Reporte VALUES ('Sede', 'Fallo general en bloque', 'Error', 'FALLÓ', ERROR_MESSAGE());
END CATCH;
ROLLBACK TRANSACTION;


-- =========================================================================================
-- 2. PRUEBAS: administracion.Seleccion (Cupos FIFA y Grupos)
-- =========================================================================================
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @id_pais_sel INT, @id_sel_test INT;

    EXEC administracion.sp_InsertarPais @nombre = 'País Selección Test', @pbi_percapita = 30000, @huso_horario = '+00:00', @id_generado = @id_pais_sel OUTPUT;

    -- 2.A. Alta exitosa
    EXEC administracion.sp_InsertarSeleccion
        @id_pais = @id_pais_sel,
        @confederacion = 'UEFA',
        @grupo_asignado = 'B',
        @id_generado = @id_sel_test OUTPUT;
    INSERT INTO @Reporte VALUES ('sp_InsertarSeleccion', 'Asignación correcta a Grupo B', 'Caso de Éxito', 'OK', 'Selección ID: ' + CAST(@id_sel_test AS VARCHAR(10)));

    -- 2.B. Error: Confederación inválida
    BEGIN TRY
        EXEC administracion.sp_InsertarSeleccion @id_pais = @id_pais_sel, @confederacion = 'LIGA_FANTASMA', @grupo_asignado = 'B', @id_generado = @id_sel_test OUTPUT;
        INSERT INTO @Reporte VALUES ('sp_InsertarSeleccion', 'Bloqueo por confederación inválida', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50042');
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_InsertarSeleccion', 'Bloqueo por confederación inválida', 'Validación THROW', 'OK', 'Capturado 50042');
    END CATCH;

    -- 2.C. Error: Grupo fuera de rango (ej: Grupo Z)
    BEGIN TRY
        DECLARE @id_pais_otro INT;
        EXEC administracion.sp_InsertarPais @nombre = 'País Grupo Z', @id_generado = @id_pais_otro OUTPUT;
        EXEC administracion.sp_InsertarSeleccion @id_pais = @id_pais_otro, @confederacion = 'UEFA', @grupo_asignado = 'Z', @id_generado = @id_sel_test OUTPUT;
        INSERT INTO @Reporte VALUES ('sp_InsertarSeleccion', 'Bloqueo por grupo fuera de A-L', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50043');
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_InsertarSeleccion', 'Bloqueo por grupo fuera de A-L', 'Validación THROW', 'OK', 'Capturado 50043');
    END CATCH;

END TRY
BEGIN CATCH
    INSERT INTO @Reporte VALUES ('Seleccion', 'Fallo general en bloque', 'Error', 'FALLÓ', ERROR_MESSAGE());
END CATCH;
ROLLBACK TRANSACTION;


-- =========================================================================================
-- 3. PRUEBAS: administracion.Jugador
-- =========================================================================================
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @id_club_test INT, @id_jug_test INT;
    EXEC administracion.sp_InsertarClub @nombre = 'Club Test FC', @id_generado = @id_club_test OUTPUT;

    -- 3.A. Alta exitosa
    EXEC administracion.sp_InsertarJugador
        @nombre = 'Lautaro', @apellido = 'Test',
        @fecha_nacimiento = '2000-01-01', @id_club = @id_club_test,
        @posicion_habitual = 'Delantero', @id_generado = @id_jug_test OUTPUT;
    INSERT INTO @Reporte VALUES ('sp_InsertarJugador', 'Alta de jugador mayor a 15 años', 'Caso de Éxito', 'OK', 'Jugador ID: ' + CAST(@id_jug_test AS VARCHAR(10)));

    -- 3.B. Error: Menor a 15 años
    BEGIN TRY
        EXEC administracion.sp_InsertarJugador
            @nombre = 'Niño', @apellido = 'Test',
            @fecha_nacimiento = '2020-01-01', @id_club = @id_club_test,
            @posicion_habitual = 'Delantero', @id_generado = @id_jug_test OUTPUT;
        INSERT INTO @Reporte VALUES ('sp_InsertarJugador', 'Bloqueo por edad menor a 15 años', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50063');
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_InsertarJugador', 'Bloqueo por edad menor a 15 años', 'Validación THROW', 'OK', 'Capturado 50063');
    END CATCH;

END TRY
BEGIN CATCH
    INSERT INTO @Reporte VALUES ('Jugador', 'Fallo general en bloque', 'Error', 'FALLÓ', ERROR_MESSAGE());
END CATCH;
ROLLBACK TRANSACTION;


-- =========================================================================================
-- 4. PRUEBAS: administracion.Miembro_Cuerpo_Tecnico (Roles FIFA y Bloqueo 1 DT)
-- =========================================================================================
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @id_pais_ct INT, @id_sel_ct INT;
    DECLARE @id_dt_test INT, @id_ayudante_test INT;

    EXEC administracion.sp_InsertarPais @nombre = 'País Cuerpo Técnico Test', @id_generado = @id_pais_ct OUTPUT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_pais_ct, @confederacion = 'CONMEBOL', @grupo_asignado = 'H', @id_generado = @id_sel_ct OUTPUT;

    -- 4.A. Alta exitosa de Director Técnico principal
    EXEC administracion.sp_InsertarMiembroCuerpoTecnico
        @nombre = 'Lionel', @apellido = 'Scaloni Test',
        @rol = 'Director Técnico', @id_seleccion = @id_sel_ct,
        @id_generado = @id_dt_test OUTPUT;

    INSERT INTO @Reporte VALUES ('sp_InsertarMiembroCuerpoTecnico', 'Alta exitosa de Director Técnico principal', 'Caso de Éxito', 'OK', 'DT ID: ' + CAST(@id_dt_test AS VARCHAR(10)));

    -- 4.B. Error: Bloqueo anti-"carnicero" (Rol no oficial)
    BEGIN TRY
        EXEC administracion.sp_InsertarMiembroCuerpoTecnico
            @nombre = 'Juan', @apellido = 'Pérez',
            @rol = 'Carnicero', @id_seleccion = @id_sel_ct,
            @id_generado = @id_ayudante_test OUTPUT;
        INSERT INTO @Reporte VALUES ('sp_InsertarMiembroCuerpoTecnico', 'Bloqueo de rol no oficial (Carnicero)', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50052');
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_InsertarMiembroCuerpoTecnico', 'Bloqueo de rol no oficial (Carnicero)', 'Validación THROW', 'OK', 'Capturado 50052: ' + ERROR_MESSAGE());
    END CATCH;

    -- 4.C. Error: Bloqueo de 2do Director Técnico principal en la misma selección
    BEGIN TRY
        EXEC administracion.sp_InsertarMiembroCuerpoTecnico
            @nombre = 'Marcelo', @apellido = 'Gallardo Test',
            @rol = 'Director Técnico', @id_seleccion = @id_sel_ct,
            @id_generado = @id_ayudante_test OUTPUT;
        INSERT INTO @Reporte VALUES ('sp_InsertarMiembroCuerpoTecnico', 'Bloqueo de 2do DT principal en misma selección', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50054');
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_InsertarMiembroCuerpoTecnico', 'Bloqueo de 2do DT principal en misma selección', 'Validación THROW', 'OK', 'Capturado 50054: ' + ERROR_MESSAGE());
    END CATCH;

    -- 4.D. Alta exitosa de Ayudante de Campo (Rol secundario permitido)
    EXEC administracion.sp_InsertarMiembroCuerpoTecnico
        @nombre = 'Pablo', @apellido = 'Aimar Test',
        @rol = 'Ayudante de Campo', @id_seleccion = @id_sel_ct,
        @id_generado = @id_ayudante_test OUTPUT;

    INSERT INTO @Reporte VALUES ('sp_InsertarMiembroCuerpoTecnico', 'Alta exitosa de Ayudante de Campo', 'Caso de Éxito', 'OK', 'Ayudante ID: ' + CAST(@id_ayudante_test AS VARCHAR(10)));

    -- 4.E. Modificación exitosa
    EXEC administracion.sp_ModificarMiembroCuerpoTecnico
        @id = @id_ayudante_test,
        @nombre = 'Pablo César', @apellido = 'Aimar Test',
        @rol = 'Preparador Físico', @id_seleccion = @id_sel_ct;

    INSERT INTO @Reporte VALUES ('sp_ModificarMiembroCuerpoTecnico', 'Modificación de rol a Preparador Físico', 'Caso de Éxito', 'OK', 'Actualizado correctamente');

    -- 4.F. Baja exitosa
    EXEC administracion.sp_EliminarMiembroCuerpoTecnico @id = @id_ayudante_test;
    INSERT INTO @Reporte VALUES ('sp_EliminarMiembroCuerpoTecnico', 'Baja de miembro sin tarjetas asociadas', 'Caso de Éxito', 'OK', 'Eliminado correctamente');

END TRY
BEGIN CATCH
    INSERT INTO @Reporte VALUES ('CuerpoTecnico', 'Fallo general en bloque', 'Error', 'FALLÓ', ERROR_MESSAGE());
END CATCH;
ROLLBACK TRANSACTION;


-- =========================================================================================
-- 5. PRUEBAS: Convocatorias, Dorsales FIFA (1 al 26) y Reemplazo Atómico
-- =========================================================================================
BEGIN TRANSACTION;
BEGIN TRY
    DECLARE @id_pais_conv INT, @id_sel_conv INT, @id_club_conv INT;
    DECLARE @id_arq INT, @id_del INT, @id_reemplazo INT;
    DECLARE @id_conv INT, @id_conv_reemplazo INT;

    EXEC administracion.sp_InsertarPais @nombre = 'País Convocatoria', @id_generado = @id_pais_conv OUTPUT;
    EXEC administracion.sp_InsertarSeleccion @id_pais = @id_pais_conv, @confederacion = 'CONMEBOL', @grupo_asignado = 'K', @id_generado = @id_sel_conv OUTPUT;
    EXEC administracion.sp_InsertarClub @nombre = 'Club Convocatoria', @id_generado = @id_club_conv OUTPUT;

    -- Crear 1 arquero y 2 jugadores de campo
    EXEC administracion.sp_InsertarJugador @nombre = 'Emiliano', @apellido = 'Arquero', @fecha_nacimiento = '1992-09-02', @id_club = @id_club_conv, @posicion_habitual = 'Arquero', @id_generado = @id_arq OUTPUT;
    EXEC administracion.sp_InsertarJugador @nombre = 'Nico', @apellido = 'Lesionado', @fecha_nacimiento = '1998-04-06', @id_club = @id_club_conv, @posicion_habitual = 'Delantero', @id_generado = @id_del OUTPUT;
    EXEC administracion.sp_InsertarJugador @nombre = 'Ángel', @apellido = 'Sustituto', @fecha_nacimiento = '1995-03-09', @id_club = @id_club_conv, @posicion_habitual = 'Delantero', @id_generado = @id_reemplazo OUTPUT;

    -- 4.A. Convocatoria exitosa arquero con dorsal 1
    EXEC administracion.sp_RegistrarConvocatoria @id_jugador = @id_arq, @id_seleccion = @id_sel_conv, @dorsal = 1, @id_generado = @id_conv OUTPUT;
    INSERT INTO @Reporte VALUES ('sp_RegistrarConvocatoria', 'Inscripción de Arquero con dorsal 1', 'Caso de Éxito', 'OK', 'Dorsal 1 asignado');

    -- 4.B. Error FIFA: Camiseta 1 asignada a jugador que NO es arquero
    BEGIN TRY
        EXEC administracion.sp_RegistrarConvocatoria @id_jugador = @id_del, @id_seleccion = @id_sel_conv, @dorsal = 1, @id_generado = @id_conv OUTPUT;
        INSERT INTO @Reporte VALUES ('sp_RegistrarConvocatoria', 'Bloqueo: Camiseta 1 solo para arquero', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50078');
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_RegistrarConvocatoria', 'Bloqueo: Camiseta 1 solo para arquero', 'Validación THROW', 'OK', 'Capturado 50078');
    END CATCH;

    -- 4.C. Error FIFA: Dorsal fuera del rango 1 a 26 (ej: dorsal 30)
    BEGIN TRY
        EXEC administracion.sp_RegistrarConvocatoria @id_jugador = @id_del, @id_seleccion = @id_sel_conv, @dorsal = 30, @id_generado = @id_conv OUTPUT;
        INSERT INTO @Reporte VALUES ('sp_RegistrarConvocatoria', 'Bloqueo: Dorsal fuera del rango 1-26', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50072');
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_RegistrarConvocatoria', 'Bloqueo: Dorsal fuera del rango 1-26', 'Validación THROW', 'OK', 'Capturado 50072');
    END CATCH;

    -- Convocamos a Nico con camiseta 15
    EXEC administracion.sp_RegistrarConvocatoria @id_jugador = @id_del, @id_seleccion = @id_sel_conv, @dorsal = 15, @id_generado = @id_conv OUTPUT;

    -- 4.D. Error: Dorsal repetido entre activos
    BEGIN TRY
        EXEC administracion.sp_RegistrarConvocatoria @id_jugador = @id_reemplazo, @id_seleccion = @id_sel_conv, @dorsal = 15, @id_generado = @id_conv OUTPUT;
        INSERT INTO @Reporte VALUES ('sp_RegistrarConvocatoria', 'Bloqueo por dorsal 15 ya ocupado', 'Validación THROW', 'FALLÓ', 'Debió arrojar 50074');
    END TRY
    BEGIN CATCH
        INSERT INTO @Reporte VALUES ('sp_RegistrarConvocatoria', 'Bloqueo por dorsal 15 ya ocupado', 'Validación THROW', 'OK', 'Capturado 50074');
    END CATCH;

    -- 4.E. Reemplazo Atómico por Lesión (Heredando automáticamente la camiseta 15)
    EXEC administracion.sp_ReemplazarConvocadoUltimoMomento
        @id_jugador_lesionado = @id_del,
        @id_jugador_reemplazo = @id_reemplazo,
        @motivo_lesion = 'Desgarro muscular en entrenamiento previo',
        @dorsal_nuevo = NULL, -- Hereda la 15
        @id_convocatoria_nueva = @id_conv_reemplazo OUTPUT;

    INSERT INTO @Reporte VALUES ('sp_ReemplazarConvocadoUltimoMomento', 'Baja por lesión y alta con herencia dorsal 15', 'Caso de Éxito', 'OK', 'Reemplazado en transacción atómica');

END TRY
BEGIN CATCH
    INSERT INTO @Reporte VALUES ('Convocatoria', 'Fallo general en bloque', 'Error', 'FALLÓ', ERROR_MESSAGE());
END CATCH;
ROLLBACK TRANSACTION;


-- =========================================================================================
-- REPORTE CONSOLIDADO VISUAL (RESULTADOS EN SSMS)
-- =========================================================================================
PRINT '======================================================================';
PRINT 'LOTE DE PRUEBAS FINALIZADO. REVISAR PESTAÑA "RESULTADOS"';
PRINT '======================================================================';

SELECT 
    ID AS [#],
    Procedimiento AS [SP Evaluado],
    Escenario AS [Escenario de Prueba],
    Tipo_Prueba AS [Tipo],
    Resultado AS [Estado],
    Detalle AS [Detalle / Mensaje]
FROM @Reporte
ORDER BY ID;
GO