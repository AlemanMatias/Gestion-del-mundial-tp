/*
  Entrega 5 - Bases de Datos Aplicada - Comisión 02-5600
  Fecha: Octubre 2026
  Integrantes: Aleman Flores Matias, Gamarra Bravo Sidney, Perreira Carlos, Villa Brenda
  Descripción: Procedimientos almacenados para el Módulo de Publicidad y Asignación.
*/

USE Mundial2026;
GO

-- =========================================================================================
-- SP: publicidad.sp_GenerarEspaciosPartido
-- =========================================================================================
CREATE OR ALTER PROCEDURE publicidad.sp_GenerarEspaciosPartido
    @id_partido INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Variable para agrupar todas las validaciones fallidas en un único mensaje
    DECLARE @Errores NVARCHAR(2000) = '';

    -- Validación 1: Verificar que el partido exista en la tabla partido.Partido
    IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID = @id_partido)
    BEGIN
        SET @Errores = @Errores + 'El partido indicado no existe. ';
    END

    -- Validación 2: Verificar que no se hayan generado ya los espacios para este partido
    IF EXISTS (SELECT 1 FROM publicidad.Espacio_publicitario WHERE ID_Partido = @id_partido)
    BEGIN
        SET @Errores = @Errores + 'Los espacios publicitarios ya fueron generados previamente para este partido. ';
    END

    -- Si se acumuló algún error, se lanza la excepción única y se aborta
    IF LEN(@Errores) > 0 
        THROW 50001, @Errores, 1;

    -- Inserción de los 4 espacios reglamentarios basados en los datos semilla
    INSERT INTO publicidad.Espacio_publicitario (nombre, numero_slot, ID_Partido)
    VALUES 
        ('Panel Perimetral Norte', 1, @id_partido),
        ('Panel Perimetral Sur', 2, @id_partido),
        ('Panel Perimetral Este', 3, @id_partido),
        ('Panel Perimetral Oeste', 4, @id_partido);
END
GO 

-- =========================================================================================
-- SP: publicidad.sp_RegistrarAnunciante (Alta y Modificación)
-- =========================================================================================
CREATE OR ALTER PROCEDURE publicidad.sp_RegistrarAnunciante
    @id INT = NULL, -- Si es NULL hace un INSERT, si tiene valor hace un UPDATE
    @nombre VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2000) = '';

    IF LTRIM(RTRIM(@nombre)) = ''
        SET @Errores = @Errores + 'El nombre del anunciante no puede estar vacío. ';

    IF @id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM publicidad.Anunciante WHERE ID = @id)
        SET @Errores = @Errores + 'El anunciante que intenta modificar no existe. ';

    IF EXISTS (SELECT 1 FROM publicidad.Anunciante WHERE nombre = @nombre AND (@id IS NULL OR ID <> @id))
        SET @Errores = @Errores + 'Ya existe un anunciante registrado con ese nombre. ';

    IF LEN(@Errores) > 0 THROW 50002, @Errores, 1;

    BEGIN TRY
        BEGIN TRANSACTION;
        IF @id IS NULL
            INSERT INTO publicidad.Anunciante (nombre) VALUES (@nombre);
        ELSE
            UPDATE publicidad.Anunciante SET nombre = @nombre WHERE ID = @id;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- =========================================================================================
-- SP: publicidad.sp_RegistrarCampania (Alta y Modificación)
-- =========================================================================================
CREATE OR ALTER PROCEDURE publicidad.sp_RegistrarCampania
    @id INT = NULL,
    @nombre VARCHAR(100),
    @fecha_inicio DATE,
    @fecha_fin DATE,
    @id_anunciante INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2000) = '';

    -- Validaciones de reglas de negocio
    IF @fecha_inicio > @fecha_fin
        SET @Errores = @Errores + 'La fecha de inicio de la campaña no puede ser posterior a la fecha de fin. ';
    
    IF NOT EXISTS (SELECT 1 FROM publicidad.Anunciante WHERE ID = @id_anunciante)
        SET @Errores = @Errores + 'El anunciante referenciado no existe en el sistema. ';

    IF @id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM publicidad.Campania WHERE ID = @id)
        SET @Errores = @Errores + 'La campaña que intenta modificar no existe. ';

    IF LEN(@Errores) > 0 THROW 50003, @Errores, 1;

    BEGIN TRY
        BEGIN TRANSACTION;
        IF @id IS NULL
            INSERT INTO publicidad.Campania (nombre, fecha_inicio, fecha_fin, ID_Anunciante)
            VALUES (@nombre, @fecha_inicio, @fecha_fin, @id_anunciante);
        ELSE
            UPDATE publicidad.Campania 
            SET nombre = @nombre, fecha_inicio = @fecha_inicio, fecha_fin = @fecha_fin, ID_Anunciante = @id_anunciante
            WHERE ID = @id;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- =========================================================================================
-- SP: publicidad.sp_RegistrarPiezaContenido (Alta y Modificación)
-- =========================================================================================
CREATE OR ALTER PROCEDURE publicidad.sp_RegistrarPiezaContenido
    @id INT = NULL,
    @nombre VARCHAR(100),
    @idioma VARCHAR(30),
    @costo DECIMAL(12,2),
    @id_campania INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2000) = '';

    IF @costo < 0
        SET @Errores = @Errores + 'El costo de la pieza publicitaria no puede ser negativo. ';

    IF NOT EXISTS (SELECT 1 FROM publicidad.Campania WHERE ID = @id_campania)
        SET @Errores = @Errores + 'La campaña referenciada no existe. ';

    IF @id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM publicidad.Pieza_Contenido WHERE ID = @id)
        SET @Errores = @Errores + 'La pieza de contenido que intenta modificar no existe. ';

    IF LEN(@Errores) > 0 THROW 50004, @Errores, 1;

    BEGIN TRY
        BEGIN TRANSACTION;
        IF @id IS NULL
            INSERT INTO publicidad.Pieza_Contenido (nombre, idioma, costo, ID_Campania)
            VALUES (@nombre, @idioma, @costo, @id_campania);
        ELSE
            UPDATE publicidad.Pieza_Contenido 
            SET nombre = @nombre, idioma = @idioma, costo = @costo, ID_Campania = @id_campania
            WHERE ID = @id;
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO

-- =========================================================================================
-- SP: publicidad.sp_AsignarPublicidadPartido (Algoritmo de Prioridad)
-- =========================================================================================
CREATE OR ALTER PROCEDURE publicidad.sp_AsignarPublicidadPartido
    @id_partido INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Errores NVARCHAR(2000) = '';

    -- Validaciones
    IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID = @id_partido)
        SET @Errores = @Errores + 'El partido indicado no existe. ';

    IF NOT EXISTS (SELECT 1 FROM publicidad.Espacio_publicitario WHERE ID_Partido = @id_partido)
        SET @Errores = @Errores + 'Aún no se han generado los espacios (slots) para este partido. ';

    IF EXISTS (
        SELECT 1 FROM publicidad.Exhibicion ex 
        JOIN publicidad.Espacio_publicitario ep ON ex.ID_espacio = ep.ID 
        WHERE ep.ID_Partido = @id_partido
    )
        SET @Errores = @Errores + 'La publicidad de este partido ya fue asignada previamente. ';

    -- Si hay errores, lanzamos el THROW único
    IF LEN(@Errores) > 0 THROW 50005, @Errores, 1;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Paso 1: Obtener todas las piezas candidatas y evaluarlas con las condiciones pedidas
        ;WITH PiezasRankeadas AS (
            SELECT 
                pc.ID AS ID_Pieza,
                pc.costo,
                CASE WHEN p.ID IN (sl.ID_Pais, sv.ID_Pais) THEN 1 ELSE 0 END AS es_pais_participante,
                p.pbi_percapita,
                -- Cálculo de Prime Time: Hora UTC del partido sumada al offset del huso horario del país destino
                CASE WHEN DATEPART(HOUR, DATEADD(HOUR, CAST(SUBSTRING(p.huso_horario, 1, 3) AS INT), part.fecha_hora_utc)) BETWEEN 19 AND 23 THEN 1 ELSE 0 END AS es_prime_time
            FROM publicidad.Pieza_Contenido pc
            JOIN publicidad.Campania c ON c.ID = pc.ID_Campania
            JOIN publicidad.Pieza_Pais_Interes ppi ON ppi.ID_Pieza = pc.ID
            JOIN administracion.Pais p ON p.ID = ppi.ID_Pais
            JOIN partido.Partido part ON part.ID = @id_partido
            JOIN administracion.Seleccion sl ON sl.ID = part.ID_Seleccion_Local
            JOIN administracion.Seleccion sv ON sv.ID = part.ID_Seleccion_Visitante
            -- Filtramos campañas que estén activas el día del partido
            WHERE c.fecha_inicio <= CAST(part.fecha_hora_local AS DATE) 
              AND c.fecha_fin >= CAST(part.fecha_hora_local AS DATE)
        ),
        -- Paso 2: Agrupar por pieza (una pieza puede apuntar a varios países, nos quedamos con el mejor score)
        PiezasAgrupadas AS (
            SELECT 
                ID_Pieza,
                MAX(costo) AS costo,
                MAX(es_pais_participante) AS max_pais_part,
                MAX(pbi_percapita) AS max_pbi,
                MAX(es_prime_time) AS max_prime_time
            FROM PiezasRankeadas
            GROUP BY ID_Pieza
        ),
        -- Paso 3: Ordenar y elegir las 4 mejores piezas
        Top4Piezas AS (
            SELECT TOP 4
                ID_Pieza,
                costo AS monto_facturado,
                CAST(CASE 
                    WHEN max_pais_part = 1 THEN 1 
                    WHEN max_pbi > 30000 THEN 2 -- PBI alto
                    WHEN max_prime_time = 1 THEN 3
                    ELSE 3 
                END AS TINYINT) AS orden_prioridad,
                ROW_NUMBER() OVER(ORDER BY max_pais_part DESC, max_pbi DESC, max_prime_time DESC, costo DESC) AS fila
            FROM PiezasAgrupadas
        ),
        -- Paso 4: Numerar los 4 slots disponibles del partido
        EspaciosDisponibles AS (
            SELECT 
                ID AS ID_espacio,
                ROW_NUMBER() OVER(ORDER BY numero_slot) AS fila
            FROM publicidad.Espacio_publicitario
            WHERE ID_Partido = @id_partido
        )
        -- Paso 5: Cruzar el Top 4 de piezas con los 4 slots e insertar en Exhibicion
        INSERT INTO publicidad.Exhibicion (ID_espacio, ID_Pieza, orden_prioridad, monto_facturado)
        SELECT 
            e.ID_espacio,
            t.ID_Pieza,
            t.orden_prioridad,
            t.monto_facturado
        FROM Top4Piezas t
        JOIN EspaciosDisponibles e ON t.fila = e.fila;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END;
GO