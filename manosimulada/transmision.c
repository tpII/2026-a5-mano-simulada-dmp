#include "transmision.h"
#include "i2c.h"
#include <string.h>
#include <stdio.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "lwip/sockets.h"
#include "lwip/netdb.h"

#define PUERTO_DESTINO 12345
#define IP_DESTINO "192.168.4.255"

static void tarea_principal(void *pvParameters) {
    // 1. Crear el socket UDP
    int sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_IP);
    if (sock < 0) {
        printf("Error al crear el socket UDP\n");
        vTaskDelete(NULL);
        return;
    }

    int broadcastEnable = 1;
    setsockopt(sock, SOL_SOCKET, SO_BROADCAST, &broadcastEnable, sizeof(broadcastEnable));

    struct sockaddr_in dest_addr;
    dest_addr.sin_family = AF_INET;
    dest_addr.sin_port = htons(PUERTO_DESTINO);
    dest_addr.sin_addr.s_addr = inet_addr(IP_DESTINO);

    printf("Iniciando transmisión UDP I2C a %s:%d a 50Hz...\n", IP_DESTINO, PUERTO_DESTINO);

    // 2. Bucle principal a 50 Hz
    while (1) {
        uint8_t buffer_datos[14];

        if (leer_datos_mpu(buffer_datos, 14) == 0) { 
            // Reconstruir Acelerómetro
            int16_t accel_x = (buffer_datos[0] << 8) | buffer_datos[1];
            int16_t accel_y = (buffer_datos[2] << 8) | buffer_datos[3];
            int16_t accel_z = (buffer_datos[4] << 8) | buffer_datos[5];
            
            // Reconstruir Giroscopio
            int16_t gyro_x = (buffer_datos[8] << 8) | buffer_datos[9];
            int16_t gyro_y = (buffer_datos[10] << 8) | buffer_datos[11];
            int16_t gyro_z = (buffer_datos[12] << 8) | buffer_datos[13];

            // Imprimir en consola para depuración
            printf("Accel: %d, %d, %d | Gyro: %d, %d, %d\n", 
                accel_x, accel_y, accel_z, gyro_x, gyro_y, gyro_z);
            
            // 3. Empaquetado binario ligero y envío por UDP[cite: 4]
            int16_t paquete_datos[6] = {accel_x, accel_y, accel_z, gyro_x, gyro_y, gyro_z};
            sendto(sock, paquete_datos, sizeof(paquete_datos), 0, 
                   (struct sockaddr *)&dest_addr, sizeof(dest_addr));
        }

        // 4. Esperar 20 ms para cumplir estrictamente con los 50 Hz del sistema[cite: 4]
        vTaskDelay(pdMS_TO_TICKS(20));
    }
}

void iniciar_tarea_udp(void) {
    xTaskCreate(tarea_principal, "tarea_principal", 4096, NULL, 5, NULL);
}