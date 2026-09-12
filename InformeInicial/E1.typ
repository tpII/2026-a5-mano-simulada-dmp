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
#set heading(numbering: "1.a.")
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
#show ref: it => {
  if it.element != none and it.element.func() == math.equation {
    link(it.element.location(), numbering(
      it.element.numbering,
      ..counter(math.equation).at(it.element.location()),
    ))
  } else {
    it
  }
}

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
  #text(size: 22pt, fill: luma(80))[I118 - Taller de Proyecto II] \
  #v(0.8cm)
  #text(size: 22pt, weight: "bold")[Plan de Proyecto] \
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
        *I118 Taller de Proyecto II* \
        Mano simulada DMP
      ],
      [Grupo A5 \ Año 2026],
    )
    v(-0.3em)
    line(length: 100%, stroke: 0.5pt + luma(150))
  },
  footer: context {
    set text(size: 10pt)
    line(length: 100%, stroke: 0.5pt + luma(150))
    v(0.2em)
    align(center)[
      #counter(page).display("1 / 1", both: true)
    ]
  },
)

// Reinicio el contador para que sea la página 1
#counter(page).update(1)


// ==========================================
// INICIO DE DOCUMENTO
// ==========================================
= Introducción

La propuesta surge a partir del artículo “MPU6050 Gyro Drift Fix: DMP, Kalman Filter, and I2Cdevlib Setup“ de la empresa Industrial Monitors Direct, acerca del MPU6050, su DMP, el procesamiento de datos inerciales, los filtros de orientación y técnicas para reducir los efectos del gyro drift.

Se realizará una invesigacion con la que se busca comparar la orientación obtenida mediante el Digital Motion Processor (DMP) con una segunda estimación calculada a partir de las mediciones de los sensores y diferentes métodos de filtrado.

En el artículo se señala que el eje de yaw no posee una referencia absoluta cuando la orientación se obtiene únicamente a partir del giroscopio y acelerometro, por lo que puede presentar un error acumulativo. Como posible solución, se plantea incorporar un magnetómetro.

A partir de esta consideración, se decidió utilizar el MPU9250 en lugar del MPU6050, debido a que incorpora un magnetómetro de tres ejes.La incorporación de este tercer tipo de sensor permite disponer de una referencia adicional para la estimación de la orientación, particularmente sobre el eje de yaw.

= Objetivo

== Objetivo concreto

El objetivo del proyecto es demostrar empíricamente los errores típicos del hardware, la vibración y el drift, e identificar las mejores estrategias para reducir estos efectos.

== Funcionalidad y requerimientos
El sistema deberá cumplir con los siguientes requerimientos funcionales:
#list(
  [Adquirir las mediciones del acelerómetro, giroscopio y magnetómetro del MPU9250 mediante el ESP32.],
  [Obtener una estimación de la orientación mediante el procesamiento realizado por el DMP.],
  [Implementar los métodos matemáticos y filtros necesarios para calcular una segunda estimación utilizando los datos de los sensores, sin utilizar la estimación de orientación del DMP.],
  [Transmitir por red desde el ESP32 los datos necesarios para actualizar la representación virtual de la mano.],
  [Representar la orientación y el movimiento estimados en una aplicación de software de manera tal que se permita observar y comparar simultáneamente las dos estrategias de estimación.],
  [Permitir seleccionar entre dos o más métodos de reconstrucción de orientación para poder comparar distintas estrategias y analizar sus ventajas y limitaciones.],
)

El sistema deberá cumplir con los siguientes requerimientos no funcionales:
#list(
  [Recibir los datos del sensor MPU9250 mediante el protocolo I2C.],
  [Adquirir, procesar y transmitir los datos con una frecuencia de 50Hz (suficientemente alta para que el movimiento representado se perciba de manera fluida).],
)

= Esquema Gráfico del Proyecto
Para realizar la investigación se desarrollará un dispositivo capaz de adquirir información relacionada con el movimiento y la orientación de una mano montando el MPU9250 sobre un guante y conectándolo a un ESP32. Los datos obtenidos serán procesados y transmitidos por red hacia una aplicación de software, donde se realizará la reconstrucción y visualización del movimiento de la mano.

El MPU9250 estará conectado al ESP32 mediante el bus de comunicación I²C. El sensor proporcionará tanto la aproximación de la orientación realizada por el DMP como las mediciones del acelerómetro y del giroscopio, que serán utilizadas por el ESP32 para obtener la otra estimación de orientación planteada en el proyecto.

La información procesada por el ESP32 será transmitida mediante una conexión de red hacia una computadora donde se ejecutará la aplicación de software. Esta aplicación recibirá los datos, reconstruirá la orientación de la mano y permitirá visualizar y comparar los resultados obtenidos mediante ambos métodos.

= Identificación de partes



== Partes de hardware

El hardware necesario para el desarrollo estará compuesto principalmente por los elementos detallados en la @tab-materiales. Los precios indicados son valores de referencia al momento de elaborar el Plan de Proyecto y podrán variar según disponibilidad, costos de envío y proveedor.

#figure(
  table(
    columns: (0.75fr, 2.4fr, 1.7fr, 1.3fr),
    align: (center, left, left, left),
    inset: 6pt,
    stroke: 0.5pt,
    
    table.header([*Cantidad*], [*Descripción*], [*Link*], [*Precio unitario*]),
    
    [1],
    [ESP32 NodeMCU WROOM-32, 38 pines, USB-C, Wi-Fi y Bluetooth],
    [#link(
      "https://www.mercadolibre.com.ar/esp32-nodemcu-wroom32-38-pines-usbc-wifi-bluetooth-arduino/up/MLAU5001930260?pdp_filters=item_id:MLA3878662278#is_advertising=true&searchVariation=MLAU5001930260&backend_model=search-backend&be_origin=backend&position=1&search_layout=grid&type=pad&tracking_id=9cd4be54-9d01-4f56-8f09-c12251c0e86e&ad_domain=VQCATCORE_LST&ad_position=1&ad_click_id=N2U1Mzg1NWUtNzM0My00NmNlLWJjZjItNTkyYTkxNzU4ZTkz",
    )[ESP32 WROOM-32]],
    [\$20.700],
    
    [1],
    [Módulo GY-9250 basado en MPU9250, con acelerómetro, giroscopio y magnetómetro de tres ejes. Incluye DMP.],
    [#link(
      "https://www.sistemsoft.com.ar/electronica/placa-de-desarrollo/modulo-gy9250-mpu9250-acelerometro-giroscopo-magnetometro",
    )[MPU9250]],
    [\$21.960 + \$14.500 de envío],
    
    [1], [Guante para montaje del sistema], [], [],
    
    [1], [Juego de cables Dupont x10], [], [],
    
    [2], [Capacitores de desacople: 0,1 µF], [], [],
    
    [1], [Capacitor de desacople: 10 nF], [], [],
    
    [1], [Cable USB-C para alimentación y programación del ESP32], [], [],
    
    [1],
    [Computadora para programación, recepción de datos y ejecución de la interfaz],
    [Disponible],
    [],
    
    [1], [Power bank para alimentación portátil del prototipo (opcional)], [Disponible], [],
  ),
  caption: [Listado preliminar de materiales necesarios para el desarrollo del prototipo.],
  kind: table,
) <tab-materiales>


== Requerimientos de alimentación
El ESP32-WROOM-32 requiere una alimentación de 3,3 V, que se suministrará a través del puerto USB de la computadora. La corriente necesaria depende de la actividad del microcontrolador y del uso de las comunicaciones inalámbricas. Como el proyecto requiere una velocidad de procesamiento de 50 MHz, el consumo de la CPU será menor a 25 mA. El módulo WiFi, operando a 1 Mbps (máxima velocidad que puede proporcionar), consume 240 mA. El módulo Bluetooth no se utilizará en este proyecto, por lo cual el consumo de corriente total se mantendrá por debajo de 265 mA, dejando un margen para los picos de consumo.

Según la hoja de datos del MPU9250, su alimentación se realiza mediante VDD, con un rango de 2,4 V a 3,6 V, y VDDIO, con un rango de 1,71 V a VDD.

Cuando se encuentran habilitados los 9 ejes de movimiento y el DMP, el fabricante indica un consumo de corriente de operación típico de 3,5 mA. Este valor corresponde a una configuración específica y no se aclara cuál es el valor máximo alcanzable. Sin embargo, con una configuración específica (giroscopio a 1 kHz ODR, acelerómetro a 4 kHz ODR y magnetómetro a 8 Hz) y sin DMP, el consumo máximo es de 3,7 mA. Es por esto que la alimentación utilizada para el MPU9250 deberá proporcionar una corriente superior, para tener un margen de seguridad. De todas maneras, el consumo del MPU9250 es pequeño frente al consumo del ESP32, por lo que los requisitos de alimentación estarán determinados principalmente por el ESP32 y sus picos de consumo.

Además, como se observa en la @fig-alimentacion, el fabricante indica el uso de capacitores de desacople en el circuito de alimentación: 0,1 µF para VDD y REGOUT, y 10 nF para VDDIO.

#figure(
  image("images/alimentacion.png", width: 60%),
  caption: [Circuito de alimentación sugerido por el fabricante.],
  kind: image,
) <fig-alimentacion>

== Partes de software
El software del proyecto estará compuesto por diferentes procesos:
#list(
  [Inicialización y configuración del ESP32.],
  [Configuración y comunicación con el MPU9250 mediante I²C.],
  [Adquisición de datos del acelerómetro, giroscopio y magnetómetro.],
  [Configuración y utilización del Digital Motion Processor (DMP).],
  [Obtención de la orientación proporcionada por el DMP.],
  [Procesamiento de los datos crudos mediante filtros.],
  [Preparación de los datos para su transmisión.],
  [Comunicación entre el ESP32 y la aplicación mediante red.],
)

#figure(
  image("images/diagrama_de_flujo.png", width: 80%),
  caption: [Diagrama de flujo previsto para el desarrollo de software. A la izquierda el diagrama del microcontrolador. A la derecha el de la interfaz web.],
  kind: image,
) <diagrama-flujo>

== Sistema web
La aplicación de software deberá permitir recibir los datos transmitidos por el ESP32 y representar visualmente el movimiento y la orientación de la mano.

Se desarrollará utilizando Processing, con la biblioteca Toxiclibs para la representación y manipulación del modelo.

Como funcionalidad principal, la interfaz permitirá observar simultáneamente las dos representaciones tridimensionales de las manos. Una de ellas representará la orientación obtenida mediante el DMP, mientras que la otra representará la orientación calculada a partir de los datos crudos del acelerómetro, giroscopio y magnetómetro, utilizando los filtros implementados.

La interfaz contará con un panel de selección de filtros que permitirá al usuario elegir entre distintas opciones y visualizar las diferencias en el procesamiento de cada uno de ellos, con el objetivo de compararlos.

También contará con la visualización de la gráfica de error entre ambas estimaciones.

La interfaz estará orientada principalmente a facilitar la evaluación experimental de las dos estrategias, permitiendo observar sus diferencias y analizar su comportamiento bajo distintas condiciones.
= Avances cronológicos de tareas

== Diagrama de Gantt

En la @fig-gantt se ilustra la distribución temporal de las tareas y los hitos del proyecto a lo largo de las semanas lectivas del semestre.

#figure(
  {
    set text(size: 7.5pt, font: "Liberation Sans")
    
    // Paleta de colores
    let col-f1 = rgb("2b6cb0") // Azul (Fase 1)
    let col-f2 = rgb("2c7a7b") // Teal (Fase 2)
    let col-f3 = rgb("c05621") // Ámbar (Fase 3)
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
      columns: (5.2fr, ..(1fr,) * 12),
      align: (left + horizon, ..(center + horizon,) * 12),
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
      table.cell(colspan: 4)[*Octubre*],
      table.cell(colspan: 5)[*Noviembre*],
      
      // Fila 2: Semanas (Fecha lunes)
      [14], [21], [28], [5], [12], [19], [26], [2], [9], [16], [23], [30],
      
      // FASE 1
      table.cell(colspan: 13, fill: col-f1.lighten(92%), inset: 4pt)[
        #text(weight: "bold", fill: col-f1.darken(25%))[Etapa 1: Adquisición base, hardware y primer filtro]
      ],
      [Adquisición y montaje de hardware], table.cell(colspan: 1)[#bar(col-f1)], ..([],) * 11,
      [Investigación teórica y librerías], table.cell(colspan: 1)[#bar(col-f1)], ..([],) * 11,
      [Comunicación I²C y lectura de datos crudos], [], table.cell(colspan: 2)[#bar(col-f1)], ..([],) * 9,
      [Configuración inicial y lecturas del DMP], [], table.cell(colspan: 2)[#bar(col-f1)], ..([],) * 9,
      [Implementación del Filtro Complementario], ..([],) * 2, table.cell(colspan: 1)[#bar(col-f1)], ..([],) * 9,
      [Transmisión ESP32 a PC y monitor serie], ..([],) * 2, table.cell(colspan: 1)[#bar(col-f1)], ..([],) * 9,
      [Redacción del Informe de Avance E2], ..([],) * 2, table.cell(colspan: 2)[#bar(col-f1)], ..([],) * 8,
      
      // FASE 2
      table.cell(colspan: 13, fill: col-f2.lighten(92%), inset: 4pt)[
        #text(weight: "bold", fill: col-f2.darken(25%))[Etapa 2: Integración, Filtro de Kalman y visualización 3D]
      ],
      [Calibración fina de offsets del DMP], ..([],) * 4, table.cell(colspan: 1)[#bar(col-f2)], ..([],) * 7,
      [Implementación y ajuste del Filtro de Kalman], ..([],) * 4, table.cell(colspan: 2)[#bar(col-f2)], ..([],) * 6,
      [Desarrollo visual (manos 3D)], ..([],) * 4, table.cell(colspan: 3)[#bar(col-f2)], ..([],) * 5,
      [Optimización del Filtro Complementario], ..([],) * 5, table.cell(colspan: 2)[#bar(col-f2)], ..([],) * 5,
      [Panel selector y graficador de error], ..([],) * 5, table.cell(colspan: 2)[#bar(col-f2)], ..([],) * 5,
      [Integración de prototipo funcional (50 Hz)], ..([],) * 7, table.cell(colspan: 1)[#bar(col-f2)], ..([],) * 4,
      [Redacción del Informe de Avance E3], ..([],) * 7, table.cell(colspan: 1)[#bar(col-f2)], ..([],) * 4,
      
      // FASE 3
      table.cell(colspan: 13, fill: col-f3.lighten(92%), inset: 4pt)[
        #text(weight: "bold", fill: col-f3.darken(25%))[Etapa 3: Ensayos experimentales, video y cierre]
      ],
      [Ensayos empíricos de drift y vibración], ..([],) * 8, table.cell(colspan: 2)[#bar(col-f3)], ..([],) * 2,
      [Análisis comparativo de resultados], ..([],) * 8, table.cell(colspan: 2)[#bar(col-f3)], ..([],) * 2,
      [Pulido final de interfaz y firmware], ..([],) * 9, table.cell(colspan: 2)[#bar(col-f3)], [],
      [Grabación y edición del video demostrativo], ..([],) * 9, table.cell(colspan: 2)[#bar(col-f3)], [],
      [Redacción del Informe Final], ..([],) * 9, table.cell(colspan: 3)[#bar(col-f3)],
      
      // HITOS Y ENTREGAS FORMALES
      table.cell(colspan: 13, fill: col-hito.lighten(90%), inset: 4pt)[
        #text(weight: "bold", fill: col-hito.darken(25%))[Entregas formales (hitos)]
      ],
      [Informe de Avance 1 (E2) -- 11/10/2026], ..([],) * 3, celda-hito(), ..([],) * 8,
      [Informe de Avance 2 (E3) -- 08/11/2026], ..([],) * 7, celda-hito(), ..([],) * 4,
      [Entrega Final e Informe -- 06/12/2026], ..([],) * 11, celda-hito(),
    )
  },
  caption: [Diagrama de Gantt por etapas con entregas formales.],
  kind: table,
) <fig-gantt>
= Documentación en video
