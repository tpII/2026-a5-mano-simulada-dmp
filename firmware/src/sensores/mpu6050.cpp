#include "mpu6050.h"

#include "../matematica/orientacion.h"
#include <Arduino.h>
#include <MPU6050_6Axis_MotionApps20.h>

namespace {
MPU6050 dispositivo;
uint8_t paqueteFifo[64];
float sensibilidadGiro = 16.4f;
float sensibilidadAcelerometro = 16384.0f;
} // namespace

namespace Mpu6050 {
bool conectado() {
  return dispositivo.testConnection();
}

void calibrar() {
  dispositivo.CalibrateAccel(6);
  dispositivo.CalibrateGyro(6);
}

bool iniciar() {
  dispositivo.initialize();
  if (!conectado()) {
    Serial.println("MPU6050 no responde (revisar cables).");
    return false;
  }
  const uint8_t estado = dispositivo.dmpInitialize();
  if (estado != 0) {
    Serial.printf("dmpInitialize fallo, codigo %u\n", estado);
    return false;
  }

  // Valores iniciales usados en E2; la rutina siguiente los recalcula.
  dispositivo.setXAccelOffset(-1000);
  dispositivo.setYAccelOffset(-1000);
  dispositivo.setZAccelOffset(1000);
  dispositivo.setXGyroOffset(0);
  dispositivo.setYGyroOffset(0);
  dispositivo.setZGyroOffset(0);
  calibrar();
  habilitarDmp(true);

  sensibilidadGiro = 131.0f / (1 << dispositivo.getFullScaleGyroRange());
  sensibilidadAcelerometro = 16384.0f / (1 << dispositivo.getFullScaleAccelRange());
  dispositivo.getIntStatus();
  return true;
}

void habilitarDmp(bool habilitar) {
  dispositivo.setDMPEnabled(habilitar);
}

void limpiarFifo() {
  dispositivo.resetFIFO();
}

bool leerPaquete(Cuaternion &orientacion) {
  if (!dispositivo.dmpGetCurrentFIFOPacket(paqueteFifo))
    return false;
  Quaternion cuaternion;
  dispositivo.dmpGetQuaternion(&cuaternion, paqueteFifo);
  orientacion.w = cuaternion.w;
  orientacion.x = cuaternion.x;
  orientacion.y = cuaternion.y;
  orientacion.z = cuaternion.z;
  return true;
}

DatosInerciales leerMovimiento() {
  int16_t ax, ay, az, gx, gy, gz;
  dispositivo.getMotion6(&ax, &ay, &az, &gx, &gy, &gz);
  const float aRadianes = (Matematica::PI_RAD / 180.0f) / sensibilidadGiro;
  DatosInerciales datos;
  datos.aceleracion.x = ax / sensibilidadAcelerometro;
  datos.aceleracion.y = ay / sensibilidadAcelerometro;
  datos.aceleracion.z = az / sensibilidadAcelerometro;
  datos.giro.x = gx * aRadianes;
  datos.giro.y = gy * aRadianes;
  datos.giro.z = gz * aRadianes;
  return datos;
}
} // namespace Mpu6050
