#include "accesspoint.h"
#include "transmision.h"
#include "i2c.h"

void setup() {
    Serial.begin(115200); // Inicia la comunicación serial
    delay(2000);          // Breve pausa para asegurar que la consola conecte antes de lanzar los logs

    access_point_init();
    i2c_init();

    // Le damos un par de segundos al ESP32 para que establezca la red antes de enviar datos
    delay(2000); 
    iniciar_tarea_udp();
}

void loop() {
}