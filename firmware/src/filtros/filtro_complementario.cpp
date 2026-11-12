#include "filtro_complementario.h"

#include "../configuracion.h"
#include "../matematica/orientacion.h"
#include <math.h>

void FiltroComplementario::iniciar(const Vector3 &aceleracion, const Vector3 &campo) {
  roll = atan2f(aceleracion.y, aceleracion.z);
  pitch =
      atan2f(-aceleracion.x, sqrtf(aceleracion.y * aceleracion.y + aceleracion.z * aceleracion.z));
  yawMagnetometro = Matematica::rumboMagnetico(campo, roll, pitch);
  yawGiroscopio = yawMagnetometro;
}

void FiltroComplementario::actualizar(const DatosInerciales &datos, const Vector3 &campo,
                                      float dt) {
  const Vector3 &aceleracion = datos.aceleracion;
  const Vector3 &giro = datos.giro;
  const float peso = Configuracion::PESO_GIRO;
  const float rollAcelerometro = atan2f(aceleracion.y, aceleracion.z);
  const float pitchAcelerometro =
      atan2f(-aceleracion.x, sqrtf(aceleracion.y * aceleracion.y + aceleracion.z * aceleracion.z));
  roll = peso * (roll + giro.x * dt) + (1.0f - peso) * rollAcelerometro;
  pitch = peso * (pitch + giro.y * dt) + (1.0f - peso) * pitchAcelerometro;
  yawGiroscopio = Matematica::normalizarAngulo(yawGiroscopio + giro.z * dt);

  const float yawIntegrado = yawMagnetometro + giro.z * dt;
  const float diferencia =
      Matematica::normalizarAngulo(Matematica::rumboMagnetico(campo, roll, pitch) - yawIntegrado);
  yawMagnetometro = Matematica::normalizarAngulo(yawIntegrado + (1.0f - peso) * diferencia);
}

Orientacion FiltroComplementario::obtener(bool usarMagnetometro) const {
  Orientacion orientacion;
  orientacion.roll = roll;
  orientacion.pitch = pitch;
  orientacion.yaw = usarMagnetometro ? yawMagnetometro : yawGiroscopio;
  return orientacion;
}
