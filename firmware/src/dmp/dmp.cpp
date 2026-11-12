#include "dmp.h"

#include "../configuracion.h"
#include "../sensores/mpu6050.h"
#include <Arduino.h>

namespace {
volatile bool paquetePendiente = false;
bool listo = false;

// La interrupción solo avisa; las lecturas I2C se hacen fuera de ella.
void IRAM_ATTR avisarPaquete() {
  paquetePendiente = true;
}
} // namespace

namespace Dmp {
bool iniciar() {
  listo = Mpu6050::iniciar();
  if (!listo)
    return false;
  pinMode(Configuracion::PIN_INTERRUPCION_MPU, INPUT);
  attachInterrupt(digitalPinToInterrupt(Configuracion::PIN_INTERRUPCION_MPU), avisarPaquete,
                  RISING);
  return true;
}

bool disponible() {
  return listo;
}

bool leer(Cuaternion &orientacion) {
  if (!listo || !paquetePendiente)
    return false;
  paquetePendiente = false;
  return Mpu6050::leerPaquete(orientacion);
}

void reiniciar() {
  paquetePendiente = false;
  if (listo)
    Mpu6050::limpiarFifo();
}
} // namespace Dmp
