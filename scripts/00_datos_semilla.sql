/* 
   SOLO PARA PRUEBAS INDIVIDUALES 

   ADVERTENCIA: borra TODOS los datos de las 25 tablas antes de cargar.
                Los datos (clubes, fechas de nacimiento, PBI, fixture) son de prueba.
*/

USE Mundial2026;
GO

-- =========================================================================================
-- 1. LIMPIEZA (hijas primero) Y REINICIO DE IDENTITY
-- =========================================================================================
DELETE FROM publicidad.Exhibicion;
DELETE FROM publicidad.Espacio_publicitario;
DELETE FROM publicidad.Pieza_Pais_Interes;
DELETE FROM publicidad.Pieza_Contenido;
DELETE FROM publicidad.Campania;
DELETE FROM publicidad.Anunciante;

DELETE FROM partido.Partido_Perdido_Suspension;
DELETE FROM partido.Suspension;
DELETE FROM partido.Tarjeta;
DELETE FROM partido.Gol;
DELETE FROM partido.Sustitucion;
DELETE FROM arbitraje.Designacion_Arbitral;
DELETE FROM partido.Alineacion;
DELETE FROM partido.Formacion_Partido;
DELETE FROM partido.Partido;

DELETE FROM arbitraje.Idioma;
DELETE FROM arbitraje.Arbitro;
DELETE FROM administracion.Convocatoria;
DELETE FROM administracion.Jugador;
DELETE FROM administracion.Miembro_Cuerpo_Tecnico;
DELETE FROM administracion.Seleccion;
DELETE FROM administracion.Sede;
DELETE FROM administracion.Club;
DELETE FROM administracion.Fase_Torneo;
DELETE FROM administracion.Pais;
GO

DBCC CHECKIDENT ('publicidad.Exhibicion', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('publicidad.Espacio_publicitario', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('publicidad.Pieza_Pais_Interes', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('publicidad.Pieza_Contenido', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('publicidad.Campania', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('publicidad.Anunciante', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('partido.Partido_Perdido_Suspension', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('partido.Suspension', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('partido.Tarjeta', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('partido.Gol', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('partido.Sustitucion', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('arbitraje.Designacion_Arbitral', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('partido.Alineacion', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('partido.Formacion_Partido', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('partido.Partido', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('arbitraje.Idioma', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('arbitraje.Arbitro', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('administracion.Convocatoria', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('administracion.Jugador', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('administracion.Miembro_Cuerpo_Tecnico', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('administracion.Seleccion', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('administracion.Sede', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('administracion.Club', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('administracion.Fase_Torneo', RESEED, 0) WITH NO_INFOMSGS;
DBCC CHECKIDENT ('administracion.Pais', RESEED, 0) WITH NO_INFOMSGS;
GO

-- =========================================================================================
-- 2. PAÍSES (huso_horario = offset de referencia del mercado, en verano boreal)
-- =========================================================================================
INSERT INTO administracion.Pais (nombre, pbi_percapita, huso_horario) VALUES
    ('Argentina',        13650.00, '-03:00'),
    ('Argelia',           5300.00, '+01:00'),
    ('México',           13800.00, '-06:00'),
    ('Estados Unidos',   85000.00, '-04:00'),
    ('Canadá',           53000.00, '-04:00'),
    ('Brasil',           10300.00, '-03:00'),
    ('Francia',          44400.00, '+02:00'),
    ('Alemania',         52800.00, '+02:00'),
    ('Japón',            33800.00, '+09:00'),
    ('Polonia',          22100.00, '+02:00');
GO

-- =========================================================================================
-- 3. FASES DEL TORNEO
-- =========================================================================================
INSERT INTO administracion.Fase_Torneo (nombre, orden) VALUES
    ('Fase de Grupos', 1),
    ('Dieciseisavos',  2),
    ('Octavos',        3),
    ('Cuartos',        4),
    ('Semifinal',      5),
    ('Tercer Puesto',  6),
    ('Final',          7);
GO

-- =========================================================================================
-- 4. SEDES (el huso es el de la ciudad, no el del país)
-- =========================================================================================
INSERT INTO administracion.Sede (nombre, ciudad, capacidad, huso_horario, ID_Pais)
SELECT v.nombre, v.ciudad, v.capacidad, v.huso, p.ID
FROM (VALUES
    ('Estadio Azteca',  'Ciudad de México', 83000, '-06:00', 'México'),
    ('AT&T Stadium',    'Dallas',           94000, '-05:00', 'Estados Unidos'),
    ('MetLife Stadium', 'Nueva York',       82500, '-04:00', 'Estados Unidos'),
    ('SoFi Stadium',    'Los Ángeles',      70240, '-07:00', 'Estados Unidos'),
    ('BMO Field',       'Toronto',          45000, '-04:00', 'Canadá')
) AS v(nombre, ciudad, capacidad, huso, pais)
JOIN administracion.Pais p ON p.nombre = v.pais;
GO

-- =========================================================================================
-- 5. SELECCIONES (grupos de prueba)
-- =========================================================================================
INSERT INTO administracion.Seleccion (ID_Pais, confederacion, grupo_asignado)
SELECT p.ID, v.confederacion, v.grupo
FROM (VALUES
    ('Argentina', 'CONMEBOL', 'J'),
    ('Argelia',   'CAF',      'J'),
    ('México',    'CONCACAF', 'A'),
    ('Polonia',   'UEFA',     'A'),
    ('Brasil',    'CONMEBOL', 'C'),
    ('Francia',   'UEFA',     'I'),
    ('Alemania',  'UEFA',     'E'),
    ('Japón',     'AFC',      'F')
) AS v(pais, confederacion, grupo)
JOIN administracion.Pais p ON p.nombre = v.pais;
GO

-- Cuerpo técnico mínimo (un DT por selección de Argentina y Argelia)
INSERT INTO administracion.Miembro_Cuerpo_Tecnico (nombre, apellido, rol, ID_Seleccion)
SELECT v.nombre, v.apellido, v.rol, s.ID
FROM (VALUES
    ('Lionel',  'Scaloni', 'Director Técnico',  'Argentina'),
    ('Pablo',   'Aimar',   'Ayudante de Campo', 'Argentina'),
    ('Rachid',  'Benzidane', 'Director Técnico', 'Argelia')
) AS v(nombre, apellido, rol, pais)
JOIN administracion.Pais p ON p.nombre = v.pais
JOIN administracion.Seleccion s ON s.ID_Pais = p.ID;
GO

-- =========================================================================================
-- 6. CLUBES, JUGADORES Y CONVOCATORIAS
--    Argentina: nombres reales (clubes y fechas con fines de prueba).
--    Argelia: nombres ficticios.
--    14 por selección: alcanza para 11 titulares + 3 suplentes.
-- =========================================================================================
INSERT INTO administracion.Club (nombre) VALUES
    ('Aston Villa'), ('Atlético de Madrid'), ('Tottenham'), ('Manchester United'),
    ('Olympique Lyon'), ('Inter Miami'), ('Chelsea'), ('Liverpool'), ('Inter'),
    ('Benfica'), ('Sevilla'), ('Boca Juniors'), ('Club Argel FC');
GO

DECLARE @plantel TABLE (
    nombre VARCHAR(100), apellido VARCHAR(100), nacimiento DATE,
    club VARCHAR(100), posicion VARCHAR(30), pais VARCHAR(100), dorsal TINYINT
);

INSERT INTO @plantel VALUES
    -- Argentina
    ('Emiliano', 'Martínez',  '1992-09-02', 'Aston Villa',       'Arquero',       'Argentina',  1),
    ('Nahuel',   'Molina',    '1998-04-06', 'Atlético de Madrid','Defensor',      'Argentina',  2),
    ('Nicolás',  'Tagliafico','1992-08-31', 'Olympique Lyon',    'Defensor',      'Argentina',  3),
    ('Gonzalo',  'Montiel',   '1997-01-01', 'Sevilla',           'Defensor',      'Argentina',  4),
    ('Leandro',  'Paredes',   '1994-06-29', 'Boca Juniors',      'Mediocampista', 'Argentina',  5),
    ('Rodrigo',  'De Paul',   '1994-05-24', 'Inter Miami',       'Mediocampista', 'Argentina',  7),
    ('Julián',   'Álvarez',   '2000-01-30', 'Atlético de Madrid','Delantero',     'Argentina',  9),
    ('Lionel',   'Messi',     '1987-06-24', 'Inter Miami',       'Delantero',     'Argentina', 10),
    ('Ángel',    'Di María',  '1988-02-14', 'Benfica',           'Delantero',     'Argentina', 11),
    ('Cristian', 'Romero',    '1998-04-27', 'Tottenham',         'Defensor',      'Argentina', 13),
    ('Alexis',   'Mac Allister','1998-12-24','Liverpool',        'Mediocampista', 'Argentina', 20),
    ('Lautaro',  'Martínez',  '1997-08-22', 'Inter',             'Delantero',     'Argentina', 22),
    ('Enzo',     'Fernández', '2001-01-17', 'Chelsea',           'Mediocampista', 'Argentina', 24),
    ('Lisandro', 'Martínez',  '1998-01-18', 'Manchester United', 'Defensor',      'Argentina', 25),
     -- Suplentes adicionales de Argentina para permitir hasta 5 cambios / 4 ventanas
    ('Nicolás',  'Otamendi',  '1988-02-12', 'Benfica',           'Defensor',      'Argentina', 19),
    ('Paulo',    'Dybala',    '1993-11-15', 'AS Roma',           'Delantero',     'Argentina', 21),
    ('Gerónimo', 'Rulli',     '1992-05-20', 'Olympique Marsella','Arquero',       'Argentina', 12),
    ('Giovani',  'Lo Celso',  '1996-04-09', 'Real Betis',        'Mediocampista', 'Argentina', 16),
    -- Argelia (ficticios)
    ('Karim',    'Benali',    '1993-03-10', 'Club Argel FC',     'Arquero',       'Argelia',    1),
    ('Yacine',   'Boudiaf',   '1996-07-12', 'Club Argel FC',     'Defensor',      'Argelia',    2),
    ('Sofiane',  'Mansouri',  '1994-11-03', 'Club Argel FC',     'Defensor',      'Argelia',    3),
    ('Rayan',    'Haddad',    '1998-02-25', 'Club Argel FC',     'Defensor',      'Argelia',    4),
    ('Amir',     'Zerrouki',  '1995-09-14', 'Club Argel FC',     'Defensor',      'Argelia',    5),
    ('Nabil',    'Khelifi',   '1997-05-30', 'Club Argel FC',     'Mediocampista', 'Argelia',    6),
    ('Walid',    'Ferhat',    '1999-12-01', 'Club Argel FC',     'Mediocampista', 'Argelia',    8),
    ('Samir',    'Belkacem',  '1992-04-18', 'Club Argel FC',     'Mediocampista', 'Argelia',   10),
    ('Idir',     'Mokrani',   '2000-08-09', 'Club Argel FC',     'Delantero',     'Argelia',    9),
    ('Hamza',    'Slimani',   '1996-01-22', 'Club Argel FC',     'Delantero',     'Argelia',   11),
    ('Mehdi',    'Ouali',     '1998-10-05', 'Club Argel FC',     'Delantero',     'Argelia',   14),
    ('Tarek',    'Amrani',    '1994-06-27', 'Club Argel FC',     'Arquero',       'Argelia',   12),
    ('Lyes',     'Cherif',    '2001-03-16', 'Club Argel FC',     'Mediocampista', 'Argelia',   15),
    ('Anis',     'Djebbar',   '1999-07-08', 'Club Argel FC',     'Defensor',      'Argelia',   16);

INSERT INTO administracion.Jugador (nombre, apellido, fecha_nacimiento, ID_Club, posicion_habitual)
SELECT t.nombre, t.apellido, t.nacimiento, c.ID, t.posicion
FROM @plantel t
JOIN administracion.Club c ON c.nombre = t.club;

-- Convocatoria: todos en alta (estado = 1), sin fecha ni motivo de baja
INSERT INTO administracion.Convocatoria (ID_Jugador, ID_Seleccion, estado, dorsal, fecha, motivo)
SELECT j.ID, s.ID, 1, t.dorsal, NULL, NULL
FROM @plantel t
JOIN administracion.Jugador j ON j.nombre = t.nombre AND j.apellido = t.apellido
JOIN administracion.Pais p ON p.nombre = t.pais
JOIN administracion.Seleccion s ON s.ID_Pais = p.ID;
GO

-- =========================================================================================
-- 7. PARTIDOS (fecha_hora_utc = hora local - offset de la sede)
--    1) Argentina vs Argelia  - Dallas (-05:00)       - 17:00 local = 22:00 UTC
--    2) México vs Polonia     - Cd. de México (-06:00) - 13:00 local = 19:00 UTC
--    3) Francia vs Alemania   - Nueva York (-04:00)    - 15:00 local = 19:00 UTC (Dieciseisavos)
-- =========================================================================================
INSERT INTO partido.Partido
    (fecha_hora_local, fecha_hora_utc, ID_Fase, ID_Sede, ID_Seleccion_Local, ID_Seleccion_Visitante)
SELECT v.local_dt, DATEADD(HOUR, v.horas_a_utc, v.local_dt), f.ID, sd.ID, sl.ID, sv.ID
FROM (VALUES
    ('2026-06-16 17:00', 5, 'Fase de Grupos', 'AT&T Stadium',    'Argentina', 'Argelia'),
    ('2026-06-11 13:00', 6, 'Fase de Grupos', 'Estadio Azteca',  'México',    'Polonia'),
    ('2026-07-01 15:00', 4, 'Dieciseisavos',  'MetLife Stadium', 'Francia',   'Alemania')
) AS v(local_dt, horas_a_utc, fase, sede, local, visita)
JOIN administracion.Fase_Torneo f ON f.nombre = v.fase
JOIN administracion.Sede sd ON sd.nombre = v.sede
JOIN administracion.Pais pl ON pl.nombre = v.local
JOIN administracion.Seleccion sl ON sl.ID_Pais = pl.ID
JOIN administracion.Pais pv ON pv.nombre = v.visita
JOIN administracion.Seleccion sv ON sv.ID_Pais = pv.ID;
GO

-- =========================================================================================
-- 8. ÁRBITROS E IDIOMAS
--    Sampaio (Brasil), Elfath (EE.UU.), Marciniak (Polonia): neutrales en Argentina-Argelia.
--    Tello (Argentina): sirve para probar el conflicto de nacionalidad.
--    Turpin (Francia): conflicto en Francia-Alemania.
-- =========================================================================================
INSERT INTO arbitraje.Arbitro (nombre, apellido, categoria, ID_Pais)
SELECT v.nombre, v.apellido, v.categoria, p.ID
FROM (VALUES
    ('Wilton',  'Sampaio',   'FIFA Elite', 'Brasil'),
    ('Ismail',  'Elfath',    'FIFA Elite', 'Estados Unidos'),
    ('Szymon',  'Marciniak', 'FIFA Elite', 'Polonia'),
    ('Facundo', 'Tello',     'FIFA Elite', 'Argentina'),
    ('Clément', 'Turpin',    'FIFA Elite', 'Francia')
) AS v(nombre, apellido, categoria, pais)
JOIN administracion.Pais p ON p.nombre = v.pais;

INSERT INTO arbitraje.Idioma (lengua, ID_Arbitro)
SELECT v.lengua, a.ID
FROM (VALUES
    ('Portugués', 'Sampaio'), ('Inglés', 'Sampaio'),
    ('Inglés',    'Elfath'),
    ('Polaco',    'Marciniak'), ('Inglés', 'Marciniak'),
    ('Español',   'Tello'),
    ('Francés',   'Turpin'), ('Inglés', 'Turpin')
) AS v(lengua, apellido)
JOIN arbitraje.Arbitro a ON a.apellido = v.apellido;
GO

-- =========================================================================================
-- 9. PUBLICIDAD: anunciantes, campañas, piezas, países de interés y 4 espacios por partido
--    (Exhibicion queda vacía: la completa el SP del algoritmo)
-- =========================================================================================
INSERT INTO publicidad.Anunciante (nombre) VALUES
    ('Coca-Cola'), ('Adidas'), ('Visa'), ('YPF');

INSERT INTO publicidad.Campania (nombre, fecha_inicio, fecha_fin, ID_Anunciante)
SELECT v.campania, v.inicio, v.fin, a.ID
FROM (VALUES
    ('Sabor Mundial',          '2026-05-01', '2026-08-01', 'Coca-Cola'),
    ('Camisetas Selecciones',  '2026-05-15', '2026-07-31', 'Adidas'),
    ('Pagá Mundial',           '2026-06-01', '2026-07-31', 'Visa'),
    ('Energía Argentina',      '2026-06-01', '2026-07-20', 'YPF')
) AS v(campania, inicio, fin, anunciante)
JOIN publicidad.Anunciante a ON a.nombre = v.anunciante;

INSERT INTO publicidad.Pieza_Contenido (nombre, idioma, costo, ID_Campania)
SELECT v.pieza, v.idioma, v.costo, c.ID
FROM (VALUES
    ('Spot Coca-Cola ES',   'Español',   50000.00, 'Sabor Mundial'),
    ('Spot Coca-Cola EN',   'Inglés',    60000.00, 'Sabor Mundial'),
    ('Spot Adidas EN',      'Inglés',    75000.00, 'Camisetas Selecciones'),
    ('Spot Adidas FR',      'Francés',   70000.00, 'Camisetas Selecciones'),
    ('Spot Visa EN',        'Inglés',    90000.00, 'Pagá Mundial'),
    ('Spot YPF ES',         'Español',   40000.00, 'Energía Argentina')
) AS v(pieza, idioma, costo, campania)
JOIN publicidad.Campania c ON c.nombre = v.campania;

INSERT INTO publicidad.Pieza_Pais_Interes (ID_Pieza, ID_Pais)
SELECT pc.ID, p.ID
FROM (VALUES
    ('Spot Coca-Cola ES', 'Argentina'), ('Spot Coca-Cola ES', 'México'),
    ('Spot Coca-Cola EN', 'Estados Unidos'), ('Spot Coca-Cola EN', 'Canadá'),
    ('Spot Adidas EN',    'Alemania'), ('Spot Adidas EN', 'Japón'),
    ('Spot Adidas FR',    'Francia'),
    ('Spot Visa EN',      'Estados Unidos'), ('Spot Visa EN', 'Alemania'),
    ('Spot YPF ES',       'Argentina')
) AS v(pieza, pais)
JOIN publicidad.Pieza_Contenido pc ON pc.nombre = v.pieza
JOIN administracion.Pais p ON p.nombre = v.pais;

-- Se generan los espacios publicitarios iniciales exclusivamente para el Partido 1 (Argentina vs Argelia)
-- Los partidos 2 y 3 quedan sin espacios para validar los flujos del Módulo de Publicidad (test_07)
INSERT INTO publicidad.Espacio_publicitario (nombre, numero_slot, ID_Partido)
SELECT s.nombre, s.slot, p.ID
FROM partido.Partido p
CROSS JOIN (VALUES
    (1, 'Panel Perimetral Norte'),
    (2, 'Panel Perimetral Sur'),
    (3, 'Panel Perimetral Este'),
    (4, 'Panel Perimetral Oeste')
) AS s(slot, nombre)
WHERE p.ID = 1;
GO

-- =========================================================================================
-- 10. VERIFICACIÓN: filas por tabla
-- =========================================================================================
SELECT 'Pais' AS tabla, COUNT(*) AS filas FROM administracion.Pais
UNION ALL SELECT 'Fase_Torneo',            COUNT(*) FROM administracion.Fase_Torneo
UNION ALL SELECT 'Sede',                   COUNT(*) FROM administracion.Sede
UNION ALL SELECT 'Seleccion',              COUNT(*) FROM administracion.Seleccion
UNION ALL SELECT 'Miembro_Cuerpo_Tecnico', COUNT(*) FROM administracion.Miembro_Cuerpo_Tecnico
UNION ALL SELECT 'Club',                   COUNT(*) FROM administracion.Club
UNION ALL SELECT 'Jugador',                COUNT(*) FROM administracion.Jugador
UNION ALL SELECT 'Convocatoria',           COUNT(*) FROM administracion.Convocatoria
UNION ALL SELECT 'Partido',                COUNT(*) FROM partido.Partido
UNION ALL SELECT 'Arbitro',                COUNT(*) FROM arbitraje.Arbitro
UNION ALL SELECT 'Idioma',                 COUNT(*) FROM arbitraje.Idioma
UNION ALL SELECT 'Anunciante',             COUNT(*) FROM publicidad.Anunciante
UNION ALL SELECT 'Campania',               COUNT(*) FROM publicidad.Campania
UNION ALL SELECT 'Pieza_Contenido',        COUNT(*) FROM publicidad.Pieza_Contenido
UNION ALL SELECT 'Pieza_Pais_Interes',     COUNT(*) FROM publicidad.Pieza_Pais_Interes
UNION ALL SELECT 'Espacio_publicitario',   COUNT(*) FROM publicidad.Espacio_publicitario;

-- Control de horas: la columna UTC debe ser local + offset de la sede
SELECT p.ID, sd.nombre AS sede, sd.huso_horario, p.fecha_hora_local, p.fecha_hora_utc
FROM partido.Partido p
JOIN administracion.Sede sd ON sd.ID = p.ID_Sede;
GO

PRINT 'OK: datos semilla cargados correctamente en Mundial2026.';
GO

select * from administracion.Seleccion