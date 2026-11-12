#include "calibracion.h"

#include "../dmp/dmp.h"
#include "../sensores/mpu6050.h"
#include "../sensores/qmc5883l.h"
#include "calibracion_magnetometro.h"
#include <Arduino.h>

namespace {
enum class Etapa { Inactiva, PendienteMpu, PendienteMag, MidiendoMag };
Etapa etapa = Etapa::Inactiva;
CalibracionMagnetometro magnetometro;
Calibracion::Notificar notificar = nullptr;

// Publica un aviso si la aplicación registró un destinatario.
void avisar(const char *sensor, const char *estado, const char *mensaje) {
  if (notificar)
    notificar(sensor, estado, mensaje);
}

// Ejecuta la rutina bloqueante del MPU fuera del evento WebSocket.
bool calibrarMpu() {
  etapa = Etapa::Inactiva;
  if (!Dmp::disponible() || !Mpu6050::conectado()) {
    avisar("mpu", "error", "MPU6050 no disponible. Revisar la conexion y reiniciar el ESP32.");
    return false;
  }
  avisar("mpu", "iniciada",
         "MPU6050: mantener quieto y horizontal, con +Z hacia arriba, hasta terminar.");
  Serial.println("Recalibrando: no mover el guante...");
  Mpu6050::habilitarDmp(false);
  Mpu6050::calibrar();
  Mpu6050::limpiarFifo();
  Mpu6050::habilitarDmp(true);
  avisar("mpu", "finalizada",
         "Rutina del MPU6050 terminada. Comproba la estabilidad; los offsets se pierden al "
         "reiniciar.");
  return true;
}

// Valida los extremos antes de reemplazar la calibración magnética anterior.
void finalizarMagnetometro() {
  etapa = Etapa::Inactiva;
  AjustesMagnetometro ajustes = Qmc5883l::calibracion();
  if (!magnetometro.finalizar(ajustes)) {
    Serial.println("Calibracion insuficiente: girar el sensor en los tres ejes.");
    avisar("mag", "error",
           "Giro o lecturas insuficientes. Se conserva la calibracion anterior; repetir en los "
           "tres ejes.");
    return;
  }
  Qmc5883l::aplicarCalibracion(ajustes);
  for (int eje = 0; eje < 3; ++eje) {
    Serial.printf("Eje %d: Offset = %.2f | Scale = %.4f\n", eje, ajustes.offset[eje],
                  ajustes.escala[eje]);
  }
  avisar("mag", "finalizada",
         "Calibracion del magnetometro aplicada. Se pierde al reiniciar el ESP32.");
}
} // namespace

namespace Calibracion {
void iniciar(Notificar destinatario) {
  notificar = destinatario;
  etapa = Etapa::Inactiva;
}

void solicitar(Sensor sensor) {
  if (ocupada()) {
    const char *actual = etapa == Etapa::PendienteMpu ? "mpu" : "mag";
    avisar(actual, "iniciada", "Ya hay una calibracion en curso. Esperar a que termine.");
    return;
  }
  etapa = sensor == Sensor::Mpu6050 ? Etapa::PendienteMpu : Etapa::PendienteMag;
}

bool actualizar() {
  if (etapa == Etapa::PendienteMpu)
    return calibrarMpu();
  if (etapa == Etapa::PendienteMag) {
    if (!Qmc5883l::iniciar()) {
      etapa = Etapa::Inactiva;
      avisar("mag", "error",
             "QMC5883L no responde. Revisar cables; se conserva la calibracion anterior.");
      return false;
    }
    magnetometro.iniciar(millis());
    etapa = Etapa::MidiendoMag;
    Serial.println("Calibracion QMC5883L: girar en los tres ejes durante 20 segundos.");
    avisar("mag", "iniciada", "Gira el guante lentamente en los tres ejes durante 20 segundos.");
  }
  if (etapa != Etapa::MidiendoMag)
    return false;
  Vector3 crudo;
  if (Qmc5883l::leerCrudo(crudo))
    magnetometro.agregar(crudo);
  if (!magnetometro.vencida(millis()))
    return false;
  finalizarMagnetometro();
  return true;
}

bool ocupada() {
  return etapa != Etapa::Inactiva;
}
} // namespace Calibracion
