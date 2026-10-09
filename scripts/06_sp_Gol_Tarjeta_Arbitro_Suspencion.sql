
USE Mundial2026;
GO

-- 1. ABM DE ÁRBITROS E IDIOMAS

CREATE OR ALTER PROCEDURE arbitraje.sp_GestionarArbitro
    @Operacion VARCHAR(10), -- 'ALTA', 'MODIFICAR', 'BAJA'
    @ID INT = NULL OUTPUT,
    @Nombre VARCHAR(100) = NULL,
    @Apellido VARCHAR(100) = NULL,
    @Categoria VARCHAR(50) = NULL,
    @ID_Pais INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF @Operacion = 'ALTA'
    BEGIN
        IF @Nombre IS NULL OR @Apellido IS NULL OR @Categoria IS NULL OR @ID_Pais IS NULL
        BEGIN
            THROW 50010, 'Para dar de alta un árbitro se deben completar todos los campos obligatorios.', 1;
        END

        INSERT INTO arbitraje.Arbitro (nombre, apellido, categoria, ID_Pais)
        VALUES (@Nombre, @Apellido, @Categoria, @ID_Pais);

        SET @ID = SCOPE_IDENTITY();
    END
    ELSE IF @Operacion = 'MODIFICAR'
    BEGIN
        IF @ID IS NULL OR NOT EXISTS (SELECT 1 FROM arbitraje.Arbitro WHERE ID = @ID)
        BEGIN
            THROW 50011, 'El árbitro a modificar no existe.', 1;
        END

        UPDATE arbitraje.Arbitro
        SET nombre = ISNULL(@Nombre, nombre),
            apellido = ISNULL(@Apellido, apellido),
            categoria = ISNULL(@Categoria, categoria),
            ID_Pais = ISNULL(@ID_Pais, ID_Pais)
        WHERE ID = @ID;
    END
    ELSE IF @Operacion = 'BAJA'
    BEGIN
        IF @ID IS NULL OR NOT EXISTS (SELECT 1 FROM arbitraje.Arbitro WHERE ID = @ID)
        BEGIN
            THROW 50012, 'El árbitro a eliminar no existe.', 1;
        END

        -- Verificar si ya dirigió partidos
        IF EXISTS (SELECT 1 FROM arbitraje.Designacion_Arbitral WHERE ID_Arbitro = @ID)
        BEGIN
            THROW 50013, 'No se puede eliminar el árbitro porque posee designaciones arbitrales registradas.', 1;
        END

        DELETE FROM arbitraje.Idioma WHERE ID_Arbitro = @ID;
        DELETE FROM arbitraje.Arbitro WHERE ID = @ID;
    END
    ELSE
    BEGIN
        THROW 50014, 'Operación no válida para la gestión de árbitros.', 1;
    END
END;
GO

CREATE OR ALTER PROCEDURE arbitraje.sp_GestionarIdiomaArbitro
    @ID_Arbitro INT,
    @Lengua VARCHAR(50),
    @Accion VARCHAR(10) -- INSERTAR o ELIMINAR
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM arbitraje.Arbitro WHERE ID = @ID_Arbitro)
    BEGIN
        THROW 50015, 'El árbitro especificado no existe.', 1;
    END

    IF @Accion = 'INSERTAR'
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM arbitraje.Idioma WHERE ID_Arbitro = @ID_Arbitro AND lengua = @Lengua)
        BEGIN
            INSERT INTO arbitraje.Idioma (lengua, ID_Arbitro) VALUES (@Lengua, @ID_Arbitro);
        END
    END
    ELSE IF @Accion = 'ELIMINAR'
    BEGIN
        DELETE FROM arbitraje.Idioma WHERE ID_Arbitro = @ID_Arbitro AND lengua = @Lengua;
    END
END;
GO


-- 2. DESIGNACIÓN ARBITRAL CON REGLA FIFA Y ADVERTENCIA DE FASES ELIMINATORIAS

CREATE OR ALTER PROCEDURE arbitraje.sp_DesignarArbitro
    @ID_Partido INT,
    @ID_Arbitro INT,
    @Rol VARCHAR(30),
    @Informe VARCHAR(1000) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar existencia
    IF NOT EXISTS (SELECT 1 FROM arbitraje.Arbitro WHERE ID = @ID_Arbitro)
       OR NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID = @ID_Partido)
    BEGIN
        THROW 50001, 'El árbitro o el partido especificado no existen.', 1;
        RETURN;
    END

    -- Bloquear si el país del árbitro coincide con local o visitante
    IF EXISTS (
        SELECT 1 
        FROM partido.Partido p
        JOIN arbitraje.Arbitro a ON a.ID = @ID_Arbitro
        WHERE p.ID = @ID_Partido 
          AND (a.ID_Pais = p.ID_Seleccion_Local OR a.ID_Pais = p.ID_Seleccion_Visitante)
    )
    BEGIN
        THROW 50002, 'Conflicto de nacionalidad estricto: Un árbitro no puede dirigir un partido de su propio país.', 1;
        RETURN;
    END

    -- A partir de dieciseisavos emitir advertencia si procede de un entorno cercano o cruzado
    DECLARE @OrdenFase SMALLINT;
    SELECT @OrdenFase = f.orden 
    FROM partido.Partido p
    JOIN administracion.Fase_Torneo f ON f.ID = p.ID_Fase
    WHERE p.ID = @ID_Partido;

    IF @OrdenFase >= 2
    BEGIN
        
        PRINT 'ADVERTENCIA FIFA: El partido pertenece a una fase de eliminación directa (orden >= 2). Verifique posibles cruces futuros de confederación.';
    END

    -- Insertar designación
    INSERT INTO arbitraje.Designacion_Arbitral (ID_Partido, ID_Arbitro, rol, informe)
    VALUES (@ID_Partido, @ID_Arbitro, @Rol, @Informe);
END;
GO

-- 3. REGISTRO DE TARJETA Y SUSPENSIÓN
CREATE OR ALTER PROCEDURE partido.sp_RegistrarTarjetaYSuspension
    @ID_Partido INT,
    @ID_Jugador INT = NULL,
    @ID_Cuerpo_Tecnico INT = NULL,
    @Minuto SMALLINT,
    @Motivo VARCHAR(100),
    @Tipo VARCHAR(10), -- 'AMARILLA' o 'ROJA'
    @Es_Doble_Amarilla BIT = 0,
    @Partidos_Suspension INT = 1 --  parámetro para elegir cuántas fechas suspender (por defecto 1)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;

    BEGIN TRY
        -- Validar destinatario único
        IF (@ID_Jugador IS NOT NULL AND @ID_Cuerpo_Tecnico IS NOT NULL) OR (@ID_Jugador IS NULL AND @ID_Cuerpo_Tecnico IS NULL)
        BEGIN
            THROW 50004, 'La tarjeta debe ser exclusivamente para un jugador o para un miembro del cuerpo técnico.', 1;
        END

        IF @Minuto <= 0 OR @Minuto > 140
        BEGIN
            THROW 50018, 'El minuto de la tarjeta es inválido.', 1;
        END

        -- Insertar tarjeta
        INSERT INTO partido.Tarjeta (ID_Partido, ID_Jugador, ID_Miembro_Cuerpo_Tecnico, minuto, motivo, tipo, es_doble_amarilla)
        VALUES (@ID_Partido, @ID_Jugador, @ID_Cuerpo_Tecnico, @Minuto, @Motivo, @Tipo, @Es_Doble_Amarilla);

        -- Si es jugador, evaluar acumulación de amarillas o roja directa
        IF @ID_Jugador IS NOT NULL
        BEGIN
            DECLARE @TotalAmarillas INT;
            
            IF @Tipo = 'AMARILLA'
            BEGIN
                SELECT @TotalAmarillas = COUNT(*) 
                FROM partido.Tarjeta 
                WHERE ID_Jugador = @ID_Jugador AND tipo = 'AMARILLA';

                -- Si acumula 2 amarillas o es doble amarilla, generar suspensión automática
                IF @TotalAmarillas >= 2 OR @Es_Doble_Amarilla = 1
                BEGIN
                    INSERT INTO partido.Suspension (ID_Jugador, ID_Partido, partidos_totales, partidos_descontados, motivo)
                    VALUES (@ID_Jugador, @ID_Partido, @Partidos_Suspension, 0, 'Suspensión automática por acumulación de tarjetas amarillas o doble amarilla.');
                END
            END
            ELSE IF @Tipo = 'ROJA'
            BEGIN
                -- Roja directa con la cantidad de fechas elegida
                INSERT INTO partido.Suspension (ID_Jugador, ID_Partido, partidos_totales, partidos_descontados, motivo)
                VALUES (@ID_Jugador, @ID_Partido, @Partidos_Suspension, 0, 'Suspensión automática por expulsión con tarjeta roja directa.');
            END
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO