#pragma once

#include <stddef.h>
#include <stdint.h>

namespace BusI2c {
// Inicializa el bus compartido por los sensores con los pines de configuración.
void iniciar();

// Escribe un registro; devuelve false si el dispositivo no responde.
bool escribirRegistro(uint8_t direccion, uint8_t registro, uint8_t valor);

// Lee registros consecutivos; solo devuelve true si recibe todos los bytes.
bool leerRegistros(uint8_t direccion, uint8_t registro, uint8_t *datos, size_t cantidad);
} // namespace BusI2c
