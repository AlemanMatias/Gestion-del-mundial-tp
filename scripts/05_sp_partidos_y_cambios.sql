
/*
  Entrega 5 - Bases de Datos Aplicada - Comisión 02-5600
  Fecha: Octubre 2026
  Integrantes: Aleman Flores Matias, Gamarra Bravo Sidney, Perreira Carlos, Villa Brenda
  Descripción: [creacion de SP de
                partidos (valido datos ingresados menos goles y asistencia_publico)
                alta/actualizacion/baja de formacion de partido,
                alta/actualizacion/baja de alineacion de la seleccion de un partido (controlo que sea como maximo 11 titulares),
                registro de sustituciones (tengo en cuenta el maximo de 3 ventanas )
                
               ]
*/

USE Mundial2026;
GO

-------------------SP CREACION DEL PARTIDO----------------------------------------------------------------------
CREATE OR ALTER PROCEDURE partido.sp_CrearPartido 
    @id_sede INT,
    @id_fase INT,
    @fecha_hora_local DATETIME,
    @id_local INT,
    @id_visitante INT
AS
BEGIN


    BEGIN TRANSACTION;

    BEGIN TRY

           -- validacion de que existe cada seleccion
            IF NOT EXISTS (SELECT 1 FROM administracion.Seleccion WHERE id = @id_local) OR
               NOT EXISTS (SELECT 1 FROM administracion.Seleccion WHERE id = @id_visitante)
           
                THROW 50001, 'Una o las dos selecciones indicadas no existen.', 1;
           

           --validacion de selecciones distintas
            IF @id_local = @id_visitante
                THROW 50002, 'La selección local y la selección visitante no pueden ser la misma', 1;
            

            -- validacion de sede 
            IF NOT EXISTS (SELECT 1 FROM administracion.Sede WHERE id = @id_sede)     
                THROW 50003, 'La sede especificada no existe en el sistema', 1;
            

            -- validacion de fase
            IF NOT EXISTS (SELECT 1 FROM administracion.Fase_Torneo WHERE id = @id_fase)
                THROW 50004, 'La fase del torneo especificada no es válida', 1;


            -- validación de partido duplicado en la misma fase
            IF EXISTS ( SELECT 1 FROM partido.Partido WHERE ID_Fase = @id_fase  AND (
                        (ID_Seleccion_Local = @id_local AND ID_Seleccion_Visitante = @id_visitante)
                        OR (ID_Seleccion_Local = @id_visitante AND ID_Seleccion_Visitante = @id_local)
                      )
                )
                    THROW 50005, 'Ya existe un partido registrado entre estas dos selecciones para la misma fase.', 1;

            -- validacion que evita que haya 2 partidos a la misma hora en el mismo estadio
            IF EXISTS ( SELECT 1 FROM partido.Partido   WHERE ID_Sede = @id_sede 
                     AND fecha_hora_local = @fecha_hora_local
                )
                    THROW 50006, 'La sede seleccionada ya tiene programado otro partido para esa misma fecha y hora.', 1;

            -- obtener el huso horario de la sede
            DECLARE @huso_horario VARCHAR(6)
            SELECT @huso_horario = huso_horario FROM administracion.Sede WHERE ID = @id_sede

            -- el dato al ser varchar debe convertirse en int 
            DECLARE @offset_horas INT = CAST(SUBSTRING(@huso_horario, 1, 3) AS INT);

            -- se le resta o suma la hora correspondiente
            DECLARE @hora_utc DATETIME = DATEADD(HOUR, -@offset_horas, @fecha_hora_local);


            -- insertar el Partido
            INSERT INTO partido.Partido (fecha_hora_local, fecha_hora_utc, ID_Fase, ID_Sede, ID_Seleccion_Local, ID_Seleccion_Visitante)
            VALUES (@fecha_hora_local, @hora_utc, @id_fase, @id_sede, @id_local, @id_visitante); 

            -- obtener id del partido para generar los espacios publicitarios
            DECLARE @id_partido INT = SCOPE_IDENTITY();

            -- invocacion de SP de espacios de publicidad
            --EXEC publicidad.sp_GenerarEspaciosPartido @id_partido;
            
            COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
            -- hubo un error, deshacemos todos los cambios
            IF @@TRANCOUNT > 0
                    ROLLBACK TRANSACTION;

            THROW;

    END CATCH;
END;
GO



-----------SP ALTA/ACTUALIZACION FORMACION-----------------------------------------------------------
CREATE OR ALTER PROCEDURE partido.sp_RegistrarFormacion
    @id_partido INT,
    @id_seleccion INT,
    @esquema_tactico VARCHAR(10)
AS
BEGIN

    BEGIN TRANSACTION;

    BEGIN TRY
        -- validacion de que el partido exista
        IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID = @id_partido)
            THROW 50010, 'El partido ingresado no existe en el sistema.', 1;

        -- validacion de que la selección participe en ese partido
        IF NOT EXISTS (
            SELECT 1 FROM partido.Partido WHERE ID = @id_partido 
              AND (ID_Seleccion_Local = @id_seleccion OR ID_Seleccion_Visitante = @id_seleccion)
            )
                THROW 50011, 'La selección indicada no participa en este partido.', 1;

        -- validacion de esquema táctico permitido (podria no estar)
        IF @esquema_tactico NOT IN ('4-4-2', '4-3-3', '4-2-3-1', '3-5-2', '3-4-3', '5-3-2', '5-4-1')
            THROW 50012, 'El esquema táctico ingresado no es válido.', 1;

        --  alta o modificación/actualizacion  
        IF EXISTS (SELECT 1 FROM partido.Formacion_Partido WHERE ID_Partido = @id_partido AND ID_Seleccion = @id_seleccion)
        BEGIN
            -- modificación
            UPDATE partido.Formacion_Partido
            SET esquema_tactico = @esquema_tactico
            WHERE ID_Partido = @id_partido AND ID_Seleccion = @id_seleccion;
        END

        ELSE
        BEGIN
            -- alta
            INSERT INTO partido.Formacion_Partido (ID_Partido, ID_Seleccion, esquema_tactico)
            VALUES (@id_partido, @id_seleccion, @esquema_tactico);
        END

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO


-----------SP BAJA FORMACION---------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE partido.sp_EliminarFormacion
    @id_partido INT,
    @id_seleccion INT
AS
BEGIN

    BEGIN TRANSACTION;

    BEGIN TRY

        -- validacion de que la formación exista antes de borrarla
        IF NOT EXISTS (SELECT 1 FROM partido.Formacion_Partido WHERE ID_Partido = @id_partido AND ID_Seleccion = @id_seleccion)
            THROW 50013, 'no existe una formación registrada para esta selección en este partido.', 1;

        -- elimino ese registro
        DELETE FROM partido.Formacion_Partido
        WHERE ID_Partido = @id_partido AND ID_Seleccion = @id_seleccion;

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;

    END CATCH;
END;
GO

--------------------SP ALTA/ACTUALIZACION ALINEACION---------------------------------------------------
-- titular=1 suplente=0
--------------------------------
CREATE OR ALTER PROCEDURE partido.sp_RegistrarAlineacion
    @id_formacion INT,
    @id_jugador INT,
    @es_titular BIT
AS
BEGIN

    BEGIN TRANSACTION;

    BEGIN TRY
        -- validacion de que la formación exista
        IF NOT EXISTS (SELECT 1 FROM partido.Formacion_Partido WHERE ID = @id_formacion)
            THROW 50020, 'La formación táctica indicada no existe.', 1;

        -- validacion de que el jugador exista
        IF NOT EXISTS (SELECT 1 FROM administracion.Jugador WHERE ID = @id_jugador)
            THROW 50021, 'El jugador indicado no existe en el sistema.', 1;

        -- validación de que el jugador pertenezca a la selección de esa formación y tenga convocatoria activa  ( su estado =1 )
        IF NOT EXISTS ( SELECT 1 FROM partido.Formacion_Partido FO
                        JOIN administracion.Convocatoria CO 
                        ON CO.ID_Seleccion = FO.ID_Seleccion
                        WHERE FO.ID = @id_formacion AND CO.ID_Jugador = @id_jugador 
                         AND CO.estado = 1
                  )
                    THROW 50022, 'El jugador no pertenece a la selección de esta formación o no posee una convocatoria activa.', 1;


        -- validacion de suspensión vigente (jugador con tarjeta roja no puede jugar)
        IF EXISTS (
            SELECT 1 FROM partido.Suspension SU
            JOIN partido.Formacion_Partido FO 
            ON FO.ID = @id_formacion
            WHERE SU.ID_Jugador = @id_jugador 
              AND SU.ID_Partido < FO.ID_Partido -- como el id_partido es identity incremental verifico
                                                -- que la sancion fue en un partido anterior al actual de la formación
             
             AND SU.partidos_descontados < SU.partidos_totales
        )
            THROW 50023, 'El jugador se encuentra suspendido y no puede ser alineado en este partido.', 1;

      

        -- validacion de que si se registra un titular no supere el limite de 11 jugadores en cancha
        IF @es_titular = 1
        BEGIN
            -- cuento la cantidad de titulares pero no lo incluyo al mismo que estoy por agregar o actualizar su estado
      
            DECLARE @cant_titulares INT;
            
            SELECT @cant_titulares = COUNT(*) FROM partido.Alineacion 
            WHERE ID_Formacion = @id_formacion AND es_titular = 1 
              AND ID_Jugador != @id_jugador;

            IF @cant_titulares >= 11
                THROW 50024, 'No se puede registrar al jugador como titular porque el equipo ya cuenta con los 11 titulares permitidos.', 1;
        END

        -- si ya estaba registrado,actualizo el estado del jugador 
        IF EXISTS (SELECT 1 FROM partido.Alineacion WHERE ID_Formacion = @id_formacion AND ID_Jugador = @id_jugador)
        BEGIN
            -- actualizo
            UPDATE partido.Alineacion SET es_titular = @es_titular
            WHERE ID_Formacion = @id_formacion AND ID_Jugador = @id_jugador;
        END

        ELSE

        BEGIN
            -- alta
            INSERT INTO partido.Alineacion (ID_Formacion, ID_Jugador, es_titular)
            VALUES (@id_formacion, @id_jugador, @es_titular);
        END

        COMMIT TRANSACTION;

    END TRY

    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO


------------------SP BAJA ALINEACION--------------------------------------------------------------------
CREATE OR ALTER PROCEDURE partido.sp_EliminarAlineacion
    @id_formacion INT,
    @id_jugador INT
AS
BEGIN

    BEGIN TRANSACTION;

    BEGIN TRY
        -- validacion de que el jugador ya que registrado en la alineacion
        IF NOT EXISTS (SELECT 1 FROM partido.Alineacion WHERE ID_Formacion = @id_formacion AND ID_Jugador = @id_jugador)
            THROW 50025, 'El jugador no se encuentra registrado en esta alineación.', 1;

        -- elimino ese registro
        DELETE FROM partido.Alineacion WHERE ID_Formacion = @id_formacion AND ID_Jugador = @id_jugador;

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

------------REGISTRO SUSTITUCION----------------------------------------------------------------------
CREATE OR ALTER PROCEDURE partido.sp_RegistrarSustitucion
    @id_partido INT,
    @id_jugador_sale INT,
    @id_jugador_entra INT,
    @minuto SMALLINT,
    @motivo VARCHAR(50)
AS
BEGIN
    BEGIN TRANSACTION;

    BEGIN TRY
        -- validacion de que el partido exista
        IF NOT EXISTS (SELECT 1 FROM partido.Partido WHERE ID = @id_partido)
            THROW 50030, 'El partido especificado no existe.', 1;

        -- validacion de que los jugadores sean distintos
        IF @id_jugador_sale = @id_jugador_entra
            THROW 50031, 'El jugador que sale y el que entra no pueden ser el mismo.', 1;

        -- identifico a que seleccion pertenece el jugador que sale 
        DECLARE @id_seleccion INT;
        SELECT @id_seleccion = FP.ID_Seleccion FROM partido.Formacion_Partido FP
        JOIN partido.Alineacion AL ON AL.ID_Formacion = FP.ID
        WHERE FP.ID_Partido = @id_partido AND AL.ID_Jugador = @id_jugador_sale;

        IF @id_seleccion IS NULL
            THROW 50032, 'El jugador que sale no forma parte de ninguno de los equipos en este partido.', 1;

        -- validacion de que el jugador que SALE no haya salido antes en este partido
        IF EXISTS (SELECT 1 FROM partido.Sustitucion 
                   WHERE ID_Partido = @id_partido AND ID_Jugador_Sale = @id_jugador_sale)
            THROW 50033, 'El jugador que sale ya había sido sustituido anteriormente en este partido.', 1;

        -- validacion de que el jugador que ENTRA pertenezca a la misma selección, esté convocado Y sea suplente (es_titular = 0)
        IF NOT EXISTS (SELECT 1 FROM partido.Formacion_Partido FP
                       JOIN partido.Alineacion AL ON AL.ID_Formacion = FP.ID
                       WHERE FP.ID_Partido = @id_partido 
                         AND FP.ID_Seleccion = @id_seleccion
                         AND AL.ID_Jugador = @id_jugador_entra
                         AND AL.es_titular = 0) -- suplente 
            THROW 50034, 'El jugador que entra no pertenece al banco de suplentes de la selección en este partido.', 1;

        -- validacion de que el jugador que ENTRA no haya salido del partido antes
        IF EXISTS (SELECT 1 FROM partido.Sustitucion 
                   WHERE ID_Partido = @id_partido AND ID_Jugador_Sale = @id_jugador_entra)
            THROW 50035, 'El jugador que entra ya había salido del campo de juego previamente.', 1;

        -- validacion de que haya como maximo 5 sustituciones por equipo
        DECLARE @cant_cambios INT;
        SELECT @cant_cambios = COUNT(*) FROM partido.Sustitucion SU
        JOIN partido.Formacion_Partido FP ON FP.ID_Partido = SU.ID_Partido
        WHERE SU.ID_Partido = @id_partido AND FP.ID_Seleccion = @id_seleccion;

        IF @cant_cambios >= 5
            THROW 50036, 'El equipo ya ha alcanzado el límite máximo de 5 sustituciones permitidas.', 1;

        -- validacion del límite de ventanas (máximo 3, excluyendo el entretiempo minuto:45 cualquier cambio ahi se registra en ese minuto)
        IF NOT (@minuto <> 45 ) 
        BEGIN
            DECLARE @ventanas_usadas INT;
            
            SELECT @ventanas_usadas = COUNT(DISTINCT SU.minuto) FROM partido.Sustitucion SU
            JOIN partido.Formacion_Partido FP ON FP.ID_Partido = SU.ID_Partido
            WHERE SU.ID_Partido = @id_partido 
              AND FP.ID_Seleccion = @id_seleccion
              AND NOT (SU.minuto <> 45 );

            IF @ventanas_usadas >= 3
                THROW 50037, 'El equipo ya ha utilizado las 3 ventanas de sustitución permitidas (fuera del entretiempo).', 1;
        END

        -- registro la sustitución
        INSERT INTO partido.Sustitucion (ID_Partido, ID_Jugador_Sale, ID_Jugador_Entra, minuto, motivo)
        VALUES (@id_partido, @id_jugador_sale, @id_jugador_entra, @minuto, @motivo);

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO