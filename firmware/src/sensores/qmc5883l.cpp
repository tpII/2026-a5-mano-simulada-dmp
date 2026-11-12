#include "qmc5883l.h"

#include "../configuracion.h"
#include "i2c.h"

namespace {
AjustesMagnetometro ajustes;
}

namespace Qmc5883l {
bool iniciar() {
  return BusI2c::escribirRegistro(Configuracion::DIRECCION_QMC, 0x0B, 0x01) &&
         BusI2c::escribirRegistro(Configuracion::DIRECCION_QMC, 0x09, 0x19);
}

bool leerCrudo(Vector3 &campo) {
  uint8_t bytes[6];
  if (!BusI2c::leerRegistros(Configuracion::DIRECCION_QMC, 0x00, bytes, sizeof(bytes))) {
    return false;
  }
  campo.x = (int16_t)((bytes[1] << 8) | bytes[0]);
  campo.y = (int16_t)((bytes[3] << 8) | bytes[2]);
  campo.z = (int16_t)((bytes[5] << 8) | bytes[4]);
  return true;
}

bool leer(Vector3 &campo) {
  Vector3 crudo;
  if (!leerCrudo(crudo))
    return false;
  campo.x = (crudo.x - ajustes.offset[0]) * ajustes.escala[0];
  campo.y = (crudo.y - ajustes.offset[1]) * ajustes.escala[1];
  campo.z = (crudo.z - ajustes.offset[2]) * ajustes.escala[2];
  // Se conserva la alineación identidad del montaje actual: no se permutan ejes.
  return true;
}

const AjustesMagnetometro &calibracion() {
  return ajustes;
}

void aplicarCalibracion(const AjustesMagnetometro &nuevosAjustes) {
  ajustes = nuevosAjustes;
}
} // namespace Qmc5883l
