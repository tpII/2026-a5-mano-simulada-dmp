import socket
import struct

# 1. Configuramos el socket UDP
sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sock.bind(("0.0.0.0", 12345))

print("Escuchando datos inerciales (12 bytes) en el puerto 12345 a 50Hz...")

try:
    while True:
        datos, direccion = sock.recvfrom(1024)
        
        # 2. Verificamos que el paquete tenga el tamaño exacto del arreglo (6 int16_t)
        if len(datos) == 12:
            
            # 3. Desempaquetamos 6 enteros cortos con signo ('h') en Little-Endian ('<')
            valores = struct.unpack('<6h', datos)
            
            # Asignamos las variables
            ax, ay, az, gx, gy, gz = valores
            
            print(f"A: ({ax}, {ay}, {az}) | G: ({gx}, {gy}, {gz})")
            
except KeyboardInterrupt:
    print("\nCaptura detenida.")
    sock.close()