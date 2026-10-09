#ifndef FILTRO_COMPLEMENTARIO_H
#define FILTRO_COMPLEMENTARIO_H

#include "mpu9250.h"

struct Orientacion {
    float roll;
    float pitch;
    float yaw;
};

// Establece la orientacion inicial usando la gravedad.
void filtro_iniciar(const mpu_datos_t &datos);

// Actualiza roll, pitch y yaw. dt se expresa en segundos.
// Los angulos devueltos estan en radianes.
Orientacion filtro_actualizar(const mpu_datos_t &datos, float dt);

#endif
