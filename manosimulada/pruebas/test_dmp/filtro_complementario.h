#ifndef FILTRO_COMPLEMENTARIO_H
#define FILTRO_COMPLEMENTARIO_H

#include "mpu9250.h"
#include "mag.h"

struct Orientacion {
    float roll;
    float pitch;
    float yaw;
};

// Establece la orientacion inicial usando acelerometro y magnetometro.
void filtro_iniciar(const mpu_datos_t &datos, const mag_datos_t &mag);

// Actualiza roll, pitch y yaw (9-DoF) en radianes. dt en segundos.
Orientacion filtro_actualizar(const mpu_datos_t &datos, const mag_datos_t &mag, float dt);

#endif