#include "websocket.h"

#include "../configuracion.h"
#include <Arduino.h>
#include <WebSocketsServer.h>
#include <string.h>

namespace {
WebSocketsServer servidor(Configuracion::PUERTO_WEBSOCKET);
Comunicacion::RecibirComando recibirComando = nullptr;
bool transmitiendo = true;
uint32_t numeroMuestra = 0;

// Traduce los eventos de red a comandos, sin acceder a sensores ni filtros.
void recibirEvento(uint8_t cliente, WStype_t tipo, uint8_t *datos, size_t cantidad) {
  switch (tipo) {
  case WStype_CONNECTED:
    Serial.printf("Cliente %u conectado\n", cliente);
    break;
  case WStype_DISCONNECTED:
    Serial.printf("Cliente %u desconectado\n", cliente);
    break;
  case WStype_TEXT: {
    char texto[80];
    const size_t longitud = cantidad < sizeof(texto) - 1 ? cantidad : sizeof(texto) - 1;
    memcpy(texto, datos, longitud);
    texto[longitud] = 0;
    if (recibirComando)
      recibirComando(Protocolo::interpretar(texto));
    break;
  }
  default:
    break;
  }
}
} // namespace

namespace Comunicacion {
void iniciar(RecibirComando destinatario) {
  recibirComando = destinatario;
  servidor.begin();
  servidor.onEvent(recibirEvento);
}

void atender() {
  servidor.loop();
}

void transmitir(bool habilitar) {
  transmitiendo = habilitar;
}

void enviarMuestra(const Cuaternion &dmp, const Cuaternion &software, const char *filtro) {
  if (!transmitiendo || servidor.connectedClients() == 0)
    return;
  char mensaje[200];
  const size_t longitud = Protocolo::muestra(mensaje, sizeof(mensaje), numeroMuestra++, millis(),
                                             filtro, dmp, software);
  if (longitud)
    servidor.broadcastTXT(mensaje, longitud);
}

void enviarError(const char *mensaje) {
  char datos[96];
  const size_t longitud = Protocolo::error(datos, sizeof(datos), mensaje);
  if (longitud)
    servidor.broadcastTXT(datos, longitud);
}

void enviarCalibracion(const char *sensor, const char *estado, const char *mensaje) {
  char datos[256];
  const size_t longitud = Protocolo::calibracion(datos, sizeof(datos), sensor, estado, mensaje);
  if (longitud)
    servidor.broadcastTXT(datos, longitud);
}
} // namespace Comunicacion
