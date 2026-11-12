#include "protocolo.h"

#include <stdio.h>
#include <string.h>

namespace {
// Evita enviar un JSON truncado o leer fuera del búfer de salida.
size_t longitudValida(int longitud, size_t capacidad) {
  return longitud > 0 && (size_t)longitud < capacidad ? (size_t)longitud : 0;
}
} // namespace

namespace Protocolo {
Comando interpretar(const char *texto) {
  Comando comando;
  if (!texto)
    return comando;
  if (strstr(texto, "\"iniciar\""))
    comando.accion = Accion::Iniciar;
  else if (strstr(texto, "\"detener\""))
    comando.accion = Accion::Detener;
  else if (strstr(texto, "\"calibrarMag\""))
    comando.accion = Accion::CalibrarMag;
  else if (strstr(texto, "\"calibrar\""))
    comando.accion = Accion::CalibrarMpu;
  else if (strstr(texto, "\"filtro\"")) {
    if (strstr(texto, "\"comp\"")) {
      comando.accion = Accion::ElegirFiltro;
      comando.filtro = FiltroSoftware::Complementario;
    } else if (strstr(texto, "\"mag\"")) {
      comando.accion = Accion::ElegirFiltro;
      comando.filtro = FiltroSoftware::ConMagnetometro;
    } else if (strstr(texto, "\"kalman\"")) {
      comando.accion = Accion::ElegirFiltro;
      comando.filtro = FiltroSoftware::Kalman;
    }
  }
  return comando;
}

size_t muestra(char *destino, size_t capacidad, uint32_t numero, uint32_t tiempoMs,
               const char *filtro, const Cuaternion &dmp, const Cuaternion &software) {
  const int longitud =
      snprintf(destino, capacidad,
               "{\"n\":%lu,\"t\":%lu,\"f\":\"%s\",\"dmp\":[%.5f,%.5f,%.5f,%.5f],\"sw\":[%.5f,%.5f,%"
               ".5f,%.5f]}",
               (unsigned long)numero, (unsigned long)tiempoMs, filtro, dmp.w, dmp.x, dmp.y, dmp.z,
               software.w, software.x, software.y, software.z);
  return longitudValida(longitud, capacidad);
}

size_t error(char *destino, size_t capacidad, const char *mensaje) {
  return longitudValida(snprintf(destino, capacidad, "{\"err\":\"%s\"}", mensaje), capacidad);
}

size_t calibracion(char *destino, size_t capacidad, const char *sensor, const char *estado,
                   const char *mensaje) {
  return longitudValida(
      snprintf(destino, capacidad,
               "{\"calibracion\":{\"sensor\":\"%s\",\"estado\":\"%s\",\"mensaje\":\"%s\"}}", sensor,
               estado, mensaje),
      capacidad);
}
} // namespace Protocolo
