const MAX = 400, EJES = ['roll', 'pitch', 'yaw'];
const unir = (a, v) => (a.length ? v + 360 * Math.round((a[a.length - 1] - v) / 360) : v);

// Dos gráficos: A) orientación de ambas rutas en un eje, B) divergencia angular.
export function crearGraficos(cA, cB) {
  Chart.defaults.color = '#8fb0c9'; Chart.defaults.borderColor = '#17395a';
  const H = { t: [], div: [], dmp: {}, sw: {} };
  EJES.forEach(e => { H.dmp[e] = []; H.sw[e] = []; });
  let eje = 'roll', pausa = false;
  const opc = (unidad) => ({
    animation: false, responsive: true, maintainAspectRatio: false, pointRadius: 0, borderWidth: 1.8,
    interaction: { mode: 'nearest', intersect: false },
    scales: { x: { ticks: { maxTicksLimit: 6, callback: (_, i) => (+H.t[i]).toFixed(0) + ' s' } },
              y: { title: { display: true, text: unidad } } },
    plugins: { legend: { labels: { boxWidth: 12 } } },
  });
  const ds = (label, color, data) => ({ label, borderColor: color, backgroundColor: color, data, tension: .15 });
  const A = new Chart(cA, { type: 'line', options: opc('grados'), data: { labels: H.t, datasets: [
    ds('DMP', '#19d3c5', H.dmp[eje]), ds('Software', '#ffa23a', H.sw[eje])] } });
  const B = new Chart(cB, { type: 'line', options: opc('grados'), data: { labels: H.t, datasets: [
    ds('Divergencia', '#ff5d73', H.div)] } });
  return {
    push(t, e1, e2, div) {
      EJES.forEach(e => { H.dmp[e].push(unir(H.dmp[e], e1[e])); H.sw[e].push(unir(H.sw[e], e2[e])); });
      H.t.push(t); H.div.push(div);
      if (H.t.length > MAX) { H.t.shift(); H.div.shift(); EJES.forEach(e => { H.dmp[e].shift(); H.sw[e].shift(); }); }
    },
    dibujar() { if (!pausa) { A.update('none'); B.update('none'); } },
    setEje(e) { eje = e; A.data.datasets[0].data = H.dmp[e]; A.data.datasets[1].data = H.sw[e]; A.update('none'); },
    limpiar() { H.t.length = 0; H.div.length = 0; EJES.forEach(e => { H.dmp[e].length = 0; H.sw[e].length = 0; }); A.update('none'); B.update('none'); },
    pausar(v) { pausa = v; },
  };
}
