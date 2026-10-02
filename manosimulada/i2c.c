#include "i2c.h"
#include <stdio.h>
#include "esp_err.h"
#include "driver/i2c.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#define I2C_MASTER_SDA_IO 21    
#define I2C_MASTER_SCL_IO 22
#define I2C_MASTER_NUM    0       
#define I2C_MASTER_FREQ   400000    // Fast Mode (400 kHz)
#define MPU9250_ADDR      0x68

static void despertar_mpu9250(void) {
    uint8_t registro_pwr = 0x6B; // Registro PWR_MGMT_1
    uint8_t comando_wake = 0x00; // Escribir 0x00 enciende todos los sensores
    
    uint8_t buffer_escritura[2] = {registro_pwr, comando_wake};
    
    esp_err_t err = i2c_master_write_to_device(
        I2C_MASTER_NUM, MPU9250_ADDR, buffer_escritura, 2, pdMS_TO_TICKS(100)
    );
    
    if (err == ESP_OK) {
        printf("MPU9250 despertado correctamente.\n");
    } else {
        printf("Fallo al despertar MPU9250. Error: %s\n", esp_err_to_name(err));
    }
}

void i2c_init(void) {
    i2c_config_t conf = {
        .mode = I2C_MODE_MASTER,
        .sda_io_num = I2C_MASTER_SDA_IO,
        .scl_io_num = I2C_MASTER_SCL_IO,
        .sda_pullup_en = GPIO_PULLUP_ENABLE, 
        .scl_pullup_en = GPIO_PULLUP_ENABLE,
        .master.clk_speed = I2C_MASTER_FREQ,
    };
    i2c_param_config(I2C_MASTER_NUM, &conf);
    i2c_driver_install(I2C_MASTER_NUM, conf.mode, 0, 0, 0);

    // Damos tiempo al bus para estabilizarse y despertamos el chip
    vTaskDelay(pdMS_TO_TICKS(10));
    despertar_mpu9250();
}

int leer_datos_mpu(uint8_t *buffer, size_t longitud) {
    uint8_t registro_inicio = 0x3B; // Acelerómetro X High

    // Transacción nativa unificada: Sin pausas artificiales
    esp_err_t err = i2c_master_write_read_device(
        I2C_MASTER_NUM, 
        MPU9250_ADDR, 
        &registro_inicio, 1, 
        buffer, longitud, 
        pdMS_TO_TICKS(100)
    );
    
    if (err == ESP_OK) {
        return 0; // Lectura exitosa
    } else {
        printf("Error de lectura I2C: %s\n", esp_err_to_name(err));
        return -1;
    }
}