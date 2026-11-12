import { desdeEuler } from './cuat.js';

// Fuente de datos: WebSocket del ESP32 o demo local (simula 50 Hz con deriva de yaw).
export function crearConexion(onDato, onEstado, onCalibracion = () => {}) {
  let ws = null,
    timer = null,
    filtro = 'comp';
  const cerrar = () => {
    if (ws) {
      ws.onopen = null;
      ws.onclose = null;
      ws.onerror = null;
      ws.onmessage = null;
      ws.close();
      ws = null;
    }
    clearInterval(timer);
    timer = null;
  };
  const api = {
    ws(url) {
      cerrar();
      onEstado('conectando');
      try {
        ws = new WebSocket(url);
      } catch (e) {
        onEstado('error', 'URL inválida: ' + url);
        return;
      }
      ws.onopen = () => onEstado('abierto');
      ws.onclose = () => onEstado('cerrado');
      ws.onerror = () => onEstado('error', 'No se pudo conectar a ' + url);
      ws.onmessage = (e) => {
        try {
          const d = JSON.parse(e.data);
          if (d.calibracion) {
            const { sensor, estado, mensaje } = d.calibracion;
            if (
              !['mpu', 'mag'].includes(sensor) ||
              !['iniciada', 'finalizada', 'error'].includes(estado) ||
              typeof mensaje !== 'string'
            ) {
              onEstado('aviso', 'Estado de calibración inválido ignorado');
              return;
            }
            onCalibracion({ sensor, estado, mensaje });
            return;
          }
          if (d.err) onEstado('aviso', 'Firmware: ' + d.err);
          if (Array.isArray(d.dmp) && Array.isArray(d.sw)) onDato(d);
          else if (!d.err) onEstado('aviso', 'Paquete sin dmp/sw ignorado');
        } catch {
          onEstado('aviso', 'Paquete inválido ignorado');
        }
      };
    },
    demo() {
      cerrar();
      onEstado('abierto');
      const t0 = performance.now();
      let n = 0;
      timer = setInterval(() => {
        n += Math.random() < 0.004 ? 2 : 1; // de vez en cuando "pierde" un paquete
        const t = (performance.now() - t0) / 1000,
          r = () => (Math.random() - 0.5) * 0.8;
        const roll = 35 * Math.sin(0.7 * t),
          pitch = 25 * Math.sin(0.5 * t + 1),
          yaw = 70 * Math.sin(0.3 * t);
        const deriva = { comp: 0.9, mag: 0.03, kalman: 0.05 }[filtro] * t;
        onDato({
          n,
          t: Math.round(t * 1000),
          f: filtro,
          dmp: desdeEuler(roll + r() * 0.3, pitch + r() * 0.3, yaw + 0.15 * t),
          sw: desdeEuler(roll + r(), pitch + r(), yaw + deriva + r())
        });
      }, 20);
    },
    detener() {
      cerrar();
      onEstado('cerrado');
    },
    enviar(o) {
      if (!ws || ws.readyState !== 1) return false;
      ws.send(JSON.stringify(o));
      return true;
    },
    filtro(f) {
      filtro = f;
      api.enviar({ cmd: 'filtro', valor: f });
    }
  };
  return api;
}
