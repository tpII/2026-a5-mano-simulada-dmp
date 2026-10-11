#ifndef A5_MPU6050_H
#define A5_MPU6050_H
#ifdef __cplusplus
extern "C" {
#endif
typedef struct {
  float ax,ay,az; // m/s^2
  float gx,gy,gz; // rad/s
  float temperatura; // Celsius, conversion MPU6050
} mpu_datos_t;
int mpu_init(void);
int mpu_leer(mpu_datos_t *datos);
int mpu_habilitar_interrupcion(void);
#ifdef __cplusplus
}
#endif
#endif
