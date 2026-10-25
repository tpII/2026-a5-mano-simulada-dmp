import { validarMuestra } from './telemetria.mjs';

// Cuaterniones sinteticos conocidos; no simula la fisica ni la calidad del filtro.
export function* generarDemostracion({cantidad=150, escenario='giro', sesion='0000000000000001'}={}) {
  if (!Number.isInteger(cantidad) || cantidad<1 || cantidad>100000) throw new RangeError('Cantidad invalida');
  if (!['reposo','giro','sin_dmp','sin_magnetometro'].includes(escenario)) throw new TypeError('Escenario desconocido');
  for (let i=0;i<cantidad;i++) {
    const tiempo_us=1000000+i*20000;
    // Giro Z a 30 grados/s. Sesgo sintetico conocido de 5 grados entre rutas.
    const yaw=escenario==='reposo'?0:(i/50)*Math.PI/6;
    const q=a => [Math.cos(a/2),0,0,Math.sin(a/2)];
    const mag=escenario!=='sin_magnetometro';
    const dmp=escenario!=='sin_dmp';
    yield validarMuestra({
      version:1,tipo:'muestra',sesion,origen:'simulacion',muestra:i,tiempo_us,
      crudos:{acelerometro:[0,0,16384],giroscopio:[0,0,escenario==='reposo'?0:3930],
        magnetometro:mag?[Math.round(1200*Math.cos(yaw)),Math.round(-1200*Math.sin(yaw)),0]:null},
      tiempo_mag_us:mag?tiempo_us-2000:null,
      orientaciones:{dmp:dmp?{tiempo_us,cuaternion:q(yaw)}:null,
        software:{tiempo_us,cuaternion:q(yaw+(escenario==='reposo'?0:Math.PI/36))}},
      filtro:'complementario',
      validez:{mpu:true,magnetometro:mag,mag_nuevo:mag,dmp,software:true},
      calibracion:{acelerometro:false,giroscopio:false,magnetometro:false}
    });
  }
}
