#include <Arduino.h>
#include "i2c.h"
#include "mpu9250.h"
#include "filtro_complementario.h"

// A5: MPU6050 -> DATA_READY -> I2C -> filtro complementario -> USB CSV.
static const uint8_t PIN_INT = 23;
volatile uint32_t eventosPendientes = 0;
volatile uint32_t eventosTotales = 0;
uint32_t muestras = 0 , erroresI2C = 0 , avisosAgrupados = 0;
uint32_t ultimoReporteMs = 0;
uint32_t timestampAnterior = 0;
bool filtroListo = false;

void IRAM_ATTR isrMpu(){
  eventosPendientes++;
  eventosTotales++;
}

void setup(){
  Serial.begin(115200);
  delay(350);
  Serial.println("# A5 - filtro complementario ejecutado en ESP32");
  i2c_init();
  delay(100);
  if (mpu_init() != 0){
    Serial.println("# ERROR MPU init");
    while (true) delay(1000);
  }
  pinMode(PIN_INT , INPUT);
  attachInterrupt(digitalPinToInterrupt(PIN_INT) , isrMpu , RISING);
  if (mpu_habilitar_interrupcion() != 0){
    Serial.println("# ERROR DATA_READY");
    while (true) delay(1000);
  }
  Serial.println("# CSV: t_us,ax,ay,az,gx,gy,gz,roll,pitch,yaw (angulos rad)");
  ultimoReporteMs = millis();
}

void loop(){
  uint32_t pendientes;
  noInterrupts();
  pendientes = eventosPendientes;
  eventosPendientes = 0;
  interrupts();

  if (pendientes > 0){
    if (pendientes > 1) avisosAgrupados += pendientes - 1;
    mpu_datos_t d;
    if (mpu_leer(&d) == 0){
      const uint32_t t = micros(); // timestamp despues de la lectura I2C
      if (!filtroListo){
        filtro_iniciar(d);
        filtroListo = true;
        timestampAnterior = t;
      }
      else{
        float dt = (uint32_t) (t - timestampAnterior) / 1000000.0f;
        timestampAnterior = t;
        // No integramos saltos anormales de tiempo.
        if (dt > 0.0f && dt < 0.2f){
          Orientacion o = filtro_actualizar(d , dt);
          Serial.printf("%lu,%.4f,%.4f,%.4f,%.5f,%.5f,%.5f,%.6f,%.6f,%.6f\n" ,
            (unsigned long) t , d.ax , d.ay , d.az ,
            d.gx , d.gy , d.gz , o.roll , o.pitch , o.yaw);
          muestras++;
        }
      }
    }
    else{
      erroresI2C++;
    }
  }

  if (millis() - ultimoReporteMs >= 5000){
    uint32_t eventos;
    noInterrupts();
    eventos = eventosTotales;
    interrupts();
    Serial.printf("# estado: muestras=%lu erroresI2C=%lu avisosAgrupados=%lu eventosTotales=%lu\n" ,
      (unsigned long) muestras , (unsigned long) erroresI2C ,
      (unsigned long) avisosAgrupados , (unsigned long) eventos);
    ultimoReporteMs = millis();
  }
  delay(1);
}
