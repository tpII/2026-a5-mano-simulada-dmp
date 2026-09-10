// Bloques de código
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.10": codly-languages
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
    [\$16.100],

    [1],
    [Módulo GY-9250 basado en MPU9250, con acelerómetro, giroscopio y magnetómetro de tres ejes. Incluye DMP.],
    [#link(
      "https://www.sistemsoft.com.ar/electronica/placa-de-desarrollo/modulo-gy9250-mpu9250-acelerometro-giroscopo-magnetometro",
    )[MPU9250]],
    [\$21.960 + \$14.500 de envío],

    [1], [Guante para montaje del sistema], [A definir], [\$11.900],

    [1], [Juego de cables Dupont x10], [A definir], [A definir],

    [A confirmar], [Capacitores de desacople: 0,1 µF y 10 nF], [A definir], [A definir],

    [1], [Cable USB-C para alimentación y programación del ESP32], [A definir], [A definir],

    [1],
    [Computadora para programación, recepción de datos y ejecución de la interfaz],
    [Disponible],
    [No requiere compra],

    [1], [Power bank para alimentación portátil del prototipo (opcional)], [A definir], [A definir],
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

== Sistema web
La aplicación de software deberá permitir recibir los datos transmitidos por el ESP32 y representar visualmente el movimiento y la orientación de la mano.

Se desarrollará utilizando Processing, con la biblioteca Toxiclibs para la representación y manipulación del modelo.

Como funcionalidad principal, la interfaz permitirá observar simultáneamente las dos representaciones tridimensionales de las manos. Una de ellas representará la orientación obtenida mediante el DMP, mientras que la otra representará la orientación calculada a partir de los datos crudos del acelerómetro, giroscopio y magnetómetro, utilizando los filtros implementados.

La interfaz contará con un panel de selección de filtros que permitirá al usuario elegir entre distintas opciones y visualizar las diferencias en el procesamiento de cada uno de ellos, con el objetivo de compararlos.

También contará con la visualización de la gráfica de error entre ambas estimaciones.

La interfaz estará orientada principalmente a facilitar la evaluación experimental de las dos estrategias, permitiendo observar sus diferencias y analizar su comportamiento bajo distintas condiciones.

= Avances cronológicos de tareas
== Informe de avance de octubre
Para el Informe de Avance de Octubre se planifica haber completado la etapa inicial de investigación y una primera implementación funcional del sistema de adquisición.

Las tareas previstas son:
#list(
  [Investigar el funcionamiento del MPU9250, su alimentación, principales configuraciones y el Digital Motion Processor (DMP).],
  [Analizar las diferentes formas de representar la orientación, principalmente los cuaterniones, y distintos filtros para los sensores.],
  [Investigar las librerías y herramientas disponibles para la comunicación entre el ESP32 y el MPU9250.],
  [Montar el hardware necesario.],
  [Establecer la comunicación mediante I²C.],
  [Realizar una primera configuración del DMP y obtener una estimación de orientación.],
  [Implementar el filtro complementario para la primera estimación de la orientación a partir de los datos crudos.],
  [Establecer la comunicación entre el ESP32 y la aplicación, que tendrá una interfaz simple, mostrando únicamente los datos recibidos en pantalla.],
  [Calibrar el DMP.],
)

Al finalizar esta etapa se espera contar con el hardware montado, las comunicaciones establecidas, una primera estimación de orientación mediante el DMP y alguna implementación del primer filtro.

== Informe de avance de noviembre
Para la fecha correspondiente al Informe de Avance de Noviembre se planifica haber avanzado hacia la integración completa de las dos estrategias de estimación.

#list(
  [Terminar de calibrar el DMP.],
  [Implementar y evaluar el filtro de Kalman, y pulir el filtro complementario.],
  [Desarrollar la aplicación con la representación visual de las manos.],
  [Implementar la comparación entre ambas reconstrucciones.],
)

Al finalizar esta etapa se espera disponer de un prototipo funcional capaz de adquirir los datos del MPU9250, procesarlos mediante las dos estrategias planteadas, transmitir los resultados por red y visualizarlos en la aplicación. De esta manera, en la etapa final se puede trabajar en el refinamiento de los filtros y el análisis de los resultados y las limitaciones del hardware.


= Documentación en video
