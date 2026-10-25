#include <Arduino.h>
#include <math.h>
#include <esp_timer.h>
#include <esp_random.h>
#include "src/sensores/i2c.h"
#include "src/sensores/mpu6050.h"
#include "src/sensores/qmc5883l.h"
#include "src/filtros/filtro_complementario.h"
#include "src/comunicacion/telemetria.h"

// El GPIO despierta la lectura; INT_STATUS confirma DATA_READY.
static const uint8_t PIN_INT = 23;
static const bool EMITIR_JSON = true; // Contrato v1, NDJSON por USB.
static const bool EMITIR_CSV = false; // Solo diagnostico antiguo: desactivar JSON antes.
static_assert(!(EMITIR_JSON&& EMITIR_CSV) , "Seleccionar un solo formato de datos");
static const uint32_t BAUDIOS = EMITIR_JSON ? 460800 : 115200;
static const bool USAR_FILTRO = true; // false: diagnostico de sensores sin fusion.
static const uint32_t EDAD_MAG_MAX_US = 100000;
static portMUX_TYPE cerrojo = portMUX_INITIALIZER_UNLOCKED;
static volatile uint32_t pendientes = 0 , secuencia = 0 , ultimoIrqUs = 0;
static volatile uint32_t irqVentana = 0 , dtMinUs = UINT32_MAX , dtMaxUs = 0 , nIntervalos = 0;
static volatile uint64_t sumaIntervalosUs = 0;
static volatile bool primerIrq = true;

struct Contadores{
    uint32_t mpu = 0 , mag = 0 , csv = 0 , agrupadas = 0 , sinDrdy = 0;
    uint32_t json = 0 , descartesTx = 0 , erroresFormato = 0;
    uint32_t errorMpu = 0 , errorMag = 0 , saturadas = 0 , dor = 0 , saltos = 0;
    uint32_t latenciaMaxUs = 0 , lecturaMaxUs = 0;
    uint32_t intervaloMinUs = UINT32_MAX , intervaloMaxUs = 0 , intervalos = 0;
    uint64_t sumaIntervalosUs = 0;
};
static Contadores cuenta;
static uint32_t inicioVentanaUs = 0 , anteriorMpuUs = 0 , ultimoMagUs = 0 , sondeoMagUs = 0;
static bool filtroListo = false , hayMag = false , magPendiente = false;
static mag_datos_t magnetico = {};
static Orientacion orientacion = {};
static char sesion[17] = {};
static uint32_t numeroMuestra = 0; // Muestras validas, nunca flancos GPIO.
static uint64_t tiempoMagUs = 0;

void IRAM_ATTR isrMpu(){
    const uint32_t t = micros();
    portENTER_CRITICAL_ISR(&cerrojo);
    if (!primerIrq){
        const uint32_t dt = t - ultimoIrqUs;
        if (dt < dtMinUs) dtMinUs = dt;
        if (dt > dtMaxUs) dtMaxUs = dt;
        sumaIntervalosUs += dt;
        nIntervalos++;
    }
    primerIrq = false;
    ultimoIrqUs = t;
    secuencia++;
    pendientes++;
    irqVentana++;
    portEXIT_CRITICAL_ISR(&cerrojo);
}

static void detener(const char* mensaje){
    Serial.println(mensaje);
    while (true) delay(1000);
}

void setup(){
    // Encolar los resúmenes evita esperar su transmision (~30 ms a 115200).
    // Debe configurarse antes de begin() en ESP32 Arduino.
    const size_t capacidadTx = Serial.setTxBufferSize(2048);
    Serial.begin(BAUDIOS);
    delay(350);
    Serial.println("# A5 diagnostico adquisicion MPU6050 + QMC5883L");
    Serial.printf("# UART TX buffer=%u bytes; %lu baudios\n" , (unsigned) capacidadTx , (unsigned long) BAUDIOS);
    snprintf(sesion , sizeof(sesion) , "%08lx%08lx" , (unsigned long) esp_random() , (unsigned long) esp_random());
    Serial.printf("# telemetria version=1 sesion=%s formato=%s\n" , sesion , EMITIR_JSON ? "ndjson" : "diagnostico");
    Serial.println("# AVISO calibracion provisional: bias fijo y offsets magneticos cero; no valida orientacion");
    i2c_init();
    delay(100);
    if (mpu_init() != 0) detener("# ERROR inicializacion MPU; revisar WHO_AM_I, cableado y registros");
    if (mag_init() != 0) detener("# ERROR inicializacion QMC; revisar direccion 0x0D, cableado y registros");
    if (EMITIR_CSV) Serial.println("# CSV: t_us,ax,ay,az,gx,gy,gz,roll,pitch,yaw,mx,my,mz,secuencia,mag_nuevo,mag_valido,edad_mag_us");
    Serial.println("# Unidades: us,m/s2,rad/s,rad,LSB; nan=sin dato valido; edad=-1=sin muestra");
    Serial.printf("# modo JSON=%u CSV=%u filtro=%u; JSON tiempo_us=64 bits; numero=muestras; CSV secuencia=IRQ crudas\n" ,
                  EMITIR_JSON , EMITIR_CSV , USAR_FILTRO);
    pinMode(PIN_INT , INPUT_PULLDOWN); // Evitar entrada flotante si falta el cable INT.
    attachInterrupt(digitalPinToInterrupt(PIN_INT) , isrMpu , RISING);
    inicioVentanaUs = micros();
    if (mpu_habilitar_interrupcion() != 0) detener("# ERROR habilitando DATA_READY");
}

static void sondearMagnetometro(){
    const uint32_t ahora = micros();
    if ((uint32_t) (ahora - sondeoMagUs) < 2000) return;
    sondeoMagUs = ahora;
    mag_datos_t nueva = {};
    uint8_t estado = 0;
    const int resultado = mag_leer(&nueva , &estado);
    if (estado & 0x04) cuenta.dor++; // Indica al menos una perdida, no cuantas.
    if (resultado == MAG_OK){
        magnetico = nueva;
        ultimoMagUs = micros();
        tiempoMagUs = (uint64_t) esp_timer_get_time();
        hayMag = true;
        magPendiente = true;
        cuenta.mag++;
    }
    else if (resultado == MAG_ERROR_I2C || resultado == MAG_SATURADO){
        if (resultado == MAG_ERROR_I2C) cuenta.errorMag++;
        else cuenta.saturadas++;
        hayMag = false;
        magPendiente = false;
    }
}

static void adquirirMpu(){
    uint32_t eventos , t , numero;
    portENTER_CRITICAL(&cerrojo);
    eventos = pendientes;
    pendientes = 0;
    t = ultimoIrqUs;
    numero = secuencia;
    portEXIT_CRITICAL(&cerrojo);
    if (!eventos) return;
    cuenta.agrupadas += eventos - 1; // Flancos agrupados no equivalen a muestras perdidas.
    const uint64_t tiempoLecturaUs = (uint64_t) esp_timer_get_time();
    const uint32_t comienzo = (uint32_t) tiempoLecturaUs;
    const uint32_t latencia = comienzo - t;
    if (latencia > cuenta.latenciaMaxUs) cuenta.latenciaMaxUs = latencia;
    mpu_datos_t d = {};
    const int resultado = mpu_leer(&d);
    const uint32_t duracion = micros() - comienzo;
    if (duracion > cuenta.lecturaMaxUs) cuenta.lecturaMaxUs = duracion;
    if (resultado == MPU_SIN_MUESTRA){ cuenta.sinDrdy++; return; }
    if (resultado != MPU_OK){ cuenta.errorMpu++; return; }
    // La rafaga conserva mediciones coherentes. No descartar por nuevos
    // flancos GPIO: el registro, no esos flancos, valida la muestra.
    t = comienzo;
    if (filtroListo || anteriorMpuUs != 0){
        const uint32_t dt = t - anteriorMpuUs;
        if (dt < cuenta.intervaloMinUs) cuenta.intervaloMinUs = dt;
        if (dt > cuenta.intervaloMaxUs) cuenta.intervaloMaxUs = dt;
        cuenta.sumaIntervalosUs += dt;
        cuenta.intervalos++;
    }
    cuenta.mpu++;
    const uint32_t muestraActual = numeroMuestra++;
    const uint32_t edad = micros() - ultimoMagUs;
    const bool valido = hayMag && edad <= EDAD_MAG_MAX_US;
    const bool nuevo = valido && magPendiente;
    if (USAR_FILTRO){
        if (!filtroListo){
            filtro_iniciar(d , magnetico , valido);
            filtroListo = true;
            // Obtener el estado inicial por la misma API, sin integrar tiempo.
            orientacion = filtro_actualizar(d , magnetico , 0.0f , false);
        }
        else{
            const float dt = (uint32_t) (t - anteriorMpuUs) / 1000000.0f;
            if (dt > 0.0f && dt < 0.2f)
                orientacion = filtro_actualizar(d , magnetico , dt , nuevo);
            else{
                cuenta.saltos++;
                filtro_iniciar(d , magnetico , valido);
                orientacion = filtro_actualizar(d , magnetico , 0.0f , false);
            }
        }
    }
    else orientacion = {NAN, NAN, NAN};
    anteriorMpuUs = t;
    magPendiente = false;
    if (EMITIR_JSON){
        MuestraTelemetria mensaje;
        mensaje.sesion = sesion; mensaje.numero = muestraActual; mensaje.tiempo_us = tiempoLecturaUs;
        mensaje.mpu = d; mensaje.mag = magnetico; mensaje.tiempo_mag_us = tiempoMagUs;
        mensaje.mag_valido = valido; mensaje.mag_nuevo = nuevo;
        mensaje.software.valida = USAR_FILTRO && telemetria_cuaternion(orientacion , mensaje.software.cuaternion);
        mensaje.software.tiempo_us = tiempoLecturaUs;
        mensaje.filtro_activo = USAR_FILTRO;
        // DMP no integrado: ruta ausente, no se inventa una segunda orientacion.
        char linea[1536]; size_t longitud = 0;
        if (!telemetria_codificar(mensaje , linea , sizeof(linea) , &longitud)) cuenta.erroresFormato++;
        else if (Serial.availableForWrite() < (int) longitud) cuenta.descartesTx++;
        else{ Serial.write((const uint8_t*) linea , longitud); cuenta.json++; }
    }
    if (EMITIR_CSV){
        Serial.printf("%lu,%.4f,%.4f,%.4f,%.5f,%.5f,%.5f,%.6f,%.6f,%.6f,%.1f,%.1f,%.1f,%lu,%u,%u,%ld\n" ,
            (unsigned long) t , d.ax , d.ay , d.az , d.gx , d.gy , d.gz ,
            orientacion.roll , orientacion.pitch , orientacion.yaw ,
            valido ? magnetico.mx : NAN , valido ? magnetico.my : NAN , valido ? magnetico.mz : NAN ,
            (unsigned long) numero , nuevo , valido , hayMag ? (long) edad : -1L);
        cuenta.csv++;
    }
}

static void informar(){
    if ((uint32_t) (micros() - inicioVentanaUs) < 5000000) return;
    uint32_t ahora , eventos , minimo , maximo , intervalos;
    uint64_t suma;
    portENTER_CRITICAL(&cerrojo);
    ahora = micros();
    eventos = irqVentana;
    minimo = dtMinUs;
    maximo = dtMaxUs;
    intervalos = nIntervalos;
    suma = sumaIntervalosUs;
    irqVentana = 0; dtMinUs = UINT32_MAX; dtMaxUs = 0; nIntervalos = 0; sumaIntervalosUs = 0;
    portEXIT_CRITICAL(&cerrojo);
    const float segundos = (uint32_t) (ahora - inicioVentanaUs) / 1000000.0f;
    inicioVentanaUs = ahora;
    Serial.printf("# frecuencia ventana_s=%.3f irq_hz=%.2f mpu_hz=%.2f mag_hz=%.2f csv_hz=%.2f "
                  "dt_irq_us=%.1f/%lu/%lu irq_agrupadas=%lu sin_drdy=%lu error_mpu=%lu error_mag=%lu "
                  "ovl=%lu dor=%lu saltos=%lu latencia_max_us=%lu lectura_mpu_max_us=%lu "
                  "json_hz=%.2f descartes_tx=%lu errores_formato=%lu\n" ,
        segundos , eventos / segundos , cuenta.mpu / segundos , cuenta.mag / segundos , cuenta.csv / segundos ,
        intervalos ? (double) suma / intervalos : 0.0 , (unsigned long) (intervalos ? minimo : 0) ,
        (unsigned long) maximo , (unsigned long) cuenta.agrupadas , (unsigned long) cuenta.sinDrdy ,
        (unsigned long) cuenta.errorMpu , (unsigned long) cuenta.errorMag , (unsigned long) cuenta.saturadas ,
        (unsigned long) cuenta.dor , (unsigned long) cuenta.saltos , (unsigned long) cuenta.latenciaMaxUs ,
        (unsigned long) cuenta.lecturaMaxUs , cuenta.json / segundos ,
        (unsigned long) cuenta.descartesTx , (unsigned long) cuenta.erroresFormato);
    Serial.printf("# muestras_mpu dt_us=%.1f/%lu/%lu (medio/min/max); GPIO es diagnostico, DATA_READY valida las muestras\n" ,
        cuenta.intervalos ? (double) cuenta.sumaIntervalosUs / cuenta.intervalos : 0.0 ,
        (unsigned long) (cuenta.intervalos ? cuenta.intervaloMinUs : 0) ,
        (unsigned long) cuenta.intervaloMaxUs);
    if (eventos > cuenta.mpu * 2 + 5){
        Serial.println("# AVISO exceso de flancos GPIO: revisar INT MPU -> GPIO23 y masa comun; no equivalen a muestras");
    }
    cuenta = {};
}

void loop(){
    // Atender primero el MPU; el QMC tiene reloj propio y se sondea aparte.
    adquirirMpu();
    sondearMagnetometro();
    informar();
    delay(1);
}
