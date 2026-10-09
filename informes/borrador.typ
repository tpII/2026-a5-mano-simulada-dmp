// Bloques de código

#import "@preview/codly:1.3.0": *

#import "@preview/codly-languages:0.1.10": codly-languages

#import "@preview/timeliney:0.4.0"

// Diagramas de estados o bloques

#import "@preview/fletcher:0.5.8"

// Listas o cuestionarios

#import "@preview/lilaq:0.5.0" as lq

// Notación matemática

#import "@preview/physica:0.9.6": *

#import "@preview/zero:0.5.0"



// Configuración general del texto y títulos

#set text(lang: "es", size: 12pt)

#set par(
  justify: true,

  first-line-indent: 0pt, // sangría de primera línea
)

// Numeración de títulos automática

#set heading(numbering: "1.1.1.")

#show heading: set text(size: 14pt)



// Leyenda ARRIBA solo para tablas; las figuras de imagen la mantienen abajo

#show figure: set figure(supplement: [Fig.])

#show figure.where(kind: table): set figure.caption(position: top)



// Leyenda ARRIBA solo para tablas; las figuras de imagen la mantienen abajo

#show figure.where(kind: image): set figure(supplement: [Fig.])

#show figure.where(kind: table): set figure(supplement: [Tabla])

#show figure.where(kind: table): set figure.caption(position: top)



// Enlaces de colores y referencias

#show cite: set text(blue)

#show link: set text(blue)

#show ref: set text(blue)



#set math.equation(numbering: "(1)")

// Configuración de codly y zero

#show: codly-init.with()

#codly(languages: codly-languages, display-name: false, display-icon: false)

#import zero: num, zi

#zero.set-num(decimal-separator: ",")

#zero.set-group(size: 3, separator: ".", threshold: (integer: 5, fractional: calc.inf))

#zero.set-unit(fraction: "inline")



// ==========================================

// 1. CONFIGURACIÓN DE LA PORTADA

// ==========================================

#set page(
  paper: "a4",

  margin: (x: 2.5cm, y: 2.5cm),

  header: none, // Sin encabezado en la portada

  footer: none, // Sin pie de página en la portada
)



// Logo cabecera

#align(top + center)[

  #image("images/logo_INFO-UNLP.png", width: 13cm)

]

// Espacio flexible que empuja el texto del centro

#v(0.3fr)



// Título centrado vertical y horizontalmente

#align(center)[

  #text(size: 22pt, fill: luma(80))[I118 - Taller de Proyecto II] \\

  #v(0.8cm)

  #text(size: 22pt, weight: "bold")[Informe de Avance - Octubre] \\

  #v(0.8cm)

  #text(size: 20pt)[Proyecto A5 - Mano simulada DMP]

]



#v(1fr)



// Datos de los autores en la parte inferior

#align(center)[

  #text(size: 18pt, weight: "bold")[Grupo de desarrollo]

  #text(size: 14pt)[

    #v(0.1cm)

    Acuña, Lucia - 03213/1

    #v(0.1cm)

    Avila Montoya, Eygleen Fernanda - 02931/2

    #v(0.1cm)

    Bejarano, Abril - 03339/5

  ]

]







#pagebreak()





// ==========================================

// 2. CONFIGURACIÓN DE LAS PÁGINAS NORMALES

// ==========================================

#set page(
  margin: (top: 3.5cm, bottom: 3cm, x: 2.5cm),

  header: context {
    set text(size: 9pt, fill: luma(80))

    grid(

      columns: (1fr, auto),

      align: (left, right),

      [

        *I118 Taller de Proyecto II* \\

        Mano simulada DMP

      ],

      [Grupo A5 — Año 2026],
    )

    v(-0.3em)

    line(length: 100%, stroke: 0.5pt + luma(150))
  },

  footer: context {
    set text(size: 10pt)

    line(length: 100%, stroke: 0.5pt + luma(150))

    v(0.2em)

    align(center)[

      #counter(page).display("1")

    ]
  },
)



// Reinicio el contador para que sea la página 1

#counter(page).update(1)





// ==========================================

// INICIO DE DOCUMENTO

// ==========================================

= Descripción general del proyecto

El proyecto A5 — *Mano simulada DMP* tiene como objetivo desarrollar un sistema de adquisición y visualización de orientación tridimensional para comparar dos métodos de estimación a partir de una unidad de medición inercial (IMU). El primero utilizará la orientación calculada por el procesador digital de movimiento (DMP) del sensor y el segundo empleará filtros implementados por software sobre las mediciones del acelerómetro y el giroscopio.

El dispositivo final estará compuesto por un módulo GY-9250 con sensor MPU9250 montado sobre un guante y conectado por I²C a un ESP32. Los resultados se transmitirán a una interfaz web que mostrará dos modelos tridimensionales y una gráfica de diferencias entre estimaciones.

Se decidió utilizar el MPU9250 en lugar del MPU6050 inicialmente considerado para incorporar también un magnetómetro, potencialmente útil como referencia del rumbo (yaw). En esta primera etapa se utilizó un MPU6050 para verificar adquisición, interrupciones, calibración inicial y filtrado. *Los resultados experimentales de octubre corresponden al MPU6050*; el MPU9250 definitivo aún requiere pruebas.

= Materiales y presupuesto

#figure(
  table(
    columns: (0.65fr, 2.6fr, 1.25fr, 1.2fr),
    align: (center, left, center, right),
    inset: 5pt,
    stroke: 0.5pt,
    table.header([*Cantidad*], [*Descripción*], [*Disponible*], [*Precio unitario*]),
    [1], [ESP32 NodeMCU WROOM-32, 38 pines, USB-C, Wi-Fi y Bluetooth], [Sí], [\$20.700],
    [1], [Módulo GY-9250 con MPU9250: acelerómetro, giroscopio y magnetómetro; DMP], [Sí], [\$21.960],
    [1], [MPU6050 empleado para las pruebas preliminares], [Sí], [—],
    [1], [Guante para montaje del sistema], [Pendiente], [A cotizar],
    [1], [Juego de cables Dupont x10], [Sí], [—],
    [1], [Capacitor de desacople de 0,1 µF (según necesidad del montaje definitivo)], [Sí], [—],
    [1], [Cable USB-C para alimentación y programación], [Sí], [—],
    [1], [Power bank para alimentación portátil (opcional)], [Pendiente], [A cotizar],
  ),
  caption: [Materiales del prototipo y disponibilidad. Los precios son referencias del presupuesto inicial.],
  kind: table,
) <tab-materiales>

El ESP32 y el módulo GY-9250 fueron proporcionados por la cátedra. El MPU6050 se empleó como dispositivo de ensayo. Los dos componentes principales tienen un valor de referencia conjunto de \$42.660, sin representar un gasto realizado por el grupo. Quedan por completar los precios y enlaces de proveedor de los elementos no cotizados.

En las primeras pruebas, el sistema se alimentó mediante el puerto USB del ESP32, que proporciona 3,3 V al módulo. La necesidad de capacitores externos deberá verificarse según los componentes de desacople incorporados en la placa definitiva; no se consideran instalados en la configuración ensayada.

= Esquema gráfico del proyecto

La arquitectura propuesta separa adquisición, procesamiento y visualización. El ESP32 recibe las mediciones por I²C, estima orientación mediante los dos métodos previstos y transmite los resultados a la interfaz. Durante octubre se verificó una ruta provisional por USB, mientras que el transporte Wi-Fi permanece sin validar.


#figure(
  image("images/Esquema.png", width: 100%),
  caption: [Esquema de arquitectura general del sistema A5 – Mano Simulada con DMP.],
  kind: image,
) <fig-arquitectura>


#figure(
  box(width: 100%, inset: 12pt, stroke: 0.6pt + luma(150))[
    #align(center)[*Prototipo probado en octubre*]
    #v(6pt)
    #align(center)[MPU6050 → I²C + DATA_READY → ESP32 → USB serie → PC]
    #v(5pt)
    #align(center)[Filtro complementario en ESP32 y visualizador de prueba]
  ],
  caption: [Ruta experimental validada hasta la transmisión serie.],
) <fig-arquitectura-prueba>

= Grado de avance, problemas y soluciones

El cronograma inicial contemplaba completar el montaje, la adquisición I²C, las primeras lecturas del DMP, la implementación del filtro complementario y la transmisión ESP32–computadora. Se logró una primera versión funcional de adquisición y filtrado, mientras que el DMP y la comunicación inalámbrica continúan pendientes. El diagrama @fig-gantt reproduce la planificación original y no debe interpretarse como un registro de tareas completadas.

#figure(
  {
    set text(size: 7.5pt)
    let azul = rgb("2b6cb0")
    let rojo = rgb("c92a2a")
    let barra = box(width: 100%, height: 8pt, fill: azul.lighten(20%), radius: 2pt)
    table(
      columns: (5fr, 1fr, 1fr, 1fr, 1fr, 1fr),
      align: (left, center, center, center, center, center),
      inset: 3pt,
      stroke: 0.35pt + luma(195),
      table.header([*Tarea planificada*], [*14/9*], [*21/9*], [*28/9*], [*5/10*], [*12/10*]),
      [Montaje y adquisición de hardware], [#barra], [], [], [], [],
      [Investigación y librerías], [#barra], [], [], [], [],
      [Comunicación I²C y lectura], [], [#barra], [#barra], [], [],
      [Primeras lecturas del DMP], [], [#barra], [#barra], [], [],
      [Filtro complementario], [], [], [#barra], [], [],
      [Transmisión a PC], [], [], [#barra], [], [],
      [Informe E2], [], [], [#barra], [#barra], [],
      [*Entrega E2: 11/10/2026*], [], [], [], [#text(fill: rojo)[◆]], [],
    )
  },
  caption: [Diagrama de Gantt correspondiente a la planificación de octubre.],
  kind: table,
) <fig-gantt>

== Montaje de hardware

=== Conexión y alimentación

Se preparó un prototipo con ESP32 y MPU6050. Se soldaron los conductores directamente a los pines del módulo y se conectaron al ESP32 mediante cables Dupont. El microcontrolador se alimentó por USB y suministró 3,3 V al sensor.

#figure(
  table(
    columns: (1fr, 1fr, 2fr),
    inset: 5pt,
    stroke: 0.5pt,
    table.header([*MPU6050*], [*ESP32*], [*Función*]),
    [VCC], [3V3], [Alimentación],
    [GND], [GND], [Masa común],
    [SDA], [GPIO21], [Datos I²C],
    [SCL], [GPIO22], [Reloj I²C],
    [INT], [GPIO23], [Interrupción DATA_READY],
    [AD0], [Sin conexión externa], [Selección de dirección en el módulo],
  ),
  caption: [Conexiones verificadas del prototipo experimental con MPU6050.],
  kind: table,
) <tab-pines>

El registro de identificación devolvió `0x68`. La conexión INT se emplea para indicar nuevas mediciones disponibles; en estas pruebas *no* corresponde a una interrupción de resultado del DMP. Quedan pendientes el montaje sobre el guante, la alimentación portátil y la conexión del MPU9250 definitivo.

#figure(
  box(width: 100%, inset: 10pt, stroke: 0.6pt + luma(150))[
    *Figura pendiente:* incorporar fotografía del MPU6050 con los cables soldados y esquema eléctrico definitivo (ESP32–MPU6050).
  ],
  caption: [Espacio para evidencia fotográfica y esquema de conexiones físicas.],
) <fig-montaje>

== Investigación teórica y librerías

Se estudiaron la adquisición con acelerómetro y giroscopio, los rangos de sensibilidad, el filtro digital pasabajos (DLPF), el divisor de muestreo, las interrupciones DATA_READY y el DMP. Inicialmente se utilizó la biblioteca `Adafruit_MPU6050` para comprobar la lectura de aceleración, velocidad angular y temperatura.

Luego se implementó el acceso directo a registros mediante `Wire`, con módulos separados para I²C, configuración y lectura del sensor, y posteriormente un módulo específico de filtrado. Esta organización facilita mantener independientes la adquisición y el procesamiento, aunque será necesario adaptar y verificar las particularidades del MPU9250. Para la visualización inicial se utilizó JavaScript con Three.js.

== Comunicación I²C y lectura de datos crudos

Se configuró el acelerómetro en ±2 g, el giroscopio en ±250 °/s y el DLPF en aproximadamente 21 Hz. Se leyeron 14 bytes consecutivos a partir del registro `0x3B`, correspondientes a aceleración, temperatura y velocidad angular. Los valores enteros de 16 bits del sensor se convirtieron a m/s² y rad/s antes de su transmisión.

La sincronización se realizó con la interrupción DATA_READY en GPIO23, con una frecuencia nominal de 50 Hz. En una prueba de 1500 muestras se registró una frecuencia media de 50,090 Hz, sin errores I²C y sin eventos adicionales pendientes detectados. El intervalo promedio de lectura fue de 19.963,96 µs; el mínimo fue 18.999 µs y el máximo, 20.001 µs. Estos valores corresponden a instantes registrados por el firmware, no a una medición directa del jitter eléctrico de INT.

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

Las medias del giroscopio se utilizaron como estimaciones preliminares de su bias. Si el valor medido en X (−0,022842 rad/s) permaneciera constante, su integración sin corrección produciría una deriva teórica de aproximadamente 78,5° en un minuto. No se trata de un error angular medido en una prueba independiente. En el acelerómetro, una única posición de reposo no permite separar errores de escala, alineación y offset.

#figure(
  box(width: 100%, inset: 10pt, stroke: 0.6pt + luma(150))[
    *Figura pendiente:* insertar captura del monitor serie con las 1500 muestras, la frecuencia medida y los valores de media y desviación estándar.
  ],
  caption: [Referencia para la evidencia de calibración inicial.],
) <fig-calibracion>

== Configuración inicial y lecturas del DMP

Se realizó investigación preliminar sobre la obtención de orientación mediante el DMP. Sin embargo, *todavía no se inicializó ni se validó el DMP del MPU9250* y no se dispone de mediciones de orientación provenientes de ese procesador. La señal DATA_READY utilizada en las pruebas actuales no representa una salida de orientación del DMP.

Como próximos pasos se prevé conectar el GY-9250, comprobar su identificación, configurar la lectura de orientación del DMP y registrar su frecuencia y estabilidad. Recién entonces podrá efectuarse una comparación experimental entre ambos métodos.

== Implementación del filtro complementario

Se implementó en el ESP32 un filtro complementario que combina la integración del giroscopio con la referencia de inclinación del acelerómetro. La estimación inicial se expresa mediante roll, pitch y yaw. Para roll y pitch se adoptó un coeficiente de ponderación de 0,98 y se corrigieron los sesgos obtenidos en la prueba de calibración.

El procesamiento se organizó en los archivos `filtro_complementario.cpp` y `filtro_complementario.h`, que funcionan separados de los módulos de adquisición. La actualización se ejecuta al recibirse una nueva muestra y utiliza el intervalo de tiempo transcurrido. El yaw se obtiene integrando la velocidad angular Z, por lo que puede acumular deriva: el MPU6050 no dispone de magnetómetro como referencia absoluta de rumbo.

#figure(
  box(width: 100%, inset: 10pt, stroke: 0.6pt + luma(160))[
    #align(center)[$theta_k = alpha (theta_(k-1) + omega_k Delta t) + (1 - alpha) theta_("acc", k)$]
  ],
  caption: [Ecuación básica del filtro complementario, aplicada por separado a roll y pitch.],
) <fig-filtro>

Las pruebas de transmisión confirmaron que el firmware calcula y actualiza ángulos junto con las mediciones del sensor. En el registro compartido no se reportaron errores I²C ni interrupciones agrupadas. Sigue pendiente validar los ángulos frente a orientaciones conocidas y medir su deriva. El algoritmo actual emplea una integración independiente por eje y deberá evaluarse ante rotaciones tridimensionales combinadas.

== Transmisión ESP32 a PC

La transmisión comprobada se realiza por comunicación serie USB a 115200 baudios. El ESP32 envía registros CSV con tiempo, aceleraciones, velocidades angulares y los tres ángulos estimados. El formato de cada línea es: `tiempo, Ax, Ay, Az, Gx, Gy, Gz, roll, pitch, yaw`.

Se desarrolló un visualizador experimental mediante JavaScript y Three.js, que permite recibir datos con Web Serial y representar un modelo tridimensional. Inicialmente el filtrado se realizaba en JavaScript; después se trasladó al ESP32. Se verificó el flujo de ángulos del firmware, pero todavía se debe confirmar completamente su correspondencia con los ejes de la última versión del modelo 3D.

Existen archivos preliminares para crear un punto de acceso Wi-Fi y transmitir datos mediante UDP. No obstante, esa vía todavía no fue integrada ni ensayada con el sistema completo y, por lo tanto, no se considera finalizada la comunicación inalámbrica.

#figure(
  box(width: 100%, inset: 10pt, stroke: 0.6pt + luma(150))[
    *Figura pendiente:* insertar captura del monitor serie (CSV) y de la interfaz Three.js en funcionamiento.
  ],
  caption: [Evidencia de transmisión serie y visualización tridimensional de prueba.],
) <fig-visualizacion>

== Estado general y próximos pasos

#figure(
  table(
    columns: (2.7fr, 1.5fr),
    inset: 5pt,
    stroke: 0.5pt,
    table.header([*Actividad*], [*Estado*]),
    [Montaje ESP32–MPU6050], [Probado],
    [Lectura I²C y DATA_READY a 50 Hz], [Probado],
    [Calibración estática del giroscopio], [Ensayo inicial],
    [Filtro complementario en ESP32], [Implementado; validación pendiente],
    [Transmisión CSV por USB], [Probado],
    [Visualizador Three.js], [Prototipo de prueba],
    [MPU9250 y DMP], [Pendiente],
    [Comunicación Wi-Fi], [Pendiente],
    [Guante y comparación de las dos manos], [Pendiente],
  ),
  caption: [Síntesis del avance experimental.],
  kind: table,
) <tab-avance>

La próxima etapa incluirá la puesta en marcha del MPU9250, el DMP, la transmisión inalámbrica y la integración de dos modelos tridimensionales con una gráfica de error. También se repetirán las pruebas de calibración y se estudiará la estabilidad del filtro bajo movimientos controlados.

= Documentación relacionada

Como evidencia se incluirán fotografías del montaje y las soldaduras, el esquema de conexiones revisado, el registro de identificación del sensor, la salida de la prueba de calibración, capturas del formato CSV y del visualizador. Además, se deberá incorporar el vínculo al repositorio de código, una bitácora de desarrollo y, de ser posible, un video breve de funcionamiento.

*Pendiente antes de la entrega:* completar las figuras identificadas, los enlaces de proveedores y repositorio, y la información de documentación compartida con la cátedra.
