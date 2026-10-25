import * as THREE from 'three';

// Material degradé + grilla de malla, inspirado en la mano de referencia.
const VS = `varying vec3 vN; varying vec3 vNv; varying vec2 vUv;
void main(){ vUv = uv; vN = normalize(mat3(modelMatrix) * normal); vNv = normalize(normalMatrix * normal);
gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0); }`;
const FS = `uniform vec3 c1; uniform vec3 c2; uniform vec3 c3; uniform vec2 grid;
varying vec3 vN; varying vec3 vNv; varying vec2 vUv;
void main(){
  float a = vN.y * .5 + .5, b = vN.x * .5 + .5;
  vec3 c = mix(mix(c1, c2, a), c3, smoothstep(.4, 1., b));
  c += pow(1. - abs(vNv.z), 2.5) * .35;
  vec2 g = abs(fract(vUv * grid - .5) - .5) / fwidth(vUv * grid);
  float l = 1. - min(min(g.x, g.y), 1.);
  gl_FragColor = vec4(mix(c, vec3(1., .88, .55), l * .6), 1.);
}`;

export const PALETAS = {
  dmp: ['#1d63ff', '#19d3c5', '#8cf06a'],
  sw: ['#7a2bff', '#ff4f9a', '#ffa23a'],
};

function material(paleta, grid) {
  return new THREE.ShaderMaterial({
    vertexShader: VS, fragmentShader: FS,
    uniforms: {
      c1: { value: new THREE.Color(paleta[0]) }, c2: { value: new THREE.Color(paleta[1]) },
      c3: { value: new THREE.Color(paleta[2]) }, grid: { value: new THREE.Vector2(...grid) } },
  });
}

// Mano con dedos en postura fija: solo representa la orientación global.
// Caja con bordes redondeados: empuja cada vértice fuera de una caja interior y recalcula la normal.
function cajaRedonda(w, h, d, r) {
  const g = new THREE.BoxGeometry(w, h, d, 10, 10, 4), p = g.attributes.position, n = g.attributes.normal;
  const hi = [w / 2 - r[0], h / 2 - r[1], d / 2 - r[2]], v = new THREE.Vector3();
  for (let i = 0; i < p.count; i++) {
    v.fromBufferAttribute(p, i);
    const c = new THREE.Vector3(...v.toArray().map((x, k) => Math.max(-hi[k], Math.min(hi[k], x))));
    const u = v.clone().sub(c).normalize();
    n.setXYZ(i, ...new THREE.Vector3(u.x / r[0], u.y / r[1], u.z / r[2]).normalize().toArray());
    p.setXYZ(i, c.x + u.x * r[0], c.y + u.y * r[1], c.z + u.z * r[2]);
  }
  return g;
}

export function crearMano(paleta) {
  const raiz = new THREE.Group();
  const add = (padre, geo, grid, pos) => {
    const m = new THREE.Mesh(geo, material(paleta, grid));
    m.position.copy(pos); padre.add(m); return m;
  };
  add(raiz, cajaRedonda(1.7, 1.9, .5, [.3, .3, .2]), [10, 10], new THREE.Vector3());
  add(raiz, new THREE.CylinderGeometry(.5, .6, 1.3, 14, 5, false), [14, 5], new THREE.Vector3(0, -1.5, 0));

  // x base, y base, ángulo (rad), radio, largo de falanges
  const dedos = [
    [-.62, .95, 0.03, .17, [.5, .36, .28]], [-.2, .95, 0, .17, [.58, .4, .3]],
    [.22, .95, -.03, .16, [.54, .38, .28]], [.62, .9, -.08, .14, [.42, .3, .24]],
    [.9, -.35, -.95, .2, [.4, .34, .28]],
  ];
  for (const [x, y, ang, r, falanges] of dedos) {
    const base = new THREE.Group(); base.position.set(x, y, 0); base.rotation.z = ang; raiz.add(base);
    let padre = base;
    falanges.forEach((largo, i) => {
      const art = new THREE.Group(); art.rotation.x = i === 0 ? 0.05 : 0.2; padre.add(art);
      add(art, new THREE.CapsuleGeometry(r * (1 - i * .08), largo, 4, 12), [12, 6], new THREE.Vector3(0, largo / 2 + r * .5, 0));
      const sig = new THREE.Group(); sig.position.y = largo + r * 1.3; art.add(sig); padre = sig;
    });
  }
  return raiz;
}
