#include "orientacion.h"

#include <math.h>

namespace Matematica {
float normalizarAngulo(float angulo) {
  while (angulo > PI_RAD)
    angulo -= 2.0f * PI_RAD;
  while (angulo < -PI_RAD)
    angulo += 2.0f * PI_RAD;
  return angulo;
}

Cuaternion desdeEuler(const Orientacion &orientacion) {
  const float cr = cosf(orientacion.roll / 2);
  const float sr = sinf(orientacion.roll / 2);
  const float cp = cosf(orientacion.pitch / 2);
  const float sp = sinf(orientacion.pitch / 2);
  const float cy = cosf(orientacion.yaw / 2);
  const float sy = sinf(orientacion.yaw / 2);
  Cuaternion resultado;
  resultado.w = cr * cp * cy + sr * sp * sy;
  resultado.x = sr * cp * cy - cr * sp * sy;
  resultado.y = cr * sp * cy + sr * cp * sy;
  resultado.z = cr * cp * sy - sr * sp * cy;
  return resultado;
}

float rumboMagnetico(const Vector3 &campo, float roll, float pitch) {
  const float cr = cosf(roll);
  const float sr = sinf(roll);
  const float cp = cosf(pitch);
  const float sp = sinf(pitch);
  const float horizontalX = campo.x * cp + sp * (sr * campo.y + cr * campo.z);
  const float horizontalY = cr * campo.y - sr * campo.z;
  return atan2f(-horizontalY, horizontalX);
}
} // namespace Matematica
