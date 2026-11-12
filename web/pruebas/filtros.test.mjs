import assert from 'node:assert/strict';
import { crearSeguimientoFiltro, nombreFiltro } from '../js/filtros.js';
import { crearConexion } from '../js/conexion.js';

const seguimiento = crearSeguimientoFiltro();
assert.equal(seguimiento.estado().confirmado, null);
seguimiento.recibir('comp');
assert.equal(seguimiento.estado().esperando, false);
seguimiento.solicitar('kalman');
seguimiento.recibir('comp');
assert.equal(seguimiento.estado().solicitado, 'kalman');
assert.equal(seguimiento.estado().confirmado, 'comp');
assert.equal(seguimiento.estado().esperando, true);
seguimiento.recibir('kalman');
assert.equal(seguimiento.estado().esperando, false);
seguimiento.recibir('mag'); // Otro cliente puede cambiar el filtro del dispositivo.
assert.equal(seguimiento.estado().solicitado, 'mag');
seguimiento.reiniciar();
assert.equal(seguimiento.estado().confirmado, null);
assert.equal(seguimiento.estado().solicitado, 'mag');
assert.equal(seguimiento.estado().esperando, true);
for (const desconocido of [
  undefined,
  null,
  'otro',
  '__proto__',
  'toString',
  {}
]) {
  assert.equal(nombreFiltro(desconocido), null);
  assert.equal(seguimiento.solicitar(desconocido), false);
  seguimiento.recibir(desconocido);
  assert.equal(seguimiento.estado().confirmado, null);
  assert.equal(seguimiento.estado().desconocido, true);
}
seguimiento.recibir('mag');
assert.equal(seguimiento.estado().desconocido, false);
assert.equal(seguimiento.estado().esperando, false);

// La fuente simulada permite verificar conexiones, reconexiones y demo sin ESP32.
const sockets = [];
class WebSocketSimulado {
  constructor() {
    this.readyState = 0;
    this.enviados = [];
    sockets.push(this);
  }
  send(texto) {
    this.enviados.push(JSON.parse(texto));
  }
  close() {
    this.readyState = 3;
  }
}
globalThis.WebSocket = WebSocketSimulado;
let pulsoDemo;
globalThis.setInterval = (callback) => {
  pulsoDemo = callback;
  return 1;
};
globalThis.clearInterval = () => {
  pulsoDemo = null;
};
const control = crearSeguimientoFiltro();
control.solicitar('kalman');
const avisos = [];
const conexion = crearConexion(
  (dato) => control.recibir(dato.f),
  (tipo, mensaje) => {
    if (tipo === 'abierto') {
      control.reiniciar();
      conexion.filtro(control.estado().solicitado);
    }
    if (tipo === 'conectando' || tipo === 'cerrado' || tipo === 'error')
      control.reiniciar();
    if (tipo === 'aviso') avisos.push(mensaje);
  }
);
conexion.ws('ws://prueba');
const anterior = sockets[0];
anterior.readyState = 1;
anterior.onopen();
assert.deepEqual(anterior.enviados, [{ cmd: 'filtro', valor: 'kalman' }]);
anterior.onmessage({ data: JSON.stringify({ err: 'Filtro rechazado' }) });
assert.equal(control.estado().confirmado, null);
assert.equal(control.estado().esperando, true);
assert.equal(avisos.length, 1);
anterior.onmessage({
  data: JSON.stringify({ f: 'comp', dmp: [1, 0, 0, 0], sw: [1, 0, 0, 0] })
});
assert.equal(control.estado().confirmado, 'comp');
assert.equal(control.estado().esperando, true);
conexion.ws('ws://segunda');
for (const evento of ['onopen', 'onclose', 'onerror', 'onmessage'])
  assert.equal(anterior[evento], null);
const actual = sockets[1];
actual.readyState = 1;
actual.onopen();
assert.deepEqual(actual.enviados, [{ cmd: 'filtro', valor: 'kalman' }]);
assert.equal(control.estado().confirmado, null);
actual.onmessage({
  data: JSON.stringify({ f: 'kalman', dmp: [1, 0, 0, 0], sw: [1, 0, 0, 0] })
});
assert.equal(control.estado().esperando, false);
conexion.demo();
assert.equal(control.estado().confirmado, null);
pulsoDemo();
assert.equal(control.estado().confirmado, 'kalman');
assert.equal(control.estado().esperando, false);
conexion.detener();
assert.equal(control.estado().confirmado, null);
assert.equal(pulsoDemo, null);
console.log(
  'OK: solicitud, confirmación, rechazo, cambios externos, reconexión, fuente anterior y demo.'
);
