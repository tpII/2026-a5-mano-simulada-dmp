#pragma once

namespace Calibracion {
enum class Sensor { Mpu6050, Magnetometro };
using Notificar = void (*)(const char *sensor, const char *estado, const char *mensaje);

// Registra cómo informar a la web los cambios del procedimiento.
void iniciar(Notificar notificar);

// Encola una solicitud; si ya está ocupado, informa el procedimiento en curso.
void solicitar(Sensor sensor);

// Atiende solicitudes y lecturas; devuelve true cuando hay que reiniciar filtros.
bool actualizar();

// Indica si hay una solicitud pendiente o una calibración en marcha.
bool ocupada();
} // namespace Calibracion
