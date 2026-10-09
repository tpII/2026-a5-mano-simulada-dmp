#include "filtro_complementario.h"
#include <math.h>

// Coeficiente inicial del filtro complementario.
#define ALPHA 0.98f

// Bias del giroscopio medido durante 1500 muestras en reposo (rad/s).
// Recalibrar si cambian el sensor o las condiciones de funcionamiento.
#define BIAS_GX -0.022842f
#define BIAS_GY  0.000215f
#define BIAS_GZ -0.006985f

static Orientacion orientacion = {0.0f, 0.0f, 0.0f};

void filtro_iniciar(const mpu_datos_t &d) {
    orientacion.roll = atan2f(d.ay, d.az);
    orientacion.pitch = atan2f(-d.ax, sqrtf(d.ay * d.ay + d.az * d.az));
    // El MPU6050 no tiene referencia absoluta para yaw.
    orientacion.yaw = 0.0f;
}

Orientacion filtro_actualizar(const mpu_datos_t &d, float dt) {
    // Si el intervalo no es valido, conservar la ultima orientacion.
    if (dt <= 0.0f || !isfinite(dt)) {
        return orientacion;
    }

    // 1. Corregir el offset del giroscopio (rad/s).
    const float gx = d.gx - BIAS_GX;
    const float gy = d.gy - BIAS_GY;
    const float gz = d.gz - BIAS_GZ;

    // 2. Calcular la inclinacion con el acelerometro (rad).
    const float roll_acc = atan2f(d.ay, d.az);
    const float pitch_acc = atan2f(-d.ax, sqrtf(d.ay * d.ay + d.az * d.az));

    // 3. Predecir los angulos integrando el giroscopio.
    const float roll_gyro = orientacion.roll + gx * dt;
    const float pitch_gyro = orientacion.pitch + gy * dt;

    // 4. Fusionar las estimaciones.
    orientacion.roll = ALPHA * roll_gyro + (1.0f - ALPHA) * roll_acc;
    orientacion.pitch = ALPHA * pitch_gyro + (1.0f - ALPHA) * pitch_acc;

    // 5. Yaw: no se puede corregir con la gravedad.
    orientacion.yaw += gz * dt;

    return orientacion;
}
