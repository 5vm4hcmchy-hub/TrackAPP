-- =====================================================================
--  APEX TIMER · Esquema de base de datos
--  SQLite (ejecutado en el navegador mediante sql.js / WebAssembly)
--
--  Convenciones:
--   · Todos los tiempos y duraciones en MILISEGUNDOS (INTEGER).
--     Nunca se almacenan cadenas tipo "1:47.32": el formateo es
--     responsabilidad de la capa de presentacion.
--   · Marcas de tiempo absolutas en TEXT con formato ISO-8601 UTC.
--   · Velocidades en m/s (unidad nativa del GPS). La conversion a km/h
--     o mph se hace al mostrar, no al guardar.
--   · Angulos en grados. Inclinacion negativa = izquierda.
-- =====================================================================

-- SQLite NO aplica las claves foraneas por defecto.
-- Esta linea debe ejecutarse en CADA apertura de la base de datos.
PRAGMA foreign_keys = ON;


-- ---------------------------------------------------------------------
-- 1. CIRCUITOS
-- ---------------------------------------------------------------------
CREATE TABLE circuito (
    id           INTEGER PRIMARY KEY,
    nombre       TEXT    NOT NULL UNIQUE,
    pais         TEXT,
    longitud_m   REAL    CHECK (longitud_m IS NULL OR longitud_m > 0),
    creado_utc   TEXT    NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ','now'))
);


-- ---------------------------------------------------------------------
-- 2. LINEAS DE CRONOMETRAJE
--
--    Una linea de meta NO es un punto: es un SEGMENTO definido por dos
--    coordenadas (A y B). El algoritmo de deteccion comprueba si el
--    trayecto entre dos fixes consecutivos del GPS intersecta ese
--    segmento. Con un solo punto y un radio, un fix a 1 Hz a 200 km/h
--    puede saltarselo por completo.
-- ---------------------------------------------------------------------
CREATE TABLE linea (
    id           INTEGER PRIMARY KEY,
    circuito_id  INTEGER NOT NULL REFERENCES circuito(id) ON DELETE CASCADE,
    tipo         TEXT    NOT NULL CHECK (tipo IN ('meta','sector')),
    orden        INTEGER NOT NULL,
    lat_a        REAL    NOT NULL,
    lon_a        REAL    NOT NULL,
    lat_b        REAL    NOT NULL,
    lon_b        REAL    NOT NULL,
    UNIQUE (circuito_id, orden)
);

-- Indice parcial: garantiza como maximo UNA linea de meta por circuito.
CREATE UNIQUE INDEX ux_linea_meta_unica
    ON linea (circuito_id) WHERE tipo = 'meta';


-- ---------------------------------------------------------------------
-- 3. PILOTOS
-- ---------------------------------------------------------------------
CREATE TABLE piloto (
    id      INTEGER PRIMARY KEY,
    nombre  TEXT NOT NULL UNIQUE
);


-- ---------------------------------------------------------------------
-- 4. SESIONES
-- ---------------------------------------------------------------------
CREATE TABLE sesion (
    id           INTEGER PRIMARY KEY,
    circuito_id  INTEGER NOT NULL REFERENCES circuito(id) ON DELETE RESTRICT,
    piloto_id    INTEGER          REFERENCES piloto(id)   ON DELETE SET NULL,
    inicio_utc   TEXT    NOT NULL,
    fin_utc      TEXT,
    moto         TEXT,
    notas        TEXT
);

CREATE INDEX ix_sesion_circuito ON sesion (circuito_id, inicio_utc);


-- ---------------------------------------------------------------------
-- 5. VUELTAS
--
--    tiempo_ms es NULL mientras la vuelta esta en curso.
--    'valida' permite descartar vueltas de entrada y salida de boxes,
--    banderas amarillas, etc., sin borrar los datos.
-- ---------------------------------------------------------------------
CREATE TABLE vuelta (
    id          INTEGER PRIMARY KEY,
    sesion_id   INTEGER NOT NULL REFERENCES sesion(id) ON DELETE CASCADE,
    numero      INTEGER NOT NULL CHECK (numero > 0),
    tiempo_ms   INTEGER          CHECK (tiempo_ms IS NULL OR tiempo_ms > 0),
    valida      INTEGER NOT NULL DEFAULT 1 CHECK (valida IN (0,1)),
    UNIQUE (sesion_id, numero)
);


-- ---------------------------------------------------------------------
-- 6. TIEMPOS PARCIALES POR SECTOR
-- ---------------------------------------------------------------------
CREATE TABLE tiempo_sector (
    vuelta_id   INTEGER NOT NULL REFERENCES vuelta(id) ON DELETE CASCADE,
    sector      INTEGER NOT NULL CHECK (sector > 0),
    tiempo_ms   INTEGER NOT NULL CHECK (tiempo_ms > 0),
    PRIMARY KEY (vuelta_id, sector)
);


-- ---------------------------------------------------------------------
-- 7. MUESTRAS DE TELEMETRIA
--
--    Una fila por fix de GPS (aprox. 1 Hz). Es la tabla que mas crece:
--    unas 1.200 filas por sesion de 20 minutos.
--
--    t_ms son milisegundos transcurridos desde sesion.inicio_utc, no
--    una marca absoluta: ocupa menos y simplifica los calculos.
--
--    vuelta_id es NULL para las muestras anteriores al primer cruce de
--    meta (vuelta de lanzamiento).
-- ---------------------------------------------------------------------
CREATE TABLE muestra (
    id                  INTEGER PRIMARY KEY,
    sesion_id           INTEGER NOT NULL REFERENCES sesion(id) ON DELETE CASCADE,
    vuelta_id           INTEGER          REFERENCES vuelta(id) ON DELETE SET NULL,
    t_ms                INTEGER NOT NULL,
    lat                 REAL    NOT NULL,
    lon                 REAL    NOT NULL,
    vel_ms              REAL,
    rumbo_grados        REAL,
    precision_m         REAL,
    inclinacion_grados  REAL    CHECK (inclinacion_grados IS NULL
                                       OR inclinacion_grados BETWEEN -70 AND 70),
    g_lat               REAL,
    g_lon               REAL
);

CREATE INDEX ix_muestra_sesion  ON muestra (sesion_id, t_ms);
CREATE INDEX ix_muestra_vuelta  ON muestra (vuelta_id);


-- =====================================================================
--  VISTAS
--
--  Las metricas derivadas (velocidad maxima, media, inclinacion maxima)
--  NO se almacenan: se calculan desde las muestras. Asi no puede haber
--  incoherencia entre el dato bruto y el resumen, que es el argumento
--  de normalizacion que conviene defender en la documentacion.
--  Si el rendimiento llegase a ser un problema, se materializarian
--  estas vistas en columnas al cerrar cada vuelta.
-- =====================================================================

CREATE VIEW v_resumen_vuelta AS
SELECT
    v.id                                        AS vuelta_id,
    v.sesion_id,
    v.numero,
    v.tiempo_ms,
    v.valida,
    COUNT(m.id)                                 AS n_muestras,
    ROUND(MAX(m.vel_ms) * 3.6, 1)               AS vel_max_kmh,
    ROUND(AVG(m.vel_ms) * 3.6, 1)               AS vel_media_kmh,
    ROUND(MIN(m.inclinacion_grados), 1)         AS incl_max_izq,
    ROUND(MAX(m.inclinacion_grados), 1)         AS incl_max_der
FROM vuelta v
LEFT JOIN muestra m ON m.vuelta_id = v.id
GROUP BY v.id;


CREATE VIEW v_mejor_vuelta AS
SELECT
    sesion_id,
    MIN(tiempo_ms) AS mejor_ms
FROM vuelta
WHERE valida = 1 AND tiempo_ms IS NOT NULL
GROUP BY sesion_id;


-- Vueltas con su diferencia respecto a la mejor de la sesion.
-- Es la consulta que alimenta directamente la pantalla VUELTAS.
CREATE VIEW v_vuelta_delta AS
SELECT
    r.*,
    r.tiempo_ms - b.mejor_ms                    AS delta_ms,
    CASE WHEN r.tiempo_ms = b.mejor_ms THEN 1 ELSE 0 END AS es_mejor
FROM v_resumen_vuelta r
JOIN v_mejor_vuelta   b ON b.sesion_id = r.sesion_id;


-- =====================================================================
--  DATOS DE PRUEBA
--  Permiten desarrollar las pantallas sin haber pisado un circuito.
-- =====================================================================

INSERT INTO circuito (nombre, pais, longitud_m) VALUES
    ('Circuito de Almeria', 'ES', 4028.0);

INSERT INTO linea (circuito_id, tipo, orden, lat_a, lon_a, lat_b, lon_b) VALUES
    (1, 'meta',   0, 36.84120, -2.07310, 36.84105, -2.07285),
    (1, 'sector', 1, 36.84370, -2.07650, 36.84355, -2.07625),
    (1, 'sector', 2, 36.83910, -2.08020, 36.83895, -2.07995);

INSERT INTO piloto (nombre) VALUES ('Piloto de prueba');

INSERT INTO sesion (circuito_id, piloto_id, inicio_utc, moto) VALUES
    (1, 1, '2026-08-03T09:15:00Z', 'Kawasaki Ninja 125');

INSERT INTO vuelta (sesion_id, numero, tiempo_ms) VALUES
    (1, 1, 112180),
    (1, 2, 109750),
    (1, 3, 108020),
    (1, 4, 106900),
    (1, 5, 107440);