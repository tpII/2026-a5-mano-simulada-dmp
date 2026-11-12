#pragma once

#include "../tipos.h"

namespace Mpu6050 {
// Inicializa el sensor, carga MotionApps y calibra antes de habilitar el DMP.
bool iniciar();

// Comprueba la comunicación con el sensor.
bool conectado();

// Recalcula offsets internos: sensor quieto, horizontal y con +Z hacia arriba.
void calibrar();

// Habilita o pausa la producción de paquetes del DMP.
void habilitarDmp(bool habilitar);

// Descarta paquetes acumulados en la FIFO del sensor.
void limpiarFifo();

// Lee el último paquete disponible y extrae su orientación DMP.
bool leerPaquete(Cuaternion &orientacion);

// Lee aceleración en g y giro en rad/s según los rangos configurados.
DatosInerciales leerMovimiento();
} // namespace Mpu6050
