#include "wifi_ap.h"
#include <string.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_mac.h"
#include "esp_wifi.h"
#include "esp_event.h"
#include "esp_log.h"
#include "nvs_flash.h"
#include "lwip/err.h"
#include "lwip/sys.h"

// Credenciales y configuración del Access Point
#define AP_SSID      "ESP32_Mano_Simulada"
#define AP_PASS      "12345678"
#define AP_MAX_CONN  4
#define AP_CHANNEL   1

static const char *TAG = "wifi_ap";

// Manejador de eventos para detectar cuando la PC se conecta o desconecta
static void wifi_event_handler(void* arg, esp_event_base_t event_base, int32_t event_id, void* event_data) {
    if (event_id == WIFI_EVENT_AP_STACONNECTED) {
        wifi_event_ap_staconnected_t* event = (wifi_event_ap_staconnected_t*) event_data;
        printf("PC conectada. MAC: " MACSTR ", AID: %d\n", MAC2STR(event->mac), event->aid);
        fflush(stdout); // Fuerza la impresión en el Monitor Serie
    } else if (event_id == WIFI_EVENT_AP_STADISCONNECTED) {
        wifi_event_ap_stadisconnected_t* event = (wifi_event_ap_stadisconnected_t*) event_data;
        printf("PC desconectada. MAC: " MACSTR ", AID: %d\n", MAC2STR(event->mac), event->aid);
        fflush(stdout); // Fuerza la impresión en el Monitor Serie
    }
}

void inicializar_wifi_ap(void) {
    // 1. Inicializar NVS (Requisito estricto de ESP-IDF para guardar configuraciones base)
    esp_err_t ret = nvs_flash_init();
    if (ret == ESP_ERR_NVS_NO_FREE_PAGES || ret == ESP_ERR_NVS_NEW_VERSION_FOUND) {
        nvs_flash_erase();
        nvs_flash_init();
    }

    // 2. Inicializar la interfaz de red y el bucle de eventos subyacente
    esp_netif_init();
    esp_event_loop_create_default();
    esp_netif_create_default_wifi_ap();

    // 3. Inicializar el controlador Wi-Fi con la configuración por defecto
    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    esp_wifi_init(&cfg);

    // Registrar el manejador para observar el estado de la conexión
    esp_event_handler_instance_register(WIFI_EVENT, ESP_EVENT_ANY_ID, &wifi_event_handler, NULL, NULL);

    // 4. Configurar los parámetros de la red que va a emitir el ESP32
    wifi_config_t wifi_config = {
        .ap = {
            .ssid = AP_SSID,
            .ssid_len = strlen(AP_SSID),
            .channel = AP_CHANNEL,
            .password = AP_PASS,
            .max_connection = AP_MAX_CONN,
            .authmode = WIFI_AUTH_WPA2_PSK // Seguridad WPA2
        },
    };

    // 5. Aplicar configuración e iniciar
    esp_wifi_set_mode(WIFI_MODE_AP);
    esp_wifi_set_config(WIFI_IF_AP, &wifi_config);
    esp_wifi_start();

    printf("Access Point iniciado exitosamente. SSID:%s Password:%s", AP_SSID, AP_PASS);
    fflush(stdout); // Fuerza la impresión en el Monitor Serie
}