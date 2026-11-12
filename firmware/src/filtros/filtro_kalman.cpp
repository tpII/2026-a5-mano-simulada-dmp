#include "filtro_kalman.h"

#include "../matematica/orientacion.h"
#include <math.h>

namespace {
constexpr float RUIDO_ANGULO = 0.001f;
constexpr float RUIDO_GIRO = 0.003f;
constexpr float RUIDO_MEDICION = 0.03f;
} // namespace

void KalmanUnEje::reiniciar() {
  angulo = 0;
  sesgo = 0;
  for (int fila = 0; fila < 2; ++fila) {
    for (int columna = 0; columna < 2; ++columna)
      covarianza[fila][columna] = 0;
  }
}

float KalmanUnEje::actualizar(float referencia, float giro, float dt) {
  angulo += dt * (giro - sesgo);
  covarianza[0][0] +=
      dt * (dt * covarianza[1][1] - covarianza[0][1] - covarianza[1][0] + RUIDO_ANGULO);
  covarianza[0][1] -= dt * covarianza[1][1];
  covarianza[1][0] -= dt * covarianza[1][1];
  covarianza[1][1] += RUIDO_GIRO * dt;

  const float innovacion = covarianza[0][0] + RUIDO_MEDICION;
  const float gananciaAngulo = covarianza[0][0] / innovacion;
  const float gananciaSesgo = covarianza[1][0] / innovacion;
  const float diferencia = referencia - angulo;
  angulo += gananciaAngulo * diferencia;
  sesgo += gananciaSesgo * diferencia;

  const float anterior00 = covarianza[0][0];
  const float anterior01 = covarianza[0][1];
  covarianza[0][0] -= gananciaAngulo * anterior00;
  covarianza[0][1] -= gananciaAngulo * anterior01;
  covarianza[1][0] -= gananciaSesgo * anterior00;
  covarianza[1][1] -= gananciaSesgo * anterior01;
  return angulo;
}

void FiltroKalman::reiniciar() {
  filtroRoll.reiniciar();
  filtroPitch.reiniciar();
  filtroYaw.reiniciar();
  orientacion = Orientacion{};
}

void FiltroKalman::actualizar(const DatosInerciales &datos, const Vector3 &campo, float dt) {
  const Vector3 &aceleracion = datos.aceleracion;
  const float rollAcelerometro = atan2f(aceleracion.y, aceleracion.z);
  const float pitchAcelerometro =
      atan2f(-aceleracion.x, sqrtf(aceleracion.y * aceleracion.y + aceleracion.z * aceleracion.z));
  const float yawMagnetico = Matematica::rumboMagnetico(campo, orientacion.roll, orientacion.pitch);
  orientacion.roll = filtroRoll.actualizar(rollAcelerometro, datos.giro.x, dt);
  orientacion.pitch = filtroPitch.actualizar(pitchAcelerometro, datos.giro.y, dt);
  const float diferenciaYaw = Matematica::normalizarAngulo(yawMagnetico - orientacion.yaw);
  orientacion.yaw = Matematica::normalizarAngulo(
      orientacion.yaw + filtroYaw.actualizar(orientacion.yaw + diferenciaYaw, datos.giro.z, dt) -
      orientacion.yaw);
}

Orientacion FiltroKalman::obtener() const {
  return orientacion;
}
