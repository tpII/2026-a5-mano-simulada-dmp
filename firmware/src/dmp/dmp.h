#pragma once

#include "../tipos.h"

namespace Dmp {
// Inicializa el MPU6050 y conecta la interrupción que anuncia paquetes nuevos.
bool iniciar();

// Indica si el sensor y su DMP se inicializaron correctamente.
bool disponible();

// Consume un aviso de interrupción y obtiene el último paquete DMP.
bool leer(Cuaternion &orientacion);

// Descarta paquetes y avisos anteriores después de una calibración.
void reiniciar();
} // namespace Dmp
