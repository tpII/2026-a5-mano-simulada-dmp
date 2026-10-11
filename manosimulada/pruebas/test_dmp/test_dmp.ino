#include <Arduino.h>
#include <Wire.h>
#include "I2Cdev.h"
#include "MPU6050_6Axis_MotionApps20.h"

MPU6050 mpu;

// Pines
static const uint8_t PIN_INT = 23;

// Variables de control del DMP
bool dmpListo = false;
uint8_t mpuIntStatus;
uint8_t devStatus;
uint16_t packetSize;
uint16_t fifoCount;
uint8_t fifoBuffer[64];

// Orientación
Quaternion q;           // [w, x, y, z]
VectorFloat gravity;    // [x, y, z] vector de gravedad
float ypr[3];           // [yaw, pitch, roll] en radianes

volatile bool dmpDataReady = false;
void IRAM_ATTR isrDmp() {
    dmpDataReady = true;
}

void setup() {
    Serial.begin(115200);
    delay(500);
    Serial.println("\n=== TEST DE RUTA A: INICIALIZANDO DMP ===");

    Wire.begin(21, 22);
    Wire.setClock(400000); // 400kHz para leer la FIFO rápido

    mpu.initialize();
    pinMode(PIN_INT, INPUT);

    Serial.print("Comprobando conexion con MPU6050... ");
    Serial.println(mpu.testConnection() ? "OK" : "FALLO");

    // Inicializar DMP
    devStatus = mpu.dmpInitialize();

    // Offsets de fábrica o aproximados (se pueden afinar en la calibración)
    mpu.setXAccelOffset(-1000);
    mpu.setYAccelOffset(-1000);
    mpu.setZAccelOffset(1000);
    mpu.setXGyroOffset(0);
    mpu.setYGyroOffset(0);
    mpu.setZGyroOffset(0);

    if (devStatus == 0) {
        // Calibración inicial automática del hardware
        mpu.CalibrateAccel(6);
        mpu.CalibrateGyro(6);
        mpu.setDMPEnabled(true);

        attachInterrupt(digitalPinToInterrupt(PIN_INT), isrDmp, RISING);
        mpuIntStatus = mpu.getIntStatus();
        dmpListo = true;
        packetSize = mpu.dmpGetFIFOPacketSize();
        Serial.println("DMP inicializado con exito.");
    } else {
        Serial.printf("Error al cargar DMP (codigo %d)\n", devStatus);
        while (true) delay(1000);
    }
}

void loop() {
    if (!dmpListo) return;

    // Leemos el paquete cuando se llena la FIFO y hay datos listos
    if (mpu.dmpGetCurrentFIFOPacket(fifoBuffer)) {
        // Extraer cuaternión del paquete FIFO
        mpu.dmpGetQuaternion(&q, fifoBuffer);
        // Extraer vector de gravedad a partir del cuaternión
        mpu.dmpGetGravity(&gravity, &q);
        // Calcular Yaw, Pitch y Roll
        mpu.dmpGetYawPitchRoll(ypr, &q, &gravity);

        // Imprimir en grados para verificar visualmente
        static uint32_t ultimoPrint = 0;
        if (millis() - ultimoPrint >= 100) { // 10 Hz para lectura cómoda
            ultimoPrint = millis();
            Serial.printf("DMP -> Roll: %+6.1f° | Pitch: %+6.1f° | Yaw: %+6.1f°\n",
                          ypr[2] * 180.0f / M_PI,
                          ypr[1] * 180.0f / M_PI,
                          ypr[0] * 180.0f / M_PI);
        }
    }
}