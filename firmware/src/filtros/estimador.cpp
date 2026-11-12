#include "estimador.h"

#include "filtro_complementario.h"
#include "filtro_kalman.h"

namespace {
FiltroComplementario complementario;
FiltroKalman kalman;
FiltroSoftware seleccionado = FiltroSoftware::Complementario;
bool iniciado = false;
} // namespace

namespace Estimador {
void reiniciar() {
  iniciado = false;
  kalman.reiniciar();
}

bool actualizar(const DatosInerciales &datos, const Vector3 &campo, float dt) {
  if (!iniciado) {
    complementario.iniciar(datos.aceleracion, campo);
    iniciado = true;
    return false;
  }
  if (dt <= 0.0f || dt > 0.1f)
    return false;
  complementario.actualizar(datos, campo, dt);
  kalman.actualizar(datos, campo, dt);
  return true;
}

void seleccionar(FiltroSoftware filtro) {
  seleccionado = filtro;
}

Orientacion obtener() {
  switch (seleccionado) {
  case FiltroSoftware::Complementario:
    return complementario.obtener(false);
  case FiltroSoftware::ConMagnetometro:
    return complementario.obtener(true);
  case FiltroSoftware::Kalman:
    return kalman.obtener();
  }
  return Orientacion{};
}

const char *nombre() {
  switch (seleccionado) {
  case FiltroSoftware::Complementario:
    return "comp";
  case FiltroSoftware::ConMagnetometro:
    return "mag";
  case FiltroSoftware::Kalman:
    return "kalman";
  }
  return "comp";
}
} // namespace Estimador
