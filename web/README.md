# Interfaz web

Desde esta carpeta, ejecutar:

```sh
python3 -m http.server 8000 --bind 127.0.0.1
```

Abrir http://127.0.0.1:8000 en el navegador.

## Bibliotecas

La página carga Three.js 0.186.0 y Chart.js 4.6.1 desde jsDelivr, sin guardar
copias de sus archivos en el proyecto. Las versiones están fijadas en
`index.html` para evitar actualizaciones automáticas.

Se necesita acceso a Internet para descargar las bibliotecas. Si se usa la red
Wi-Fi del ESP32 sin salida a Internet, la página puede no cargar las manos ni
los gráficos. La caché del navegador no garantiza el funcionamiento sin
conexión; para ese uso habría que volver a servir las bibliotecas localmente
o implementar un modo sin conexión.

## Filtro solicitado y confirmado

El selector pide un algoritmo; el título de la mano software muestra únicamente
el identificador `f` de las muestras recibidas. Hasta recibir datos, indica
"Sin confirmar". Si se pide otro algoritmo, se mantiene el último confirmado
y se avisa que el cambio está pendiente hasta recibir una muestra coincidente.
Un error del firmware no se considera una confirmación.

Al conectar o reconectar se envía la selección actual. Sin una solicitud
pendiente, los cambios recibidos de otro cliente actualizan también el selector.
El modo demo confirma su algoritmo mediante sus propias muestras sintéticas.
Los identificadores desconocidos no se presentan como un algoritmo válido.
Este paso utiliza el campo `f` existente y no requiere cambios en el firmware.

Pruebas sin dispositivo (requieren Node.js, solo para ejecutar las pruebas):

```sh
node web/pruebas/filtros.test.mjs
```

Ejecutar ese comando desde la raíz del repositorio.

## Calibración

La referencia visual y la calibración son acciones distintas. Para calibrar,
conectar el ESP32 y detener el ensayo. Los controles se deshabilitan en modo
demo, sin conexión y mientras hay una calibración en curso.

- **MPU6050** (`calibrar`): acelerómetro y giroscopio. Apoyar el guante inmóvil,
  horizontal y con el eje +Z del sensor hacia arriba. La rutina descuenta la
  gravedad sobre ese eje. Esperar el mensaje de finalización del firmware;
  no se supone una duración fija ni se certifica la precisión del resultado.
- **QMC5883L** (`calibrarMag`): girar lentamente en los tres ejes durante
  20 segundos. Si las lecturas no cubren suficiente recorrido en cada eje,
  se rechaza el intento y se conservan los offsets y escalas anteriores.

El firmware informa inicio, finalización o error mediante mensajes
`{"calibracion":{"sensor":"mpu|mag","estado":"iniciada|finalizada|error","mensaje":"..."}}`.
Los valores separados por `|` indican las alternativas del protocolo.
Estos mensajes requieren cargar la versión actualizada de `firmware.ino`
en el ESP32; modificar la web no actualiza el dispositivo.

Durante la calibración no se incorporan muestras a la visualización ni al
ensayo. Al terminar correctamente, se limpian los gráficos y la referencia
visual anterior. Los ajustes se mantienen en RAM y se pierden al reiniciar
el ESP32; el MPU6050 ejecuta una nueva calibración al arrancar.

La rutina min/max del magnetómetro aplica offsets y escalas por eje;
no corrige desalineaciones ni reemplaza una calibración elipsoidal completa.
La precisión debe verificarse con el guante real. Si se corta la conexión,
la web no puede confirmar el resultado; el ESP32 puede continuar calibrando.

