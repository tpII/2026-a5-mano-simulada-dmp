# Mano Simulada DMP — Grupo A5

Taller de Proyecto II, UNLP, 2026. Comparación de orientación obtenida por el
DMP y por filtros ejecutados en un ESP32. Hardware: **MPU6050 + QMC5883L**. Frecuencia objetivo de adquisición: 50 Hz.

## Organización

| Carpeta | Contenido |
| --- | --- |
| `firmware/` | Base modular del dispositivo; entrada `firmware.ino` |
| `firmware/src/sensores/` | I²C, MPU6050 y QMC5883L |
| `firmware/src/filtros/` | Filtro complementario |
| `firmware/src/dmp/` | Integración futura del DMP |
| `firmware/src/calibracion/` | Calibración por implementar |
| `firmware/src/comunicacion/` | Telemetría JSON v1 por USB; Wi-Fi pendiente |
| `web/` | Demo de dos manos, gráficos y exportación; integración v1 pendiente |
| `experimentos/` | Prototipos conservados para reproducir las pruebas anteriores |
| `documentacion/` | Entregas, imágenes, investigación y decisiones |
| `pruebas/` | Validación del contrato y archivos de ejemplo |
| `herramientas/` | Generador de capturas sintéticas |


## Ejecutar el firmware

Abrir `firmware/firmware.ino` en Arduino IDE con soporte ESP32 y elegir la placa
y el puerto correctos. El nombre coincide con la carpeta del sketch. Arduino
compila los módulos de `src/` recursivamente; las cabeceras usan rutas relativas.

El firmware incluye el diagnóstico de adquisición y manejo de lecturas inválidas.
Ver [requisitos y pendientes](firmware/README.md) antes de cargar el código.

La salida principal ahora es **JSON v1 a 460800 baudios**. Incluye muestras
numeradas, tiempos de 64 bits, cuentas originales, cuaterniones y validez.
La ruta DMP se marca ausente hasta su integración. El CSV anterior sigue
disponible como modo de diagnóstico alternativo.

## Reproducir los prototipos

- Complementario: `experimentos/filtro_complementario/filtro_complementario.ino`.
- DMP: `experimentos/prueba_dmp/prueba_dmp.ino`, con la biblioteca MPU6050/I2Cdev.
- UDP: `python experimentos/receptor_udp/receptor_udp.py`, para el experimento antiguo.
- Visualizador: desde la raíz, ejecutar:

```sh
python -m http.server 8000 --bind 127.0.0.1
```

Abrir `http://localhost:8000/experimentos/visualizador_serial/` en Chrome o Edge,
conectar el ESP32 a 115200 baudios y cerrar cualquier monitor serie que ocupe
el puerto. El prototipo carga Three.js desde Internet.

La web ya incluye dos manos, gráficos y exportación CSV en modo demo.
Para abrirla: `node web/servidor.cjs --sin-abrir` y visitar la dirección que imprime.
El WebSocket de la interfaz todavía no es compatible con el contrato del firmware
ni tiene un servidor implementado en el ESP32. Ver [instrucciones de la web](web/README.md).

## Documentación

- [Checklist completo, hallazgos y orden recomendado de trabajo](documentacion/estado_proyecto.md).
- [Validar la frecuencia real y los sensores](documentacion/hardware/validacion_adquisicion.md).
- [Contrato único de telemetría y ejemplos sin hardware](documentacion/protocolo/telemetria_v1.md).

## Probar telemetría sin ESP32

```sh
node --test pruebas/telemetria.test.mjs
node herramientas/generar_telemetria.mjs pruebas/datos/demo.ndjson giro 3000
```

La web puede importar el generador y el decodificador de `web/js/`; los ejemplos
usan `origen="simulacion"` para diferenciarlos de las mediciones físicas.
