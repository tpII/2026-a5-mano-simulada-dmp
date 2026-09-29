#include "i2c.h"
#include "driver/i2c.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_err.h"
#include <stdio.h>

#define I2C_MASTER_SDA_IO 21
#define I2C_MASTER_SCL_IO 22
#define I2C_MASTER_NUM    0       
#define I2C_MASTER_FREQ   100000  
#define MPU9250_ADDR      0x68    

void inicializar_i2c_master(void) {
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
}

int leer_datos_simulados(uint8_t *buffer, size_t longitud) {
    // Dirección del primer registro del acelerómetro (0x3B)
    uint8_t registro_inicio = 0x3B; 

    // Ejecuta la escritura (1 byte) y la lectura (14 bytes) en una única transacción
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
        // Imprimimos el error nativo para saber exactamente por qué falla
        printf("Fallo en i2c_master_write_read_device. Error: %s\n", esp_err_to_name(err));
        return -1;
    }
}