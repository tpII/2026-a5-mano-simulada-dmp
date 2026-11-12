#pragma once

#include "../tipos.h"
#include <stddef.h>
#include <stdint.h>

namespace Protocolo {
enum class Accion { Desconocida, Iniciar, Detener, CalibrarMpu, CalibrarMag, ElegirFiltro };
struct Comando {
  Accion accion = Accion::Desconocida;
  FiltroSoftware filtro = FiltroSoftware::Complementario;
};

// Interpreta los comandos cortos actuales sin agregar una biblioteca JSON.
Comando interpretar(const char *texto);

// Serializa una muestra con el contrato n/t/f/dmp/sw; devuelve 0 si no cabe.
size_t muestra(char *destino, size_t capacidad, uint32_t numero, uint32_t tiempoMs,
               const char *filtro, const Cuaternion &dmp, const Cuaternion &software);

// Serializa un error del firmware; el mensaje debe ser un literal sin comillas.
size_t error(char *destino, size_t capacidad, const char *mensaje);

// Serializa el estado de calibración; los campos son literales internos del firmware.
size_t calibracion(char *destino, size_t capacidad, const char *sensor, const char *estado,
                   const char *mensaje);
} // namespace Protocolo
