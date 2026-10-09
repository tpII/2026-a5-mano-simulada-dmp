#include "mpu9250.h"
#include "i2c.h"
#include <stdint.h>
#include <stddef.h>
#include <stdio.h>
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
static int16_t a16(uint8_t h , uint8_t l){ uint16_t u = ((uint16_t) h << 8) | l; return (int16_t) u; }


int mpu_init(void){
  uint8_t id = 0;
  if (i2c_leer_registros(MPU_ADDR , WHO_AM_I , &id , 1) != 0)return -1;
  printf("WHO_AM_I: 0x%02X\n" , id);
  // Esta version esta validada solo con MPU6050. MPU9250 requiere validar su configuracion.
  if (id != 0x68){ printf("Esta version requiere MPU6050 (id 0x68).\n"); return -1; }
  mpu_id = id;
  if (i2c_escribir_registro(MPU_ADDR , PWR_MGMT_1 , 0x01) != 0)return -1;
  // 1 kHz / (1 + 19) = 50 Hz (con DLPF activado).
  if (i2c_escribir_registro(MPU_ADDR , SMPLRT_DIV , 19) != 0)return -1;
  if (i2c_escribir_registro(MPU_ADDR , CONFIG , 0x04) != 0)return -1;
  if (i2c_escribir_registro(MPU_ADDR , GYRO_CONFIG , 0x00) != 0)return -1;
  if (i2c_escribir_registro(MPU_ADDR , ACCEL_CONFIG , 0x00) != 0)return -1;
  printf("MPU6050 configurado (+/-2g, +/-250deg/s, DLPF 21Hz, 50Hz nominal).\n");
  return 0;
}

int mpu_habilitar_interrupcion(void){
  if (!mpu_id)return -1;
  if (i2c_escribir_registro(MPU_ADDR , INT_PIN_CFG , 0x00) != 0)return -1;
  return i2c_escribir_registro(MPU_ADDR , INT_ENABLE , 0x01);
}
int mpu_leer(mpu_datos_t* d){
  if (!d || !mpu_id)return -1;
  uint8_t b[14];
  if (i2c_leer_registros(MPU_ADDR , ACCEL_XOUT_H , b , sizeof(b)) != 0)return -1;
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
