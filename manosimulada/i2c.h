#ifndef I2C_H
#define I2C_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

static void despertar_mpu9250(void);
void i2c_init(void);
int leer_datos_mpu(uint8_t *buffer, size_t longitud);

#ifdef __cplusplus
}
#endif

#endif