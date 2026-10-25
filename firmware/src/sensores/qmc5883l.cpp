#include "qmc5883l.h"
#include "i2c.h"
#include <Arduino.h>

static const uint8_t DIRECCION = 0x0D;
static bool listo = false;

static int configurar(uint8_t registro, uint8_t valor) {
    uint8_t leido = 0;
    if (i2c_escribir_registro(DIRECCION, registro, valor) != 0 ||
        i2c_leer_registros(DIRECCION, registro, &leido, 1) != 0 || leido != valor) {
        Serial.printf("# ERROR QMC registro=0x%02X esperado=0x%02X leido=0x%02X\n", registro, valor, leido);
        return -1;
    }
    return 0;
}

int mag_init(void) {
    listo = false;
    uint8_t id = 0;
    if (i2c_leer_registros(DIRECCION, 0x0D, &id, 1) != 0) return -1;
    Serial.printf("# QMC direccion=0x0D chip_id=0x%02X; verificar identidad fisica del modulo\n", id);
    if (i2c_escribir_registro(DIRECCION, 0x0A, 0x80) != 0) return -1;
    delay(10); // SOFT_RST se borra automaticamente.
    // OSR=512 (00), rango=8G (01), ODR=50Hz (01), continuo (01).
    if (configurar(0x0B, 0x01) != 0 || configurar(0x09, 0x15) != 0) return -1;
    listo = true;
    Serial.println("# QMC registros verificados: CONTROL1=0x15 SET_RESET=0x01; 50 Hz nominales +/-8G OSR512");
    return 0;
}

int mag_leer(mag_datos_t* d, uint8_t* estado) {
    if (estado) *estado = 0;
    if (!d || !listo) return MAG_ERROR_I2C;
    uint8_t s = 0;
    if (i2c_leer_registros(DIRECCION, 0x06, &s, 1) != 0) return MAG_ERROR_I2C;
    if (estado) *estado = s;
    if (!(s & 0x01)) return MAG_SIN_MUESTRA;
    uint8_t b[6];
    // Leer los seis bytes desbloquea la siguiente muestra, incluso si hay OVL.
    if (i2c_leer_registros(DIRECCION, 0x00, b, sizeof(b)) != 0) return MAG_ERROR_I2C;
    if (s & 0x02) return MAG_SATURADO;
    mag_datos_t muestra = {};
    for (int eje = 0; eje < 3; eje++)
        muestra.crudo[eje] = (int16_t)((uint16_t)b[2*eje+1] << 8 | b[2*eje]);
    muestra.mx = muestra.crudo[0];
    muestra.my = muestra.crudo[1];
    muestra.mz = muestra.crudo[2];
    *d = muestra;
    return MAG_OK;
}
