
#ifndef I2C_H
#define I2C_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

    // Inicializar bus I2C
    void i2c_init(void);

    // Escribir un registro
    int i2c_escribir_registro(uint8_t direccion , uint8_t registro , uint8_t valor);

    // Leer uno o varios registros consecutivos
    int i2c_leer_registros(uint8_t direccion , uint8_t registro , uint8_t* buffer , size_t longitud);

#ifdef __cplusplus
}
#endif

#endif


/* #ifndef I2C_H
#define I2C_H

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

    static void despertar_mpu9250(void);
    void i2c_init(void);
    int leer_datos_mpu(uint8_t* buffer , size_t longitud);

#ifdef __cplusplus
}
#endif

#endif

 */