/*
 * Mano simulada DMP (ESP32): coordina sensores, filtros y comunicación con la web.
 * SDA GPIO21, SCL GPIO22, interrupción MPU GPIO23, alimentación 3V3 y GND común.
 * Los detalles de hardware y algoritmos están en src/; ver README.md.
 */
#include "src/calibracion/calibracion.h"
#include "src/comunicacion/websocket.h"
#include "src/comunicacion/wifi.h"
#include "src/configuracion.h"
#include "src/dmp/dmp.h"
#include "src/filtros/estimador.h"
#include "src/matematica/orientacion.h"
#include "src/sensores/i2c.h"
#include "src/sensores/mpu6050.h"
#include "src/sensores/qmc5883l.h"
#include <Arduino.h>

namespace {
Vector3 campoMagnetico;
uint32_t ultimoPaqueteUs = 0;
uint32_t paquetesProcesados = 0;

// Aplica los comandos de la web sin mezclar el transporte con los algoritmos.
void manejarComando(const Protocolo::Comando &comando) {
  switch (comando.accion) {
  case Protocolo::Accion::Iniciar:
    Comunicacion::transmitir(true);
    break;
  case Protocolo::Accion::Detener:
    Comunicacion::transmitir(false);
    break;
  case Protocolo::Accion::CalibrarMpu:
    Calibracion::solicitar(Calibracion::Sensor::Mpu6050);
    break;
  case Protocolo::Accion::CalibrarMag:
    Calibracion::solicitar(Calibracion::Sensor::Magnetometro);
    break;
  case Protocolo::Accion::ElegirFiltro:
    Estimador::seleccionar(comando.filtro);
    break;
  case Protocolo::Accion::Desconocida:
    break;
  }
}

// Descarta el estado anterior para que los filtros arranquen con datos posteriores a la
// calibración.
void reiniciarEstimaciones() {
  Estimador::reiniciar();
  ultimoPaqueteUs = micros();
  Dmp::reiniciar();
}

// Actualiza los filtros con cada paquete y publica una de cada DIVISOR_ENVIO muestras.
void procesarPaquete(const Cuaternion &orientacionDmp) {
  const DatosInerciales datos = Mpu6050::leerMovimiento();
  Qmc5883l::leer(campoMagnetico); // Si falla, se conserva la última lectura, como antes.
  const uint32_t ahora = micros();
  const float dt = (ahora - ultimoPaqueteUs) * 1e-6f;
  ultimoPaqueteUs = ahora;
  if (!Estimador::actualizar(datos, campoMagnetico, dt))
    return;
  if (++paquetesProcesados % Configuracion::DIVISOR_ENVIO != 0)
    return;
  Comunicacion::enviarMuestra(orientacionDmp, Matematica::desdeEuler(Estimador::obtener()),
                              Estimador::nombre());
}
} // namespace

// Inicializa sensores y servicios; el MPU se calibra antes de producir datos.
void setup() {
  Serial.begin(Configuracion::BAUDIOS_SERIE);
  BusI2c::iniciar();
  if (!Qmc5883l::iniciar())
    Serial.println("Magnetometro QMC5883L no responde (revisar cables).");
  Serial.println("Iniciando DMP: guante quieto y horizontal, con +Z hacia arriba...");
  const bool listo = Dmp::iniciar();
  Serial.println(listo ? "DMP listo." : "DMP NO se pudo iniciar.");
  RedWifi::iniciarRedPropia();
  // RedWifi::iniciarConRouter(); // Alternativa conservada y comentada en wifi.cpp.
  Comunicacion::iniciar(manejarComando);
  Calibracion::iniciar(Comunicacion::enviarCalibracion);
  Estimador::reiniciar();
}

// Atiende primero la red y la calibración; luego procesa los paquetes disponibles.
void loop() {
  Comunicacion::atender();
  if (Calibracion::actualizar())
    reiniciarEstimaciones();
  if (Calibracion::ocupada())
    return;
  if (!Dmp::disponible()) {
    static uint32_t ultimoAvisoMs = 0;
    if (millis() - ultimoAvisoMs > 2000) {
      ultimoAvisoMs = millis();
      Comunicacion::enviarError("DMP no iniciado, revisar cables");
    }
    return;
  }
  Cuaternion orientacionDmp;
  if (Dmp::leer(orientacionDmp))
    procesarPaquete(orientacionDmp);
}
