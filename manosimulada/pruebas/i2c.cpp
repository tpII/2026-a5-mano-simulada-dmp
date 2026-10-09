
#include "i2c.h"
#include <Arduino.h>
#include <Wire.h>

#define I2C_SDA 21
#define I2C_SCL 22
#define I2C_FREQ 100000

void i2c_init(void){
    Wire.begin(I2C_SDA , I2C_SCL);
    Wire.setClock(I2C_FREQ);
}

int i2c_escribir_registro(uint8_t direccion ,
                         uint8_t registro ,
                         uint8_t valor){

    Wire.beginTransmission(direccion);
    Wire.write(registro);
    Wire.write(valor);

    return Wire.endTransmission() == 0 ? 0 : -1;
}

int i2c_leer_registros(uint8_t direccion ,
                       uint8_t registro ,
                       uint8_t* buffer ,
                       size_t longitud){

    if (buffer == nullptr || longitud == 0 ||
        longitud > 32){
        return -1;
    }

    Wire.beginTransmission(direccion);
    Wire.write(registro);

    if (Wire.endTransmission(false) != 0){
        return -1;
    }

    size_t recibidos = Wire.requestFrom(
        direccion , longitud , true
    );

    if (recibidos != longitud){
        return -1;
    }

    for (size_t i = 0; i < longitud; i++){
        buffer[i] = Wire.read();
    }

    return 0;
}
