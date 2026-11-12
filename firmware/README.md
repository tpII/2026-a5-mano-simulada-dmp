# Firmware de la mano simulada

Abrir `firmware.ino` en Arduino IDE. El sketch coordina los módulos de `src/`,
que Arduino compila de forma recursiva. Cada `.h` documenta las funciones públicas;
los `.cpp` contienen la implementación y mantienen privado su estado interno.

## Responsabilidades

| Archivo o carpeta | Responsabilidad |
| --- | --- |
| `firmware.ino` | Arranque, comandos de la web y orden de adquisición y procesamiento |
| `src/configuracion.h` | Pines, velocidad I²C, frecuencia de envío y red propia |
| `src/tipos.h` | Datos compartidos y unidades, sin depender de Arduino |
| `src/sensores/i2c.*` | Acceso al bus compartido |
| `src/sensores/mpu6050.*` | Driver MPU6050, MotionApps, calibración interna y lecturas |
| `src/sensores/qmc5883l.*` | Lecturas crudas y aplicación de offsets y escalas magnéticas |
| `src/dmp/` | Interrupción del MPU y disponibilidad de paquetes DMP |
| `src/filtros/filtro_complementario.*` | Complementario con y sin corrección magnética |
| `src/filtros/filtro_kalman.*` | Kalman de ángulo y sesgo, aplicado a los tres ejes |
| `src/filtros/estimador.*` | Actualiza las rutas y elige cuál publicar |
| `src/calibracion/calibracion_magnetometro.*` | Cálculo min/max, plazo y validación de ajustes |
| `src/calibracion/calibracion.*` | Coordina ambos procedimientos e informa su resultado |
| `src/matematica/` | Conversión a cuaternión, normalización angular y rumbo magnético |
| `src/comunicacion/wifi.*` | Red ManoDMP y alternativa de conexión al router comentada |
| `src/comunicacion/websocket.*` | Conexiones, recepción de comandos y envío de mensajes |
| `src/comunicacion/protocolo.*` | Interpretación de comandos y formato JSON, sin acceso a hardware |
| `pruebas/` | Pruebas de los algoritmos y del protocolo ejecutables en la computadora |

## Funcionamiento

1. Se inicia I²C en GPIO21/GPIO22 a 400 kHz y se configura el QMC5883L a 100 Hz.
2. Se inicializa el MPU6050, se carga el DMP y se calibra con el guante quieto,
   horizontal y con +Z hacia arriba. GPIO23 recibe la interrupción del MPU.
3. Se crea la red `ManoDMP` y el servidor WebSocket del puerto 81.
4. Cada vuelta atiende primero la red y las solicitudes de calibración.
5. Cada paquete DMP permite leer también aceleración y giro y actualizar todos
   los filtros. Se conserva la última lectura magnética cuando falla I²C.
6. Se publica una de cada dos muestras procesadas: objetivo nominal ~50 Hz.
   Detener el envío no detiene los filtros ni la adquisición.

Los ángulos internos están en radianes, la aceleración en g y el giro en rad/s.
El campo magnético se expresa en cuentas del QMC. Los cuaterniones usan
`[w, x, y, z]`. La transformación entre ejes de ambos sensores sigue siendo
la identidad del firmware anterior; debe verificarse en el montaje físico.

Se mantienen las fórmulas y los parámetros del firmware anterior. La integración
del giro por eje y la reutilización del último campo magnético son limitaciones
existentes; esta reorganización no agrega un algoritmo de fusión nuevo.

## Calibración

La web envía `calibrar` para el MPU6050 y `calibrarMag` para el QMC5883L.
El MPU usa las rutinas de la biblioteca con el DMP pausado. El magnetómetro
recopila extremos durante 20 segundos y solo aplica los ajustes si los tres
ejes tienen recorrido suficiente. Un intento fallido conserva los valores
anteriores. El vencimiento se comprueba aunque no lleguen lecturas.

Durante el procedimiento no se publican muestras. Al finalizar se reinician
los filtros y se descartan los paquetes DMP acumulados. Se envía el estado a
la web independientemente de que el ensayo esté detenido. Los ajustes viven
en RAM y se pierden al reiniciar; el MPU vuelve a calibrarse en el arranque.
La calibración del MPU es bloqueante, por lo que puede pausar brevemente la
atención de red. Terminar la rutina no certifica la precisión de los sensores.

## Red y protocolo

La red propia permanece activa. La conexión al router se conserva comentada
en `src/comunicacion/wifi.cpp`, con instrucciones para habilitarla. No se leen
credenciales de `secretos.h` mientras ese bloque esté desactivado.

Conectar la web a `ws://<IP mostrada por el monitor serie>:81`, normalmente
`ws://192.168.4.1:81`. `manodmp.local` solo se anuncia en la alternativa de
router. Las dependencias de la página web deben estar cargadas antes de
cambiar a una red del ESP32 sin Internet.

Se conserva el contrato de la web actual, que es distinto del antiguo JSON v1
por USB conservado en experimentos:

```json
{"n":12,"t":3400,"f":"comp","dmp":[1,0,0,0],"sw":[1,0,0,0]}
```

Comandos: `iniciar`, `detener`, `calibrar`, `calibrarMag` y
`{"cmd":"filtro","valor":"comp"}` (`comp`, `mag` o `kalman`). Se conserva
el intérprete sencillo por palabras clave; no es un validador JSON completo.
Los errores usan `{"err":"mensaje"}` y los avisos de calibración usan
`{"calibracion":{"sensor":"mag","estado":"iniciada","mensaje":"..."}}`.

## Compilación y pruebas

Se necesitan el core ESP32, las bibliotecas `I2Cdev`, `MPU6050` con MotionApps20
y `WebSockets` de Links2004. WiFi, Wire y ESPmDNS pertenecen al core ESP32.
La placa de compilación usada para verificar es ESP32 Dev Module:

```sh
arduino-cli compile --fqbn esp32:esp32:esp32 firmware
```

Desde la raíz del repositorio, las pruebas sin hardware se ejecutan con:

```sh
python3 firmware/pruebas/ejecutar.py
```

El script requiere un compilador C++ (`c++` o `clang++`) y deja el ejecutable
en una carpeta temporal. No conecta con sensores ni carga firmware al ESP32.
La compilación y estas pruebas no reemplazan la validación física del guante.
