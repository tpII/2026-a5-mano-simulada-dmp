# Mano Simulada DMP — Grupo A5

Taller de Proyecto II, UNLP, 2026. Comparación de orientación obtenida por el
DMP y por filtros ejecutados en un ESP32. Hardware: **MPU6050 + QMC5883L**. Frecuencia objetivo de adquisición: 50 Hz.

## Organización

| Carpeta | Contenido |
| --- | --- |
| `firmware/` | Firmware modular; entrada `firmware.ino` y guía en `firmware/README.md` |
| `firmware/src/sensores/` | I²C, MPU6050 y QMC5883L |
| `firmware/src/filtros/` | Complementario, complementario con magnetómetro y Kalman |
| `firmware/src/dmp/` | Interrupción y adquisición de paquetes DMP |
| `firmware/src/calibracion/` | Calibración del MPU6050 y del magnetómetro |
| `firmware/src/comunicacion/` | Red propia, WebSocket y protocolo JSON de la web |
| `firmware/src/matematica/` | Cuaterniones, ángulos y rumbo magnético |
| `web/` | Visualización de dos manos, gráficos, calibración y exportación CSV |
| `experimentos/` | Prototipos conservados para reproducir las pruebas anteriores |
| `documentacion/` | Entregas, imágenes, investigación y decisiones |


