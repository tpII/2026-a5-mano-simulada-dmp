#include "calibracion_magnetometro.h"

#include "../configuracion.h"

void CalibracionMagnetometro::iniciar(uint32_t ahora) {
  inicio = ahora;
  for (int eje = 0; eje < 3; ++eje) {
    minimo[eje] = 32767;
    maximo[eje] = -32768;
  }
}

void CalibracionMagnetometro::agregar(const Vector3 &campo) {
  const float valores[3] = {campo.x, campo.y, campo.z};
  for (int eje = 0; eje < 3; ++eje) {
    if (valores[eje] < minimo[eje])
      minimo[eje] = valores[eje];
    if (valores[eje] > maximo[eje])
      maximo[eje] = valores[eje];
  }
}

bool CalibracionMagnetometro::vencida(uint32_t ahora) const {
  return uint32_t(ahora - inicio) >= Configuracion::DURACION_CALIBRACION_MAG_MS;
}

bool CalibracionMagnetometro::finalizar(AjustesMagnetometro &ajustes) const {
  float radio[3];
  for (int eje = 0; eje < 3; ++eje) {
    radio[eje] = (maximo[eje] - minimo[eje]) / 2.0f;
    if (radio[eje] < 100)
      return false;
  }
  const float radioPromedio = (radio[0] + radio[1] + radio[2]) / 3.0f;
  for (int eje = 0; eje < 3; ++eje) {
    ajustes.offset[eje] = (maximo[eje] + minimo[eje]) / 2.0f;
    ajustes.escala[eje] = radioPromedio / radio[eje];
  }
  return true;
}
