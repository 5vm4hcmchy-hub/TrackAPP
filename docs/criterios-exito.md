# TrackApp · Justificación y criterios de éxito

Internal Assessment · Computer Science
Autor: [nombre] · Fecha: [fecha]

---

## 1. Justificación del proyecto

El proyecto nace de combinar dos intereses propios: el motociclismo en circuito y la
programación. Rodar en tanda libre genera constantemente preguntas que la memoria no
puede responder —si una vuelta fue más rápida que la anterior, en qué punto se pierde
tiempo, si una trazada nueva funciona— y responderlas exige medir.

Las soluciones existentes son de dos tipos: cronómetros de transpondedor, caros y
atados a la organización del circuito, o aplicaciones móviles que funcionan como cajas
negras, con datos encerrados en formatos propietarios y sin posibilidad de consultarlos
libremente.

Construir una herramienta propia permite decidir exactamente qué se mide, cómo se
almacena y cómo se consulta. Es también un problema técnicamente interesante: sensores
en tiempo real, geometría computacional para detectar el cruce de meta, y un modelo de
datos relacional para el historial. Es decir, un problema real con restricciones reales
—sin cobertura, con guantes, a 200 km/h— y no un ejercicio académico.

---

## 2. Alcance

### Dentro del alcance

- Aplicación web ejecutada en Safari sobre iPhone, montado en la moto
- Definición de circuitos con línea de meta y sectores sobre un mapa
- Cronometraje automático de vueltas por detección de cruce de línea
- Diferencia en vivo contra la mejor vuelta de la sesión
- Almacenamiento en base de datos relacional SQL en el propio dispositivo
- Consulta del historial de sesiones anteriores
- Funcionamiento completo sin conexión a internet

### Fuera del alcance

- Aplicación nativa de iOS (App Store)
- Sincronización con servidor remoto
- Comparación con otros pilotos o funciones sociales
- Integración con la centralita de la moto

### Extensiones opcionales

Se implementarán solo si el calendario lo permite. **No forman parte de los criterios
de éxito** y su ausencia no supone un fallo del proyecto.

- Estimación del ángulo de inclinación por fusión de sensores
- Registro de fuerzas G
- Mando Bluetooth como disparador de vuelta manual
- Personalización de temas de color
- Sincronización con base de datos PostgreSQL remota

---

## 3. Criterios de éxito

Cada criterio es verificable con un sí o un no. La columna de verificación indica el
procedimiento concreto con el que se comprobará en la evaluación final.

### Funcionalidad núcleo

**CE-1 · Definición de circuitos**
El usuario puede crear un circuito trazando su línea de meta mediante dos puntos sobre
un mapa, asignarle un nombre y guardarlo. Al cerrar y reabrir la aplicación, el
circuito sigue disponible y es seleccionable.

> *Verificación:* crear tres circuitos, cerrar el navegador por completo, reabrir y
> comprobar que los tres aparecen con sus coordenadas intactas.

**CE-2 · Detección automática de vueltas**
Sobre una traza de referencia que contiene un número conocido de vueltas completas, la
aplicación detecta exactamente ese número de cruces de meta, sin omisiones ni falsos
positivos.

> *Verificación:* reproducir en modo replay una traza con 10 vueltas verificadas
> manualmente sobre el mapa. La aplicación debe registrar 10 vueltas.

**CE-3 · Precisión del cronómetro**
El tiempo de vuelta calculado difiere en menos de 0,2 s del tiempo de referencia
obtenido por interpolación manual sobre la misma traza.

> *Verificación:* calcular a mano el instante de cruce de cinco vueltas a partir de las
> marcas de tiempo y coordenadas de los fixes, y contrastar con el valor que produce la
> aplicación.
>
> *Justificación del umbral:* a 1 Hz —frecuencia medida en pruebas de campo— y a
> 200 km/h, un fix cubre 56 m. Sin interpolación el error alcanzaría ±0,5 s, magnitud
> superior a las diferencias que se pretenden detectar entre vueltas.

**CE-4 · Diferencia en vivo**
Durante una vuelta, la aplicación muestra de forma continua la diferencia acumulada
respecto a la mejor vuelta de la sesión, actualizada en cada fix de GPS, y diferenciada
visualmente según se vaya por delante, por detrás o en tiempo.

> *Verificación:* reproducir una sesión de al menos cinco vueltas y comprobar que el
> valor se actualiza en cada fix y que el signo es coherente con los tiempos finales.

### Datos

**CE-5 · Almacenamiento relacional**
Toda la información —circuitos, líneas, sesiones, vueltas y muestras de telemetría— se
almacena en una base de datos SQL con integridad referencial activa. Los datos
sobreviven al cierre completo de la aplicación.

> *Verificación:* completar una sesión, cerrar el navegador, reabrir y comprobar que
> los datos persisten. Intentar insertar una vuelta con un identificador de sesión
> inexistente debe ser rechazado por la base de datos.

**CE-6 · Consulta del historial**
El usuario puede seleccionar cualquier sesión anterior y ver la lista completa de sus
vueltas con el tiempo de cada una y su diferencia respecto a la mejor, generada
mediante consulta SQL sobre los datos almacenados.

> *Verificación:* registrar tres sesiones distintas y comprobar que cada una muestra
> sus propias vueltas, con la mejor correctamente identificada.

**CE-7 · Exportación**
Una sesión puede exportarse como archivo de base de datos completo y como archivo CSV
legible en una hoja de cálculo.

> *Verificación:* exportar una sesión, abrir el CSV en una hoja de cálculo y comprobar
> que las filas coinciden con las mostradas en pantalla.

### Condiciones de uso

**CE-8 · Funcionamiento sin conexión**
Tras una primera carga, la aplicación opera completamente en modo avión: registra
vueltas, calcula tiempos, consulta el historial y guarda datos sin acceso a internet.

> *Verificación:* cargar la aplicación, activar el modo avión y completar una sesión
> de replay entera.

**CE-9 · Legibilidad en marcha**
Los tres datos principales —velocidad, tiempo de vuelta y diferencia— son
identificables en una sola mirada de menos de un segundo, a 60 cm de distancia y bajo
luz solar directa. Todos los controles táctiles son operables con guantes de piel.

> *Verificación:* prueba con tres personas ajenas al proyecto, en exterior a pleno sol,
> pidiéndoles que lean cada valor tras un vistazo breve. Medición de las zonas táctiles:
> mínimo 64 px de lado.

**CE-10 · Sesión completa sin interrupción**
La aplicación mantiene una sesión de 20 minutos continuos sin que la pantalla se apague
y sin pérdida de datos.

> *Verificación:* sesión cronometrada de 20 minutos con el dispositivo desatendido.
> Comprobar al final que el número de muestras registradas corresponde al tiempo
> transcurrido.

---

## 4. Gestión de riesgos

| Riesgo | Impacto | Mitigación |
|---|---|---|
| No conseguir acceso a circuito antes de la entrega | CE-2, CE-3, CE-9 sin validar en condiciones reales | Todos los criterios de precisión se verifican contra trazas de referencia en modo replay, procedimiento reproducible e independiente del acceso a pista. La prueba en circuito es validación adicional, no evidencia única. |
| Sobrecalentamiento del dispositivo al sol | Pérdida de sesión | Prueba específica dentro de CE-10. Registro incremental en base de datos para que una interrupción no invalide los datos ya recogidos. |
| La estimación de inclinación no alcanza precisión aceptable | Ninguno sobre los criterios | Clasificada como extensión opcional desde el diseño inicial. |
| Purga del almacenamiento del navegador por inactividad | Pérdida de historial | Exportación a archivo (CE-7) como respaldo, disponible desde las primeras fases. |

---

## 5. Registro de cambios

| Fecha | Cambio | Motivo |
|---|---|---|
| [fecha] | Versión inicial | — |
