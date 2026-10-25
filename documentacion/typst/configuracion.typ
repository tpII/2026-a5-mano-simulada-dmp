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


#let informe(
  titulo: "Informe de Avance",
  body,
) = {
// Configuración general del texto y títulos
set text(lang: "es", size: 12pt)
set par(
  justify: true,
  first-line-indent: 0pt, // sangría de primera línea
)
// Numeración de títulos automática
set heading(numbering: "1.1.1.")
show heading: set text(size: 14pt)

// Leyenda ARRIBA solo para tablas; las figuras de imagen la mantienen abajo
show figure: set figure(supplement: [Fig.])
show figure.where(kind: table): set figure.caption(position: top)

// Leyenda ARRIBA solo para tablas; las figuras de imagen la mantienen abajo
show figure.where(kind: image): set figure(supplement: [Figura])
show figure.where(kind: table): set figure(supplement: [Tabla])
show figure.where(kind: table): set figure.caption(position: top)

// Enlaces de colores y referencias
show cite: set text(blue)
show link: set text(blue)
show ref: set text(blue)

set math.equation(numbering: "(1)")
show ref: it => {
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
show: codly-init.with()
codly(languages: codly-languages, display-name: false, display-icon: false)
import zero: num, zi
zero.set-num(decimal-separator: ",")
zero.set-group(size: 3, separator: ".", threshold: (integer: 5, fractional: calc.inf))
zero.set-unit(fraction: "inline")


show figure.where(kind: "codigo"): set figure(supplement: [Código])
show figure.where(kind: "codigo"): set block(breakable: true)
show raw.where(block: true): set text(size: 8pt)

// ==========================================
// 1. CONFIGURACIÓN DE LA PORTADA
// ==========================================
set page(
  paper: "a4",
  margin: (x: 2.5cm, y: 2.5cm),
  header: none, // Sin encabezado en la portada
  footer: none, // Sin pie de página en la portada
)
// Logo cabecera
align(top + center)[
  #image("../imagenes/logo_info_unlp.png", width: 13cm)
]
// Espacio flexible que empuja el texto del centro
v(0.3fr)

// Título centrado vertical y horizontalmente
align(center)[
  #text(size: 22pt, fill: luma(80))[I118 - Taller de Proyecto II] \
  #v(0.8cm)
  #text(size: 22pt, weight: "bold")[#titulo] \
  #v(0.8cm)
  #text(size: 20pt)[Proyecto A5 - Mano simulada DMP]
]

v(1fr)

// Datos de los autores en la parte inferior
align(center)[
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



pagebreak()


// ==========================================
// 2. CONFIGURACIÓN DE LAS PÁGINAS NORMALES
// ==========================================
set page(
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
counter(page).update(1)

// ----------------------------------------------------------
// CONTENIDO DEL DOCUMENTO
// ----------------------------------------------------------

  body
}