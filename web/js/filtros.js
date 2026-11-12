// Identificadores compartidos por el firmware, la demo y la interfaz.
const NOMBRES = {
  comp: 'Complementario',
  mag: 'Complementario + magnetómetro',
  kalman: 'Kalman'
};

export function nombreFiltro(filtro) {
  return typeof filtro === 'string' &&
    Object.prototype.hasOwnProperty.call(NOMBRES, filtro)
    ? NOMBRES[filtro]
    : null;
}

// Separa la selección del usuario del filtro confirmado por los datos.
export function crearSeguimientoFiltro() {
  let solicitado = 'comp';
  let confirmado = null;
  let esperando = true;
  let desconocido = false;

  return {
    solicitar(filtro) {
      if (!nombreFiltro(filtro)) return false;
      solicitado = filtro;
      esperando = true;
      desconocido = false;
      return true;
    },
    recibir(filtro) {
      desconocido = !nombreFiltro(filtro);
      confirmado = desconocido ? null : filtro;
      if (desconocido) return;
      // Sin solicitud pendiente, refleja cambios hechos por otro cliente.
      if (!esperando) solicitado = filtro;
      if (confirmado === solicitado) esperando = false;
    },
    reiniciar() {
      confirmado = null;
      esperando = true;
      desconocido = false;
    },
    estado() {
      return { solicitado, confirmado, esperando, desconocido };
    }
  };
}
