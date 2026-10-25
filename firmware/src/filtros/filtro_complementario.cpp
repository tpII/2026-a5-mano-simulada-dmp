#include "filtro_complementario.h"
#include <math.h>

#define ALPHA 0.98f

// Bias del giroscopio medido en reposo (rad/s)
#define BIAS_GX -0.022842f
#define BIAS_GY  0.000215f
#define BIAS_GZ -0.006985f

// Calibración inicial simple (offset / hard-iron) del magnetómetro
// Si al girarlo 360° ves que está descentrado, se ajustan estos valores
#define MAG_OFFSET_X 0.0f
#define MAG_OFFSET_Y 0.0f
#define MAG_OFFSET_Z 0.0f

static Orientacion orientacion = {0.0f, 0.0f, 0.0f};

// Normaliza un ángulo al rango [-PI, PI] para evitar saltos bruscos en el filtro
static float normalizar_angulo(float angulo) {
    while (angulo > M_PI)  angulo -= 2.0f * M_PI;
    while (angulo < -M_PI) angulo += 2.0f * M_PI;
    return angulo;
}

// Calcula el rumbo magnético compensado por inclinación (tilt compensation)
static float calcular_yaw_mag(const mag_datos_t &m, float roll, float pitch) {
    const float mx = m.mx - MAG_OFFSET_X;
    const float my = m.my - MAG_OFFSET_Y;
    const float mz = m.mz - MAG_OFFSET_Z;

    const float cos_roll = cosf(roll);
    const float sin_roll = sinf(roll);
    const float cos_pitch = cosf(pitch);
    const float sin_pitch = sinf(pitch);

    // Proyección del vector magnético sobre el plano horizontal
    const float Xh = mx * cos_pitch + my * sin_roll * sin_pitch + mz * cos_roll * sin_pitch;
    const float Yh = my * cos_roll - mz * sin_roll;

    return atan2f(-Yh, Xh);
}

void filtro_iniciar(const mpu_datos_t &d, const mag_datos_t &m, bool mag_valido) {
    orientacion.roll = atan2f(d.ay, d.az);
    orientacion.pitch = atan2f(-d.ax, sqrtf(d.ay * d.ay + d.az * d.az));
    orientacion.yaw = mag_valido ? calcular_yaw_mag(m, orientacion.roll, orientacion.pitch) : 0.0f;
}

Orientacion filtro_actualizar(const mpu_datos_t &d, const mag_datos_t &m, float dt, bool mag_nuevo) {
    if (dt <= 0.0f || !isfinite(dt)) {
        return orientacion;
    }

    // 1. Corregir bias del giroscopio
    const float gx = d.gx - BIAS_GX;
    const float gy = d.gy - BIAS_GY;
    const float gz = d.gz - BIAS_GZ;

    // 2. Inclinación con acelerómetro
    const float roll_acc = atan2f(d.ay, d.az);
    const float pitch_acc = atan2f(-d.ax, sqrtf(d.ay * d.ay + d.az * d.az));

    // 3. Integración con giróscopo
    const float roll_gyro = orientacion.roll + gx * dt;
    const float pitch_gyro = orientacion.pitch + gy * dt;
    const float yaw_gyro = orientacion.yaw + gz * dt;

    // 4. Fusión Roll y Pitch
    orientacion.roll = ALPHA * roll_gyro + (1.0f - ALPHA) * roll_acc;
    orientacion.pitch = ALPHA * pitch_gyro + (1.0f - ALPHA) * pitch_acc;

    if (!mag_nuevo) {
        orientacion.yaw = normalizar_angulo(yaw_gyro);
        return orientacion;
    }

    // 5. Rumbo absoluto del magnetómetro con tilt compensation
    const float yaw_mag = calcular_yaw_mag(m, orientacion.roll, orientacion.pitch);

    // 6. Fusión Yaw considerando la discontinuidad circular [-PI, PI]
    const float diff_yaw = normalizar_angulo(yaw_mag - yaw_gyro);
    orientacion.yaw = normalizar_angulo(yaw_gyro + (1.0f - ALPHA) * diff_yaw);

    return orientacion;
}
