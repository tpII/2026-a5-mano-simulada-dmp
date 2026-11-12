#pragma once

#include "../tipos.h"
#include <stdint.h>

// Acumula extremos sin modificar los ajustes vigentes hasta validar los tres ejes.
class CalibracionMagnetometro {
public:
  // Reinicia la ventana de medición usando el reloj recibido en milisegundos.
  void iniciar(uint32_t ahora);

  // Incorpora una lectura cruda a los mínimos y máximos por eje.
  void agregar(const Vector3 &campo);

  // Comprueba el plazo, incluyendo el desbordamiento del contador millis().
  bool vencida(uint32_t ahora) const;

  // Actualiza los ajustes solo si hubo recorrido suficiente en los tres ejes.
  bool finalizar(AjustesMagnetometro &ajustes) const;

private:
  uint32_t inicio = 0;
  float minimo[3] = {};
  float maximo[3] = {};
};
