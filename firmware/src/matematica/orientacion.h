#pragma once

#include "../tipos.h"

namespace Matematica {
constexpr double PI_RAD = 3.14159265358979323846;

// Lleva el ángulo al intervalo [-pi, pi].
float normalizarAngulo(float angulo);

// Convierte Euler ZYX (radianes) al cuaternión que consume la web.
Cuaternion desdeEuler(const Orientacion &orientacion);

// Obtiene el rumbo magnético compensando la inclinación de la mano.
float rumboMagnetico(const Vector3 &campo, float roll, float pitch);
} // namespace Matematica
