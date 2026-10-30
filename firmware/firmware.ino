/*
 * firmware -  Mano simulada DMP (ESP32)
 *
 * Qué hace, en una línea:
 *   lee el MPU6050 (con su DMP) y el magnetómetro QMC5883L, calcula la orientación
 *   de dos formas (DMP y filtro por software) y se las manda por Wi-Fi a la página web.
 *
 *
 * Conexiones (las mismas del informe E2):
 *   SDA -> GPIO21   SCL -> GPIO22   MPU6050 INT -> GPIO23   VCC -> 3V3   GND -> GND
 *   El QMC5883L comparte SDA y SCL con el MPU6050.
 *
 * Partes de este archivo:
 *   1. Configuración        6. MPU6050 y DMP
 *   2. Variables            7. Wi-Fi y WebSocket
 *   3. Matemática básica    8. setup()
 *   4. Magnetómetro         9. loop()
 *   5. Filtros
 */

#include <Arduino.h>
#include <Wire.h>
#include <WiFi.h>
#include <WebSocketsServer.h>
#include <ESPmDNS.h>                  // permite usar ws://manodmp.local:81 en vez de la IP
#include "I2Cdev.h"
#include "MPU6050_6Axis_MotionApps20.h"   // trae el firmware del DMP

 // ======================================================================
 // 1. CONFIGURACIÓN  (lo que probablemente quieras tocar está acá)
 // ======================================================================
static const int      PIN_SDA = 21;
static const int      PIN_SCL = 22;
static const int      PIN_INT = 23;          // el MPU avisa por acá "hay un paquete nuevo"
static const uint8_t  QMC_ADDR = 0x0D;       // dirección I2C del magnetómetro

// Red propia del ESP32 (Access Point). Queda siempre activa como respaldo.
static const char* AP_SSID = "ManoDMP";
static const char* AP_PASS = "mano1234";     // mínimo 8 caracteres
static const uint16_t PUERTO_WS = 81;        // la página se conecta a ws://<ip>:81

// Tu red Wi-Fi (opcional): así no hace falta cambiar de red en la compu.
// Los datos se leen de secretos.h (copiá secretos.h.ejemplo). Ese archivo NO se sube al repo.
// Si no existe, el ESP32 funciona solo con su propia red, como antes.
#if __has_include("secretos.h")
  #include "secretos.h"                      // define RED_SSID y RED_CLAVE
#endif
#ifndef RED_SSID
  #define RED_SSID  ""
  #define RED_CLAVE ""
#endif
static const char*    NOMBRE_MDNS    = "manodmp";   // -> ws://manodmp.local:81
static const uint32_t TIMEOUT_RED_MS = 10000;       // cuánto espera conectarse a tu red

// El DMP entrega paquetes a ~100 Hz. Al navegador mandamos 1 de cada DIVISOR_ENVIO:
// 100 Hz / 2 = 50 Hz, que es la frecuencia objetivo del proyecto.
// (El filtro igual corre con TODOS los paquetes, así integra mejor.)
static const uint8_t  DIVISOR_ENVIO = 2;

// Peso del giroscopio en el filtro complementario. 0.98 = "98% giroscopio, 2% referencia".
static const float    ALPHA = 0.98f;

// Calibración del magnetómetro (hard-iron). Hoy en cero: falta hacer la calibración
// (idea: un script en /herramientas que mida el mínimo y máximo de cada eje girando el guante).
static const float    MAG_OFFSET[3] = {0.0f, 0.0f, 0.0f};

// ======================================================================
// 2. VARIABLES
// ======================================================================
MPU6050 mpu;
WebSocketsServer ws(PUERTO_WS);

// Qué algoritmo usa la "mano software". Se cambia desde la página.
enum Modo{ MODO_COMP , MODO_MAG , MODO_KALMAN };
Modo modo = MODO_COMP;
// COMP = complementario (acelerómetro + giroscopio)   MAG = complementario + magnetómetro

// DMP
uint8_t fifoBuffer[64];                  // acá llega cada paquete del DMP
volatile bool paqueteListo = false;      // la interrupción lo pone en true
bool dmpListo = false;
float sensGiro = 16.4f;                  // cuentas por (°/s)  (se recalcula al iniciar)
float sensAcel = 16384.0f;               // cuentas por g      (se recalcula al iniciar)

// Último dato del magnetómetro (si una lectura falla, se reutiliza el anterior)
float magX = 0 , magY = 0 , magZ = 0;

// Estado del filtro (ángulos en radianes)
float fRoll = 0 , fPitch = 0;
float fYawComp = 0;                      // yaw integrando solo el giroscopio (deriva)
float fYawMag = 0;                      // yaw corregido con el magnetómetro
bool  filtroIniciado = false;

// Control
bool transmitiendo = true;               // la página puede pausar el envío
bool pedirCalibracion = false;
uint32_t ultimoUs = 0;                   // para calcular dt entre paquetes
uint32_t contadorPaquetes = 0;           // paquetes del DMP procesados
uint32_t contadorEnvio = 0;              // mensajes enviados (la página lo usa para detectar saltos)

// ======================================================================
// 3. MATEMÁTICA BÁSICA
// ======================================================================

// Lleva un ángulo al rango [-PI, PI] para que no "salte" al pasar de 180° a -180°.
static float normalizarAngulo(float a){
  while (a > PI) a -= 2.0f * PI;
  while (a < -PI) a += 2.0f * PI;
  return a;
}

// Convierte roll, pitch, yaw (radianes) a cuaternión [w, x, y, z].
// La página trabaja con cuaterniones porque comparar dos orientaciones es más fácil así.
static void cuatDesdeEuler(float r , float p , float y , float q[4]){
  float cr = cosf(r / 2) , sr = sinf(r / 2);
  float cp = cosf(p / 2) , sp = sinf(p / 2);
  float cy = cosf(y / 2) , sy = sinf(y / 2);
  q[0] = cr * cp * cy + sr * sp * sy;
  q[1] = sr * cp * cy - cr * sp * sy;
  q[2] = cr * sp * cy + sr * cp * sy;
  q[3] = cr * cp * sy - sr * sp * cy;
}

// ======================================================================
// 4. MAGNETÓMETRO QMC5883L
// ======================================================================

// El módulo del magnetómetro y el MPU6050 están (por ahora) pegados en la protoboard con
// sus ejes rotados entre sí. Acá se pasa la medida del magnetómetro a los ejes del MPU6050,
// que son los del guante: X hacia el meñique, Y hacia los dedos, Z saliendo del dorso.
//
// Según la serigrafía de las placas, vistas desde arriba y con la misma orientación:
//   MPU6050 : X → derecha   Y → arriba    Z → hacia vos
//   Módulo  : X → arriba    Y → izquierda Z → hacia vos
// Por lo tanto:  X_mpu = -Y_modulo   Y_mpu = +X_modulo   Z_mpu = +Z_modulo
// OJO: esos ejes son los del HMC5883L impresos en la placa; el chip se lee como QMC5883L (0x0D),
// así que hay que confirmarlo girando el módulo (ver prueba de yaw). Si no coincide, se corrige acá.
// Cuando los sensores queden montados con los ejes alineados, esta función queda sin cambios.
static void alinearMag(float& x , float& y , float& z){
  float xm = x , ym = y;   // ejes del módulo (ya con los offsets restados)
  x = -ym;
  y =  xm;
  // z queda igual
}

static bool magIniciar(){
  Wire.beginTransmission(QMC_ADDR);
  Wire.write(0x0B); Wire.write(0x01);          // período de set/reset recomendado por el fabricante
  if (Wire.endTransmission() != 0) return false;
  Wire.beginTransmission(QMC_ADDR);
  Wire.write(0x09); Wire.write(0x19);          // sobremuestreo 512, rango ±8 G, 100 Hz, modo continuo
  return Wire.endTransmission() == 0;
}

// Lee X, Y, Z (cuentas crudas). Devuelve false si el sensor no respondió.
static bool magLeer(){
  Wire.beginTransmission(QMC_ADDR);
  Wire.write(0x00);                            // primer registro de datos
  if (Wire.endTransmission(false) != 0) return false;
  if (Wire.requestFrom((uint16_t) QMC_ADDR , (size_t) 6 , true) != 6) return false;
  uint8_t b[6];
  for (int i = 0; i < 6; i++) b[i] = Wire.read();
  // Cada eje son 2 bytes, primero el menos significativo (little-endian).
  float x = (int16_t) ((b[1] << 8) | b[0]) - MAG_OFFSET[0];
  float y = (int16_t) ((b[3] << 8) | b[2]) - MAG_OFFSET[1];
  float z = (int16_t) ((b[5] << 8) | b[4]) - MAG_OFFSET[2];
  alinearMag(x , y , z);
  magX = x; magY = y; magZ = z;
  return true;
}

// Rumbo (yaw) según el magnetómetro, "enderezando" el vector con el roll y pitch actuales.
static float yawDesdeMag(float roll , float pitch){
  float cr = cosf(roll) , sr = sinf(roll) , cp = cosf(pitch) , sp = sinf(pitch);
  float xh = magX * cp + sp * (sr * magY + cr * magZ);
  float yh = cr * magY - sr * magZ;
  return atan2f(-yh , xh);
}

// ======================================================================
// 5. FILTROS  (estimación "por software", sin usar nada del DMP)
// ======================================================================

// Primera muestra: parte de una orientación coherente con la posición real del sensor.
static void filtroIniciar(float ax , float ay , float az){
  fRoll = atan2f(ay , az);
  fPitch = atan2f(-ax , sqrtf(ay * ay + az * az));
  fYawMag = yawDesdeMag(fRoll , fPitch);
  fYawComp = fYawMag;
}

// Filtro complementario. Se llama en cada paquete.
//   ax,ay,az: aceleración (en g)   gx,gy,gz: velocidad angular (rad/s)   dt: segundos
static void filtroComplementario(float ax , float ay , float az ,
                                 float gx , float gy , float gz , float dt){
  // Roll y pitch: giroscopio (rápido pero deriva) + acelerómetro (lento pero estable).
  float rollAcc = atan2f(ay , az);
  float pitchAcc = atan2f(-ax , sqrtf(ay * ay + az * az));
  fRoll = ALPHA * (fRoll + gx * dt) + (1.0f - ALPHA) * rollAcc;
  fPitch = ALPHA * (fPitch + gy * dt) + (1.0f - ALPHA) * pitchAcc;

  // Yaw modo COMP: solo giroscopio. Nada lo corrige, así que va a derivar (es lo esperado).
  fYawComp = normalizarAngulo(fYawComp + gz * dt);

  // Yaw modo MAG: giroscopio corregido con el rumbo del magnetómetro.
  // Se corrige la DIFERENCIA (normalizada) para evitar saltos en ±180°.
  float yawGiro = fYawMag + gz * dt;
  float dif = normalizarAngulo(yawDesdeMag(fRoll , fPitch) - yawGiro);
  fYawMag = normalizarAngulo(yawGiro + (1.0f - ALPHA) * dif);

  // Mejoras posibles más adelante:
  //  - ignorar el acelerómetro cuando |a| se aleja de 1 g (el guante se está moviendo fuerte)
  //  - integrar con la cinemática real de Euler en vez de eje por eje
}

// ---------- ESPACIO RESERVADO PARA EL FILTRO DE KALMAN ----------
// Cuando exista: poner kalmanDisponible() en true, completar kalmanActualizar() y
// elegirEstimacion() ya sabe usarlo. Mientras tanto la página lo muestra deshabilitado.
static bool kalmanDisponible(){ return false; }
static void kalmanActualizar(float ax , float ay , float az ,
                             float gx , float gy , float gz , float dt){
  // TODO
}
static void kalmanEstimacion(float& r , float& p , float& y){
  // TODO: devolver el roll, pitch y yaw estimados por Kalman
  r = fRoll; p = fPitch; y = fYawMag;
}
// ----------------------------------------------------------------

// Devuelve la estimación que corresponde al modo elegido en la página.
static void elegirEstimacion(float& r , float& p , float& y , const char*& nombre){
  r = fRoll; p = fPitch;
  switch (modo){
  case MODO_COMP:   y = fYawComp; nombre = "comp";   break;
  case MODO_MAG:    y = fYawMag;  nombre = "mag";    break;
  case MODO_KALMAN: kalmanEstimacion(r , p , y); nombre = "kalman"; break;
  }
}

// ======================================================================
// 6. MPU6050 Y DMP
// ======================================================================

// Interrupción: se ejecuta cuando el MPU avisa que hay un paquete nuevo.
// Es mejor hacer lo mínimo acá: solo levantar una bandera. El trabajo real va en loop().
static void IRAM_ATTR isrDmp(){ paqueteListo = true; }

// Calibra offsets de acelerómetro y giroscopio. El guante debe estar QUIETO.
// Como esto corrige los registros del propio sensor, NO hace falta restar un
// "bias" del giroscopio por software (se estaría corrigiendo dos veces).
static void calibrarSensor(){
  mpu.CalibrateAccel(6);
  mpu.CalibrateGyro(6);
}

static bool dmpIniciar(){
  mpu.initialize();
  if (!mpu.testConnection()){ Serial.println("MPU6050 no responde (revisar cables)."); return false; }

  uint8_t estado = mpu.dmpInitialize();        // carga el firmware del DMP en el sensor
  if (estado != 0){ Serial.printf("dmpInitialize fallo, codigo %u\n" , estado); return false; }

  // Offsets iniciales (los mismos del E2) y calibración automática.
  mpu.setXAccelOffset(-1000); mpu.setYAccelOffset(-1000); mpu.setZAccelOffset(1000);
  mpu.setXGyroOffset(0);      mpu.setYGyroOffset(0);      mpu.setZGyroOffset(0);
  calibrarSensor();

  mpu.setDMPEnabled(true);
  pinMode(PIN_INT , INPUT);
  attachInterrupt(digitalPinToInterrupt(PIN_INT) , isrDmp , RISING);
  mpu.getIntStatus();

  // Las lecturas crudas dependen del rango configurado: lo leemos en vez de suponerlo.
  // Giroscopio: 131 cuentas por °/s en ±250, y se divide a la mitad con cada rango más grande.
  // Acelerómetro: 16384 cuentas por g en ±2 g, mismo criterio.
  sensGiro = 131.0f / (1 << mpu.getFullScaleGyroRange());
  sensAcel = 16384.0f / (1 << mpu.getFullScaleAccelRange());
  return true;
}

// Pide al sensor que se recalibre (llamado desde loop, nunca desde un evento de red).
static void recalibrar(){
  Serial.println("Recalibrando: no mover el guante...");
  mpu.setDMPEnabled(false);
  calibrarSensor();
  mpu.resetFIFO();
  mpu.setDMPEnabled(true);
  filtroIniciado = false;                      // el filtro vuelve a arrancar desde cero
}

// ======================================================================
// 7. WI-FI Y WEBSOCKET
// ======================================================================
//
// ¿Por qué WebSocket? Una página web NO puede recibir UDP ni abrir sockets "crudos"
// por seguridad del navegador. Lo que sí permite es un WebSocket: una conexión que se
// abre una vez y queda abierta, por la que el ESP32 va "empujando" mensajes de texto.
// Es como una llamada abierta en vez de mandar una carta (pedido HTTP) por cada dato.

// Manda un mensaje de error a la página (aparece en el panel de Conexión).
static void enviarError(const char* msg){
  char buf[96];
  int n = snprintf(buf , sizeof(buf) , "{\"err\":\"%s\"}" , msg);
  ws.broadcastTXT(buf , n);
}

// Interpreta los comandos que manda la página. Son JSON cortitos, por ejemplo:
//   {"cmd":"filtro","valor":"mag"}      {"cmd":"iniciar"}
// Para no depender de otra librería, solo buscamos las palabras clave en el texto.
static void manejarComando(const char* txt){
  if (strstr(txt , "\"iniciar\""))   transmitiendo = true;
  else if (strstr(txt , "\"detener\""))   transmitiendo = false;
  else if (strstr(txt , "\"calibrar\""))  pedirCalibracion = true;   // se hace en loop()
  else if (strstr(txt , "\"filtro\"")){
    if (strstr(txt , "\"comp\""))    modo = MODO_COMP;
    else if (strstr(txt , "\"mag\""))     modo = MODO_MAG;
    else if (strstr(txt , "\"kalman\"")){
      if (kalmanDisponible()) modo = MODO_KALMAN;
      else enviarError("Kalman todavia no esta implementado");
    }
  }
}

// Se llama cada vez que pasa algo con un cliente (se conecta, se va, manda un texto).
static void eventoWs(uint8_t num , WStype_t tipo , uint8_t* payload , size_t largo){
  switch (tipo){
  case WStype_CONNECTED:    Serial.printf("Cliente %u conectado\n" , num); break;
  case WStype_DISCONNECTED: Serial.printf("Cliente %u desconectado\n" , num); break;
  case WStype_TEXT:
  {
    char tmp[80];
    size_t n = largo < sizeof(tmp) - 1 ? largo : sizeof(tmp) - 1;
    memcpy(tmp , payload , n); tmp[n] = 0;     // copia terminada en 0 para poder buscar texto
    manejarComando(tmp);
    break;
  }
  default: break;
  }
}

static void wifiIniciar(){
  bool usarRed = strlen(RED_SSID) > 0;
  WiFi.mode(usarRed ? WIFI_AP_STA : WIFI_AP);  // AP (red propia) + estación (tu router), o solo AP
  WiFi.softAP(AP_SSID , AP_PASS);              // siempre queda esta red como respaldo

  if (usarRed){
    WiFi.begin(RED_SSID , RED_CLAVE);
    Serial.print("Conectando a "); Serial.print(RED_SSID);
    uint32_t t0 = millis();
    while (WiFi.status() != WL_CONNECTED && millis() - t0 < TIMEOUT_RED_MS){
      delay(250); Serial.print(".");
    }
    Serial.println();
  }
  WiFi.setSleep(false);                        // menos latencia

  Serial.print("Red Wi-Fi: "); Serial.print(AP_SSID);
  Serial.print("   IP: ");     Serial.println(WiFi.softAPIP());   // normalmente 192.168.4.1
  if (usarRed){
    if (WiFi.status() == WL_CONNECTED){
      Serial.print("Conectado a "); Serial.print(RED_SSID);
      Serial.print("   IP: ");      Serial.println(WiFi.localIP());
      if (MDNS.begin(NOMBRE_MDNS)){
        MDNS.addService("ws" , "tcp" , PUERTO_WS);
        Serial.printf("Tambien disponible en ws://%s.local:%u\n" , NOMBRE_MDNS , PUERTO_WS);
      }
    } else {
      Serial.println("No se pudo conectar a tu red; queda solo la red ManoDMP.");
    }
  }
  ws.begin();
  ws.onEvent(eventoWs);
}

// Arma y envía un mensaje con las dos orientaciones. Formato (ver web/README.md):
//   {"n":12,"t":3400,"f":"comp","dmp":[w,x,y,z],"sw":[w,x,y,z]}
static void enviarMuestra(const Quaternion& qDmp){
  if (!transmitiendo || ws.connectedClients() == 0) return;   // nadie escuchando: no gastar tiempo

  float r , p , y; const char* nombre;
  elegirEstimacion(r , p , y , nombre);
  float s[4];
  cuatDesdeEuler(r , p , y , s);                  // la estimación por software, como cuaternión

  char buf[200];
  int n = snprintf(buf , sizeof(buf) ,
    "{\"n\":%lu,\"t\":%lu,\"f\":\"%s\",\"dmp\":[%.5f,%.5f,%.5f,%.5f],\"sw\":[%.5f,%.5f,%.5f,%.5f]}" ,
    (unsigned long) contadorEnvio++ , (unsigned long) millis() , nombre ,
    qDmp.w , qDmp.x , qDmp.y , qDmp.z , s[0] , s[1] , s[2] , s[3]);
  ws.broadcastTXT(buf , n);
}

// ======================================================================
// 8. SETUP
// ======================================================================
void setup(){
  Serial.begin(115200);
  Wire.begin(PIN_SDA , PIN_SCL);
  Wire.setClock(400000);                       // 400 kHz: necesario para leer rápido la FIFO

  if (!magIniciar()) Serial.println("Magnetometro QMC5883L no responde (revisar cables).");

  Serial.println("Iniciando DMP. No mover el guante (calibracion)...");
  dmpListo = dmpIniciar();
  Serial.println(dmpListo ? "DMP listo." : "DMP NO se pudo iniciar.");

  wifiIniciar();
}

// ======================================================================
// 9. LOOP
// ======================================================================

// Procesa un paquete del DMP: lee datos, actualiza el filtro y (cada tanto) envía.
static void procesarPaquete(){
  // 1) Orientación del DMP (ruta A)
  Quaternion q;
  mpu.dmpGetQuaternion(&q , fifoBuffer);

  // 2) Datos crudos del mismo instante (ruta B): acelerómetro y giroscopio...
  int16_t axr , ayr , azr , gxr , gyr , gzr;
  mpu.getMotion6(&axr , &ayr , &azr , &gxr , &gyr , &gzr);
  float ax = axr / sensAcel , ay = ayr / sensAcel , az = azr / sensAcel;            // en g
  const float aRad = (PI / 180.0f) / sensGiro;                                    // cuentas -> rad/s
  float gx = gxr * aRad , gy = gyr * aRad , gz = gzr * aRad;
  magLeer();                                                                      // ...y magnetómetro

  // 3) Tiempo desde el paquete anterior (el filtro lo necesita para integrar)
  uint32_t ahora = micros();
  float dt = (ahora - ultimoUs) * 1e-6f;
  ultimoUs = ahora;

  if (!filtroIniciado){ filtroIniciar(ax , ay , az); filtroIniciado = true; return; }
  if (dt <= 0.0f || dt > 0.1f) return;         // dt raro (pausa larga): descartar

  // 4) Filtros
  filtroComplementario(ax , ay , az , gx , gy , gz , dt);
  if (kalmanDisponible()) kalmanActualizar(ax , ay , az , gx , gy , gz , dt);

  // 5) Enviar a la página (1 de cada DIVISOR_ENVIO paquetes)
  if (++contadorPaquetes % DIVISOR_ENVIO == 0) enviarMuestra(q);
}

void loop(){
  ws.loop();                                   // atiende a los clientes WebSocket (llamar siempre)

  if (pedirCalibracion){ pedirCalibracion = false; recalibrar(); }

  if (!dmpListo){                             // sin DMP no hay nada que enviar: avisar cada 2 s
    static uint32_t ultimoAviso = 0;
    if (millis() - ultimoAviso > 2000){ ultimoAviso = millis(); enviarError("DMP no iniciado, revisar cables"); }
    return;
  }

  if (!paqueteListo) return;                   // la interrupción todavía no avisó nada
  paqueteListo = false;
  if (mpu.dmpGetCurrentFIFOPacket(fifoBuffer)) procesarPaquete();
}
