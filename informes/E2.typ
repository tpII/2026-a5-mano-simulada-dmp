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
  #text(size: 22pt, weight: "bold")[Informe de Avance - Octubre] \
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
= Descripción general del proyecto
= Materiales y presupuesto
#figure(
  table(
    columns: (0.75fr, 2.4fr, 1.7fr, 1.3fr),
    align: (center, left, left, left),
    inset: 6pt,
    stroke: 0.5pt,

    table.header([*Cantidad*], [*Descripción*], [*Ya disponible*], [*Precio unitario*]),

    [1],
    [ESP32 NodeMCU WROOM-32, 38 pines, USB-C, Wi-Fi y Bluetooth], [Sí], [\$20.700],

    [1],
    [Módulo GY-9250 basado en MPU9250, con acelerómetro, giroscopio y magnetómetro de tres ejes. Incluye DMP.],[Sí], [\$21.960],

    [1], [Guante para montaje del sistema], [], [],

    [1], [Juego de cables Dupont x10], [Sí], [],

    [1], [Capacitor de desacople: 0,1 µF], [Sí], [],

    [1], [Cable USB-C para alimentación y programación del ESP32], [Sí], [],

    [1], [Power bank para alimentación portátil del prototipo (opcional)], [], [],
  ),
  caption: [Listado de materiales necesarios para el desarrollo del prototipo.],
  kind: table,
) <tab-materiales>
La cátedra proporcionó el ESP32 y el módulo GY-9250. El resto de los materiales ya se encontraban disponibles, resta la compra del guante para montar el sistema.

En un principio se había contemplado el uso de tres capacitores de desacople pero, al conectar los dispositivos se vió que dos de ellos iban en pines que no se utilizan en este proyecto, por lo cuál se redujo la cantidad a uno.

= Esquema gráfico del proyecto
= Grado de avance, problemas y soluciones
En el plan de proyecto se había planificado inicialmente completar la adquisición y montaje del hardware, establecer la comunicación I²C con el sensor y WiFi con la computadora, implementar el filtro complementario y realizar las lecturas del DMP aunque sin realizar configuraciones ni calibraciones por ahora. Esto se puede ver en la @fig-gantt.
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

== Montaje de hardware
=== Conexión
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

== Investigación teórica y librerías
== Comunicación I²C y lectura de datos crudos
== Configuración inicial y lecturas del DMP
== Implementación del filtro complementario
== Transmisión ESP a PC
= Documentación relacionada