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
     
   Script: test_06_sp_Gol_Tarjeta_Arbitro_Suspencion.sql
   Descripción: Lote de pruebas para los Stored Procedures de 06_sp_Gol_Tarjeta_Arbitro_Suspencion.sql.
                Valida el ciclo de vida del Módulo 3: ABM e idiomas de árbitros, designación neutral
                en partidos oficiales, registro de goles con actualización automática de marcador,
                y aplicación de tarjetas con cálculo de suspensiones y sanciones disciplinarias.
                Ejecuta bajo transacción aislada (ROLLBACK) para que la base quede limpia y no se
                acumulen registros al reejecutar el script.
*/

USE Mundial2026;
GO

SET NOCOUNT ON;

PRINT '======================================================================';
PRINT 'INICIANDO LOTE DE PRUEBAS AISLADO - MÓDULO 3 (GOLES, TARJETAS, ÁRBITROS)';
PRINT '======================================================================';

BEGIN TRANSACTION;
BEGIN TRY

    -- =========================================================================
    -- PASO 1: GESTIÓN DE ÁRBITROS (ABM - Caso Alta)
    -- =========================================================================
    DECLARE @ID_NuevoArbitro INT;
    EXEC arbitraje.sp_GestionarArbitro
        @Operacion = 'ALTA',
        @ID = @ID_NuevoArbitro OUTPUT,
        @Nombre = 'Björn',
        @Apellido = 'Kuipers',
        @Categoria = 'FIFA Elite',
        @ID_Pais = 4; -- País neutral (Canadá)

    PRINT 'Paso 1: Árbitro registrado con éxito (ID generado: ' + CAST(ISNULL(@ID_NuevoArbitro, 0) AS VARCHAR) + ')';


    -- =========================================================================
    -- PASO 2: OBTENER EL PARTIDO BASE (Argentina vs Argelia)
    -- =========================================================================
    DECLARE @ID_Partido_Test INT, @ID_Argentina INT, @ID_Argelia INT;

    SELECT @ID_Argentina = ID FROM administracion.Seleccion WHERE ID_Pais = (SELECT ID FROM administracion.Pais WHERE nombre = 'Argentina');
    SELECT @ID_Argelia = ID FROM administracion.Seleccion WHERE ID_Pais = (SELECT ID FROM administracion.Pais WHERE nombre = 'Argelia');

    SELECT TOP 1 @ID_Partido_Test = ID 
    FROM partido.Partido 
    WHERE (ID_Seleccion_Local = @ID_Argentina AND ID_Seleccion_Visitante = @ID_Argelia)
       OR (ID_Seleccion_Local = @ID_Argelia AND ID_Seleccion_Visitante = @ID_Argentina);

    IF @ID_Partido_Test IS NULL
    BEGIN
        SELECT TOP 1 @ID_Partido_Test = ID FROM partido.Partido ORDER BY ID ASC;
    END

    PRINT 'Paso 2: Partido asignado para la prueba (ID: ' + CAST(@ID_Partido_Test AS VARCHAR) + ')';


    -- =========================================================================
    -- PASO 3: DESIGNAR ÁRBITRO NEUTRAL
    -- =========================================================================
    EXEC arbitraje.sp_DesignarArbitro
        @ID_Partido = @ID_Partido_Test,
        @ID_Arbitro = @ID_NuevoArbitro,
        @Rol = 'Árbitro Principal',
        @Informe = 'Designación correcta de árbitro neutral.';

    PRINT 'Paso 3: Árbitro neutral designado correctamente al partido.';


    -- =========================================================================
    -- PASO 4: REGISTRAR TARJETA ROJA Y SUSPENSIÓN A CRISTIAN ROMERO
    -- =========================================================================
    DECLARE @ID_CristianRomero INT;
    SELECT TOP 1 @ID_CristianRomero = ID FROM administracion.Jugador WHERE nombre = 'Cristian' AND apellido = 'Romero';

    EXEC partido.sp_RegistrarTarjetaYSuspension
        @ID_Partido = @ID_Partido_Test,
        @ID_Jugador = @ID_CristianRomero,
        @ID_Cuerpo_Tecnico = NULL,
        @Minuto = 82,
        @Motivo = 'Jugada brusca grave',
        @Tipo = 'ROJA',                
        @Es_Doble_Amarilla = 0,       
        @Partidos_Suspension = 2;

    PRINT 'Paso 4: Tarjeta roja y suspensión de 2 fechas registradas.';


    -- =========================================================================
    -- PASO 5: ASEGURAR FORMACIÓN Y ALINEACIÓN DE LIONEL MESSI
    -- =========================================================================
    DECLARE @ID_Messi INT;
    SELECT TOP 1 @ID_Messi = ID FROM administracion.Jugador WHERE nombre = 'Lionel' AND apellido = 'Messi';

    IF NOT EXISTS (SELECT 1 FROM partido.Formacion_Partido WHERE ID_Partido = @ID_Partido_Test AND ID_Seleccion = @ID_Argentina)
    BEGIN
        INSERT INTO partido.Formacion_Partido (ID_Partido, ID_Seleccion, esquema_tactico)
        VALUES (@ID_Partido_Test, @ID_Argentina, '4-3-3');
    END

    DECLARE @ID_Formacion INT;
    SELECT @ID_Formacion = ID FROM partido.Formacion_Partido WHERE ID_Partido = @ID_Partido_Test AND ID_Seleccion = @ID_Argentina;

    IF NOT EXISTS (SELECT 1 FROM partido.Alineacion WHERE ID_Formacion = @ID_Formacion AND ID_Jugador = @ID_Messi)
    BEGIN
        EXEC partido.sp_RegistrarAlineacion 
            @id_formacion = @ID_Formacion, 
            @id_jugador = @ID_Messi,          
            @es_titular = 1;
    END

    PRINT 'Paso 5: Formación y alineación titular de Messi verificadas.';


    -- =========================================================================
    -- PASO 6: REGISTRAR GOL DE LIONEL MESSI
    -- =========================================================================
    DECLARE @ID_DePaul INT;
    SELECT TOP 1 @ID_DePaul = ID FROM administracion.Jugador WHERE nombre = 'Rodrigo' AND apellido = 'De Paul';

    EXEC partido.sp_RegistrarGol
        @ID_Partido = @ID_Partido_Test,
        @ID_Jugador_autor = @ID_Messi,
        @ID_Jugador_asistencia = @ID_DePaul,
        @ID_Seleccion = @ID_Argelia,
        @Minuto = 34,
        @Tipo = 'En contra',
        @Periodo = 'Primer Tiempo';

    PRINT 'Paso 6: Gol en contra registrado e impacto en marcador realizado.';


    -- =========================================================================
    -- PASO 7: GRILLAS VISUALES DE VERIFICACIÓN (Mostradas antes de revertir)
    -- =========================================================================

    -- 7.1: Estado del Marcador General
    SELECT 
        p.ID AS ID_Partido,
        pa_local.nombre AS Seleccion_Local,
        p.goles_local AS Goles_Local,
        pa_visita.nombre AS Seleccion_Visitante,
        p.goles_visitante AS Goles_Visitante
    FROM partido.Partido p
    JOIN administracion.Seleccion sl ON sl.ID = p.ID_Seleccion_Local
    JOIN administracion.Pais pa_local ON pa_local.ID = sl.ID_Pais
    JOIN administracion.Seleccion sv ON sv.ID = p.ID_Seleccion_Visitante
    JOIN administracion.Pais pa_visita ON pa_visita.ID = sv.ID
    WHERE p.ID = @ID_Partido_Test;

    -- 7.2: Detalle de Goles Registrados
    SELECT 
        g.minuto,
        g.periodo,
        g.tipo AS Tipo_Gol,
        autor.nombre + ' ' + autor.apellido AS Autor_Gol,
        ISNULL(asistente.nombre + ' ' + asistente.apellido, 'Sin asistencia') AS Asistente,
        sel.nombre AS Seleccion_Beneficiada
    FROM partido.Gol g
    JOIN administracion.Jugador autor ON autor.ID = g.ID_Jugador_autor
    LEFT JOIN administracion.Jugador asistente ON asistente.ID = g.ID_Jugador_asistencia
    JOIN administracion.Seleccion s ON s.ID = g.ID_Seleccion
    JOIN administracion.Pais sel ON sel.ID = s.ID_Pais
    WHERE g.ID_Partido = @ID_Partido_Test;

    -- 7.3: Reporte del Jugador Expulsado y sus Sanciones
    SELECT 
        s.ID AS ID_Suspension,
        j.nombre + ' ' + j.apellido AS Jugador_Expulsado,
        s.partidos_totales AS Fechas_De_Suspension,
        s.partidos_descontados AS Fechas_Cumplidas,
        s.motivo,
        CASE 
            WHEN s.partidos_descontados >= s.partidos_totales THEN 'Cumplida ✅'
            ELSE 'En Curso / Pendiente ❌'
        END AS Estado_Actual
    FROM partido.Suspension s
    JOIN administracion.Jugador j ON j.ID = s.ID_Jugador
    WHERE s.ID_Jugador = @ID_CristianRomero;

    -- 7.4: Reporte del Árbitro Asignado al Partido
    SELECT 
        d.ID_Partido,
        a.nombre + ' ' + a.apellido AS Arbitro,
        a.categoria,
        pais.nombre AS Pais_Origen,
        d.rol,
        d.informe
    FROM arbitraje.Designacion_Arbitral d
    JOIN arbitraje.Arbitro a ON a.ID = d.ID_Arbitro
    JOIN administracion.Pais pais ON pais.ID = a.ID_Pais
    WHERE d.ID_Partido = @ID_Partido_Test
      AND d.ID_Arbitro = @ID_NuevoArbitro;

END TRY
BEGIN CATCH
    PRINT 'ERROR EN LA PRUEBA DEL MÓDULO 3: ' + ERROR_MESSAGE();
END CATCH;

-- REVERSIÓN ATÓMICA: La base queda exactamente como estaba al inicio
ROLLBACK TRANSACTION;

PRINT '======================================================================';
PRINT 'PRUEBA FINALIZADA - TRANSACCIÓN REVERTIDA (BASE LIMPIA E INTACTA)';
PRINT '======================================================================';
GO
