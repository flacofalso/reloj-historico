/* Revisión de fotos: muestra la foto de fondo de cada hecho y avisa cuáles faltan o no cargan. */
(() => {
  const $ = id => document.getElementById(id);
  const dos = n => String(n).padStart(2, '0');
  const fmt = min => `${dos(Math.floor(min / 60))}:${dos(min % 60)}`;
  const ETIQUETAS = { propia: 'Foto propia', generica: 'Foto genérica', vacia: 'Sin foto', rota: 'No carga' };
  let filtro = 'todas';
  const items = [];

  function contar() {
    const n = { propia: 0, generica: 0, vacia: 0, rota: 0 };
    items.forEach(it => n[it.estado]++);
    $('nPropia').textContent = n.propia; $('nGenerica').textContent = n.generica;
    $('nVacia').textContent = n.vacia; $('nRota').textContent = n.rota;
  }
  function aplicarFiltro() {
    items.forEach(it => {
      it.li.hidden = filtro === 'faltan' ? it.estado === 'propia' : filtro === 'rota' ? it.estado !== 'rota' : false;
    });
    document.querySelectorAll('#filtros .chip').forEach(c => c.setAttribute('aria-pressed', String(c.dataset.filtro === filtro)));
  }
  function marcar(it, estado) {
    it.estado = estado;
    it.li.dataset.estado = estado;
    it.etiqueta.textContent = ETIQUETAS[estado];
    contar(); aplicarFiltro();
  }

  function tarjeta(e) {
    const li = document.createElement('li'); li.className = 'revision-item';
    const enlace = document.createElement('a'); enlace.className = 'miniatura'; enlace.href = `./#${fmt(e.minuto)}`;
    enlace.setAttribute('aria-label', `Ver las ${fmt(e.minuto)} en el reloj`);
    const it = { li, estado: e.foto, etiqueta: document.createElement('span') };
    const url = RH.urlFoto(e.imgOriginal, 480, 270);
    if (url) {
      const img = document.createElement('img');
      img.decoding = 'async'; // sin carga diferida: así se detectan todas las fotos rotas de inmediato img.alt = ''; img.width = 480; img.height = 270;
      img.addEventListener('error', () => {
        const v = document.createElement('span'); v.className = 'miniatura-vacia leyenda-2'; v.textContent = 'La foto no carga';
        img.replaceWith(v);
        marcar(it, 'rota');
      });
      img.src = url;
      enlace.append(img);
    } else {
      const v = document.createElement('span'); v.className = 'miniatura-vacia leyenda-2'; v.textContent = 'Fondo liso';
      enlace.append(v);
    }
    const cuerpo = document.createElement('div'); cuerpo.className = 'revision-cuerpo';
    const cabeza = document.createElement('div'); cabeza.className = 'tarjeta-cabeza';
    const hora = document.createElement('span'); hora.className = 'titulo-3 cifras';
    hora.textContent = `${fmt(e.minuto)} · ${e.alcance === 'minuto' ? 'Por minuto' : 'Por hora'}`;
    it.etiqueta.className = 'estado leyenda-3';
    cabeza.append(hora, it.etiqueta);
    const titulo = document.createElement('p'); titulo.className = 'titulo-4'; titulo.textContent = e.titulo;
    const dir = document.createElement('p'); dir.className = 'revision-url leyenda-4';
    dir.textContent = e.imgOriginal || 'La columna ImagenURL está vacía';
    cuerpo.append(cabeza, titulo, dir);
    if (e.creditos) { const c = document.createElement('p'); c.className = 'leyenda-4'; c.textContent = `Créditos: ${e.creditos}`; cuerpo.append(c); }
    li.append(enlace, cuerpo);
    li.dataset.estado = e.foto;
    it.etiqueta.textContent = ETIQUETAS[e.foto];
    items.push(it);
    return li;
  }

  async function iniciar() {
    document.querySelectorAll('#filtros .chip').forEach(c => c.addEventListener('click', () => { filtro = c.dataset.filtro; aplicarFiltro(); }));
    const lista = $('lista');
    try {
      const { minutos, horas } = await RH.cargar();
      const todos = [...minutos, ...horas].sort((a, b) => a.minuto - b.minuto || (a.alcance === 'minuto' ? -1 : 1));
      lista.replaceChildren(...todos.map(tarjeta));
      contar(); aplicarFiltro();
    } catch (err) {
      const li = document.createElement('li'); li.className = 'vacio';
      li.textContent = 'No pudimos leer la planilla. Revisa tu conexión y recarga la página.';
      lista.replaceChildren(li);
      console.error(err);
    }
  }
  iniciar();
})();
