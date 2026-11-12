#pragma once

#include "protocolo.h"

namespace Comunicacion {
using RecibirComando = void (*)(const Protocolo::Comando &comando);

// Abre el servidor WebSocket y registra el destinatario de sus comandos.
void iniciar(RecibirComando destinatario);

// Atiende conexiones y mensajes; llamar en cada vuelta del loop().
void atender();

// Habilita o detiene la transmisión sin detener la adquisición ni los filtros.
void transmitir(bool habilitar);

// Publica ambas orientaciones si hay clientes y la transmisión está habilitada.
void enviarMuestra(const Cuaternion &dmp, const Cuaternion &software, const char *filtro);

// Informa un error aunque la transmisión de muestras esté detenida.
void enviarError(const char *mensaje);

// Publica inicio, finalización o error de calibración independientemente del ensayo.
void enviarCalibracion(const char *sensor, const char *estado, const char *mensaje);
} // namespace Comunicacion
