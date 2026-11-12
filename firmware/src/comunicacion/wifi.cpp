#include "wifi.h"

#include "../configuracion.h"
#include <Arduino.h>
#include <WiFi.h>

namespace RedWifi {
void iniciarRedPropia() {
  WiFi.persistent(false);
  WiFi.mode(WIFI_AP);
  WiFi.softAP(Configuracion::NOMBRE_RED, Configuracion::CLAVE_RED);
  WiFi.setSleep(false);
  Serial.print("Red Wi-Fi: ");
  Serial.print(Configuracion::NOMBRE_RED);
  Serial.print("   IP: ");
  Serial.println(WiFi.softAPIP());
  Serial.printf("WebSocket en ws://%s:%u\n", WiFi.softAPIP().toString().c_str(),
                Configuracion::PUERTO_WEBSOCKET);
}
} // namespace RedWifi

// MODO ESTACIÓN CONSERVADO Y DESACTIVADO.
// Para habilitarlo: descomentar el bloque de código y su declaración en wifi.h;
// en setup(), sustituir iniciarRedPropia() por iniciarConRouter().
// La red ManoDMP se mantiene como respaldo. Las credenciales van en secretos.h.
/*
#include <ESPmDNS.h>
#if __has_include("../../secretos.h")
#include "../../secretos.h"
#endif
#ifndef RED_SSID
#define RED_SSID ""
#define RED_CLAVE ""
#endif

namespace RedWifi {
// Conecta al router con un plazo limitado, conservando la red propia del ESP32.
void iniciarConRouter() {
  const bool usarRed = strlen(RED_SSID) > 0;
  WiFi.mode(usarRed ? WIFI_AP_STA : WIFI_AP);
  WiFi.softAP(Configuracion::NOMBRE_RED, Configuracion::CLAVE_RED);
  if (usarRed) {
    IPAddress direccion(192, 168, 0, 11);
    IPAddress puertaDeEnlace(192, 168, 0, 1);
    IPAddress mascara(255, 255, 255, 0);
    if (!WiFi.config(direccion, puertaDeEnlace, mascara)) {
      Serial.println("Error al configurar IP estatica");
    }
    WiFi.begin(RED_SSID, RED_CLAVE);
    const uint32_t inicio = millis();
    while (WiFi.status() != WL_CONNECTED && millis() - inicio < 10000) {
      delay(250);
      Serial.print('.');
    }
    Serial.println();
  }
  WiFi.setSleep(false);
  Serial.print("Red de respaldo: ");
  Serial.println(WiFi.softAPIP());
  if (usarRed && WiFi.status() == WL_CONNECTED) {
    Serial.print("IP en el router: ");
    Serial.println(WiFi.localIP());
    if (MDNS.begin("manodmp")) {
      MDNS.addService("ws", "tcp", Configuracion::PUERTO_WEBSOCKET);
      Serial.printf("WebSocket en ws://manodmp.local:%u\n", Configuracion::PUERTO_WEBSOCKET);
    }
  } else if (usarRed) {
    Serial.println("No se pudo conectar al router; queda activa la red ManoDMP.");
  }
}
}
*/
