import * as THREE from 'three';
import { OrbitControls } from 'three/addons/OrbitControls.js';
import { crearMano, PALETAS } from './mano.js';
import { crearConexion } from './conexion.js';
import { crearGraficos } from './graficos.js';
import { mul, conj, norm, angulo, euler } from './cuat.js';

const $ = id => document.getElementById(id);
const f1 = v => (v >= 0 ? '+' : '') + v.toFixed(1) + '°';

// ---------- Escena ----------
const escena = $('escena'), renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
renderer.setPixelRatio(Math.min(devicePixelRatio, 2));
escena.prepend(renderer.domElement);
const sc = new THREE.Scene(), cam = new THREE.PerspectiveCamera(38, 1, .1, 100);
const ctl = new OrbitControls(cam, renderer.domElement);
ctl.enableDamping = true; ctl.target.set(0, -.2, 0);
const manos = { dmp: crearMano(PALETAS.dmp), sw: crearMano(PALETAS.sw) };
const objetivo = { dmp: new THREE.Quaternion(), sw: new THREE.Quaternion() };
// Ejes del cuerpo de la mano = ejes del sensor (se mueven con la mano):
//   X (rojo) → meñique · Y (verde) → punta de los dedos · Z (azul) → sale del dorso (lado de las uñas)
function etiqueta(texto, color) {
  const c = document.createElement('canvas'); c.width = 256; c.height = 64;
  const x = c.getContext('2d'); x.font = 'bold 30px system-ui, sans-serif';
  x.textAlign = 'center'; x.textBaseline = 'middle';
  x.lineWidth = 7; x.strokeStyle = 'rgba(4,12,26,.95)'; x.strokeText(texto, 128, 32);
  x.fillStyle = color; x.fillText(texto, 128, 32);
  const s = new THREE.Sprite(new THREE.SpriteMaterial({ map: new THREE.CanvasTexture(c), depthTest: false, transparent: true }));
  s.scale.set(1.7, .425, 1); s.renderOrder = 10; return s;
}
function ejesCuerpo() {
  const L = 1.8, g = new THREE.Group(), ax = new THREE.AxesHelper(L);
  ax.material.depthTest = false; ax.renderOrder = 9; g.add(ax);
  [['X', '#ff6b6b', [L + .8, 0, 0]], ['Y', '#6bff8a', [0, L + .35, 0]], ['Z', '#6fb0ff', [0, 0, L + .35]]]
    .forEach(([t, col, p]) => { const e = etiqueta(t, col); e.position.set(...p); g.add(e); });
  return g;
}
[['dmp', -2.4], ['sw', 2.4]].forEach(([k, x]) => {
  const g = new THREE.Group(); g.position.set(x, -.2, 0);
  manos[k].add(ejesCuerpo()); g.add(manos[k]); sc.add(g);
});
const piso = new THREE.GridHelper(14, 28, 0x1d4a70, 0x102c46); piso.position.y = -3; sc.add(piso);
function vistaInicial() {
  const asp = escena.clientWidth / escena.clientHeight;
  cam.position.set(0, 1, Math.max(10.5, 10.5 * 1.7 / asp)); ctl.target.set(0, -.2, 0); ctl.update();
}
new ResizeObserver(() => {
  const w = escena.clientWidth, h = escena.clientHeight;
  renderer.setSize(w, h); cam.aspect = w / h; cam.updateProjectionMatrix();
}).observe(escena);
vistaInicial();
renderer.setAnimationLoop(() => {
  for (const k of ['dmp', 'sw']) manos[k].quaternion.slerp(objetivo[k], .4);
  ctl.update(); renderer.render(sc, cam);
});

// ---------- Datos ----------
const gr = crearGraficos($('gA'), $('gB'));
const S = { ref: null, crudo: null, ult: null, rx: [], lastRx: 0, lastN: null, perdidos: 0, total: 0, t0: null, aviso: '', conectado: false };
const E = { on: false, filas: [], t0: 0, n: 0, media: 0, m2: 0, max: 0 };
// El modelo de la mano usa los mismos ejes que el sensor (X meñique, Y dedos, Z dorso) y la cámara
// mira el dorso desde +Z. El cuaternión (ya relativo a la referencia) se aplica tal cual: sin permutar
// ejes ni cambiar signos. Permutarlos haría girar la mano virtual sobre un eje distinto al real.
const sensorAThree = q => new THREE.Quaternion(q[1], q[2], q[3], q[0]);

function onDato(d) {
  const ahora = performance.now(); S.lastRx = ahora; S.rx.push(ahora); S.total++;
  if (S.lastN !== null && d.n > S.lastN + 1) S.perdidos += d.n - S.lastN - 1;
  S.lastN = d.n; S.crudo = { dmp: norm(d.dmp), sw: norm(d.sw) };
  const rel = k => S.ref ? mul(conj(S.ref[k]), S.crudo[k]) : S.crudo[k];
  const q = { dmp: rel('dmp'), sw: rel('sw') };
  objetivo.dmp.copy(sensorAThree(q.dmp)); objetivo.sw.copy(sensorAThree(q.sw));
  const e1 = euler(q.dmp), e2 = euler(q.sw), div = angulo(q.dmp, q.sw);
  S.ult = { e1, e2, div, f: d.f };
  if (S.t0 === null) S.t0 = d.t;
  gr.push((d.t - S.t0) / 1000, e1, e2, div);
  if (E.on) {
    E.n++; const dl = div - E.media; E.media += dl / E.n; E.m2 += dl * (div - E.media); E.max = Math.max(E.max, div);
    E.filas.push([d.n, d.t, d.f || '', ...q.dmp, ...q.sw, div.toFixed(3)].join(','));
  }
}
const con = crearConexion(onDato, (tipo, msg) => {
  if (tipo === 'abierto') S.conectado = true;
  if (tipo === 'cerrado' || tipo === 'error') S.conectado = false;
  S.aviso = msg || (tipo === 'cerrado' ? 'Conexión cerrada.' : '');
});

// ---------- Interfaz ----------
function reiniciarSerie() { S.t0 = null; S.lastN = null; S.perdidos = 0; S.total = 0; gr.limpiar(); }
$('btnWs').onclick = () => { reiniciarSerie(); con.ws($('url').value.trim()); };
$('btnDemo').onclick = () => { reiniciarSerie(); con.demo(); };
$('btnCorte').onclick = () => con.detener();
$('btnIni').onclick = () => {
  Object.assign(E, { on: true, filas: [], t0: performance.now(), n: 0, media: 0, m2: 0, max: 0 });
  con.enviar({ cmd: 'iniciar' }); $('btnIni').disabled = true; $('btnStop').disabled = false;
};
$('btnStop').onclick = () => {
  E.on = false; con.enviar({ cmd: 'detener' }); $('btnIni').disabled = false; $('btnStop').disabled = true;
  $('btnCsv').disabled = !E.filas.length;
};
$('btnCsv').onclick = () => {
  const cab = 'n,t_ms,filtro,dmp_w,dmp_x,dmp_y,dmp_z,sw_w,sw_x,sw_y,sw_z,divergencia_deg';
  const a = Object.assign(document.createElement('a'), {
    href: URL.createObjectURL(new Blob([cab + '\n' + E.filas.join('\n')], { type: 'text/csv' })),
    download: 'ensayo_' + new Date().toISOString().slice(0, 19).replace(/[:T]/g, '-') + '.csv'
  });
  a.click(); URL.revokeObjectURL(a.href);
};
$('filtro').onchange = e => { con.filtro(e.target.value); $('filtroNombre').textContent = e.target.selectedOptions[0].text; };
$('eje').onchange = e => gr.setEje(e.target.value);
$('btnRef').onclick = () => { if (S.crudo) S.ref = { dmp: S.crudo.dmp, sw: S.crudo.sw }; };
$('btnRefOff').onclick = () => { S.ref = null; };
$('btnCal').onclick = () => con.enviar({ cmd: 'calibrar' });
$('btnLimpiar').onclick = () => gr.limpiar();
$('btnCam').onclick = vistaInicial;
$('btnPausa').onclick = e => { const p = e.target.getAttribute('aria-pressed') !== 'true'; e.target.setAttribute('aria-pressed', p); e.target.textContent = p ? 'Reanudar gráficos' : 'Pausar gráficos'; gr.pausar(p); };

setInterval(() => gr.dibujar(), 70);
setInterval(() => {
  const ahora = performance.now();
  S.rx = S.rx.filter(t => ahora - t < 1000);
  const vivo = S.conectado && ahora - S.lastRx < 1000;
  const est = !S.conectado ? ['Desconectado', 'off'] : vivo ? ['Recibiendo datos', 'ok'] : ['Esperando datos', 'wait'];
  $('estado').textContent = est[0]; $('estado').dataset.s = est[1];
  $('aviso').textContent = S.aviso;
  $('hz').textContent = vivo ? S.rx.length + ' Hz' : '—';
  $('muestras').textContent = S.total; $('perdidos').textContent = S.perdidos;
  if (S.ult && vivo) { // no mostrar lecturas viejas como actuales
    const { e1, e2, div } = S.ult;
    [['d', e1], ['s', e2]].forEach(([p, e]) => { $(p + 'R').textContent = f1(e.roll); $(p + 'P').textContent = f1(e.pitch); $(p + 'Y').textContent = f1(e.yaw); });
    $('div').textContent = div.toFixed(1) + '°';
  } else if (!vivo) ['dR', 'dP', 'dY', 'sR', 'sP', 'sY', 'div'].forEach(i => $(i).textContent = '—');
  const s = E.on ? (ahora - E.t0) / 1000 : 0;
  if (E.on) $('tiempo').textContent = String(Math.floor(s / 60)).padStart(2, '0') + ':' + String(Math.floor(s % 60)).padStart(2, '0');
  $('media').textContent = E.n ? E.media.toFixed(2) + '°' : '—';
  $('max').textContent = E.n ? E.max.toFixed(2) + '°' : '—';
  $('desv').textContent = E.n > 1 ? Math.sqrt(E.m2 / (E.n - 1)).toFixed(2) + '°' : '—';
  $('refEstado').textContent = S.ref ? 'Manos alineadas a la pose de referencia.' : 'Sin referencia: se muestra la orientación absoluta.';
}, 200);
