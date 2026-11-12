#include "i2c.h"

#include "../configuracion.h"
#include <Wire.h>

namespace BusI2c {
void iniciar() {
  Wire.begin(Configuracion::PIN_SDA, Configuracion::PIN_SCL);
  Wire.setClock(Configuracion::FRECUENCIA_I2C);
}

bool escribirRegistro(uint8_t direccion, uint8_t registro, uint8_t valor) {
  Wire.beginTransmission(direccion);
  Wire.write(registro);
  Wire.write(valor);
  return Wire.endTransmission() == 0;
}

bool leerRegistros(uint8_t direccion, uint8_t registro, uint8_t *datos, size_t cantidad) {
  if (!datos || cantidad == 0 || cantidad > 32)
    return false;
  Wire.beginTransmission(direccion);
  Wire.write(registro);
  if (Wire.endTransmission(false) != 0)
    return false;
  if (Wire.requestFrom((uint16_t)direccion, cantidad, true) != cantidad)
    return false;
  for (size_t i = 0; i < cantidad; ++i)
    datos[i] = Wire.read();
  return true;
}
} // namespace BusI2c
