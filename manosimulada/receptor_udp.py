import socket
import struct

# 1. Configuramos el socket UDP
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind(("0.0.0.0", 12345))

print("Escuchando datos I2C crudos (14 bytes) en el puerto 12345...")

try:
    while True:
        datos, direccion = sock.recvfrom(1024)
        
        # 2. Verificamos que el paquete tenga el tamaño exacto del bloque I2C
        if len(datos) == 14:
            
            # 3. Desempaquetamos 7 enteros cortos con signo ('h' = 2 bytes) en Big-Endian ('>')
            valores = struct.unpack('>7h', datos)
            
            # Asignamos las variables según el mapa de registros del MPU9250
            ax, ay, az, temp, gx, gy, gz = valores
            
            print(f"Acel: ({ax}, {ay}, {az}) | Giro: ({gx}, {gy}, {gz}) | Temp: {temp}")
            
except KeyboardInterrupt:
    print("\nCaptura detenida.")
    sock.close()