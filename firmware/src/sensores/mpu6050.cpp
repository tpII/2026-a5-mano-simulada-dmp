#include "mpu6050.h"
#include "i2c.h"
#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
#include <Arduino.h>
#define MPU_ADDR 0x68
#define WHO_AM_I 0x75
#define PWR_MGMT_1 0x6B
#define SMPLRT_DIV 0x19
#define CONFIG 0x1A
#define GYRO_CONFIG 0x1B
#define ACCEL_CONFIG 0x1C
#define INT_PIN_CFG 0x37
#define INT_ENABLE 0x38
#define ACCEL_XOUT_H 0x3B
#define G 9.80665f
#define PI_F 3.14159265358979323846f
static uint8_t mpu_id = 0;
static int configurar(uint8_t registro, uint8_t valor) {
  uint8_t leido = 0;
  if (i2c_escribir_registro(MPU_ADDR, registro, valor) != 0 ||
      i2c_leer_registros(MPU_ADDR, registro, &leido, 1) != 0 || leido != valor) {
    Serial.printf("# ERROR MPU registro=0x%02X esperado=0x%02X leido=0x%02X\n", registro, valor, leido);
    return -1;
  }
  return 0;
}
static int16_t a16(uint8_t h , uint8_t l){ uint16_t u = ((uint16_t) h << 8) | l; return (int16_t) u; }


int mpu_init(void){
  mpu_id = 0;
  uint8_t id = 0;
  if (i2c_leer_registros(MPU_ADDR , WHO_AM_I , &id , 1) != 0)return -1;
  Serial.printf("# MPU WHO_AM_I=0x%02X (esperado 0x68)\n", id);
  if (id != 0x68){ Serial.printf("# ERROR: se requiere MPU6050 (id 0x68).\n"); return -1; }
  if (configurar(INT_ENABLE, 0x00) != 0)return -1;
  if (configurar(0x6A, 0x00) != 0)return -1; // DMP/FIFO/master auxiliar desactivados.
  if (configurar(0x23, 0x00) != 0)return -1;
  if (configurar(PWR_MGMT_1, 0x01) != 0)return -1;
  delay(100);
  if (configurar(0x6C, 0x00) != 0)return -1;
  // 1 kHz / (1 + 19) = 50 Hz (con DLPF activado).
  if (configurar(SMPLRT_DIV, 19) != 0)return -1;
  if (configurar(CONFIG, 0x04) != 0)return -1;
  if (configurar(GYRO_CONFIG, 0x00) != 0)return -1;
  if (configurar(ACCEL_CONFIG, 0x00) != 0)return -1;
  mpu_id = id;
  Serial.printf("# MPU registros verificados: DIV=19 CONFIG=0x04 +/-2g +/-250dps; 50 Hz nominales\n");
  return 0;
}

int mpu_habilitar_interrupcion(void){
  if (!mpu_id)return -1;
  // Activo alto, push-pull y enclavado hasta leer INT_STATUS.
  if (configurar(INT_PIN_CFG, 0x20) != 0)return -1;
  uint8_t estado = 0;
  if (i2c_leer_registros(MPU_ADDR, 0x3A, &estado, 1) != 0)return -1;
  if (configurar(INT_ENABLE, 0x01) != 0)return -1;
  Serial.printf("# MPU INT_PIN_CFG=0x20 INT_ENABLE=0x01; DATA_READY se confirma por INT_STATUS\n");
  return 0;
}
int mpu_leer(mpu_datos_t* d){
  if (!d || !mpu_id)return -1;
  // Leer estado y las 14 mediciones en una misma transaccion. Un flanco en
  // el GPIO no garantiza datos nuevos (cable flotante, ruido o pin equivocado).
  uint8_t bloque[15];
  if (i2c_leer_registros(MPU_ADDR, 0x3A, bloque, sizeof(bloque)) != 0)return MPU_ERROR_I2C;
  if (!(bloque[0] & 0x01))return MPU_SIN_MUESTRA;
  const uint8_t* b = bloque + 1;
  for (int eje = 0; eje < 3; eje++) {
    d->acelerometro_crudo[eje] = a16(b[2*eje], b[2*eje+1]);
    d->giroscopio_crudo[eje] = a16(b[8+2*eje], b[9+2*eje]);
  }
  d->ax = (a16(b[0] , b[1]) / 16384.0f) * G;
  d->ay = (a16(b[2] , b[3]) / 16384.0f) * G;
  d->az = (a16(b[4] , b[5]) / 16384.0f) * G;
  d->temperatura = a16(b[6] , b[7]) / 340.0f + 36.53f;
  const float conv = (PI_F / 180.0f) / 131.0f;
  d->gx = a16(b[8] , b[9]) * conv;
  d->gy = a16(b[10] , b[11]) * conv;
  d->gz = a16(b[12] , b[13]) * conv;
  return 0;
}
