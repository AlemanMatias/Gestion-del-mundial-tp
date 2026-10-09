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
     
   Script: test_partido_inaugural.sql
   Descripción: Simulación del Partido Inaugural oficial integrando los 3 Módulos del Sistema.
                No requiere vaciar la base previa; corre bajo ROLLBACK dejando la base intacta.

                PARTIDO INAUGURAL OFICIAL - COPA MUNDIAL DE LA FIFA 2026
                11 de junio de 2026 - Estadio Azteca (Ciudad de México)
                MÉXICO 2 - 0 SUDÁFRICA (Grupo A)
                
                Goles del partido:
                  - 09' Julián Quiñones (Asistencia: Hirving Lozano) (1-0)
                  - 67' Raúl Jiménez (2-0)
                
                Integración de Procedimientos Almacenados:
                  1. MÓDULO 1 (Administración):
                     - sp_InsertarPais (México y Sudáfrica)
                     - sp_InsertarClub (América, Fulham, West Ham, Feyenoord, Mamelodi Sundowns, Al Ahly, etc.)
                     - sp_InsertarSeleccion (Grupo A del Mundial 2026)
                     - sp_InsertarMiembroCuerpoTecnico (Javier Aguirre y Hugo Broos)
                     - sp_InsertarJugador (Nóminas oficiales 2026)
                     - sp_RegistrarConvocatoria (Dorsales correlativos 1 al 26 y camiseta 1 para Arquero)
                     - sp_ReemplazarConvocadoUltimoMomento (Baja médica real por lesión previa y herencia de camiseta)
                  2. MÓDULO 2 (Partidos y Cambios):
                     - sp_CrearPartido (11 de junio de 2026 en Estadio Azteca con cálculo UTC)
                     - sp_RegistrarFormacion (México 4-3-3 y Sudáfrica 4-2-3-1)
                     - sp_RegistrarAlineacion (11 titulares reglamentarios y suplentes)
                     - sp_RegistrarSustitucion (Ventanas IFAB de cambios en el 2do tiempo)
                  3. MÓDULO 3 (Disciplina, Árbitros y Goles):
                     - sp_DesignarArbitro (Wilton Sampaio de Brasil - Neutral FIFA Elite)
                     - sp_RegistrarTarjetaYSuspension (Amarillas oficiales a Mvala y Álvarez)
                     - sp_RegistrarGol (Goles oficiales con recálculo dinámico del marcador de partido)
*/

USE Mundial2026;
GO

SET NOCOUNT ON;

PRINT '======================================================================';
PRINT 'MUNDIAL FIFA 2026: PARTIDO INAUGURAL MÉXICO VS SUDÁFRICA (2-0)';
PRINT 'Sede: Estadio Azteca | Fecha: 11 de Junio de 2026 | Grupo A';
PRINT '======================================================================';

BEGIN TRANSACTION;

BEGIN TRY
    -- Variables para retener IDs generados dinámicamente
    DECLARE @id_pais_mex INT, @id_pais_rsa INT;
    DECLARE @id_sel_mex INT, @id_sel_rsa INT;
    DECLARE @id_sede_azteca INT, @id_fase_grupos INT;
    DECLARE @id_partido INT;
    DECLARE @id_form_mex INT, @id_form_rsa INT;
    DECLARE @id_dt_mex INT, @id_dt_rsa INT;
    DECLARE @id_club INT, @id_jug INT, @id_conv INT, @id_reemplazo INT;

    -- =========================================================================================
    -- ETAPA 1: ADMINISTRACIÓN DE PAÍSES, SEDE Y SELECCIONES (MÓDULO 1)
    -- =========================================================================================
    PRINT '>> [ETAPA 1] Configurando países y selecciones del Grupo A...';

    -- 1.A. México
    IF NOT EXISTS (SELECT 1 FROM administracion.Pais WHERE nombre = 'México')
        EXEC administracion.sp_InsertarPais @nombre = 'México', @pbi_percapita = 13800.00, @huso_horario = '-06:00', @id_generado = @id_pais_mex OUTPUT;
    ELSE
        SELECT @id_pais_mex = ID FROM administracion.Pais WHERE nombre = 'México';

    -- 1.B. Sudáfrica
    IF NOT EXISTS (SELECT 1 FROM administracion.Pais WHERE nombre = 'Sudáfrica')
        EXEC administracion.sp_InsertarPais @nombre = 'Sudáfrica', @pbi_percapita = 6700.00, @huso_horario = '+02:00', @id_generado = @id_pais_rsa OUTPUT;
    ELSE
        SELECT @id_pais_rsa = ID FROM administracion.Pais WHERE nombre = 'Sudáfrica';

    -- 1.C. Selección de México (Grupo A)
    IF NOT EXISTS (SELECT 1 FROM administracion.Seleccion WHERE ID_Pais = @id_pais_mex)
        EXEC administracion.sp_InsertarSeleccion @id_pais = @id_pais_mex, @confederacion = 'CONCACAF', @grupo_asignado = 'A', @id_generado = @id_sel_mex OUTPUT;
    ELSE
        SELECT @id_sel_mex = ID FROM administracion.Seleccion WHERE ID_Pais = @id_pais_mex;

    -- 1.D. Selección de Sudáfrica (Grupo A)
    IF NOT EXISTS (SELECT 1 FROM administracion.Seleccion WHERE ID_Pais = @id_pais_rsa)
        EXEC administracion.sp_InsertarSeleccion @id_pais = @id_pais_rsa, @confederacion = 'CAF', @grupo_asignado = 'A', @id_generado = @id_sel_rsa OUTPUT;
    ELSE
        SELECT @id_sel_rsa = ID FROM administracion.Seleccion WHERE ID_Pais = @id_pais_rsa;

    -- 1.E. Sede Estadio Azteca y Fase de Grupos
    SELECT TOP 1 @id_sede_azteca = ID FROM administracion.Sede WHERE nombre LIKE '%Azteca%';
    IF @id_sede_azteca IS NULL
        EXEC administracion.sp_InsertarSede 
            @nombre = 'Estadio Azteca', 
            @ciudad = 'Ciudad de México', 
            @capacidad = 83264, 
            @huso_horario = '-06:00', 
            @id_pais = @id_pais_mex, 
            @id_generado = @id_sede_azteca OUTPUT;

    SELECT TOP 1 @id_fase_grupos = ID FROM administracion.Fase_Torneo WHERE orden = 1;
    IF @id_fase_grupos IS NULL
        EXEC administracion.sp_InsertarFaseTorneo @nombre = 'Fase de Grupos', @orden = 1, @id_generado = @id_fase_grupos OUTPUT;

    -- =========================================================================================
    -- ETAPA 2: CUERPOS TÉCNICOS OFICIALES DEL MUNDIAL 2026 (MÓDULO 1)
    -- =========================================================================================
    PRINT '>> [ETAPA 2] Acreditando Directores Técnicos oficiales...';

    -- DT México: Javier "Vasco" Aguirre (DT oficial Mundial 2026)
    IF NOT EXISTS (SELECT 1 FROM administracion.Miembro_Cuerpo_Tecnico WHERE ID_Seleccion = @id_sel_mex AND UPPER(rol) IN ('DIRECTOR TÉCNICO', 'DIRECTOR TECNICO'))
        EXEC administracion.sp_InsertarMiembroCuerpoTecnico @nombre = 'Javier', @apellido = 'Aguirre', @rol = 'Director Técnico', @id_seleccion = @id_sel_mex, @id_generado = @id_dt_mex OUTPUT;

    -- DT Sudáfrica: Hugo Broos (DT oficial belga de Bafana Bafana)
    IF NOT EXISTS (SELECT 1 FROM administracion.Miembro_Cuerpo_Tecnico WHERE ID_Seleccion = @id_sel_rsa AND UPPER(rol) IN ('DIRECTOR TÉCNICO', 'DIRECTOR TECNICO'))
        EXEC administracion.sp_InsertarMiembroCuerpoTecnico @nombre = 'Hugo', @apellido = 'Broos', @rol = 'Director Técnico', @id_seleccion = @id_sel_rsa, @id_generado = @id_dt_rsa OUTPUT;

    -- =========================================================================================
    -- ETAPA 3: REGISTRO DE CLUBES Y JUGADORES DEL MUNDIAL 2026 (MÓDULO 1)
    -- =========================================================================================
    PRINT '>> [ETAPA 3] Registrando planteles 2026 en el maestro de jugadores...';

    -- Clubes actuales
    DECLARE @Clubes TABLE (nombre VARCHAR(100));
    INSERT INTO @Clubes VALUES 
        ('Club América'), ('Cruz Azul'), ('West Ham United'), ('Fulham FC'),
        ('Feyenoord'), ('Genoa CFC'), ('Lokomotiv Moscú'), ('Dinamo Moscú'),
        ('AEK Atenas'), ('Al Qadsiah FC'), ('Tigres UANL'), ('Toluca FC'),
        ('Mamelodi Sundowns'), ('Al Ahly SC'), ('Orlando Pirates'), ('CD Tondela');

    DECLARE @c_nom VARCHAR(100);
    DECLARE @cur_c INT = 1, @tot_c INT = (SELECT COUNT(*) FROM @Clubes);
    DECLARE @ClubesOrd TABLE (id INT IDENTITY(1,1), nombre VARCHAR(100));
    INSERT INTO @ClubesOrd SELECT nombre FROM @Clubes;

    WHILE @cur_c <= @tot_c
    BEGIN
        SELECT @c_nom = nombre FROM @ClubesOrd WHERE id = @cur_c;
        IF NOT EXISTS (SELECT 1 FROM administracion.Club WHERE LOWER(nombre) = LOWER(@c_nom))
            EXEC administracion.sp_InsertarClub @nombre = @c_nom, @id_generado = @id_club OUTPUT;
        SET @cur_c = @cur_c + 1;
    END;

    -- -----------------------------------------------------------------------------------------
    -- NÓMINA OFICIAL MÉXICO 2026
    -- -----------------------------------------------------------------------------------------
    DECLARE @NominaMex2026 TABLE (
        id INT IDENTITY(1,1),
        nombre VARCHAR(50), apellido VARCHAR(50), fn DATE, pos VARCHAR(30), club VARCHAR(100), dorsal TINYINT
    );

    INSERT INTO @NominaMex2026 VALUES
        ('Luis Ángel',   'Malagón',     '1997-03-02', 'Arquero',        'Club América',         1),
        ('Jorge',        'Sánchez',     '1997-12-10', 'Defensor',       'Cruz Azul',            2),
        ('César',        'Montes',      '1997-02-24', 'Defensor',       'Lokomotiv Moscú',      3),
        ('Edson',        'Álvarez',     '1997-10-24', 'Mediocampista',  'West Ham United',      4),
        ('Johan',        'Vásquez',     '1998-10-22', 'Defensor',       'Genoa CFC',            5),
        ('Jesús',        'Gallardo',    '1994-08-15', 'Defensor',       'Toluca FC',            23),
        ('Luis',         'Chávez',      '1996-01-15', 'Mediocampista',  'Dinamo Moscú',         18),
        ('Orbelín',      'Pineda',      '1996-03-24', 'Mediocampista',  'AEK Atenas',           17),
        ('Julián',       'Quiñones',    '1997-03-24', 'Delantero',      'Al Qadsiah FC',        9),   -- Autor gol 09'
        ('Raúl',         'Jiménez',     '1991-05-05', 'Delantero',      'Fulham FC',            11),  -- Autor gol 67'
        ('Santiago',     'Giménez',     '2001-04-18', 'Delantero',      'Feyenoord',            7),
        -- Suplentes
        ('Uriel',        'Antuna',      '1997-08-21', 'Delantero',      'Tigres UANL',          15),
        ('Luis',         'Romo',        '1995-06-05', 'Mediocampista',  'Cruz Azul',            8),
        ('Carlos',       'Acevedo',     '1996-04-19', 'Arquero',        'Club América',         13);

    DECLARE @k INT = 1, @tot_m INT = (SELECT COUNT(*) FROM @NominaMex2026);
    DECLARE @nom VARCHAR(50), @ape VARCHAR(50), @fn DATE, @pos VARCHAR(30), @cl_n VARCHAR(100), @dor TINYINT;

    WHILE @k <= @tot_m
    BEGIN
        SET @id_jug = NULL;
        SET @id_club = NULL;

        SELECT @nom = nombre, @ape = apellido, @fn = fn, @pos = pos, @cl_n = club, @dor = dorsal FROM @NominaMex2026 WHERE id = @k;
        SELECT @id_club = ID FROM administracion.Club WHERE LOWER(nombre) = LOWER(@cl_n);

        SELECT @id_jug = ID FROM administracion.Jugador WHERE nombre = @nom AND apellido = @ape;
        IF @id_jug IS NULL
            EXEC administracion.sp_InsertarJugador @nombre = @nom, @apellido = @ape, @fecha_nacimiento = @fn, @id_club = @id_club, @posicion_habitual = @pos, @id_generado = @id_jug OUTPUT;

        IF NOT EXISTS (SELECT 1 FROM administracion.Convocatoria WHERE ID_Jugador = @id_jug)
            EXEC administracion.sp_RegistrarConvocatoria @id_jugador = @id_jug, @id_seleccion = @id_sel_mex, @dorsal = @dor, @id_generado = @id_conv OUTPUT;

        SET @k = @k + 1;
    END;

    -- Caso Real de Lesión y Reemplazo FIFA: Hirving "Chucky" Lozano se lesiona antes de la inauguración
    SELECT @id_club = ID FROM administracion.Club WHERE nombre = 'Club América';
    EXEC administracion.sp_InsertarJugador @nombre = 'Hirving', @apellido = 'Lozano', @fecha_nacimiento = '1995-07-30', @id_club = @id_club, @posicion_habitual = 'Delantero', @id_generado = @id_jug OUTPUT;
    EXEC administracion.sp_RegistrarConvocatoria @id_jugador = @id_jug, @id_seleccion = @id_sel_mex, @dorsal = 22, @id_generado = @id_conv OUTPUT;

    EXEC administracion.sp_InsertarJugador @nombre = 'Roberto', @apellido = 'Alvarado', @fecha_nacimiento = '1998-09-07', @id_club = @id_club, @posicion_habitual = 'Delantero', @id_generado = @id_reemplazo OUTPUT;
    
    -- Reemplazo atómico con herencia de camiseta 22:
    EXEC administracion.sp_ReemplazarConvocadoUltimoMomento
        @id_jugador_lesionado = @id_jug,
        @id_jugador_reemplazo = @id_reemplazo,
        @motivo_lesion = 'Desgarro en el muslo derecho durante el entrenamiento previo en el CAR',
        @dorsal_nuevo = NULL, -- Hereda la camiseta 22
        @id_convocatoria_nueva = @id_conv OUTPUT;

    PRINT '   + Plantel de México 2026 cargado con reemplazo por lesión exitoso.';

    -- -----------------------------------------------------------------------------------------
    -- NÓMINA OFICIAL SUDÁFRICA (BAFANA BAFANA) 2026
    -- -----------------------------------------------------------------------------------------
    DECLARE @NominaRsa2026 TABLE (
        id INT IDENTITY(1,1),
        nombre VARCHAR(50), apellido VARCHAR(50), fn DATE, pos VARCHAR(30), club VARCHAR(100), dorsal TINYINT
    );

    INSERT INTO @NominaRsa2026 VALUES
        ('Ronwen',       'Williams',    '1992-01-21', 'Arquero',        'Mamelodi Sundowns',    1),   -- Capitán
        ('Khuliso',      'Mudau',       '1995-04-26', 'Defensor',       'Mamelodi Sundowns',    20),
        ('Mothobi',      'Mvala',       '1994-06-14', 'Defensor',       'Mamelodi Sundowns',    5),
        ('Grant',        'Kekana',      '1992-10-31', 'Defensor',       'Mamelodi Sundowns',    14),
        ('Aubrey',       'Modiba',      '1995-07-22', 'Defensor',       'Mamelodi Sundowns',    6),
        ('Teboho',       'Mokoena',     '1997-01-24', 'Mediocampista',  'Mamelodi Sundowns',    4),
        ('Sphephelo',    'Sithole',     '1999-03-03', 'Mediocampista',  'CD Tondela',           13),
        ('Themba',       'Zwane',       '1989-08-03', 'Mediocampista',  'Mamelodi Sundowns',    11),
        ('Percy',        'Tau',         '1994-05-13', 'Delantero',      'Al Ahly SC',           10),
        ('Thapelo',      'Morena',      '1993-08-06', 'Delantero',      'Mamelodi Sundowns',    23),
        ('Evidence',     'Makgopa',     '2000-06-05', 'Delantero',      'Orlando Pirates',      9),
        -- Suplentes:
        ('Oswin',        'Appollis',    '2001-11-08', 'Mediocampista',  'Orlando Pirates',      7),
        ('Zakhele',      'Lepasa',      '1997-03-19', 'Delantero',      'Orlando Pirates',      19),
        ('Veli',         'Mothwa',      '1991-02-12', 'Arquero',        'Mamelodi Sundowns',    16);

    SET @k = 1;
    SET @tot_m = (SELECT COUNT(*) FROM @NominaRsa2026);

    WHILE @k <= @tot_m
    BEGIN
        SET @id_jug = NULL;
        SET @id_club = NULL;

        SELECT @nom = nombre, @ape = apellido, @fn = fn, @pos = pos, @cl_n = club, @dor = dorsal FROM @NominaRsa2026 WHERE id = @k;
        SELECT @id_club = ID FROM administracion.Club WHERE LOWER(nombre) = LOWER(@cl_n);

        SELECT @id_jug = ID FROM administracion.Jugador WHERE nombre = @nom AND apellido = @ape;
        IF @id_jug IS NULL
            EXEC administracion.sp_InsertarJugador @nombre = @nom, @apellido = @ape, @fecha_nacimiento = @fn, @id_club = @id_club, @posicion_habitual = @pos, @id_generado = @id_jug OUTPUT;

        IF NOT EXISTS (SELECT 1 FROM administracion.Convocatoria WHERE ID_Jugador = @id_jug)
            EXEC administracion.sp_RegistrarConvocatoria @id_jugador = @id_jug, @id_seleccion = @id_sel_rsa, @dorsal = @dor, @id_generado = @id_conv OUTPUT;

        SET @k = @k + 1;
    END;
    PRINT '   + Plantel de Sudáfrica 2026 cargado exitosamente.';

    -- =========================================================================================
    -- ETAPA 4: CREACIÓN DEL PARTIDO INAUGURAL 2026 (MÓDULO 2 )
    -- =========================================================================================
    PRINT '>> [ETAPA 4] Programando Partido Inaugural vía partido.sp_CrearPartido...';

    -- Partido Inaugural Mundial 2026: 11 de junio de 2026 a las 13:00 local (19:00 UTC)
    DECLARE @fecha_inaugural DATETIME = '2026-06-11 13:00:00';

    -- Si en la base de datos existía previamente un partido cargado en esa sede y horario,
    -- lo removemos temporalmente dentro de la transacción aislada para poder probar sp_CrearPartido limpiamente:
    DECLARE @id_partido_previo INT;
    SELECT @id_partido_previo = ID FROM partido.Partido WHERE ID_Sede = @id_sede_azteca AND fecha_hora_local = @fecha_inaugural;

    IF @id_partido_previo IS NOT NULL
    BEGIN
        DELETE FROM publicidad.Exhibicion WHERE ID_espacio IN (SELECT ID FROM publicidad.Espacio_publicitario WHERE ID_Partido = @id_partido_previo);
        DELETE FROM publicidad.Espacio_publicitario WHERE ID_Partido = @id_partido_previo;
        DELETE FROM partido.Gol WHERE ID_Partido = @id_partido_previo;
        DELETE FROM partido.Tarjeta WHERE ID_Partido = @id_partido_previo;
        DELETE FROM partido.Sustitucion WHERE ID_Partido = @id_partido_previo;
        DELETE FROM arbitraje.Designacion_Arbitral WHERE ID_Partido = @id_partido_previo;
        DELETE FROM partido.Alineacion WHERE ID_Formacion IN (SELECT ID FROM partido.Formacion_Partido WHERE ID_Partido = @id_partido_previo);
        DELETE FROM partido.Formacion_Partido WHERE ID_Partido = @id_partido_previo;
        DELETE FROM partido.Partido WHERE ID = @id_partido_previo;
    END;

    SELECT @id_partido = ID FROM partido.Partido 
    WHERE ID_Fase = @id_fase_grupos 
      AND ((ID_Seleccion_Local = @id_sel_mex AND ID_Seleccion_Visitante = @id_sel_rsa)
        OR (ID_Seleccion_Local = @id_sel_rsa AND ID_Seleccion_Visitante = @id_sel_mex));

    IF @id_partido IS NULL
    BEGIN
        EXEC partido.sp_CrearPartido
            @id_sede = @id_sede_azteca,
            @id_fase = @id_fase_grupos,
            @fecha_hora_local = @fecha_inaugural,
            @id_local = @id_sel_mex,
            @id_visitante = @id_sel_rsa;

        SELECT TOP 1 @id_partido = ID FROM partido.Partido ORDER BY ID DESC;
    END;

    PRINT '   + Partido Inaugural creado con éxito (ID: ' + CAST(@id_partido AS VARCHAR(10)) + ')';

    -- =========================================================================================
    -- ETAPA 5: FORMACIONES TÁCTICAS Y 11 TITULARES (MÓDULO 2)
    -- =========================================================================================
    PRINT '>> [ETAPA 5] Registrando esquemas tácticos y alineaciones titulares...';

    -- Esquemas tácticos (México 4-3-3, Sudáfrica 4-2-3-1)
    EXEC partido.sp_RegistrarFormacion @id_partido = @id_partido, @id_seleccion = @id_sel_mex, @esquema_tactico = '4-3-3';
    SELECT @id_form_mex = ID FROM partido.Formacion_Partido WHERE ID_Partido = @id_partido AND ID_Seleccion = @id_sel_mex;

    EXEC partido.sp_RegistrarFormacion @id_partido = @id_partido, @id_seleccion = @id_sel_rsa, @esquema_tactico = '4-4-2';
    SELECT @id_form_rsa = ID FROM partido.Formacion_Partido WHERE ID_Partido = @id_partido AND ID_Seleccion = @id_sel_rsa;

    DECLARE @j_malagon INT, @j_sanchez INT, @j_montes INT, @j_alvarez INT, @j_vasquez INT;
    DECLARE @j_gallardo INT, @j_chavez INT, @j_pineda INT, @j_quinones INT, @j_jimenez INT, @j_gimenez INT;
    DECLARE @j_antuna INT, @j_romo INT, @j_acevedo INT, @j_lozano INT;

    SELECT @j_malagon = ID FROM administracion.Jugador WHERE nombre = 'Luis Ángel' AND apellido = 'Malagón';
    SELECT @j_sanchez = ID FROM administracion.Jugador WHERE nombre = 'Jorge' AND apellido = 'Sánchez';
    SELECT @j_montes = ID FROM administracion.Jugador WHERE nombre = 'César' AND apellido = 'Montes';
    SELECT @j_alvarez = ID FROM administracion.Jugador WHERE nombre = 'Edson' AND apellido = 'Álvarez';
    SELECT @j_vasquez = ID FROM administracion.Jugador WHERE nombre = 'Johan' AND apellido = 'Vásquez';
    SELECT @j_gallardo = ID FROM administracion.Jugador WHERE nombre = 'Jesús' AND apellido = 'Gallardo';
    SELECT @j_chavez = ID FROM administracion.Jugador WHERE nombre = 'Luis' AND apellido = 'Chávez';
    SELECT @j_pineda = ID FROM administracion.Jugador WHERE nombre = 'Orbelín' AND apellido = 'Pineda';
    SELECT @j_quinones = ID FROM administracion.Jugador WHERE nombre = 'Julián' AND apellido = 'Quiñones';
    SELECT @j_jimenez = ID FROM administracion.Jugador WHERE nombre = 'Raúl' AND apellido = 'Jiménez';
    SELECT @j_gimenez = ID FROM administracion.Jugador WHERE nombre = 'Santiago' AND apellido = 'Giménez';
    SELECT @j_antuna = ID FROM administracion.Jugador WHERE nombre = 'Uriel' AND apellido = 'Antuna';
    SELECT @j_romo = ID FROM administracion.Jugador WHERE nombre = 'Luis' AND apellido = 'Romo';
    SELECT @j_acevedo = ID FROM administracion.Jugador WHERE nombre = 'Carlos' AND apellido = 'Acevedo';
    SELECT @j_lozano = ID FROM administracion.Jugador WHERE nombre = 'Hirving' AND apellido = 'Lozano';

    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_mex, @id_jugador = @j_malagon,   @es_titular = 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_mex, @id_jugador = @j_sanchez,   @es_titular = 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_mex, @id_jugador = @j_montes,    @es_titular = 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_mex, @id_jugador = @j_alvarez,   @es_titular = 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_mex, @id_jugador = @j_vasquez,   @es_titular = 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_mex, @id_jugador = @j_gallardo,  @es_titular = 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_mex, @id_jugador = @j_chavez,    @es_titular = 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_mex, @id_jugador = @j_pineda,    @es_titular = 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_mex, @id_jugador = @j_quinones,  @es_titular = 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_mex, @id_jugador = @j_jimenez,   @es_titular = 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_mex, @id_jugador = @j_gimenez,   @es_titular = 1;
    -- Suplentes
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_mex, @id_jugador = @j_antuna,    @es_titular = 0;
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_mex, @id_jugador = @j_romo,      @es_titular = 0;
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_mex, @id_jugador = @j_acevedo,   @es_titular = 0;
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_mex, @id_jugador = @id_reemplazo, @es_titular = 0; -- Alvarado en el banco

    -- 5.B. 11 Titulares de Sudáfrica
    DECLARE @j_williams INT, @j_mudau INT, @j_mvala INT, @j_kekana INT, @j_modiba INT;
    DECLARE @j_mokoena INT, @j_sithole INT, @j_zwane INT, @j_tau INT, @j_morena INT, @j_makgopa INT;
    DECLARE @j_appollis INT, @j_lepasa INT;

    SELECT @j_williams = ID FROM administracion.Jugador WHERE nombre = 'Ronwen' AND apellido = 'Williams';
    SELECT @j_mudau = ID FROM administracion.Jugador WHERE nombre = 'Khuliso' AND apellido = 'Mudau';
    SELECT @j_mvala = ID FROM administracion.Jugador WHERE nombre = 'Mothobi' AND apellido = 'Mvala';
    SELECT @j_kekana = ID FROM administracion.Jugador WHERE nombre = 'Grant' AND apellido = 'Kekana';
    SELECT @j_modiba = ID FROM administracion.Jugador WHERE nombre = 'Aubrey' AND apellido = 'Modiba';
    SELECT @j_mokoena = ID FROM administracion.Jugador WHERE nombre = 'Teboho' AND apellido = 'Mokoena';
    SELECT @j_sithole = ID FROM administracion.Jugador WHERE nombre = 'Sphephelo' AND apellido = 'Sithole';
    SELECT @j_zwane = ID FROM administracion.Jugador WHERE nombre = 'Themba' AND apellido = 'Zwane';
    SELECT @j_tau = ID FROM administracion.Jugador WHERE nombre = 'Percy' AND apellido = 'Tau';
    SELECT @j_morena = ID FROM administracion.Jugador WHERE nombre = 'Thapelo' AND apellido = 'Morena';
    SELECT @j_makgopa = ID FROM administracion.Jugador WHERE nombre = 'Evidence' AND apellido = 'Makgopa';
    SELECT @j_appollis = ID FROM administracion.Jugador WHERE nombre = 'Oswin' AND apellido = 'Appollis';
    SELECT @j_lepasa = ID FROM administracion.Jugador WHERE nombre = 'Zakhele' AND apellido = 'Lepasa';

    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_rsa, @id_jugador = @j_williams,  @es_titular = 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_rsa, @id_jugador = @j_mudau,     @es_titular = 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_rsa, @id_jugador = @j_mvala,     @es_titular = 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_rsa, @id_jugador = @j_kekana,    @es_titular = 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_rsa, @id_jugador = @j_modiba,    @es_titular = 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_rsa, @id_jugador = @j_mokoena,   @es_titular = 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_rsa, @id_jugador = @j_sithole,   @es_titular = 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_rsa, @id_jugador = @j_zwane,     @es_titular = 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_rsa, @id_jugador = @j_tau,       @es_titular = 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_rsa, @id_jugador = @j_morena,    @es_titular = 1;
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_rsa, @id_jugador = @j_makgopa,   @es_titular = 1;
    -- Suplentes
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_rsa, @id_jugador = @j_appollis,  @es_titular = 0;
    EXEC partido.sp_RegistrarAlineacion @id_formacion = @id_form_rsa, @id_jugador = @j_lepasa,    @es_titular = 0;

    PRINT '   + Alineaciones de 11 titulares por selección registradas correctamente.';

    -- =========================================================================================
    -- ETAPA 6: SUSTITUCIONES EN EL SEGUNDO TIEMPO (MÓDULO 2)
    -- =========================================================================================
    PRINT '>> [ETAPA 6] Registrando sustituciones tácticas vía partido.sp_RegistrarSustitucion...';

    -- Minuto 62 (México - Ventana 1): Sale Santiago Giménez, entra Uriel Antuna
    EXEC partido.sp_RegistrarSustitucion
        @id_partido = @id_partido,
        @id_jugador_sale = @j_gimenez,
        @id_jugador_entra = @j_antuna,
        @minuto = 62,
        @motivo = 'Táctico';

    -- Minuto 70 (México - Ventana 2): Sale Raúl Jiménez (tras marcar el 2-0), entra Roberto Alvarado
    EXEC partido.sp_RegistrarSustitucion
        @id_partido = @id_partido,
        @id_jugador_sale = @j_jimenez,
        @id_jugador_entra = @id_reemplazo,
        @minuto = 70,
        @motivo = 'Táctico';

    -- Minuto 75 (Sudáfrica - Ventana 1): Sale Evidence Makgopa, entra Zakhele Lepasa
    EXEC partido.sp_RegistrarSustitucion
        @id_partido = @id_partido,
        @id_jugador_sale = @j_makgopa,
        @id_jugador_entra = @j_lepasa,
        @minuto = 75,
        @motivo = 'Táctico';

    PRINT '   + Sustituciones registradas dentro del marco reglamentario IFAB.';

    -- =========================================================================================
    -- ETAPA 6.BIS: ARBITRAJE, DISCIPLINA Y GOLES OFICIALES (MÓDULO 3)
    -- =========================================================================================
    PRINT '>> [ETAPA 6.BIS] Designando árbitros, tarjetas y registrando goles del partido inaugural...';

    -- 1. Designación de Árbitro Neutral FIFA (Wilton Sampaio de Brasil)
    DECLARE @id_arbitro_sampaio INT;
    SELECT TOP 1 @id_arbitro_sampaio = ID FROM arbitraje.Arbitro WHERE apellido = 'Sampaio';

    IF @id_arbitro_sampaio IS NOT NULL
    BEGIN
        EXEC arbitraje.sp_DesignarArbitro
            @ID_Partido = @id_partido,
            @ID_Arbitro = @id_arbitro_sampaio,
            @Rol = 'Árbitro Principal',
            @Informe = 'Designación reglamentaria de árbitro neutral de CONMEBOL para el partido inaugural.';
        PRINT '   + Árbitro neutral designado (Wilton Sampaio - Brasil).';
    END;

    -- 2. Registro de Disciplina (Módulo 3):
    -- Minuto 41: Tarjeta Amarilla a Mothobi Mvala (Sudáfrica) por falta táctica
    EXEC partido.sp_RegistrarTarjetaYSuspension
        @ID_Partido = @id_partido,
        @ID_Jugador = @j_mvala,
        @ID_Cuerpo_Tecnico = NULL,
        @Minuto = 41,
        @Motivo = 'Falta táctica reiterada',
        @Tipo = 'AMARILLA',
        @Es_Doble_Amarilla = 0,
        @Partidos_Suspension = 1;

    -- Minuto 84: Tarjeta Amarilla a Edson Álvarez (México) por conducta antideportiva
    EXEC partido.sp_RegistrarTarjetaYSuspension
        @ID_Partido = @id_partido,
        @ID_Jugador = @j_alvarez,
        @ID_Cuerpo_Tecnico = NULL,
        @Minuto = 84,
        @Motivo = 'Discusión y conducta antideportiva',
        @Tipo = 'AMARILLA',
        @Es_Doble_Amarilla = 0,
        @Partidos_Suspension = 1;
    PRINT '   + Tarjetas disciplinarias registradas con éxito.';

    -- 3. Registro Oficial de Goles (Módulo 3 - sp_RegistrarGol):
    -- Gol 1: Minuto 09 - Julián Quiñones (Asistencia de Hirving Lozano) para México
    EXEC partido.sp_RegistrarGol
        @ID_Partido = @id_partido,
        @ID_Jugador_autor = @j_quinones,
        @ID_Jugador_asistencia = @j_lozano,
        @ID_Seleccion = @id_sel_mex,
        @Minuto = 9,
        @Tipo = 'Jugada',
        @Periodo = 'Primer Tiempo';

    -- Gol 2: Minuto 67 - Raúl Jiménez (Jugada individual) para México
    EXEC partido.sp_RegistrarGol
        @ID_Partido = @id_partido,
        @ID_Jugador_autor = @j_jimenez,
        @ID_Jugador_asistencia = NULL,
        @ID_Seleccion = @id_sel_mex,
        @Minuto = 67,
        @Tipo = 'Jugada',
        @Periodo = 'Segundo Tiempo';
    PRINT '   + Goles oficiales asentados vía sp_RegistrarGol (México 2 - 0 Sudáfrica).';

    -- =========================================================================================
    -- ETAPA 7: RESULTADO FINAL Y PLANILLAS OFICIALES DEL PARTIDO INAUGURAL 2026
    -- =========================================================================================
    PRINT '======================================================================';
    PRINT 'RESULTADO FINAL: MÉXICO 2 - 0 SUDÁFRICA';
    PRINT 'Goles: 09'' Julián Quiñones, 67'' Raúl Jiménez';
    PRINT '======================================================================';

    -- 1. Ficha del Partido (Marcador Oficial actualizado dinámicamente)
    SELECT 
        p.ID AS [ID Partido],
        '11/06/2026 13:00' AS [Fecha Inaugural Local],
        p.fecha_hora_utc AS [Hora UTC Oficial],
        s.nombre AS [Estadio Sede],
        s.ciudad AS [Ciudad],
        pl.nombre AS [Local],
        p.goles_local AS [Goles Local],
        pv.nombre AS [Visitante],
        p.goles_visitante AS [Goles Visitante],
        CASE 
            WHEN p.goles_local > p.goles_visitante THEN 'Victoria de ' + pl.nombre
            WHEN p.goles_local < p.goles_visitante THEN 'Victoria de ' + pv.nombre
            ELSE 'Empate'
        END AS [Estado Oficial]
    FROM partido.Partido p
    JOIN administracion.Sede s ON s.ID = p.ID_Sede
    JOIN administracion.Seleccion sl ON sl.ID = p.ID_Seleccion_Local
    JOIN administracion.Pais pl ON pl.ID = sl.ID_Pais
    JOIN administracion.Seleccion sv ON sv.ID = p.ID_Seleccion_Visitante
    JOIN administracion.Pais pv ON pv.ID = sv.ID_Pais
    WHERE p.ID = @id_partido;

    -- 1.BIS. Tabla de Goles Oficiales del Partido
    SELECT 
        g.minuto AS [Minuto],
        g.periodo AS [Tiempo],
        g.tipo AS [Tipo de Gol],
        autor.apellido + ', ' + autor.nombre AS [Goleador],
        ISNULL(asist.apellido + ', ' + asist.nombre, 'Sin asistencia') AS [Asistencia],
        p_gol.nombre AS [Selección Beneficiada]
    FROM partido.Gol g
    JOIN administracion.Jugador autor ON autor.ID = g.ID_Jugador_autor
    LEFT JOIN administracion.Jugador asist ON asist.ID = g.ID_Jugador_asistencia
    JOIN administracion.Seleccion s_gol ON s_gol.ID = g.ID_Seleccion
    JOIN administracion.Pais p_gol ON p_gol.ID = s_gol.ID_Pais
    WHERE g.ID_Partido = @id_partido
    ORDER BY g.minuto ASC;

    -- 1.TER. Tabla de Tarjetas y Disciplina
    SELECT 
        t.minuto AS [Minuto],
        t.tipo AS [Tarjeta],
        t.motivo AS [Infracción],
        j.apellido + ', ' + j.nombre AS [Amonestado / Expulsado],
        p_inf.nombre AS [Selección]
    FROM partido.Tarjeta t
    JOIN administracion.Jugador j ON j.ID = t.ID_Jugador
    JOIN administracion.Convocatoria c ON c.ID_Jugador = j.ID
    JOIN administracion.Seleccion s_inf ON s_inf.ID = c.ID_Seleccion
    JOIN administracion.Pais p_inf ON p_inf.ID = s_inf.ID_Pais
    WHERE t.ID_Partido = @id_partido
    ORDER BY t.minuto ASC;

    -- 2. Cuerpos Técnicos en el Banco
    SELECT 
        p.nombre AS [Selección],
        ct.apellido + ', ' + ct.nombre AS [Director Técnico Oficial],
        ct.rol AS [Rol]
    FROM administracion.Miembro_Cuerpo_Tecnico ct
    JOIN administracion.Seleccion s ON s.ID = ct.ID_Seleccion
    JOIN administracion.Pais p ON p.ID = s.ID_Pais
    WHERE s.ID IN (@id_sel_mex, @id_sel_rsa)
    ORDER BY p.nombre;

    -- 3. Planilla Oficial de Alineaciones (11 Titulares y Banco)
    SELECT 
        p.nombre AS [Selección],
        fp.esquema_tactico AS [Esquema],
        c.dorsal AS [Camiseta],
        j.apellido + ', ' + j.nombre AS [Futbolista],
        j.posicion_habitual AS [Posición],
        cl.nombre AS [Club],
        CASE WHEN al.es_titular = 1 THEN 'TITULAR' ELSE 'SUPLENTE' END AS [Condición]
    FROM partido.Alineacion al
    JOIN partido.Formacion_Partido fp ON fp.ID = al.ID_Formacion
    JOIN administracion.Seleccion s ON s.ID = fp.ID_Seleccion
    JOIN administracion.Pais p ON p.ID = s.ID_Pais
    JOIN administracion.Jugador j ON j.ID = al.ID_Jugador
    JOIN administracion.Convocatoria c ON c.ID_Jugador = j.ID
    JOIN administracion.Club cl ON cl.ID = j.ID_Club
    WHERE fp.ID_Partido = @id_partido
    ORDER BY p.nombre, al.es_titular DESC, c.dorsal ASC;

    -- 4. Sustituciones en el Segundo Tiempo
    SELECT 
        su.minuto AS [Min' de Juego],
        su.motivo AS [Motivo],
        js.apellido + ', ' + js.nombre AS [Jugador que SALE],
        je.apellido + ', ' + je.nombre AS [Jugador que ENTRA]
    FROM partido.Sustitucion su
    JOIN administracion.Jugador js ON js.ID = su.ID_Jugador_Sale
    JOIN administracion.Jugador je ON je.ID = su.ID_Jugador_Entra
    WHERE su.ID_Partido = @id_partido
    ORDER BY su.minuto ASC;

    -- 5. Reconstrucción Histórica: Once en Cancha al Minuto 70'
    SELECT 
        p.nombre AS [Selección],
        c.dorsal AS [Dorsal],
        j.apellido + ', ' + j.nombre AS [Futbolista en Cancha],
        j.posicion_habitual AS [Posición],
        CASE 
            WHEN al.es_titular = 1 THEN 'Titular inicial'
            ELSE 'Ingresó por sustitución (' + CAST(s_in.minuto AS VARCHAR(3)) + ''')'
        END AS [Estado al Minuto 70']
    FROM partido.Formacion_Partido fp
    JOIN administracion.Seleccion s ON s.ID = fp.ID_Seleccion
    JOIN administracion.Pais p ON p.ID = s.ID_Pais
    JOIN partido.Alineacion al ON al.ID_Formacion = fp.ID
    JOIN administracion.Jugador j ON j.ID = al.ID_Jugador
    JOIN administracion.Convocatoria c ON c.ID_Jugador = j.ID
    LEFT JOIN partido.Sustitucion s_in ON s_in.ID_Partido = fp.ID_Partido AND s_in.ID_Jugador_Entra = j.ID
    WHERE fp.ID_Partido = @id_partido
      AND (
          -- Caso A: Titular que NO salió antes o en el minuto 70
          (al.es_titular = 1 AND NOT EXISTS (
              SELECT 1 FROM partido.Sustitucion s_out 
              WHERE s_out.ID_Partido = fp.ID_Partido 
                AND s_out.ID_Jugador_Sale = j.ID 
                AND s_out.minuto <= 70
          ))
          OR
          -- Caso B: Suplente que YA ingresó antes o en el minuto 70
          (al.es_titular = 0 
           AND s_in.minuto <= 70
           AND NOT EXISTS (
              SELECT 1 FROM partido.Sustitucion s_out2 
              WHERE s_out2.ID_Partido = fp.ID_Partido 
                AND s_out2.ID_Jugador_Sale = j.ID 
                AND s_out2.minuto <= 70
           ))
      )
      -- Caso C: No expulsado antes o en el minuto 70
      AND NOT EXISTS (
          SELECT 1 FROM partido.Tarjeta t
          WHERE t.ID_Partido = fp.ID_Partido 
            AND t.ID_Jugador = j.ID 
            AND t.tipo = 'ROJA' 
            AND t.minuto <= 70
      )
    ORDER BY p.nombre, c.dorsal ASC;

END TRY
BEGIN CATCH
    PRINT 'ERROR EN LA INTEGRACIÓN: ' + ERROR_MESSAGE();
END CATCH;

-- Mantenemos la base limpia y aislada con ROLLBACK
IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;

PRINT '>> Transacción revertida con éxito: La base queda intacta.';
GO
