#pragma once

#include "../tipos.h"

namespace Qmc5883l {
// Configura el QMC5883L: continuo, 100 Hz, +/-8 G y sobremuestreo 512.
bool iniciar();

// Lee las cuentas originales, sin offsets ni escalas, para calibrar.
bool leerCrudo(Vector3 &campo);

// Lee y corrige el campo; conserva el argumento anterior si falla la lectura.
bool leer(Vector3 &campo);

// Devuelve los offsets y escalas vigentes, almacenados solo en RAM.
const AjustesMagnetometro &calibracion();

// Sustituye los ajustes después de validar una calibración completa.
void aplicarCalibracion(const AjustesMagnetometro &ajustes);
} // namespace Qmc5883l
