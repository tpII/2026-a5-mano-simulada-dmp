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


