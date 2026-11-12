#pragma once

#include <stdint.h>

// Ajustes de hardware, adquisición y red usados por el firmware activo.
namespace Configuracion {
constexpr int PIN_SDA = 21;
constexpr int PIN_SCL = 22;
constexpr int PIN_INTERRUPCION_MPU = 23;
constexpr uint32_t FRECUENCIA_I2C = 400000;
constexpr uint8_t DIRECCION_QMC = 0x0D;
constexpr uint32_t BAUDIOS_SERIE = 115200;

// DMP ~100 Hz: se envía una de cada dos muestras, objetivo ~50 Hz.
constexpr uint8_t DIVISOR_ENVIO = 2;
constexpr float PESO_GIRO = 0.98f;
constexpr uint32_t DURACION_CALIBRACION_MAG_MS = 20000;

constexpr const char *NOMBRE_RED = "ManoDMP";
constexpr const char *CLAVE_RED = "mano1234";
constexpr uint16_t PUERTO_WEBSOCKET = 81;
} // namespace Configuracion
