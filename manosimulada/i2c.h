#ifndef I2C_H
#define I2C_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

void inicializar_i2c_master(void);
int leer_datos_simulados(uint8_t *buffer, size_t longitud);

#ifdef __cplusplus
}
#endif

#endif