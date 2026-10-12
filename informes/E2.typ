#import "config.typ": informe

#show: informe.with(
  titulo: "Informe de Avance - Octubre",
)

= Descripción general del proyecto
El proyecto tiene como objetivo comparar dos métodos de estimación de orientación tridimensional. Para esto, se deberá desarrollar un sistema de adquisición y visualización de orientación a partir de los datos obtenidos de una unidad de medición inercial de 9 ejes. El primer método utilizará la orientación calculada por el procesador digital de movimiento (DMP) del sensor y el segundo empleará filtros implementados por software sobre las mediciones del acelerómetro, el giroscopio y el magnetómetro.

El dispositivo final estará compuesto por un módulo GY-9250 con sensor MPU9250 montado sobre un guante y conectado por I²C a un ESP32. Los resultados se transmitirán a una interfaz web que mostrará dos modelos tridimensionales y una gráfica de diferencias entre estimaciones.

Se decidió utilizar el MPU9250 en lugar del MPU6050 inicialmente considerado para incorporar también un magnetómetro, potencialmente útil como referencia del eje de yaw. En esta primera etapa se utilizó un MPU6050 para verificar adquisición, interrupciones, calibración inicial y filtrado, por lo que los resultados experimentales de octubre corresponden éste sensor.

= Materiales y presupuesto
#figure(
  table(
    columns: (0.65fr, 2.6fr, 1.25fr, 1.2fr),
    align: (center, left, center, right),
    inset: 5pt,
    stroke: 0.5pt,
    table.header([*Cantidad*], [*Descripción*], [*Disponible*], [*Precio unitario*]),
    [1], [#link("https://www.mercadolibre.com.ar/esp32-nodemcu-wroom32-38-pines-usbc-wifi-bluetooth-arduino/up/MLAU5001930260?pdp_filters=item_id:MLA3878662278#is_advertising=true&searchVariation=MLAU5001930260&backend_model=search-backend&be_origin=backend&position=1&search_layout=grid&type=pad&tracking_id=9cd4be54-9d01-4f56-8f09-c12251c0e86e&ad_domain=VQCATCORE_LST&ad_position=1&ad_click_id=N2U1Mzg1NWUtNzM0My00NmNlLWJjZjItNTkyYTkxNzU4ZTkz")[ESP32 NodeMCU WROOM-32, 38 pines, USB-C, Wi-Fi y Bluetooth]], [Sí], [\$20.700],
    [1], [#link("https://www.sistemsoft.com.ar/electronica/placa-de-desarrollo/modulo-gy9250-mpu9250-acelerometro-giroscopo-magnetometro")[Módulo GY-9250 con MPU9250: acelerómetro, giroscopio y magnetómetro; DMP]], [No], [\$21.960],
    [1], [#link("https://www.zur3d.com.ar/producto/mpu-6050-acelerometro-giroscopio-3-ejes/")[MPU6050 empleado para las pruebas preliminares]], [Sí], [\$6.000],
    [1], [#link("https://www.mercadolibre.com.ar/sensor-magnetico-3-ejes-hmc5883l-brujula-i2c-candy-ho-arduino-gy273/p/MLA46859560")[Magnetómetro QMC5883L empleado para las pruebas preliminares]], [Sí], [\$7.266],
    [1], [Guante para montaje del sistema], [Pendiente], [A definir],
    [1], [Juego de cables Dupont x10], [Sí], [—],
    [1], [Capacitor de desacople de 0,1 µF], [Sí], [—],
    [1], [Cable MicroUSB para alimentación y programación], [Sí], [—],
    [1], [Power bank para alimentación portátil (opcional)], [Pendiente], [A definir],
    table.cell( colspan: 3, fill: luma(235), align: left, [*Total*]),
    table.cell( fill: luma(235), align: right, [*\$48.660*]),
  ),
  caption: [Materiales necesarios para el desarrollo del prototipo y su disponibilidad.],
  kind: table,
) <tab-materiales>
La cátedra proporcionó el ESP32 y dos unidades del módulo GY-9250. El MPU6050 y el magnetómetro QMC5883L se emplearon únicamente como dispositivos de ensayo durante la etapa preliminar. Los materiales restantes ya se encontraban disponibles, por lo que solo resta adquirir el guante sobre el cual se montará el sistema.

En la propuesta inicial se había contemplado el uso de tres capacitores de desacople. Sin embargo, al realizar el montaje se comprobó que dos de ellos correspondían a pines que no se utilizan en este proyecto, por lo que la cantidad se redujo a uno. Esta decisión deberá verificarse al montar el equipo final, ya que existe la posibilidad de que no se requiera ninguno.

Asimismo, se había previsto un cable USB-C para la alimentación, pero el ESP32 provisto por la cátedra requiere un cable MicroUSB, por lo que se lo reemplazó.

El resto de los materiales se mantienen según lo establecido en el plan de proyecto. Los costos de los dispositivos empleados en las pruebas preliminares son afrontados por el grupo de desarrollo, dado que son externos al prototipo final y, por lo tanto, no se incluyen en el total del presupuesto.

= Esquema gráfico del proyecto

La arquitectura propuesta separa las etapas de adquisición, procesamiento y visualización. El ESP32 recibe las mediciones por I²C, estima la orientación mediante los dos métodos previstos y transmite los resultados a la interfaz de visualización. Este esquema, que se muestra en la @fig-esquema-general, coincide con el presentado en el Plan de Proyecto, ya que no se realizaron modificaciones.

#figure(
  image("images/diagrama_bloque.png", width: 100%),
  caption: [
    Diagrama de bloques del sistema presentado en el Plan de Proyecto.
  ],
  kind: image,
) <fig-esquema-general>

Durante octubre se validó una ruta provisional que reemplaza el enlace Wi-Fi por una conexión USB serie con la computadora, mientras que la transmisión inalámbrica permanece sin verificar. Asimismo, en esta etapa se emplearon el MPU6050 y el magnetómetro QMC5883L en lugar del MPU9250, y la estimación se limitó al filtro complementario ejecutado en el ESP32. El esquema del prototipo probado a la fecha se presenta en la @fig-esquema-octubre.

#figure(
  {
    let caja(titulo, detalle: none) = box(
      width: 100%,
      inset: 7pt,
      stroke: 0.6pt,
      align(center)[
        *#titulo*
        #if detalle != none [
          #text(size: 8pt)[\ #detalle]
        ]
      ],
    )
    let flecha(etiqueta) = align(center + horizon)[
      #text(size: 8pt)[#etiqueta] \
      #sym.arrow.r.long
    ]
    let etapa(texto) = align(center)[
      #text(size: 8pt, tracking: 0.5pt)[#upper(texto)]
    ]

    grid(
      columns: (1.4fr, 0.8fr, 1.4fr, 0.8fr, 1.4fr),
      row-gutter: 5pt,
      align: horizon,
      stack(
        spacing: 3pt,
        caja("MPU6050", detalle: [Acelerómetro + giroscopio \ DMP]),
        caja("Magnetómetro",),
      ),
      flecha([I²C]),
      caja("ESP32", detalle: [Filtro complementario]),
      flecha([USB serie]),
      caja("PC", detalle: [Visualizador de prueba]),

      etapa[Adquisición], [], etapa[Procesamiento], [], etapa[Visualización],
    )
  },
  caption: [Ruta experimental validada en octubre, hasta la transmisión por USB serie.],
  kind: image,
) <fig-esquema-octubre>

= Grado de avance, problemas y soluciones
En el plan de proyecto se planificó para esta etapa completar la adquisición y montaje del hardware, establecer la comunicación I²C con el sensor y WiFi con la computadora, implementar el filtro complementario y realizar las lecturas del DMP aunque sin realizar configuraciones ni calibraciones por ahora. El diagrama de Gantt de la @fig-gantt muestra esta planificaci;on original.

#figure(
  {
    set text(size: 7.5pt, font: "Liberation Sans")

    // Paleta de colores
    let col-f1 = rgb("2b6cb0") // Azul (Fase 1)
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
      // Se ajusta a 5 columnas para las semanas (6 columnas en total)
      columns: (5.2fr, ..(1fr,) * 5),
      align: (left + horizon, ..(center + horizon,) * 5),
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
      table.cell(colspan: 3)[*Septiembre*],
      table.cell(colspan: 2)[*Octubre*],

      // Fila 2: Semanas (Fecha lunes)
      [14], [21], [28], [5], [12],

      // FASE 1
      table.cell(colspan: 6, fill: col-f1.lighten(92%), inset: 4pt)[
        #text(weight: "bold", fill: col-f1.darken(25%))[Etapa 1: Adquisición base, hardware y primer filtro]
      ],
      [Adquisición y montaje de hardware], table.cell(colspan: 1)[#bar(col-f1)], ..([],) * 4,
      [Investigación teórica y librerías], table.cell(colspan: 1)[#bar(col-f1)], ..([],) * 4,
      [Comunicación I²C y lectura de datos crudos], [], table.cell(colspan: 2)[#bar(col-f1)], ..([],) * 2,
      [Configuración inicial y lecturas del DMP], [], table.cell(colspan: 2)[#bar(col-f1)], ..([],) * 2,
      [Implementación del Filtro Complementario], ..([],) * 2, table.cell(colspan: 1)[#bar(col-f1)], ..([],) * 2,
      [Transmisión ESP32 a PC y monitor serie], ..([],) * 2, table.cell(colspan: 1)[#bar(col-f1)], ..([],) * 2,
      [Redacción del Informe de Avance E2], ..([],) * 2, table.cell(colspan: 2)[#bar(col-f1)], [],

      // HITOS Y ENTREGAS FORMALES
      table.cell(colspan: 6, fill: col-hito.lighten(90%), inset: 4pt)[
        #text(weight: "bold", fill: col-hito.darken(25%))[Entregas formales (hitos)]
      ],
      // Ajustado a la semana del 12 para que coincida visualmente con el 11/10
      [Informe de Avance 1 (E2) -- 11/10/2026], ..([],) * 4, celda-hito(),
    )
  },
  caption: [Diagrama de Gantt para la entrega de octubre.],
  kind: table,
) <fig-gantt>

En las siguientes secciones se evalúa el grado de avance de cada uno de estos items.

== Montaje de hardware <sec:montaje-hw>
=== Conexión y alimentación
Se armó un prototipo con un ESP32, un MPU6050 y un magnetómetro QMC5883L. Los conductores se soldaron directamente a los pines de los módulos y se conectaron al ESP32, que se alimentó por USB y suministró 3,3 V a ambos sensores. Las conexiones realizadas se detallan en la @tab-pines.

#figure(
  table(
    columns: (1fr, 1fr, 1fr, 2fr),
    inset: 5pt,
    stroke: 0.5pt,
    table.header([*QMC5883L*], [*MPU6050*], [*ESP32*], [*Función*]),
    [VCC], [VCC], [3V3], [Alimentación],
    [GND], [GND], [GND], [Masa común],
    [SDA], [SDA], [GPIO21], [Datos I²C],
    [SCL], [SCL], [GPIO22], [Reloj I²C],
    table.cell(rowspan: 2, stroke: none)[], [INT], [GPIO23], [Interrupción DATA_READY],
    [AD0], [—], [Selección de dirección en el módulo],
  ),
  caption: [Conexiones verificadas del prototipo experimental.],
  kind: table,
) <tab-pines>

Ambos sensores comparten los pines SDA y SCL, ya que se comunican por el mismo bus I²C. El pin AD0 del MPU6050 define su registro de identificación: conectado a GND se selecciona la dirección `0x68`, y conectado a VCC, la `0x69`. Durante las pruebas se comprobó que el módulo ya trae AD0 conectado a tierra, por lo que se lo dejó sin conectar y el sensor responde en `0x68`.

El pin INT se utiliza para indicar que hay nuevas mediciones disponibles (señal DATA_READY), lo que permite adquirir los datos por interrupción en lugar de por sondeo. Los pines DRDY del magnetómetro y los pines XDA y XCL del MPU6050 no se conectaron.

En la @fig-arquitectura se muestra gráficamente la conexión descripta.

#figure(
  image("images/esquemaMPU+magneto.png", width: 100%),
  caption: [Esquema de arquitectura general del sistema.],
  kind: image,
) <fig-arquitectura>

Los requisitos de alimentación son los previstos en el Plan de Proyecto. Se resumen en la @tab-consumo.
#figure(
  table(
    columns: (1.6fr, 2.4fr, 1.8fr, 1.1fr),
    align: (left, left, center, right),
    inset: 5pt,
    stroke: 0.5pt,
    table.header([*Componente*], [*Condición de operación*], [*Alimentación*], [*Corriente*]),
    [ESP32-WROOM-32], [CPU a 50 MHz], [3,3 V], [< 25 mA],
    [ESP32-WROOM-32], [Módulo Wi-Fi a 1 Mbps], [3,3 V], [240 mA],
    [ESP32-WROOM-32], [Bluetooth], [—], [No se utiliza],
    [MPU9250], [Giroscopio a 1 kHz, acelerómetro a 4 kHz y magnetómetro a 8 Hz, sin DMP (máximo)], [VDD: 2,4 a 3,6 V \ VDDIO: 1,71 V a VDD], [3,7 mA],
    [MPU9250], [9 ejes y DMP habilitados \ (aproximado, si los sensores no están al máximo)], [VDD: 2,4 a 3,6 V \ VDDIO: 1,71 V a VDD], [3,5 mA],
    table.cell(colspan: 3, fill: luma(235), align: left)[*Consumo total estimado del ESP32 (CPU + Wi-Fi)*],
    table.cell(fill: luma(235), align: right)[*< 265 mA*],
  ),
  caption: [Requerimientos de alimentación de los componentes del prototipo final.],
  kind: table,
) <tab-consumo>

/* ESQUEMA MPU9250 
#grid(
  columns: (1fr, 1fr),
  gutter: 2em,
  [
    #figure(
      image("images/mpu9250_i2c.png", width: 100%),
      caption: [Conexión recomendada en la hoja de datos para comunicación I²C.],
      kind: image,
    ) <fig-mpu9250>
  ],
  [
    #figure(
      image("images/gy9250.png", width: 60%),
      caption: [Módulo GY-9250],
      kind: image,
    ) <fig-gy9250>
  ]
)

Al usarlo en modo I²C la conexión es la siguiente:

- *VCC* a 3V3
- *GND* a GND
- *SCL* a GPIO22
- *SDA* a GPIO21
- *nCS:* Conectarlo a VDDIO fuerza al chip a comunicarse por I2C en lugar de SPI. El módulo GY-9250 ya tiene una resistencia interna que hace esto, por lo que no es necesario conectarlo.
- *FSYNC:* El circuito sugerido por el fabricante muestra este pin conectado directamente GND. La placa GY-9250 ya lo deriva a tierra por defecto.
- *EDA / ECL (AUX_DA / AUX_CL):* El diagrama de referencia los marca desconectados.
- *AD0 (AD0/SDO):* Es una salida de datos o selector de dirección. Al dejarlo desconectado, el módulo GY-9250 lo lleva internamente a tierra, lo que le asigna al sensor la dirección 0x68.
- *INT (Interrupción):* El DMP utilizará este pin para enviarle un pulso eléctrico al ESP32 indicando que ya tiene un cálculo de orientación listo para ser leído. Se conectó a GPIO23.
*/

== Investigación teórica y librerías

Se estudiaron los fundamentos de la adquisición con acelerómetro y giroscopio, incluyendo los rangos de sensibilidad, las interrupciones DATA_READY y el funcionamiento del DMP. Como primer paso se utilizó la biblioteca `Adafruit_MPU6050` para comprobar la lectura de aceleración, velocidad angular y temperatura. Luego se pasó al acceso directo a los registros del sensor mediante la librería `Wire`, lo que permite controlar la configuración y la lectura sin depender de una biblioteca específica del dispositivo.

Para las pruebas del DMP se empleó la librería I2Cdevlib, propuesta en el artículo "MPU6050 Gyro Drift Fix: DMP, Kalman Filter, and I2Cdevlib Setup" para obtener la orientación calculada por el DMP del sensor y reducir así la deriva del giroscopio. Se utilizó el archivo de cabecera `MPU6050_6Axis_MotionApps20.h`, que incluye el firmware del DMP que debe cargarse en el sensor durante la inicialización. Este firmware corresponde al MPU6050, por lo que deberá verificarse una alternativa equivalente para el MPU9250, cuyo DMP requiere un firmware y una forma de carga distintos.

Para la visualización se investigó la librería Three.js, una biblioteca de JavaScript basada en WebGL que permite crear y renderizar escenas tridimensionales directamente en el navegador, sin necesidad de instalar software adicional. Se estudiaron sus elementos básicos y la forma de representar rotaciones mediante cuaterniones y ángulos de Euler, lo que resulta adecuado para mostrar la orientación estimada. Con ella se desarrolló un visualizador de prueba que reproduce en tiempo real la orientación del sensor sobre un modelo tridimensional. Además, al ser una tecnología web, es la misma que se empleará en la interfaz final para mostrar los dos modelos de la mano y comparar ambas estimaciones.

== Comunicación I²C y lectura de datos crudos <sec:comunicacion-sensores>

La comunicación con los sensores se realizó mediante la librería `Wire`, con SDA en GPIO21, SCL en GPIO22 y el bus a 100 kHz. Se implementaron dos funciones de acceso a registros: una de escritura (@cod-i2c-esritura) y otra de lectura de uno o más bytes consecutivos (@cod-i2c-lectura). Esta última emplea un reinicio repetido entre el envío de la dirección del registro y la lectura, y se limitó a 32 bytes por transacción.

#figure(
  caption: [Función de lectura con I2C.],
  kind: "codigo",
  [```cpp
  int i2c_escribir_registro(uint8_t direccion,
                          uint8_t registro,
                          uint8_t valor){
      Wire.beginTransmission(direccion);
      Wire.write(registro);
      Wire.write(valor);
      return Wire.endTransmission() == 0 ? 0 : -1;
  }
  ```]
) <cod-i2c-esritura>
#figure(
  caption: [Función de lectura con I2C.],
  kind: "codigo",
  [```cpp
  int i2c_leer_registros(uint8_t direccion,
                        uint8_t registro,
                        uint8_t* buffer,
                        size_t longitud){
      if (buffer == nullptr || longitud == 0 || longitud > 32){
          return -1;
      }
      Wire.beginTransmission(direccion);
      Wire.write(registro);
      if (Wire.endTransmission(false) != 0){
          return -1;
      }
      size_t recibidos = Wire.requestFrom(
          direccion , longitud , true
      );
      if (recibidos != longitud){
          return -1;
      }
      for (size_t i = 0; i < longitud; i++){
          buffer[i] = Wire.read();
      }
      return 0;
  }
  ```]
) <cod-i2c-lectura>

El MPU6050 (dirección `0x68`) se sacó del modo de suspensión y se seleccionó como fuente de reloj el PLL referido al giroscopio del eje X. Se configuró el acelerómetro en ±2 g, el giroscopio en ±250 °/s y el DLPF en aproximadamente 21 Hz (21 Hz para el acelerómetro y 20 Hz para el giroscopio). Con el filtro activado, el divisor de frecuencia de muestreo se fijó en 19, lo que da 1 kHz / (1 + 19) = 50 Hz (@cod-mpu-init). Cada vez que se realiza una lectura se leen 14 bytes consecutivos a partir del registro `0x3B`, correspondientes a aceleración, temperatura y velocidad angular. Los valores enteros de 16 bits se convirtieron a m/s² y rad/s con las sensibilidades de 16.384 LSB/g y 131 LSB/(°/s), y la temperatura a °C (@cod-mpu-lectura).
#figure(
  caption: [Configuración del MPU6050.],
  kind: "codigo",
  [```cpp
int mpu_init(void){
    uint8_t id = 0;
    if (i2c_leer_registros(MPU_ADDR , WHO_AM_I , &id , 1) != 0)return -1;
    mpu_id = id;
    if (i2c_escribir_registro(MPU_ADDR , PWR_MGMT_1 , 0x01) != 0)return -1;
    // 1 kHz / (1 + 19) = 50 Hz (con DLPF activado).
    if (i2c_escribir_registro(MPU_ADDR , SMPLRT_DIV , 19) != 0)return -1;
    if (i2c_escribir_registro(MPU_ADDR , CONFIG , 0x04) != 0)return -1;
    if (i2c_escribir_registro(MPU_ADDR , GYRO_CONFIG , 0x00) != 0)return -1;
    if (i2c_escribir_registro(MPU_ADDR , ACCEL_CONFIG , 0x00) != 0)return -1;
    printf("MPU configurado (+/-2g, +/-250deg/s, DLPF 21Hz, 50Hz).\n");
    return 0;
}
  ```]
) <cod-mpu-init>

#figure(
  caption: [Lectura de acelerómetro, giroscopio y temperatura del MPU.],
  kind: "codigo",
  [```cpp
int mpu_leer(mpu_datos_t* d){
  if (!d || !mpu_id)return -1;
  uint8_t b[14];
  if (i2c_leer_registros(MPU_ADDR , ACCEL_XOUT_H , b , sizeof(b)) 
                        != 0)return -1;
  d->ax = (a16(b[0] , b[1]) / 16384.0f) * G;
  d->ay = (a16(b[2] , b[3]) / 16384.0f) * G;
  d->az = (a16(b[4] , b[5]) / 16384.0f) * G;
  d->temperatura = a16(b[6] , b[7]) / 340.0f + 36.53f;
  const float conv = (PI_F / 180.0f) / 131.0f;
  d->gx = a16(b[8] , b[9]) * conv;
  d->gy = a16(b[10] , b[11]) * conv;
  d->gz = a16(b[12] , b[13]) * conv;
  return 0;
}
  ```]
) <cod-mpu-lectura>

Para el magnetómetro se implementó una detección automática durante la inicialización. Se consulta primero la dirección `0x0D` (QMC5883L) y, si no responde, la `0x1E` (HMC5883L), y en ambos casos se configura el modo de medición continua. Se configuró el sensor con rango de ±8 G y sobremuestreo de 512. Cada lectura obtiene 6 bytes, el QMC5883L entrega los datos desde el registro `0x00` en formato little-endian y orden X, Y, Z (@cod-lectura-mag). Los valores se mantienen como cuentas crudas del conversor, sin conversión a unidades físicas. La calibración de hard-iron quedó pendiente, con los offsets de cada eje en cero.
#figure(
  caption: [],
  kind: "codigo",
  [
```cpp
int mag_leer(mag_datos_t* d) {
  if (!d || mag_addr == 0) return -1;
  uint8_t b[6];
  if (es_qmc) {
    // QMC5883L: registros 0x00..0x05, Little-Endian, orden X, Y, Z
    if (i2c_leer_registros(mag_addr, 0x00, b, 6) != 0) return -1;
    int16_t x = (int16_t)((b[1] << 8) | b[0]);
    int16_t y = (int16_t)((b[3] << 8) | b[2]);
    int16_t z = (int16_t)((b[5] << 8) | b[4]);
    d->mx = (float)x;
    d->my = (float)y;
    d->mz = (float)z;
  }
  ...
}
```
  ]
) <cod-lectura-mag>
La sincronización se realizó con la interrupción DATA_READY del MPU6050 en GPIO23, con una frecuencia nominal de 50 Hz. Como el pin DRDY del magnetómetro no está conectado, este se consulta en el ciclo marcado por dicha interrupción.

En una prueba de 1500 muestras realizada antes de incorporar el magnetómetro, se registró una frecuencia media de 50,090 Hz, sin errores I²C como se detalla a continuación.

=== Calibración inicial y ruido en reposo

Se adquirieron 1500 muestras con el MPU6050 inmóvil durante 29,926 segundos, calculando medias y desviaciones estándar muestrales por eje. La prueba permitió estimar el sesgo inicial del giroscopio y observar la variabilidad del acelerómetro.

#figure(
  table(
    columns: (1fr, 1.4fr, 1.4fr),
    inset: 5pt,
    stroke: 0.5pt,
    table.header([*Eje*], [*Media (m/s²)*], [*Desv. estándar (m/s²)*]),
    [Ax], [-0,028250], [0,010691],
    [Ay], [0,064062], [0,009362],
    [Az], [9,935172], [0,016313],
  ),
  caption: [Mediciones del acelerómetro en reposo.],
  kind: table,
) <tab-acelerometro>

#figure(
  table(
    columns: (1fr, 1.4fr, 1.4fr),
    inset: 5pt,
    stroke: 0.5pt,
    table.header([*Eje*], [*Media (rad/s)*], [*Desv. estándar (rad/s)*]),
    [Gx], [-0,022842], [0,000306],
    [Gy], [0,000215], [0,000408],
    [Gz], [-0,006985], [0,000341],
  ),
  caption: [Sesgos preliminares y dispersión del giroscopio en reposo.],
  kind: table,
) <tab-giroscopio>

Las medias del giroscopio se utilizaron como estimaciones preliminares de su bias. Si el valor medido en X (−0,022842 rad/s) permaneciera constante, su integración sin corrección produciría una deriva teórica de aproximadamente 78,5° en un minuto. En el acelerómetro, una única posición de reposo no permite separar errores de escala, alineación y offset.

== Configuración inicial y lecturas del DMP

Se desarrolló un programa de prueba para la ruta A (orientación calculada por el DMP) sobre el MPU6050, utilizando la librería I2Cdevlib. El programa configura el bus I²C a 400 kHz, para acelerar la lectura de la FIFO, e inicializa el sensor. Luego carga el firmware del DMP con `dmpInitialize()`, establece offsets iniciales de acelerómetro y giroscopio, y ejecuta una calibración automática (`CalibrateAccel` y `CalibrateGyro`). Finalmente habilita el DMP y la interrupción en GPIO23, que se activa cuando hay un paquete disponible en la FIFO. (@cod-dmp-init)

#figure(
  caption: [Inicialización del sensor, calibración y hablitacion del DMP.],
  kind: "codigo",
  [```cpp
Wire.begin(21, 22);
Wire.setClock(400000);

mpu.initialize();

devStatus = mpu.dmpInitialize();

mpu.setXAccelOffset(-1000);
mpu.setYAccelOffset(-1000);
mpu.setZAccelOffset(1000);
mpu.setXGyroOffset(0);
mpu.setYGyroOffset(0);
mpu.setZGyroOffset(0);

if (devStatus == 0) {
    mpu.CalibrateAccel(6);
    mpu.CalibrateGyro(6);
    mpu.setDMPEnabled(true);
    attachInterrupt(digitalPinToInterrupt(PIN_INT), isrDmp, RISING);
    mpuIntStatus = mpu.getIntStatus();
    dmpListo = true;
    packetSize = mpu.dmpGetFIFOPacketSize();
    Serial.println("DMP inicializado con exito.");
}
  ```]
) <cod-dmp-init>

En cada ciclo se lee el paquete de la FIFO y se extrae el cuaternión de orientación, a partir del cual se obtiene el vector de gravedad y los ángulos de yaw, pitch y roll. Estos ángulos se convierten a grados y se envían por el puerto serie a 10 Hz (@cod-dmp-fifo).
#figure(
  caption: [Lectura de un paquete de la FIFO.],
  kind: "codigo",
  [```cpp
if (mpu.dmpGetCurrentFIFOPacket(fifoBuffer)) {
    mpu.dmpGetQuaternion(&q, fifoBuffer);
    mpu.dmpGetGravity(&gravity, &q);
    mpu.dmpGetYawPitchRoll(ypr, &q, &gravity);
    static uint32_t ultimoPrint = 0;
    if (millis() - ultimoPrint >= 100) { // 10 Hz
        ultimoPrint = millis();
        Serial.printf("DMP -> R: %+6.1f° | P: %+6.1f° | Y: %+6.1f°\n",
        ypr[2]*180.0f / M_PI,ypr[1]*180.0f / M_PI,ypr[0]*180.0f / M_PI);
    }
}
  ```]
) <cod-dmp-fifo>

Por lo tanto, ya se dispone de una lectura de orientación proveniente del DMP del MPU6050, aunque solo se comprobó su funcionamiento de forma cualitativa y no se registraron su frecuencia, su estabilidad ni su deriva.

Esta prueba se realizó con el MPU6050 y no valida el DMP del MPU9250, cuyo firmware y forma de carga son distintos. Además, el DMP del MPU6050 calcula la orientación a partir de acelerómetro y giroscopio únicamente, por lo que el yaw carece de referencia absoluta y es esperable que presente deriva.

Como próximos pasos se prevé conectar el GY-9250, comprobar su identificación, configurar la lectura de orientación del DMP y registrar su frecuencia y estabilidad.

== Implementación del filtro complementario

Se implementó en el ESP32 un filtro complementario que estima la orientación en roll, pitch y yaw combinando la integración del giroscopio con dos referencias absolutas: el acelerómetro, que da la inclinación respecto de la gravedad, y el magnetómetro, que da el rumbo. En los tres ejes se adoptó un coeficiente de ponderación $alpha = 0,98$, de modo que el giroscopio domina en el corto plazo y las referencias corrigen la deriva en el largo plazo. Antes de integrar, se restan a las velocidades angulares los sesgos medidos con el sensor en reposo (@cod-parametros).
#figure(
  caption: [Parámetros del filtro y calibración.],
  kind: "codigo",
  [
```cpp
#define ALPHA 0.98f
// Bias del giroscopio medido en reposo (rad/s)
#define BIAS_GX -0.022842f
#define BIAS_GY  0.000215f
#define BIAS_GZ -0.006985f
// Calibración inicial simple (offset / hard-iron) del magnetómetro
#define MAG_OFFSET_X 0.0f
#define MAG_OFFSET_Y 0.0f
#define MAG_OFFSET_Z 0.0f
static Orientacion orientacion = {0.0f, 0.0f, 0.0f};
```
  ]
) <cod-parametros>

El procesamiento se organizó en los archivos `filtro_complementario.cpp` y `filtro_complementario.h`, separados de los módulos de adquisición. La estimación se inicializa con la primera muestra (@cod-primera-muestra): roll y pitch se obtienen del acelerómetro y el yaw del magnetómetro, de modo que el filtro parte de una orientación coherente con la posición real del sensor.

#figure(
  caption: [Inicialización con la primera muestra.],
  kind: "codigo",
  [
```cpp
void filtro_iniciar(const mpu_datos_t &d, const mag_datos_t &m) {
  orientacion.roll = atan2f(d.ay, d.az);
  orientacion.pitch = atan2f(-d.ax, sqrtf(d.ay * d.ay + d.az * d.az));
  orientacion.yaw = calcular_yaw_mag(m, orientacion.roll, orientacion.pitch);
}
```
  ]
) <cod-primera-muestra>

Luego, la actualización se ejecuta en cada nueva muestra y utiliza el intervalo de tiempo transcurrido desde la anterior, descartando los valores no positivos o no finitos de este intervalo (@cod-actualizacion-filtro). 

#figure(
  caption: [Actualización en cada muestra.],
  kind: "codigo",
  [
```cpp
Orientacion filtro_actualizar(const mpu_datos_t &d, const mag_datos_t &m, float dt) {

  if (dt <= 0.0f || !isfinite(dt)) {
      return orientacion;
  }

  // 1. Corregir bias del giroscopio
  const float gx = d.gx - BIAS_GX;
  const float gy = d.gy - BIAS_GY;
  const float gz = d.gz - BIAS_GZ;

  // 2. Inclinación con acelerómetro
  const float roll_acc = atan2f(d.ay, d.az);
  const float pitch_acc = atan2f(-d.ax, sqrtf(d.ay * d.ay + d.az * d.az));

  // 3. Integración con giroscopio
  const float roll_gyro = orientacion.roll + gx * dt;
  const float pitch_gyro = orientacion.pitch + gy * dt;
  const float yaw_gyro = orientacion.yaw + gz * dt;

  // 4. Fusión Roll y Pitch
  orientacion.roll = ALPHA * roll_gyro + (1.0f - ALPHA) * roll_acc;
  orientacion.pitch = ALPHA * pitch_gyro + (1.0f - ALPHA) * pitch_acc;

  // 5. Rumbo absoluto del magnetómetro con tilt compensation
  const float yaw_mag = calcular_yaw_mag(m, orientacion.roll, orientacion.pitch);

  // 6. Fusión Yaw considerando la discontinuidad circular [-PI, PI]
  const float diff_yaw = normalizar_angulo(yaw_mag - yaw_gyro);
  orientacion.yaw = normalizar_angulo(yaw_gyro + (1.0f - ALPHA) * diff_yaw);

  return orientacion;
}
```
  ]
) <cod-actualizacion-filtro>

Para roll y pitch, el ángulo de referencia del acelerómetro se calcula con `atan2` a partir de las componentes de la aceleración. Se aplica @eq-roll-pitch, donde la integración del giroscopio parte del ángulo estimado en la iteración anterior:

$ theta_k = alpha (theta_(k-1) + omega_k Delta t) + (1 - alpha) theta_("acc", k) $ <eq-roll-pitch>

El yaw se obtiene del rumbo magnético, como indica la @eq-yaw. Con los valores de roll y pitch ya fusionados se proyecta el vector magnético sobre el plano horizontal y se calcula el rumbo con `atan2`. La fusión con el giroscopio se hace sobre la diferencia angular, normalizada al rango $[-pi, pi]$, para evitar saltos cuando el ángulo cruza esos límites. El magnetómetro aporta datos en cuentas crudas, lo cual es suficiente porque el rumbo depende solo de la dirección del vector. Los offsets de hard-iron están en cero a la espera de la calibración.

$ psi_(g,k) &= psi_(k-1) + omega_(z,k) Delta t \
  psi_k &= psi_(g,k) + (1 - alpha) "norm"(psi_(m,k) - psi_(g,k)) $ <eq-yaw>

donde $alpha$ es el coeficiente de ponderación y $"norm"(dot)$ lleva el ángulo al rango $[-pi, pi]$.

Las pruebas de transmisión previas a incorporar el magnetómetro confirmaron que el firmware calcula y actualiza los ángulos junto con las mediciones del sensor, sin errores I²C ni interrupciones agrupadas. Resta repetir la verificación con el magnetómetro activo, validar los ángulos frente a orientaciones conocidas, calibrar el magnetómetro y medir la deriva residual. Además, el algoritmo integra cada eje de forma independiente, por lo que deberá evaluarse su comportamiento ante rotaciones tridimensionales combinadas.

== Transmisión ESP32 a PC <sec:comunicacion-pc>

La transmisión validada hasta la fecha se realiza por comunicación serie USB a 115.200 baudios. El ESP32 envía registros en formato CSV, uno por cada muestra, con el tiempo, las aceleraciones, las velocidades angulares y los tres ángulos estimados. Cada línea tiene el formato `tiempo, Ax, Ay, Az, Gx, Gy, Gz, roll, pitch, yaw`. Aún no se incluyen las mediciones del magnetómetro.

Existen además archivos preliminares para crear un punto de acceso Wi-Fi en el ESP32 y transmitir los datos mediante UDP. Sin embargo, esta vía todavía no se integró ni se ensayó con el sistema completo, por lo que la comunicación inalámbrica no se considera completada.

== Otros avances <sec:otros-avances>

Si bien no estaba planificado para este período, se desarrolló un visualizador experimental con JavaScript y Three.js, que recibe los datos del ESP32 mediante la API Web Serial y representa la orientación estimada sobre un modelo tridimensional. En una primera versión el filtrado se realizaba en JavaScript, a partir de las mediciones crudas, posteriormente se trasladó al ESP32, de modo que el visualizador recibe directamente los ángulos calculados por el firmware.

Se verificó que el flujo de ángulos del firmware llega al visualizador, pero todavía debe confirmarse que su correspondencia con los ejes de la última versión del modelo sea correcta.

== Estado general

El avance de cada actividad hasta la fecha se resume en la @tab-avance.

#figure(
  table(
    columns: (2fr, 1.5fr),
    inset: 5pt,
    stroke: 0.5pt,
    table.header([*Actividad*], [*Estado*]),
    [Montaje sobre el guante], [Pendiente],
    [Lectura I²C y DATA_READY a 50 Hz], [Probado con MPU6050],
    [Lectura del magnetómetro (QMC5883L)], [Implementado, sin calibrar],
    [Filtro complementario en ESP32], [Implementado, validación pendiente],
    [Lectura de orientación del DMP], [Probado con MPU6050 (verificación visual)],
    [Calibración estática del giroscopio], [Ensayo inicial],
    [Transmisión CSV por USB], [Probado],
    [Visualizador Three.js], [Prototipo de prueba],
    [Comunicación Wi-Fi], [Archivos preliminares, sin ensayar],
    [Puesta en marcha del MPU9250], [Pendiente],
  ),
  caption: [Síntesis del avance experimental.],
  kind: table,
) <tab-avance>

La próxima etapa incluirá, además de las tareas planificadas inicialmente para ese período, la puesta en marcha del MPU9250 y la integración de la comunicación inalámbrica, que no se llegó a completar para este informe de avance.

= Documentación relacionada
== Registro del prototipo

La @fig-prototipo-completo muestra el montaje físico del prototipo experimental, compuesto por el ESP32, el MPU6050 y el magnetómetro QMC5883L, conectados según lo detallado en la @tab-pines. Esta imagen corresponde al sistema de adquisición descrito en #link(<sec:comunicacion-sensores>)[Comunicación I²C y lectura de datos crudos] de la sección #link(<sec:montaje-hw>)[Montaje de hardware].
#figure(
  grid(
    columns: (1fr, 1fr),
    gutter: 2em,
    [
        #image("images/prototipoSensores+ESP.jpeg", width: 100%)
    ],
    [
      #image("images/prototipoSensores.jpeg", width: 100%)
    ]
  ),
  caption: [Prototipo completo para las pruebas con MPU6050 y magnetómetro],
  kind: image,
)<fig-prototipo-completo>

La @fig-captura-interfaz presenta una captura del visualizador experimental desarrollado con JavaScript y Three.js, que recibe por Web Serial los ángulos calculados por el ESP32 y los representa sobre un modelo tridimensional. Corresponde a la sección #link(<sec:otros-avances>)[Otros avances] y recibe los datos descritos en #link(<sec:comunicacion-pc>)[Transmisión ESP32 a PC].

#figure(
  image("images/interfaz-prototipo.jpeg", width: 90%),
  caption: [Captura del visualizador experimental con Three.js.],
  kind: image,
) <fig-captura-interfaz>
== Links de la entrega

El código fuente está disponible en el #link("https://github.com/tpII/2026-a5-mano-simulada-dmp")[repositorio del proyecto], la bitácora de trabajo en la #link("https://github.com/tpII/2026-a5-mano-simulada-dmp/wiki/BITACORA")[wiki del repositorio] y el video de demostración en #link("https://drive.google.com/file/d/1Ytu-ZvgfhrjKuKCjhcG4eb800j2wZBuh/view?usp=sharing")[Google Drive].
