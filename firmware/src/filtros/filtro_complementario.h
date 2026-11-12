#pragma once

#include "../tipos.h"

// Mantiene las estimaciones complementarias con y sin corrección magnética.
class FiltroComplementario {
public:
  // Parte de la inclinación medida y del rumbo magnético inicial.
  void iniciar(const Vector3 &aceleracion, const Vector3 &campo);

  // Fusiona aceleración y giro; mantiene ambos yaw en paralelo.
  void actualizar(const DatosInerciales &datos, const Vector3 &campo, float dt);

  // Elige el yaw integrado o el corregido con magnetómetro.
  Orientacion obtener(bool usarMagnetometro) const;

private:
  float roll = 0;
  float pitch = 0;
  float yawGiroscopio = 0;
  float yawMagnetometro = 0;
};
