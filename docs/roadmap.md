# APEX TIMER · Hoja de ruta

App de cronometraje en circuito para moto · IA de Computer Science

**Regla que gobierna todo el proyecto:** nunca dos funcionalidades nuevas a la vez.
Una cosa, que funcione en el iPhone, subida a GitHub, anotada en el diario. Luego la siguiente.

**Segunda regla:** la documentación no se escribe al final. Se escribe mientras.

---

## FASE 0 · Antes de programar

Requisito del IB, no una recomendación. Los criterios A y B se hacen antes del código.

- [ ] Localizar al cliente: alguien que ruede en circuito de verdad
- [ ] Entrevistarlo y transcribir la conversación (con fecha)
- [ ] Redactar 6-10 criterios de éxito **medibles**, acordados con él
- [ ] Bocetos en papel de las cinco pantallas
- [ ] Diagrama entidad-relación de la base de datos

Mal criterio: *"que la app sea rápida"*.
Bien: *"el cronómetro detecta el cruce de meta con error inferior a 0,2 s"*.

> **No avances sin esto.** Los criterios de éxito son lo que evalúas uno a uno en el
> criterio E. Escribirlos al final para que encajen con lo que salió es el error más
> común del IA y se nota.

---

## FASE 1 · Entorno

- [ ] Visual Studio Code instalado
- [ ] Cuenta de GitHub + GitHub Desktop
- [ ] Repositorio creado con la estructura de carpetas (ver anexo)
- [ ] GitHub Pages activado → URL `https://usuario.github.io/trackapp/`
- [ ] Consola de depuración resuelta: Web Inspector por cable, o **Eruda** si no tienes Mac

El ciclo de trabajo será siempre: editar → guardar → commit → push → esperar 30 s → recargar en el iPhone.

**HTTPS no es opcional.** Sin él no existen ni el GPS ni los sensores. Por eso GitHub Pages.

---

## FASE 2 · Prueba de cadena completa

Una página con un botón que muestre la velocidad del GPS. Diez líneas.

- [ ] Subida y abierta en el iPhone
- [ ] Salir a la calle andando y comprobar que el número cambia

Parece una tontería y es la fase más importante. Si esto funciona, todo lo demás se
acumula encima. Si no funciona, mejor saberlo hoy.

---

## FASE 3 · JavaScript imprescindible

No hagas un curso completo. Viniendo de Python, solo te falta esto:

| Concepto | Equivalente mental |
|---|---|
| `let` / `const`, `;`, `{}` | Sintaxis, una tarde |
| Arrays y objetos `{}` | Listas y diccionarios |
| Funciones flecha `() => {}` | `lambda`, pero de uso general |
| **Eventos** | No existe en Python básico. **Clave** |
| **`async` / `await`** | Tampoco. **Clave** |
| DOM: `getElementById`, `textContent` | Manipular la página desde JS |

Los dos en negrita son el salto real. En Python tu programa manda. Aquí tu programa
**espera** y el navegador le avisa cuando pasa algo.

---

## FASE 4 · Construcción por módulos

El orden no es arbitrario: cada módulo depende del anterior.

### 4.1 · GPS y velocidad · `js/gps.js`

- [ ] `watchPosition()` con `enableHighAccuracy: true`
- [ ] Velocidad instantánea, media y máxima en pantalla
- [ ] Gestión de `coords.speed === null` (ocurre en los primeros fixes)

Recuerda: `coords.speed` viene en **m/s**. Multiplicar por 3,6 solo al mostrar.

### 4.2 · Base de datos local · `js/bd.js`

Antes de guardar un solo dato real.

- [ ] `vendor/sql-wasm.js` y `.wasm` descargados al repositorio (no CDN)
- [ ] Función de apertura: cargar desde IndexedDB o crear vacía
- [ ] `PRAGMA foreign_keys = ON` en **cada** apertura
- [ ] Aplicar `db/esquema.sql`
- [ ] Función `guardar()`: `db.export()` → IndexedDB
- [ ] Probar con los datos de prueba del esquema: consultar `v_vuelta_delta` y ver resultados

> **No persistas en cada muestra de GPS.** Se escribe en memoria continuamente y se
> guarda solo al cerrar cada vuelta y al terminar la sesión.

### 4.3 · Grabación de sesiones

- [ ] `INSERT` de `sesion` al pulsar iniciar, con `uuid` de `crypto.randomUUID()`
- [ ] `INSERT` de `muestra` en cada fix de GPS
- [ ] Botón de exportar `.db` (descarga de archivo)

### 4.4 · Modo replay ← *el módulo que te ahorra semanas*

- [ ] Graba una traza real: en coche, en bici, andando alrededor de una manzana. Da igual.
- [ ] `SELECT * FROM muestra WHERE sesion_id = ? ORDER BY t_ms`
- [ ] Reproducir esos puntos como si vinieran del GPS en directo

Sin esto, cada prueba del cronómetro exige ir a un circuito. Con esto, lo pruebas en
el sofá cien veces en diez minutos.

### 4.5 · Mapa y editor de circuito · `js/circuito.js`

- [ ] Leaflet + OpenStreetMap
- [ ] Tocar el mapa coloca puntos
- [ ] **Dos puntos = una línea**, no un punto suelto
- [ ] `INSERT` en `circuito` y `linea`
- [ ] Cargar circuitos guardados

### 4.6 · Detección de cruce y cronómetro · `js/crono.js` ← *el corazón*

- [ ] Intersección de segmentos: trayecto entre dos fixes contra la línea de meta
- [ ] **Interpolación** del instante exacto de cruce
- [ ] `INSERT` de `vuelta` al completarse
- [ ] Asignar `vuelta_id` a las muestras correspondientes

A 1 Hz y 200 km/h, un fix cubre 55 m. Sin interpolación el error es inaceptable;
con ella baja a ~0,1 s. Documéntalo: es de lo mejor que vas a tener.

### 4.7 · Pantalla de vueltas

- [ ] Tabla alimentada por la vista `v_vuelta_delta`
- [ ] Mejor vuelta resaltada
- [ ] Marcar vueltas como no válidas (entrada/salida de boxes)

Aquí se ve el retorno del esquema: la pantalla es prácticamente un `SELECT`.

### 4.8 · Delta contra la mejor vuelta

- [ ] Proyectar la posición actual sobre la traza de la vuelta de referencia
- [ ] Diferencia en vivo, con los tres estados de color

### 4.9 · Fuerzas G · `js/sensores.js`

- [ ] `DeviceMotionEvent.requestPermission()` dentro de un clic real
- [ ] Comprobación `typeof` (en Android y escritorio esa función no existe)
- [ ] Guardar `g_lat` y `g_lon` en `muestra`

### 4.10 · Inclinación por fusión de sensores

La parte algorítmicamente más lucida. **Déjala para cuando lo demás funcione.**

- [ ] Estimación por GPS + giróscopo: `θ ≈ arctan(v · ω / g)`
- [ ] Alternativa o complemento: filtro complementario sobre el alabeo

Un acelerómetro solo **no puede** medir inclinación en curva estabilizada: la
resultante queda alineada con el eje de la moto y marca cero. Esa explicación es
material directo para el criterio C.

### 4.11 · Acabado de interfaz

- [ ] Temas mediante variables CSS
- [ ] Wake Lock activado
- [ ] Estados vacíos y de error (sin GPS, sin circuito, permiso denegado)

Es lo primero que se sacrifica si vas justo de tiempo, pero es lo que ve el
examinador en las capturas. No lo dejes sin hacer.

### 4.12 · Mando Bluetooth como teclado HID

- [ ] Emparejar un mando barato de disparador de cámara
- [ ] Escuchar `keydown`

Web Bluetooth **no existe en iOS**. Ningún navegador del iPhone lo soporta. El rodeo
por HID a nivel de sistema operativo funciona y cuesta 10 €. Justificar esa elección
puntúa más que la funcionalidad en sí.

### 4.13 · Exportación

- [ ] `.db` — respaldo completo y fiel
- [ ] `.csv` — para que el cliente lo abra en Excel
- [ ] `.json` — vehículo de sincronización, con `uuid` y campo `sincronizada`

### 4.14 · Sincronización remota · OPCIONAL

**Solo si vas sobrado de tiempo.** Unas 10-15 horas.

- [ ] Esquema PostgreSQL equivalente
- [ ] Subida con `ON CONFLICT (uuid) DO NOTHING` → idempotente
- [ ] Row Level Security bien configurado

Si no llega, **documéntala como diseño conscientemente aplazado**. Una funcionalidad
bien especificada y descartada por restricciones de tiempo puntúa. Una a medias, no.

---

## FASE 5 · Pruebas y documentación

- [ ] **Prueba de campo real**: circuito, moto, sol, sesión completa
- [ ] Comportamiento térmico y consumo de batería
- [ ] Legibilidad con casco y guantes
- [ ] Evaluación contra los criterios de éxito de la Fase 0, uno a uno, con evidencia
- [ ] **Vídeo de 7 minutos** demostrando el producto ← requisito obligatorio
- [ ] Declaración de uso de IA: herramienta, fecha, qué generó, prompts en anexo

Monta el móvil en el colín o con soporte amortiguado: la vibración del manillar
destroza el estabilizador óptico del iPhone.

---

## Presupuesto de horas

El IB estima ~30 h. Siendo realista con tu punto de partida y con la base de datos
dentro, cuenta **75-85 h**:

| Bloque | % |
|---|---|
| Planificación y cliente | 12 |
| Aprender JavaScript | 15 |
| Desarrollo | 48 |
| Pruebas y documentación | 25 |

---

## Puntos de guardado documental

Congela una copia fechada del proyecto en cada uno de estos hitos. Son las
instantáneas que ilustran tu proceso de desarrollo:

1. Maqueta de interfaz terminada (ya lo tienes)
2. Base de datos funcionando con datos de prueba
3. Primer cruce de meta detectado correctamente en replay
4. Primera sesión real completa en circuito

---

## Anexo · Estructura del repositorio

```
trackapp/
├── index.html
├── css/
│   └── estilos.css
├── js/
│   ├── app.js          arranque, permisos, navegación
│   ├── bd.js           SQLite: abrir, consultar, persistir
│   ├── gps.js          watchPosition y velocidades
│   ├── sensores.js     acelerómetro, giróscopo, fusión
│   ├── circuito.js     mapa Leaflet y editor de líneas
│   └── crono.js        detección de cruce e interpolación
├── db/
│   ├── esquema.sql
│   └── consultas.sql   consultas de cada pantalla, comentadas
├── vendor/
│   ├── sql-wasm.js
│   ├── sql-wasm.wasm
│   └── leaflet/
├── fuentes/
│   └── *.woff2
├── datos/
│   └── sesion_prueba.db
└── docs/
    ├── diario.md       qué hiciste y qué problema resolviste, por fecha
    └── entrevista-cliente.md
```

Nada de npm, ni React, ni sistemas de compilación. Todo lo externo descargado al
repositorio: en circuito no hay cobertura.
