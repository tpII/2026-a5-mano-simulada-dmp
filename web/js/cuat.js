// Cuaterniones [w,x,y,z] y ángulos en grados.
const D = 180 / Math.PI;
export const mul = (a, b) => [
  a[0]*b[0]-a[1]*b[1]-a[2]*b[2]-a[3]*b[3],
  a[0]*b[1]+a[1]*b[0]+a[2]*b[3]-a[3]*b[2],
  a[0]*b[2]-a[1]*b[3]+a[2]*b[0]+a[3]*b[1],
  a[0]*b[3]+a[1]*b[2]-a[2]*b[1]+a[3]*b[0]];
export const conj = q => [q[0], -q[1], -q[2], -q[3]];
export const norm = q => { const n = Math.hypot(...q) || 1; return q.map(v => v / n); };
// Ángulo de la rotación que lleva una orientación a la otra (sin problemas de Euler).
export const angulo = (a, b) =>
  2 * Math.acos(Math.min(1, Math.abs(a[0]*b[0]+a[1]*b[1]+a[2]*b[2]+a[3]*b[3]))) * D;
export const euler = ([w, x, y, z]) => ({
  roll: Math.atan2(2*(w*x+y*z), 1-2*(x*x+y*y)) * D,
  pitch: Math.asin(Math.max(-1, Math.min(1, 2*(w*y-z*x)))) * D,
  yaw: Math.atan2(2*(w*z+x*y), 1-2*(y*y+z*z)) * D });
export const desdeEuler = (r, p, y) => { // grados, orden ZYX
  const [cr, sr, cp, sp, cy, sy] = [Math.cos(r/D/2), Math.sin(r/D/2), Math.cos(p/D/2), Math.sin(p/D/2), Math.cos(y/D/2), Math.sin(y/D/2)];
  return [cr*cp*cy+sr*sp*sy, sr*cp*cy-cr*sp*sy, cr*sp*cy+sr*cp*sy, cr*cp*sy-sr*sp*cy];
};
