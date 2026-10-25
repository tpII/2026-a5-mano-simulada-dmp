#ifndef A5_MPU6050_H
#define A5_MPU6050_H
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
typedef struct {
  float ax,ay,az; // m/s^2
  float gx,gy,gz; // rad/s
  float temperatura; // Celsius, conversion MPU6050
  int16_t acelerometro_crudo[3]; // Cuentas originales, antes de aplicar escalas.
  int16_t giroscopio_crudo[3];
} mpu_datos_t;
int mpu_init(void);
enum { MPU_OK = 0, MPU_SIN_MUESTRA = 1, MPU_ERROR_I2C = -1 };
// Solo publica datos cuando INT_STATUS confirma DATA_READY.
int mpu_leer(mpu_datos_t *datos);
int mpu_habilitar_interrupcion(void);
#ifdef __cplusplus
}
#endif
#endif
