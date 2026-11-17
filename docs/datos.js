/* Reloj Histórico · lectura de datos (la usan el sitio y la página de revisión de fotos)

   Columnas de la planilla, en este orden:
   Hora | Fecha | Título | Descripción | Categoría | ImagenURL | Fuente | Verificado
   Columna opcional, en cualquier posición después de esas: "Créditos" (autor de la foto).

   ImagenURL acepta:
   - Un enlace completo: https://images.unsplash.com/photo-...  o cualquier otra imagen pública.
   - Una ruta a una foto guardada en el repositorio, dentro de docs/: fotos/0846.webp
   - Vacío o la foto genérica de Unsplash: el fondo queda liso. */

const RH = (() => {
  const PLANILLA = '1TdXNlzU3ofoM9FyzBiQaHNyeZosisg2IksE-IzNMXLc';
  const IMG_GENERICA = 'photo-1506905925346-21bda4d32df4';
  const COLORES = {
    guerra: '#E5484D', ciencia: '#4C9AFF', politico: '#A985F5', desastre: '#F2A33A',
    terrorismo: '#C2333C', tecnologia: '#2FB8A6', cultura: '#EC6AA8', deporte: '#56C271',
  };

  function leerCsv(texto) {
    const filas = []; let fila = [], campo = '', comillas = false;
    for (let i = 0; i < texto.length; i++) {
      const c = texto[i];
      if (comillas) {
        if (c === '"') { if (texto[i + 1] === '"') { campo += '"'; i++; } else comillas = false; }
        else campo += c;
      } else if (c === '"') comillas = true;
      else if (c === ',') { fila.push(campo); campo = ''; }
      else if (c === '\n') { fila.push(campo); filas.push(fila); fila = []; campo = ''; }
      else if (c !== '\r') campo += c;
    }
    if (campo || fila.length) { fila.push(campo); filas.push(fila); }
    return filas;
  }
  const normalizar = t => t.trim().toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '');

  function estadoFoto(img) {
    if (!img) return 'vacia';
    if (img.includes(IMG_GENERICA)) return 'generica';
    return 'propia';
  }

  function aEventos(texto, alcance) {
    const [cabecera = [], ...filas] = leerCsv(texto);
    const colCreditos = cabecera.findIndex((t, i) => i >= 8 && normalizar(t).startsWith('credito'));
    return filas.filter(f => f.length >= 8 && /^\d{1,2}:\d{2}/.test(f[0].trim())).map(f => {
      const [h, m] = f[0].trim().split(':').map(Number);
      const imgOriginal = f[5].trim();
      const foto = estadoFoto(imgOriginal);
      return {
        minuto: h * 60 + m, alcance,
        fecha: f[1].trim(), titulo: f[2].trim(), desc: f[3].trim(),
        cat: f[4].trim(), clave: normalizar(f[4]), color: COLORES[normalizar(f[4])] || '#E8B65A',
        imgOriginal, foto, img: foto === 'propia' ? imgOriginal : '',
        creditos: colCreditos >= 0 ? (f[colCreditos] || '').trim() : '',
        fuente: f[6].trim(), verificado: f[7].trim().toUpperCase() === 'TRUE',
      };
    }).filter(e => e.minuto >= 0 && e.minuto < 1440);
  }

  async function cargar() {
    const url = hoja => `https://docs.google.com/spreadsheets/d/${PLANILLA}/gviz/tq?tqx=out:csv&sheet=${hoja}`;
    const leer = async hoja => {
      const r = await fetch(url(hoja), { cache: 'no-store' });
      if (!r.ok) throw new Error(`HTTP ${r.status}`);
      return r.text();
    };
    const [m, h] = await Promise.all([leer('EventosPorMinutos'), leer('EventosPorHora')]);
    return { minutos: aEventos(m, 'minuto'), horas: aEventos(h, 'hora') };
  }

  /* Dirección final de la foto.
     - Rutas relativas (fotos/0846.webp) se resuelven desde la raíz del sitio.
     - Fotos de Unsplash se piden al tamaño de la pantalla: en el celular pesan mucho menos. */
  function urlFoto(img, ancho = innerWidth, alto = innerHeight) {
    if (!img) return '';
    let u;
    try { u = new URL(img, document.baseURI); } catch { return ''; }
    if (u.hostname === 'images.unsplash.com') {
      const dpr = Math.min(devicePixelRatio || 1, 2);
      let w = ancho * dpr, h = alto * dpr;
      const f = Math.min(1, 1920 / Math.max(w, h));
      u.searchParams.set('w', String(Math.round(w * f)));
      u.searchParams.set('h', String(Math.round(h * f)));
      u.searchParams.set('fit', 'crop');
      u.searchParams.set('auto', 'format');
      if (!u.searchParams.has('q')) u.searchParams.set('q', '80');
    }
    return u.href;
  }

  return { cargar, urlFoto, normalizar };
})();
