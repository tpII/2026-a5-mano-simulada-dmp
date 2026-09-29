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
        fflush(stdout);
        vTaskDelete(NULL);
        return;
    }

    // 2. Habilitar la opción de Broadcast
    int broadcastEnable = 1;
    setsockopt(sock, SOL_SOCKET, SO_BROADCAST, &broadcastEnable, sizeof(broadcastEnable));

    // 3. AQUÍ ESTÁ LA DECLARACIÓN QUE TE FALTABA
    struct sockaddr_in dest_addr;
    dest_addr.sin_family = AF_INET;
    dest_addr.sin_port = htons(PUERTO_DESTINO);
    dest_addr.sin_addr.s_addr = inet_addr(IP_DESTINO);

    // 4. Buffer para almacenar los 14 bytes crudos del I2C
    uint8_t buffer_datos[14]; 

    printf("Iniciando transmisión UDP I2C a %s:%d a 50Hz...\n", IP_DESTINO, PUERTO_DESTINO);
    fflush(stdout);

    while (1) {
        // 5. Leemos los datos del ESP32 esclavo
        if (leer_datos_simulados(buffer_datos, 14) == 0) {
            // Enviamos el buffer por UDP hacia Arch Linux usando la variable dest_addr
            sendto(sock, buffer_datos, sizeof(buffer_datos), 0, (struct sockaddr *)&dest_addr, sizeof(dest_addr));
        } else {
            printf("Fallo I2C: No se encontraron datos para enviar.\n");
            fflush(stdout);
        }

        // 6. Esperar 20 ms para cumplir con los 50 Hz del sistema
        vTaskDelay(pdMS_TO_TICKS(20));
    }
}

void iniciar_tarea_udp(void) {
    xTaskCreate(tarea_principal, "tarea_principal", 4096, NULL, 5, NULL);
}