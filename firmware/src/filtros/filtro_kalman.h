#pragma once

#include "../tipos.h"

// Kalman de un eje: estima ángulo y sesgo del giroscopio.
class KalmanUnEje {
public:
  // Borra estimación y covarianzas sin cambiar los parámetros de ruido.
  void reiniciar();

  // Predice con el giro y corrige con el ángulo de referencia; dt en segundos.
  float actualizar(float referencia, float giro, float dt);

private:
  float angulo = 0;
  float sesgo = 0;
  float covarianza[2][2] = {};
};

class FiltroKalman {
public:
  // Reinicia los tres ejes tras el arranque o una calibración.
  void reiniciar();

  // Actualiza roll/pitch con acelerómetro y yaw con magnetómetro.
  void actualizar(const DatosInerciales &datos, const Vector3 &campo, float dt);

  // Devuelve los ángulos estimados en radianes.
  Orientacion obtener() const;

private:
  KalmanUnEje filtroRoll;
  KalmanUnEje filtroPitch;
  KalmanUnEje filtroYaw;
  Orientacion orientacion;
};
