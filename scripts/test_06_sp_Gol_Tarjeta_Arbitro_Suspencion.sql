
USE Mundial2026;
GO




-- PASO 1: GESTIÓN DE ÁRBITROS (ABM)
DECLARE @ID_NuevoArbitro INT;
EXEC arbitraje.sp_GestionarArbitro
    @Operacion = 'ALTA',
    @ID = @ID_NuevoArbitro OUTPUT,
    @Nombre = 'Björn',
    @Apellido = 'Kuipers',
    @Categoria = 'FIFA Elite',
    @ID_Pais = 4; 
GO


-- PASO 2: OBTENER EL PARTIDO DE LA SEMILLA (Argentina vs Argelia)

DECLARE @ID_Partido_Test INT, @ID_Argentina INT, @ID_Argelia INT, @ID_Arbitro_Neutral INT;

SELECT @ID_Argentina = ID FROM administracion.Seleccion WHERE ID_Pais = (SELECT ID FROM administracion.Pais WHERE nombre = 'Argentina');
SELECT @ID_Argelia = ID FROM administracion.Seleccion WHERE ID_Pais = (SELECT ID FROM administracion.Pais WHERE nombre = 'Argelia');

-- Buscamos el partido exacto entre Argentina y Argelia
SELECT TOP 1 @ID_Partido_Test = ID 
FROM partido.Partido 
WHERE (ID_Seleccion_Local = @ID_Argentina AND ID_Seleccion_Visitante = @ID_Argelia)
   OR (ID_Seleccion_Local = @ID_Argelia AND ID_Seleccion_Visitante = @ID_Argentina);

SELECT 
    p.ID AS ID_Detectado,
    pa_l.nombre AS Local,
    pa_v.nombre AS Visitante
FROM partido.Partido p
JOIN administracion.Seleccion sl ON sl.ID = p.ID_Seleccion_Local
JOIN administracion.Pais pa_l ON pa_l.ID = sl.ID_Pais
JOIN administracion.Seleccion sv ON sv.ID = p.ID_Seleccion_Visitante
JOIN administracion.Pais pa_v ON pa_v.ID = sv.ID
WHERE p.ID = @ID_Partido_Test;

PRINT 'ID del partido obtenido de la semilla: ' + CAST(@ID_Partido_Test AS VARCHAR);

-- Obtenemos el ID del árbitro neutral
SELECT TOP 1 @ID_Arbitro_Neutral = ID FROM arbitraje.Arbitro ORDER BY ID DESC;
GO


-- PASO 3: DESIGNAR ÁRBITRO NEUTRAL (Validando que no esté duplicado)

DECLARE @ID_Partido_Test INT, @ID_Arbitro_Neutral INT, @ID_Argentina INT, @ID_Argelia INT;
SELECT @ID_Argentina = ID FROM administracion.Seleccion WHERE ID_Pais = (SELECT ID FROM administracion.Pais WHERE nombre = 'Argentina');
SELECT @ID_Argelia = ID FROM administracion.Seleccion WHERE ID_Pais = (SELECT ID FROM administracion.Pais WHERE nombre = 'Argelia');
SELECT TOP 1 @ID_Partido_Test = ID FROM partido.Partido WHERE (ID_Seleccion_Local = @ID_Argentina AND ID_Seleccion_Visitante = @ID_Argelia) OR (ID_Seleccion_Local = @ID_Argelia AND ID_Seleccion_Visitante = @ID_Argentina);
SELECT TOP 1 @ID_Arbitro_Neutral = ID FROM arbitraje.Arbitro ORDER BY ID DESC;

IF NOT EXISTS (SELECT 1 FROM arbitraje.Designacion_Arbitral WHERE ID_Partido = @ID_Partido_Test AND ID_Arbitro = @ID_Arbitro_Neutral)
BEGIN
    EXEC arbitraje.sp_DesignarArbitro
        @ID_Partido = @ID_Partido_Test,
        @ID_Arbitro = @ID_Arbitro_Neutral,
        @Rol = 'Árbitro Principal',
        @Informe = 'Designación correcta de árbitro neutral.';
    PRINT 'ÉXITO: Árbitro neutral designado.';
END
GO


-- PASO 4: REGISTRAR TARJETA Y SUSPENSIÓN A CRISTIAN ROMERO

DECLARE @ID_Partido_Test INT, @ID_CristianRomero INT, @ID_Argentina INT, @ID_Argelia INT;
SELECT @ID_Argentina = ID FROM administracion.Seleccion WHERE ID_Pais = (SELECT ID FROM administracion.Pais WHERE nombre = 'Argentina');
SELECT @ID_Argelia = ID FROM administracion.Seleccion WHERE ID_Pais = (SELECT ID FROM administracion.Pais WHERE nombre = 'Argelia');
SELECT TOP 1 @ID_Partido_Test = ID FROM partido.Partido WHERE (ID_Seleccion_Local = @ID_Argentina AND ID_Seleccion_Visitante = @ID_Argelia) OR (ID_Seleccion_Local = @ID_Argelia AND ID_Seleccion_Visitante = @ID_Argentina);
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
GO


-- PASO 5: CREAR FORMACIÓN E INCORPORAR A MESSI A LA CANCHA (Requerido para el gol)

DECLARE @ID_Partido_Test INT, @ID_Argentina INT, @ID_Argelia INT, @ID_Messi INT;
SELECT @ID_Argentina = ID FROM administracion.Seleccion WHERE ID_Pais = (SELECT ID FROM administracion.Pais WHERE nombre = 'Argentina');
SELECT @ID_Argelia = ID FROM administracion.Seleccion WHERE ID_Pais = (SELECT ID FROM administracion.Pais WHERE nombre = 'Argelia');
SELECT TOP 1 @ID_Partido_Test = ID FROM partido.Partido WHERE (ID_Seleccion_Local = @ID_Argentina AND ID_Seleccion_Visitante = @ID_Argelia) OR (ID_Seleccion_Local = @ID_Argelia AND ID_Seleccion_Visitante = @ID_Argentina);
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
GO


-- PASO 6: REGISTRAR GOL DE LIONEL MESSI

DECLARE @ID_Partido_Test INT, @ID_Messi INT, @ID_DePaul INT, @ID_Argentina INT, @ID_Argelia INT;
SELECT @ID_Argentina = ID FROM administracion.Seleccion WHERE ID_Pais = (SELECT ID FROM administracion.Pais WHERE nombre = 'Argentina');
SELECT @ID_Argelia = ID FROM administracion.Seleccion WHERE ID_Pais = (SELECT ID FROM administracion.Pais WHERE nombre = 'Argelia');
SELECT TOP 1 @ID_Partido_Test = ID FROM partido.Partido WHERE (ID_Seleccion_Local = @ID_Argentina AND ID_Seleccion_Visitante = @ID_Argelia) OR (ID_Seleccion_Local = @ID_Argelia AND ID_Seleccion_Visitante = @ID_Argentina);

SELECT TOP 1 @ID_Messi = ID FROM administracion.Jugador WHERE nombre = 'Lionel' AND apellido = 'Messi';
SELECT TOP 1 @ID_DePaul = ID FROM administracion.Jugador WHERE nombre = 'Rodrigo' AND apellido = 'De Paul';

EXEC partido.sp_RegistrarGol
    @ID_Partido = @ID_Partido_Test,
    @ID_Jugador_autor = @ID_Messi,
    @ID_Jugador_asistencia = @ID_DePaul,
    @ID_Seleccion = @ID_Argelia,
    @Minuto = 34,
    @Tipo = 'En contra',
    @Periodo = 'Primer Tiempo';
GO


-- PASO 7: CONSULTAS FINALES DE VERIFICACIÓN (Marcador, Goles, Sanciones y Árbitros)

PRINT '--- 7.1: ESTADO DEL MARCADOR GENERAL ---';
DECLARE @ID_Partido_Test INT, @ID_Argentina INT, @ID_Argelia INT;
SELECT @ID_Argentina = ID FROM administracion.Seleccion WHERE ID_Pais = (SELECT ID FROM administracion.Pais WHERE nombre = 'Argentina');
SELECT @ID_Argelia = ID FROM administracion.Seleccion WHERE ID_Pais = (SELECT ID FROM administracion.Pais WHERE nombre = 'Argelia');
SELECT TOP 1 @ID_Partido_Test = ID FROM partido.Partido WHERE (ID_Seleccion_Local = @ID_Argentina AND ID_Seleccion_Visitante = @ID_Argelia) OR (ID_Seleccion_Local = @ID_Argelia AND ID_Seleccion_Visitante = @ID_Argentina);

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

PRINT '--- 7.2: DETALLE DE GOLES REGISTRADOS ---';
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

PRINT '--- 7.3: REPORTE DEL JUGADOR EXPULSADO Y SUS SANCIONES ---';
DECLARE @ID_CristianRomero INT;
SELECT TOP 1 @ID_CristianRomero = ID FROM administracion.Jugador WHERE nombre = 'Cristian' AND apellido = 'Romero';

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
WHERE s.ID_Jugador = @ID_CristianRomero
ORDER BY s.ID DESC;

PRINT '--- 7.4: REPORTE DEL ÁRBITRO ASIGNADO AL PARTIDO ---';
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
WHERE d.ID_Partido = @ID_Partido_Test;
GO

