import { desdeEuler } from './cuat.js';

// Fuente de datos: WebSocket del ESP32 o demo local (simula 50 Hz con deriva de yaw).
export function crearConexion(onDato, onEstado) {
  let ws = null, timer = null, filtro = 'comp';
  const cerrar = () => {
    if (ws) { ws.onclose = null; ws.close(); ws = null; }
    clearInterval(timer); timer = null;
  };
  const api = {
    ws(url) {
      cerrar(); onEstado('conectando');
      try { ws = new WebSocket(url); } catch (e) { onEstado('error', 'URL inválida: ' + url); return; }
      ws.onopen = () => onEstado('abierto');
      ws.onclose = () => onEstado('cerrado');
      ws.onerror = () => onEstado('error', 'No se pudo conectar a ' + url);
      ws.onmessage = e => {
        try {
          const d = JSON.parse(e.data);
          if (d.err) onEstado('aviso', 'Firmware: ' + d.err);
          if (Array.isArray(d.dmp) && Array.isArray(d.sw)) onDato(d);
          else if (!d.err) onEstado('aviso', 'Paquete sin dmp/sw ignorado');
        } catch { onEstado('aviso', 'Paquete inválido ignorado'); }
      };
    },
    demo() {
      cerrar(); onEstado('abierto');
      const t0 = performance.now(); let n = 0;
      timer = setInterval(() => {
        n += Math.random() < .004 ? 2 : 1; // de vez en cuando "pierde" un paquete
        const t = (performance.now() - t0) / 1000, r = () => (Math.random() - .5) * .8;
        const roll = 35 * Math.sin(.7 * t), pitch = 25 * Math.sin(.5 * t + 1), yaw = 70 * Math.sin(.3 * t);
        const deriva = { comp: .9, mag: .03, kalman: .05 }[filtro] * t;
        onDato({ n, t: Math.round(t * 1000), f: filtro,
          dmp: desdeEuler(roll + r() * .3, pitch + r() * .3, yaw + .15 * t),
          sw: desdeEuler(roll + r(), pitch + r(), yaw + deriva + r()) });
      }, 20);
    },
    detener() { cerrar(); onEstado('cerrado'); },
    enviar(o) { if (ws && ws.readyState === 1) ws.send(JSON.stringify(o)); },
    filtro(f) { filtro = f; api.enviar({ cmd: 'filtro', valor: f }); },
  };
  return api;
}
