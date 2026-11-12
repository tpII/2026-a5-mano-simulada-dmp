#pragma once

// Unidades: aceleración en g, giro en rad/s, campo magnético en cuentas del QMC.
struct Vector3 {
  float x = 0;
  float y = 0;
  float z = 0;
};

struct DatosInerciales {
  Vector3 aceleracion;
  Vector3 giro;
};

// Ángulos de Euler en radianes y cuaternión en orden [w, x, y, z].
struct Orientacion {
  float roll = 0;
  float pitch = 0;
  float yaw = 0;
};

struct Cuaternion {
  float w = 1;
  float x = 0;
  float y = 0;
  float z = 0;
};

struct AjustesMagnetometro {
  float offset[3] = {0, 0, 0};
  float escala[3] = {1, 1, 1};
};

enum class FiltroSoftware { Complementario, ConMagnetometro, Kalman };
