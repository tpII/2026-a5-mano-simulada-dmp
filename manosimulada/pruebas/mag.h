#ifndef MAG_H
#define MAG_H

#include <stdint.h>

typedef struct {
    float mx;
    float my;
    float mz;
} mag_datos_t;

int mag_init(void);
int mag_leer(mag_datos_t* d);

#endif