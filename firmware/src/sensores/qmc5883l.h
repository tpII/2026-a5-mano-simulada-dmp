#ifndef MAG_H
#define MAG_H

#include <stdint.h>

typedef struct {
    float mx;
    float my;
    float mz;
    int16_t crudo[3];
} mag_datos_t;

int mag_init(void);
enum { MAG_OK = 0, MAG_SIN_MUESTRA = 1, MAG_ERROR_I2C = -1, MAG_SATURADO = -2 };
// estado devuelve DRDY/OVL/DOR. No modifica d si no hay muestra valida.
int mag_leer(mag_datos_t* d, uint8_t* estado = nullptr);

#endif
