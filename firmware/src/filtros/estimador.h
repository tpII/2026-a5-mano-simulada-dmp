#pragma once

#include "../tipos.h"

namespace Estimador {
// Borra el estado de los filtros; conserva el algoritmo seleccionado.
void reiniciar();

// Actualiza todas las rutas; devuelve false al inicializar o ante un dt inválido.
bool actualizar(const DatosInerciales &datos, const Vector3 &campo, float dt);

// Cambia qué estimación por software se publica, sin reiniciar las demás.
void seleccionar(FiltroSoftware filtro);

// Devuelve la orientación de la ruta seleccionada.
Orientacion obtener();

// Devuelve comp, mag o kalman, identificadores usados por la web.
const char *nombre();
} // namespace Estimador
