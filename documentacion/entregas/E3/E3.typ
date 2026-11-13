#import "../../typst/configuracion.typ": informe

#show: informe.with(
  titulo: "Informe de Avance - Noviembre",
)

= Descripción general del proyecto
El proyecto tiene como objetivo comparar dos métodos de estimación de orientación tridimensional. Para esto, se está desarrollando un sistema de adquisición y visualización de orientación a partir de los datos obtenidos de una unidad de medición inercial (IMU). El primer método utiliza la orientación calculada por el procesador digital de movimiento (DMP) del sensor y el segundo emplea filtros implementados por software sobre las mediciones del acelerómetro, el giroscopio y el magnetómetro.

Inicialmente se planteó utilizar un sensor MPU9250 en lugar de un MPU6050 para contar con los datos del magnetómetro, potencialmente útiles como referencia para el eje de yaw. Sin embargo, debido a la dificultad para conseguir este sensor y a que las unidades disponibles no funcionaron correctamente, se decidió volver a la propuesta original y utilizar un MPU6050, complementando sus mediciones con un magnetómetro QMC5883L.

El dispositivo final estará compuesto por ambos sensores montados sobre un guante y conectados por I²C a un ESP32. Los resultados se transmitirán a una interfaz web que mostrará dos modelos tridimensionales y una gráfica de diferencias entre estimaciones.

= Materiales y presupuesto
En la @tab-materiales se presenta la lista de materiales y presupuesto del proyecto.
#figure(
  table(
    columns: (0.8fr, 2.6fr, 0.9fr, 1.1fr),
    align: (x, y) => if y == 0 { center } else { (center, left, center, right).at(x) },
    inset: 5pt,
    stroke: 0.5pt,
    table.header([*Cantidad*], [*Descripción*], [*Disponible*], [*Precio unitario*]),
    [1], [#link("https://www.mercadolibre.com.ar/esp32-nodemcu-wroom32-38-pines-usbc-wifi-bluetooth-arduino/up/MLAU5001930260?pdp_filters=item_id:MLA3878662278#is_advertising=true&searchVariation=MLAU5001930260&backend_model=search-backend&be_origin=backend&position=1&search_layout=grid&type=pad&tracking_id=9cd4be54-9d01-4f56-8f09-c12251c0e86e&ad_domain=VQCATCORE_LST&ad_position=1&ad_click_id=N2U1Mzg1NWUtNzM0My00NmNlLWJjZjItNTkyYTkxNzU4ZTkz")[ESP32 NodeMCU WROOM-32, 38 pines, USB-C, Wi-Fi y Bluetooth]], [Sí], [\$20.700],
    [1], [#link("https://www.zur3d.com.ar/producto/mpu-6050-acelerometro-giroscopio-3-ejes/")[MPU6050]], [Sí], [\$6.000],
    [1], [#link("https://www.mercadolibre.com.ar/sensor-magnetico-3-ejes-hmc5883l-brujula-i2c-candy-ho-arduino-gy273/p/MLA46859560")[Magnetómetro QMC5883L]], [Sí], [\$7.266],
    [1], [Guante para montaje del sistema], [Pendiente], [A definir],
    [1], [Juego de cables Dupont x10], [Sí], [—],
    [1], [Capacitor de desacople de 0,1 µF], [Sí], [—],
    [1], [Cable MicroUSB para alimentación y programación], [Sí], [—],
    [1], [Batería para alimentación portátil], [Sí], [—],
    [1], [Placa perforada para el montaje de componentes], [Sí],[\$4000],
    [2], [Tiras de pines hembra], [Sí],[\$2000],
    [1], [Tira de pines macho], [Sí],[\$1000],
    table.cell( colspan: 3, fill: luma(235), align: right, [*Total*]),
    table.cell( fill: luma(235), align: right, [*\$40.966*]),
  ),
  caption: [Materiales necesarios para el desarrollo del prototipo y su disponibilidad.],
  kind: table,
) <tab-materiales>

La cátedra proporcionó el ESP32 y las dos unidades del módulo MPU9250 que se habían probado anteriormente. El MPU6050 y el magnetómetro QMC5883L fueron adquiridos por el equipo de desarrollo para realizar los ensayos y, tras el cambio de propuesta, pasan a ser los sensores definitivos.

Los demás materiales ya estaban disponibles, por lo que solo resta adquirir el guante sobre el cual se montará el sistema.

En la propuesta inicial se contemplaba el uso de tres capacitores de desacople. Sin embargo, durante el montaje se comprobó que dos de ellos correspondían a pines que no se utilizan en este proyecto, por lo que la cantidad se redujo a uno. Esta decisión deberá verificarse al armar el prototipo final, ya que es posible que no se requiera ninguno.

El resto de los materiales se mantiene según lo establecido en el plan de proyecto. Con el cambio de sensores, el costo total se redujo de \$48.660 a \$40.966, incluso después de la adquisisión de componentes para el montaje del sistema.

= Esquema gráfico del proyecto

La arquitectura del sistema separa las etapas de adquisición, procesamiento y visualización, tal como se presentó en el Plan de Proyecto (@fig-esquema-general2). El ESP32 recibe las mediciones por I²C, estima la orientación mediante los dos métodos previstos y transmite los resultados a la interfaz de visualización.

#figure(
  image("../../imagenes/diagrama_bloque.png", width: 100%),
  caption: [
    Diagrama de bloques del sistema presentado en el Plan de Proyecto.
  ],
  kind: image,
) <fig-esquema-general2>

El prototipo final mantiene esta estructura, a excepción de los sensores. Sobre el ESP32 se ejecutan en paralelo las dos rutas de estimación, con una frecuencia de adquisición de 50 Hz. Los resultados se envían a la computadora por Wi-Fi, reemplazando la conexión USB serie implementada durante las pruebas de octubre. La interfaz web muestra los dos modelos tridimensionales de la mano y un gráfico con la diferencia entre ambas estimaciones. El esquema resultante se presenta en la @fig-esquema-final.

#figure(
  {
    let caja(titulo, detalle: none) = box(
      width: 100%,
      inset: 7pt,
      stroke: 0.6pt,
      fill: luma(255),
      align(center)[
        *#titulo*
        #if detalle != none [
          #text(size: 8pt)[\ #detalle]
        ]
      ],
    )
    let contenedor(titulo, ..cuerpo) = box(
      width: 100%,
      inset: 7pt,
      stroke: 0.6pt,
      fill: luma(230),
      align(center, stack(spacing: 5pt, strong(titulo), ..cuerpo)),
    )
    let flecha(etiqueta) = align(center + horizon)[
      #text(size: 8pt)[#etiqueta] \
      #sym.arrow.r.long
    ]
    let etapa(texto) = align(center)[
      #text(size: 8pt, tracking: 0.5pt)[#upper(texto)]
    ]

    grid(
      columns: (1.7fr, 0.7fr, 2.2fr, 0.7fr, 1.4fr),
      row-gutter: 5pt,
      align: horizon,
      contenedor(
        "Guante",
        caja("MPU6050", detalle: [Acelerómetro+giroscopio \ DMP]),
        caja("QMC5883L", detalle: [Magnetómetro]),
      ),
      flecha([I²C]),
      contenedor(
        "ESP32",
        caja("Adquisición a 50 Hz"),
        grid(
          columns: (1fr, 1fr),
          column-gutter: 4pt,
          caja("Ruta A", detalle: [Orientación DMP]),
          caja("Ruta B", detalle: [Filtrado por software]),
        ),
        caja("Preparación y envío de datos"),
      ),
      flecha([Wi-Fi]),
      contenedor(
        "Computadora",
        caja("Interfaz web", detalle: [Dos modelos 3D \ Gráfico comparativo]),
      ),

      etapa[Sensado], [], etapa[Procesamiento], [], etapa[Visualización],
    )
  },
  caption: [Diagrama de bloques actual.],
  kind: image,
) <fig-esquema-final>

= Grado de avance, problemas y soluciones

En la primera etapa del proyecto se completaron 5 de las 6 tareas planificadas: la investigación teórica y de librerías, la adquisición y conexión del hardware, la comunicación I²C y lectura de datos (tanto crudos como los del DMP), la configuración inicial y la implementación del filtro complementario. Quedaron pendientes para esta etapa el montaje del hardware y la transmisión Wi-Fi del ESP32 a la PC.

Para la segunda etapa, el plan de proyecto preveía completar la calibración del DMP, implementar el filtro de Kalman, refinar el filtro complementario, desarrollar la interfaz con visualización 3D, el selector de filtros y el gráfico de error, e integrar el prototipo final (@fig-gantt).

#figure(
  {
    set text(size: 7.5pt)

    // Paleta de colores
    let col-f2 = rgb("2c7a7b") // Teal (Fase 2)
    let col-hito = rgb("c92a2a") // Rojo para hitos
    let linea-puntos = (stroke: 0.4pt + luma(215), dash: "dotted")

    // Barra de tarea limpia
    let bar(fill-col) = block(
      fill: fill-col.lighten(15%),
      height: 8.5pt,
      width: 100%,
      radius: 2.5pt,
    )

    // Celda de hito (diamante centrado)
    let celda-hito() = table.cell(
      fill: col-hito.lighten(92%),
      align: center + horizon,
      text(fill: col-hito.darken(10%), size: 7.5pt, [◆]),
    )

    table(
      columns: (3fr, ..(1fr,) * 4),
      align: (left + horizon, ..(center + horizon,) * 4),
      inset: (x: 2.5pt, y: 4pt),
      stroke: (x, y) => {
        if y == 0 { (bottom: 1pt + luma(120), rest: none) } else if y == 1 {
          (bottom: 0.8pt + luma(160), rest: none)
        } else if x > 0 { (right: linea-puntos.stroke, rest: none) } else { none }
      },
      fill: (x, y) => {
        if y < 2 { luma(246) } else if x > 0 and calc.even(x) { luma(252) } else { none }
      },

      // Fila 1: Meses
      table.cell(rowspan: 2, align: left + horizon)[*Fase / Tarea planificada*],
      table.cell(colspan: 3)[*Octubre*],
      table.cell(colspan: 1)[*Noviembre*],

      // Fila 2: Semanas (Fecha lunes)
      [12], [19], [26], [2],

      // FASE 2
      table.cell(colspan: 5, fill: col-f2.lighten(92%), inset: 4pt)[
        #text(weight: "bold", fill: col-f2.darken(25%))[Etapa 2: Integración, Filtro de Kalman y visualización 3D]
      ],
      [Calibración fina de offsets del DMP], table.cell(colspan: 1)[#bar(col-f2)], ..([],) * 3,
      [Implementación y ajuste del Filtro de Kalman], table.cell(colspan: 2)[#bar(col-f2)], ..([],) * 2,
      [Desarrollo visual (manos 3D)], table.cell(colspan: 3)[#bar(col-f2)], [],
      [Optimización del Filtro Complementario], [], table.cell(colspan: 2)[#bar(col-f2)], [],
      [Panel selector y graficador de error], [], table.cell(colspan: 2)[#bar(col-f2)], [],
      [Integración de prototipo funcional (50 Hz)], ..([],) * 3, table.cell(colspan: 1)[#bar(col-f2)],
      [Redacción del Informe de Avance E3], ..([],) * 3, table.cell(colspan: 1)[#bar(col-f2)],

      // HITO E3
      table.cell(colspan: 5, fill: col-hito.lighten(90%), inset: 4pt)[
        #text(weight: "bold", fill: col-hito.darken(25%))[Entrega formal (hito)]
      ],
      [Informe de Avance 2 (E3) -- 08/11/2026], ..([],) * 3, celda-hito(),
    )
  },
  caption: [Diagrama de Gantt de la Etapa 2.],
  kind: table,
) <fig-gantt>

En las siguientes secciones se evalúa el grado de avance de cada uno de estos items.

== Montaje de hardware

Se mantuvo la conexión utilizada en el informe de avance de octubre, la cual se muestra en la @fig-arquitectura, agregando la conexión a los pines VIN y GND del otro lado del ESP32 para conectar la batería.
#figure(
  image("../../imagenes/esquema_mpu_magnetometro.png", width: 70%),
  caption: [Esquema de arquitectura general del sistema.],
  kind: image,
) <fig-arquitectura>

El montaje sobre el guante no se realizó y queda pendiente para la próxima etapa. Sí se comenzó el armado de los componentes sobre una placa perforada, utilizando tiras de pines hembra para poder retirar los sensores y el ESP32 con facilidad. Todavía no se realizaron las soldaduras de las conexiones.

#figure(
  grid(
    columns: (1fr, 1fr),
    gutter: 2em,
    [
        #image("../../imagenes/montaje.jpg", width: 100%)
    ],
    [
      #image("../../imagenes/montaje_mano.jpg", width: 100%)
    ]
  ),
  caption: [Avance del montaje de hardware.],
  kind: image,
)<fig-prototipo-completo>

== Transmisión Wi-Fi del ESP32 a la PC

Durante esta etapa se completó la transmisión inalámbrica de las dos orientaciones, que en el informe anterior había quedado pendiente y se reemplazaba por una conexión USB serie. El ESP32 envía los resultados a la interfaz web por Wi-Fi, y la página puede además controlar el firmware mediante comandos.

=== Conexión

Para la transmisión se utilizó WebSocket, que mantiene una única conexión abierta por la que el ESP32 envía mensajes de texto a medida que están disponibles. Frente a un esquema de pedidos HTTP, esto evita abrir una conexión por cada dato y reduce la latencia. Se empleó la librería `WebSocketsServer`, con el ESP32 como servidor en el puerto 81.

El ESP32 trabaja en modo Access Point más estación (`WIFI_AP_STA`). Por un lado, crea su propia red (`ManoDMP`), que siempre queda activa y permite usar el sistema sin depender de un router. Por otro, si existe un archivo `secretos.h` con las credenciales de una red local, se conecta a ella con una dirección IP fija y se anuncia por mDNS como `manodmp.local`. Además, se desactivó el ahorro de energía del Wi-Fi para reducir la latencia (@cod-wifi-inicio).

#figure(
  caption: [Inicio del Wi-Fi, Access Point, conexión a la red local y servidor WebSocket.],
  kind: "codigo",
  [
```cpp
static void wifiIniciar() {
  bool usarRed = strlen(RED_SSID) > 0;
  WiFi.mode(usarRed ? WIFI_AP_STA : WIFI_AP);
  WiFi.softAP(AP_SSID, AP_PASS);            // red propia, siempre activa

  if (usarRed) {
    IPAddress local_IP(192, 168, 0, 11);    // IP fija en la red local
    IPAddress gateway(192, 168, 0, 1);
    IPAddress subnet(255, 255, 255, 0);
    WiFi.config(local_IP, gateway, subnet);
    WiFi.begin(RED_SSID, RED_CLAVE);

    uint32_t t0 = millis();
    while (WiFi.status() != WL_CONNECTED && millis() - t0 < TIMEOUT_RED_MS) {
      delay(250);
    }
  }
  WiFi.setSleep(false); // reduce la latencia

  if (usarRed && WiFi.status() == WL_CONNECTED && MDNS.begin(NOMBRE_MDNS)) {
    MDNS.addService("ws", "tcp", PUERTO_WS); // ws://manodmp.local:81
  }
  ws.begin();
  ws.onEvent(eventoWs);
}
```
  ]
) <cod-wifi-inicio>

Si la conexión a la red local falla dentro del tiempo de espera de 10 segundos, el equipo continúa funcionando solo con su red propia.

=== Formato y frecuencia de los mensajes

Cada mensaje es un objeto JSON con un contador de muestras (`n`), el timestamp del ESP32 en milisegundos (`t`), el filtro activo (`f`) y las dos orientaciones como cuaterniones `[w, x, y, z]`, la del DMP (`dmp`) y la estimada por software (`sw`). Se eligieron cuaterniones porque el DMP los entrega de forma nativa y porque simplifican la comparación entre ambas estimaciones en la interfaz. Como la estimación por software se calcula en ángulos de Euler, se convierte a cuaternión antes de enviarla. El contador permite que la página detecte mensajes perdidos (@cod-envio-muestra).

#figure(
  caption: [Armado y envío de cada mensaje por WebSocket.],
  kind: "codigo",
  [
```cpp
static void enviarMuestra(const Quaternion& qDmp) {
  if (!transmitiendo || ws.connectedClients() == 0) return;

  float r, p, y; const char* nombre;
  elegirEstimacion(r, p, y, nombre);        // según el filtro elegido
  float s[4];
  cuatDesdeEuler(r, p, y, s);               // estimación por software

  char buf[200];
  int n = snprintf(buf, sizeof(buf),
    "{\"n\":%lu,\"t\":%lu,\"f\":\"%s\","
    "\"dmp\":[%.5f,%.5f,%.5f,%.5f],\"sw\":[%.5f,%.5f,%.5f,%.5f]}",
    (unsigned long) contadorEnvio++, (unsigned long) millis(), nombre,
    qDmp.w, qDmp.x, qDmp.y, qDmp.z, s[0], s[1], s[2], s[3]);
  ws.broadcastTXT(buf, n);
}
```
  ]
) <cod-envio-muestra>

El DMP entrega paquetes a aproximadamente 100 Hz. Para alcanzar la frecuencia objetivo de 50 Hz, solo se transmite uno de cada dos paquetes (@cod-divisor), aunque los filtros procesan todos para integrar con mayor resolución . Además, si no hay ningún cliente conectado o la transmisión está pausada, no se arma el mensaje para no gastar tiempo de procesamiento.

#figure(
  caption: [Submuestreo del envío a 50 Hz.],
  kind: "codigo",
  [
```cpp
static const uint8_t DIVISOR_ENVIO = 2;

// En procesarPaquete(), luego de actualizar los filtros:
if (++contadorPaquetes % DIVISOR_ENVIO == 0) enviarMuestra(q);
```
  ]
) <cod-divisor>

=== Comandos desde la página

La conexión es bidireccional: la interfaz envía comandos JSON cortos para iniciar o detener la transmisión, elegir el filtro (`comp`, `mag` o `kalman`) y pedir la calibración del sensor o del magnetómetro. Para no depender de otra librería, el firmware busca las palabras clave en el texto recibido (@cod-comandos).

Algunos de estos comandos implican tareas lentas. La calibración del MPU6050, por ejemplo, ejecuta `CalibrateAccel` y `CalibrateGyro`, que tardan varios segundos. Si se realizara dentro del evento de red, el ESP32 dejaría de atender el WebSocket durante ese tiempo, se detendría el envío de muestras y la conexión podría cerrarse por inactividad. Para evitarlo, el manejador de comandos solo activa un flag y retorna de inmediato (@cod-comandos).

#figure(
  caption: [El manejador de comandos solo marca la tarea pendiente.],
  kind: "codigo",
  [
```cpp
bool pedirCalibracion = false;   // flag de calibración

static void manejarComando(const char* txt) {
  if (strstr(txt, "\"iniciar\""))          transmitiendo = true;
  else if (strstr(txt, "\"detener\""))     transmitiendo = false;
  else if (strstr(txt, "\"calibrarMag\"")) magComenzarCalibracion();
  else if (strstr(txt, "\"calibrar\""))    pedirCalibracion = true; // no se calibra acá
  else if (strstr(txt, "\"filtro\"")) {
    if (strstr(txt, "\"comp\""))           modo = MODO_COMP;
    else if (strstr(txt, "\"mag\""))       modo = MODO_MAG;
    else if (strstr(txt, "\"kalman\""))    modo = MODO_KALMAN;
  }
}
```
  ]
) <cod-comandos>

La tarea se atiende después, desde el bucle principal. En cada iteración de `loop()` se llama primero a `ws.loop()`, que procesa los eventos de red y dispara `manejarComando()`. A continuación se revisa la bandera y, si está activa, se la baja y se ejecuta la recalibración. De esta forma, la parte lenta no se realiza nunca dentro del callback de la comunicación (@cod-loop-bandera).

#figure(
  caption: [Atención de la bandera en el bucle principal.],
  kind: "codigo",
  [
```cpp
void loop() {
  ws.loop();                      // atiende la red (puede activar flags)

  if (pedirCalibracion) {         // la tarea se ejecuta fuera del evento de red
    pedirCalibracion = false;
    recalibrar();
  }

  if (!paqueteListo) return;
  paqueteListo = false;
  if (mpu.dmpGetCurrentFIFOPacket(fifoBuffer)) procesarPaquete();
}
```
  ]
) <cod-loop-bandera>

El mismo criterio se aplica a la interrupción del DMP. La rutina `isrDmp()` solo pone `paqueteListo = true` y el procesamiento real se hace en `loop()`.

Mientras dura la recalibración, el equipo deja de enviar muestras, ya que el DMP se desactiva y se reinicia su FIFO. Al terminar, el filtro vuelve a arrancar desde la posición real del sensor (@cod-recalibrar).

#figure(
  caption: [Recalibración: se reinicia el DMP y el filtro.],
  kind: "codigo",
  [
```cpp
static void recalibrar() {
  mpu.setDMPEnabled(false);
  calibrarSensor();               // CalibrateAccel(6) y CalibrateGyro(6)
  mpu.resetFIFO();
  mpu.setDMPEnabled(true);
  filtroIniciado = false;         // el filtro arranca de nuevo
}
```
  ]
) <cod-recalibrar>

La transmisión quedó integrada al firmware y la interfaz recibe ambas orientaciones por Wi-Fi.

== Calibración de offsets del DMP

Los sensores inerciales presentan un error de offset. Con el dispositivo en reposo, el giroscopio no mide exactamente cero y el acelerómetro no mide exactamente (0, 0, 1 g). Al integrar la velocidad angular, esta diferencia se acumula como una deriva creciente en el ángulo. 

Hasta el informe anterior los offsets del MPU6050 se fijaban a mano con valores aproximados. En esta etapa se incorporó una calibración automática de los offsets del acelerómetro y del giroscopio, que se ejecuta al iniciar el equipo.

El MPU6050 permite cargar un offset por eje y por sensor en registros internos, que se restan de la medición antes de que esta llegue al DMP y a la FIFO. Se aprovechó esta característica y la calibración se realiza sobre esos registros, en lugar de restar un sesgo por software. De este modo la corrección alcanza a las dos rutas de estimación (@cod-calibrar-sensor).

#figure(
  caption: [Calibración de los offsets del acelerómetro y del giroscopio.],
  kind: "codigo",
  [
```cpp
static void calibrarSensor() {
  mpu.CalibrateAccel(6);
  mpu.CalibrateGyro(6);
}
```
  ]
) <cod-calibrar-sensor>

Las funciones `CalibrateAccel` y `CalibrateGyro` de la librería promedian lecturas del sensor, ajustan el offset del registro correspondiente y repiten el proceso hasta que la medición converge al valor esperado en reposo. Mientras se está calibrando el guante debe permanecer quieto y apoyado de modo que el eje Z quede alineado con la gravedad. El parámetro (6) indica la cantidad de ciclos de refinamiento.

La calibración de offsets quedó integrada al arranque y queda para la siguiente etapa incorporar un botón en la interfaz web

== Implementación y ajuste del filtro de Kalman

El filtro complementario combina el giroscopio y la referencia (acelerómetro o magnetómetro) con un peso fijo, `ALPHA`, que no cambia con las condiciones de medición. El filtro de Kalman, en cambio, calcula en cada paso cuánto confiar en cada fuente a partir de un modelo del error, y además estima el sesgo del giroscopio en línea. Esto lo hace menos dependiente de una buena calibración inicial y, en principio, más robusto ante la deriva.

Hasta el informe anterior la estimación por software se limitaba al filtro complementario. En esta etapa se implementó un filtro de Kalman que corre en el ESP32.

Para cada eje se implementó un filtro de Kalman de una dimensión, con dos variables de estado: el ángulo $theta$ y el sesgo del giroscopio $b$. El giroscopio se usa como entrada del modelo y la referencia absoluta (acelerómetro para roll y pitch, magnetómetro para yaw) como medición.

En la predicción, el ángulo se integra con la velocidad angular medida, corregida por el sesgo estimado, y el sesgo se supone constante:

$ theta_k = theta_(k-1) + (omega_k - b_(k-1)) dot Delta t, quad b_k = b_(k-1) $

En la corrección, la medición $z$ es el ángulo de referencia. Como esta solo observa el ángulo y no el sesgo, la ganancia de Kalman $K$ tiene dos componentes: una corrige el ángulo y la otra el sesgo.

$ K = P H^T / (H P H^T + R), quad H = mat(1, 0) $

$ theta <- theta + K_0 (z - theta), quad b <- b + K_1 (z - theta) $

Aquí $P$ es la matriz de covarianza del error de estimación y $R$ el ruido de la medición. Cada eje se implementó como una estructura independiente con su propio estado y su propia covarianza (@cod-kalman1d).

#figure(
  caption: [Filtro de Kalman de una dimensión (ángulo y sesgo del giroscopio).],
  kind: "codigo",
  [
```cpp
struct Kalman1D {
  float angulo, bias, rate;
  float P[2][2];                 // covarianza del error de estimación
  float Q_angle, Q_gyro;         // ruido de proceso
  float R_measure;               // ruido de medición

  float getAngle(float newAngle, float newRate, float dt) {
    // Predicción: integrar el giroscopio sin el sesgo estimado
    rate = newRate - bias;
    angulo += dt * rate;
    P[0][0] += dt * (dt * P[1][1] - P[0][1] - P[1][0] + Q_angle);
    P[0][1] -= dt * P[1][1];
    P[1][0] -= dt * P[1][1];
    P[1][1] += Q_gyro * dt;

    // Corrección: ganancia de Kalman e innovación
    float S = P[0][0] + R_measure;
    float K0 = P[0][0] / S;
    float K1 = P[1][0] / S;
    float y = newAngle - angulo;
    angulo += K0 * y;
    bias   += K1 * y;

    // Actualizar la covarianza
    float P00 = P[0][0], P01 = P[0][1];
    P[0][0] -= K0 * P00;  P[0][1] -= K0 * P01;
    P[1][0] -= K1 * P00;  P[1][1] -= K1 * P01;
    return angulo;
  }
};
```
  ]
) <cod-kalman1d>

Se creó una instancia por eje. Para roll y pitch la medición es el ángulo de inclinación calculado con el acelerómetro, igual que en el filtro complementario. Para el yaw la medición es el rumbo del magnetómetro, compensado por inclinación con el roll y el pitch ya estimados (@cod-kalman-actualizar).

El yaw requiere un tratamiento especial por ser un ángulo circular: la diferencia entre la medición y la estimación podría salir como cercana a $2 pi$ al cruzar $plus.minus 180°$, lo que produciría un salto brusco. Para evitarlo, la medición se expresa como la estimación actual más la diferencia normalizada al rango $[-pi, pi]$, y el resultado se vuelve a normalizar.

#figure(
  caption: [Actualización de los tres filtros de Kalman en cada paquete.],
  kind: "codigo",
  [
```cpp
static void kalmanActualizar(float ax, float ay, float az,
                             float gx, float gy, float gz, float dt) {
  // Referencias absolutas
  float rollAcc   = atan2f(ay, az);
  float pitchAcc  = atan2f(-ax, sqrtf(ay * ay + az * az));
  float yawMagRef = yawDesdeMag(kRoll, kPitch);   // con compensación de inclinación

  kRoll  = kalmanRoll.getAngle(rollAcc, gx, dt);
  kPitch = kalmanPitch.getAngle(pitchAcc, gy, dt);

  // Yaw: la innovación se normaliza para evitar saltos en ±PI
  float diffYaw = normalizarAngulo(yawMagRef - kYaw);
  kYaw = normalizarAngulo(kalmanYaw.getAngle(kYaw + diffYaw, gz, dt));
}
```
  ]
) <cod-kalman-actualizar>

=== Ajuste de parámetros

El comportamiento del filtro queda determinado por tres parámetros (@cod-kalman-params):

- `Q_angle`: ruido de proceso del ángulo. Un valor mayor indica menor confianza en el modelo y hace que el filtro siga más rápido a la referencia.
- `Q_gyro`: ruido de proceso del sesgo. Un valor mayor permite que el sesgo estimado cambie más rápido.
- `R_measure`: ruido de medición. Un valor mayor indica menor confianza en el acelerómetro o el magnetómetro, por lo que el filtro se apoya más en el giroscopio.

#figure(
  caption: [Parámetros de ruido del filtro de Kalman.],
  kind: "codigo",
  [
```cpp
void init() {
  angulo = 0.0f;  bias = 0.0f;
  P[0][0] = P[0][1] = P[1][0] = P[1][1] = 0.0f;
  Q_angle   = 0.001f;
  Q_gyro    = 0.003f;
  R_measure = 0.03f;
}
```
  ]
) <cod-kalman-params>

El filtro de Kalman quedó integrado al firmware, y queda para la siguiente etapa ajustarlo para mejorar la aproximación. Actualmente, los filtros arrancan con el ángulo en cero en lugar de la posición real del sensor, y no se reinician al recalibrar, por lo que tardan un tiempo en converger.

== Optimización del filtro complementario

El filtro complementario de la etapa anterior corregía solo roll y pitch con el acelerómetro, por lo que el yaw derivaba sin límite. En esta etapa se le agregó una corrección del yaw con el magnetómetro en otra variante seleccionable desde la interfaz para poder compararlas.

El rumbo magnético se calcula compensando la inclinación con el roll y el pitch ya estimados, de modo que una inclinación del guante no se confunda con un giro. Luego se fusiona con el giroscopio igual que en roll y pitch, pero corrigiendo la diferencia normalizada al rango $[-pi, pi]$, para evitar saltos al cruzar $plus.minus 180°$ (@cod-yaw-mag).

#figure(
  caption: [Fusión del yaw con el rumbo del magnetómetro.],
  kind: "codigo",
  [
```cpp
// Variante comp: solo giroscopio (deriva, es lo esperado)
fYawComp = normalizarAngulo(fYawComp + gz * dt);

// Variante mag: giroscopio corregido con el rumbo magnético
float yawGiro = fYawMag + gz * dt;
float dif = normalizarAngulo(yawDesdeMag(fRoll, fPitch) - yawGiro);
fYawMag = normalizarAngulo(yawGiro + (1.0f - ALPHA) * dif);
```
  ]
) <cod-yaw-mag>

Para evitar errores en el arranque y en la integración se incorporaron las siguientes mejoras:

- El filtro no parte de cero: en la primera muestra se inicializa con la inclinación del acelerómetro y el rumbo del magnetómetro, y se reinicia al recalibrar.
- Se descartan los intervalos `dt` no válidos (nulos o mayores a 0,1 s), que aparecen tras una pausa y distorsionarían la integración.
- El filtro procesa todos los paquetes del DMP (~100 Hz), aunque se transmita solo uno de cada dos, lo que mejora la integración del giroscopio (@cod-robustez).

#figure(
  caption: [Inicialización y descarte de intervalos inválidos.],
  kind: "codigo",
  [
```cpp
if (!filtroIniciado) { filtroIniciar(ax, ay, az); filtroIniciado = true; return; }
if (dt <= 0.0f || dt > 0.1f) return;   // pausa larga: descartar
filtroComplementario(ax, ay, az, gx, gy, gz, dt);
```
  ]
) <cod-robustez>

El peso del giroscopio se fijó en `ALPHA = 0.98`. Un valor mayor reduce el ruido del acelerómetro pero corrige más lento la deriva, y uno menor hace lo contrario. [

== Interfaz web

La interfaz (@fig-interfaz) es una página estática (HTML, CSS y JavaScript) que se abre en el navegador de la PC y se conecta por WebSocket al ESP32. Para el modelo 3D se usó Three.js y para los gráficos Chart.js. Incluye además un modo demo que simula el flujo de datos a 50 Hz, lo que permitió desarrollar y probar la interfaz sin el hardware. En el panel de enlace de datos se muestra la frecuencia real de recepción y los paquetes perdidos, calculados con el contador `n` de cada mensaje.

#figure(
  image("../../imagenes/interfaz_v2.jpg", width: 100%),
  caption: "Avances en la interfaz web.",
  kind: image
) <fig-interfaz>

=== Visualización 3D

Se muestran dos manos lado a lado, la de la izquierda sigue la orientación del DMP y la de la derecha la estimación por software. Los modelos se construyen por código con primitivas (caja redondeada, cilindro y cápsulas) y un material con degradé y grilla, con una paleta distinta para cada uno. Los dedos tienen una postura fija, ya que solo se representa la orientación global. Cada mano lleva dibujados los ejes del sensor (X hacia el meñique, Y hacia los dedos y Z saliendo del dorso), de modo que se vea hacia dónde apunta cada eje.

Como ambas estimaciones llegan como cuaterniones, se aplican directamente al modelo, sin pasar por ángulos de Euler. Los ejes del modelo coinciden con los del sensor, por lo que no se cambian ejes ni signos. Además, en cada cuadro la orientación mostrada se acerca a la recibida con una interpolación esférica (`slerp`), lo que suaviza el movimiento a costa de un retardo visual pequeño. Los gráficos usan los datos sin suavizar (@cod-mano-3d).

#figure(
  caption: [Aplicación del cuaternión recibido a cada modelo.],
  kind: "codigo",
  [
```js
const sensorAThree = q => new THREE.Quaternion(q[1], q[2], q[3], q[0]);
objetivo.dmp.copy(sensorAThree(q.dmp));
objetivo.sw.copy(sensorAThree(q.sw));
manos[k].quaternion.slerp(objetivo[k], 0.4);
```
  ]
) <cod-mano-3d>

Como las dos estimaciones pueden arrancar con orientaciones absolutas distintas (el yaw del DMP y el del magnetómetro no tienen por qué coincidir), el botón _Fijar referencia_ guarda la orientación actual de cada ruta y desde ese momento se muestra la rotación relativa a ella, de modo que las dos manos parten alineadas. La cámara es orbitable con el mouse y puede restablecerse con un botón.

=== Panel selector

El panel lateral muestra los controles para conectar al ESP32 (con la dirección `ws://manodmp.local:81` por defecto) o iniciar el modo demo, iniciar y detener el ensayo, fijar o quitar la referencia, pedir la calibración y elegir el eje que se grafica (roll, pitch o yaw). Un desplegable permite elegir el algoritmo por software entre `comp` (filtro complementario con acelerómetro y giroscopio), `mag` (filtro complementario con los 3 sensores) y `kalman` (filtro Kalman con los 3 sensores). Al cambiarlo, la página envía el comando al ESP32 y actualiza el rótulo de la mano de software, sin reiniciar el equipo (@cod-selector-web).

#figure(
  caption: [Selección del filtro desde la interfaz.],
  kind: "codigo",
  [
```js
$('filtro').onchange = e => {
  con.filtro(e.target.value);                       // "comp", "mag" o "kalman"
  $('filtroNombre').textContent = e.target.selectedOptions[0].text;
};

// conexion.js
filtro(f) { filtro = f; api.enviar({ cmd: 'filtro', valor: f }); }
```
  ]
) <cod-selector-web>

=== Gráfico de error

Se muestran dos gráficos con una ventana de las últimas 400 muestras (unos 8 segundos a 50 Hz). El primero superpone la orientación de ambas rutas en el eje elegido, lo que permite ver, por ejemplo, la deriva del yaw. Como los ángulos de Euler saltan al cruzar $plus.minus 180°$, antes de graficar cada valor se desplaza un múltiplo de $360°$ para que quede lo más cerca posible del anterior, y así la curva no tenga saltos falsos.

El segundo gráfico muestra la diferencia angular entre las dos estimaciones, definida como el ángulo de la rotación que lleva una orientación a la otra. Para dos cuaterniones unitarios $q_1$ y $q_2$ es

$ theta = 2 arccos(|q_1 dot q_2|) $

El valor absoluto evita que $q$ y $-q$, que representan la misma rotación, den un valor falso, y como se calcula con los cuaterniones no tiene los problemas de los ángulos de Euler (@cod-divergencia).

#figure(
  caption: [Divergencia angular y continuidad del ángulo graficado.],
  kind: "codigo",
  [
```js
// Ángulo de la rotación que lleva una orientación a la otra
export const angulo = (a, b) =>
  2 * Math.acos(Math.min(1, Math.abs(a[0]*b[0] + a[1]*b[1] + a[2]*b[2] + a[3]*b[3]))) * D;

// Evita saltos de 360° al graficar un ángulo en el eje elegido
const unir = (a, v) =>
  a.length ? v + 360 * Math.round((a[a.length - 1] - v) / 360) : v;
```
  ]
) <cod-divergencia>

== Otros avances

Aunque no estaba previsto en el Plan de Proyecto, fue necesario agregar una calibración antes de poder usar el magnetómetro. Al incorporar el QMC5883L se comprobó que sus lecturas crudas no servían como referencia de yaw ya que el campo magnético medido está desplazado y deformado por el hierro y la electrónica cercanos al sensor (efectos _hard-iron_ y _soft-iron_).

El método es una calibración por mínimos y máximos. Al iniciarla desde la interfaz, durante 20 segundos se gira el guante lentamente en todas las direcciones y se registran el mínimo y el máximo de cada eje. La calibración no bloquea el programa, los extremos se acumulan en `magLeer()` con cada paquete, y al cumplirse el tiempo se calcula el resultado (@cod-mag-acumular).

#figure(
  caption: [Acumulación de extremos durante la calibración.],
  kind: "codigo",
  [
```cpp
static void magActualizarCalibracion(float x, float y, float z) {
  float v[3] = {x, y, z};
  for (int i = 0; i < 3; i++) {
    if (v[i] < magMin[i]) magMin[i] = v[i];
    if (v[i] > magMax[i]) magMax[i] = v[i];
  }
  if (millis() - magInicioCal >= MAG_TIEMPO_CAL) magFinalizarCalibracion();
}
```
  ]
) <cod-mag-acumular>

Al finalizar, el offset de cada eje es el punto medio entre su mínimo y su máximo, lo que corrige el efecto _hard-iron_ al centrar la esfera de mediciones en el origen.

La escala se obtiene igualando el radio de cada eje con el radio promedio, una corrección simplificada del efecto _soft-iron_ que convierte el elipsoide medido en una esfera. Si algún radio resulta menor a 100 cuentas, se descarta la calibración y se avisa por el puerto serie que no se giró lo suficiente (@cod-mag-calculo).

#figure(
  caption: [Cálculo de offsets y escalas.],
  kind: "codigo",
  [
```cpp
for (int i = 0; i < 3; i++) {
  magOffset[i] = (magMax[i] + magMin[i]) / 2.0f;   // hard-iron
  radio[i]     = (magMax[i] - magMin[i]) / 2.0f;
}
if (radio[0] < 100 || radio[1] < 100 || radio[2] < 100) return;  // giro insuficiente

float radioProm = (radio[0] + radio[1] + radio[2]) / 3.0f;
for (int i = 0; i < 3; i++) magScale[i] = radioProm / radio[i];  // soft-iron
```
  ]
) <cod-mag-calculo>

Cada lectura posterior se corrige restando el offset y multiplicando por la escala de su eje, antes de calcular el rumbo. 

Mientras dura la calibración el magnetómetro no actualiza sus valores, por lo que el yaw no es confiable durante esos 20 segundos. Además, la calibración debe repetirse en cada vez que se inicia el sistema y el resultado depende de que el guante se gire lejos de objetos metálicos o imanes.

== Estado general

En la @tab-avance se muestra el resumen de los avances de esta etapa.

#figure(
  table(
    columns: (2fr, 1.5fr),
    inset: 5pt,
    stroke: 0.5pt,
    table.header([*Actividad*], [*Estado*]),
    [Montaje sobre el guante], [Pendiente],
    [Transmisión Wi-Fi], [Completado],
    [Calibración de offsets del DMP], [Completado, pendiente incorporarlo a la interfaz],
    [Implementación y ajuste del filtro Kalman], [En proceso],
    [Optimización del filtro complementario], [Completado],
    [Visualización 3D], [Completado],
    [Panel selector], [Completado],
    [Gráfico de error], [Completado],
    [Calibración del magnetómetro], [Completado],
  ),
  caption: [Síntesis del avance experimental.],
  kind: table,
) <tab-avance>

/*La próxima etapa incluirá, además de las tareas planificadas inicialmente para ese período, bla bla bla bla, que no se llegó a completar para este informe de avance.*/

= Documentación relacionada

El código fuente está disponible en el #link("https://github.com/tpII/2026-a5-mano-simulada-dmp")[repositorio del proyecto], la bitácora de trabajo en la #link("https://github.com/tpII/2026-a5-mano-simulada-dmp/wiki/BITACORA")[wiki del repositorio] y el video de demostración en #link("https://drive.google.com/file/d/1kfPa1c4QhgdYRmhAnUgkTCLqPKZSwnrr/view?usp=drive_link")[Google Drive].

