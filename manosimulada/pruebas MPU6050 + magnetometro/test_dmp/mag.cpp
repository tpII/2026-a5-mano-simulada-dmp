#include "mag.h"
#include "i2c.h"
#include <Arduino.h>

static uint8_t mag_addr = 0; // Se detecta automáticamente en el init
static bool es_qmc = false;

int mag_init(void) {
    uint8_t test = 0;
    
    // 1. Probar si responde en 0x0D (QMC5883L)
    if (i2c_leer_registros(0x0D, 0x06, &test, 1) == 0) {
        mag_addr = 0x0D;
        es_qmc = true;
        
        // Reset por software
        i2c_escribir_registro(mag_addr, 0x0A, 0x80);
        delay(10);
        // Periodo de set/reset recomendado
        i2c_escribir_registro(mag_addr, 0x0B, 0x01);
        // 50Hz, +/-8G, OSR=512, Continuous Mode -> 0x1D
        i2c_escribir_registro(mag_addr, 0x09, 0x1D);
        Serial.println("Magnetometro QMC5883L inicializado (0x0D).");
        return 0;
    }
    
    // 2. Probar si responde en 0x1E (HMC5883L)
    if (i2c_leer_registros(0x1E, 0x0A, &test, 1) == 0) {
        mag_addr = 0x1E;
        es_qmc = false;
        
        // Config A: 8 muestras promedio, 75Hz -> 0x78
        i2c_escribir_registro(mag_addr, 0x00, 0x78);
        // Config B: Ganancia +/- 1.3 Gauss -> 0x20
        i2c_escribir_registro(mag_addr, 0x01, 0x20);
        // Modo continuo -> 0x00
        i2c_escribir_registro(mag_addr, 0x02, 0x00);
        Serial.println("Magnetometro HMC5883L inicializado (0x1E).");
        return 0;
    }

    Serial.println("ERROR: No se detecto magnetometro (ni 0x0D ni 0x1E).");
    return -1;
}

int mag_leer(mag_datos_t* d) {
    if (!d || mag_addr == 0) return -1;
    uint8_t b[6];

    if (es_qmc) {
        // QMC5883L: registros 0x00..0x05, Little-Endian, orden X, Y, Z
        if (i2c_leer_registros(mag_addr, 0x00, b, 6) != 0) return -1;
        int16_t x = (int16_t)((b[1] << 8) | b[0]);
        int16_t y = (int16_t)((b[3] << 8) | b[2]);
        int16_t z = (int16_t)((b[5] << 8) | b[4]);
        d->mx = (float)x;
        d->my = (float)y;
        d->mz = (float)z;
    } else {
        // HMC5883L: registros 0x03..0x08, Big-Endian, orden X, Z, Y
        if (i2c_leer_registros(mag_addr, 0x03, b, 6) != 0) return -1;
        int16_t x = (int16_t)((b[0] << 8) | b[1]);
        int16_t z = (int16_t)((b[2] << 8) | b[3]);
        int16_t y = (int16_t)((b[4] << 8) | b[5]);
        d->mx = (float)x;
        d->my = (float)y;
        d->mz = (float)z;
    }
    return 0;
}