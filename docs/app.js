/* Reloj Histórico · lógica del sitio
   Los datos y las reglas de las fotos están en datos.js. */

const $ = id => document.getElementById(id);
const sinMovimiento = matchMedia('(prefers-reduced-motion: reduce)');

const estado = {
  minuto: 0,
  enVivo: true,
  cargado: false,
  porMinuto: new Map(),
  porHora: new Map(),
  ordenados: [],
  actual: undefined,
  filtro: 'todos',
};

/* ---------- Datos ---------- */
async function cargar() {
  const { minutos, horas } = await RH.cargar();
  estado.porMinuto.clear(); estado.porHora.clear();
  minutos.forEach(e => estado.porMinuto.set(e.minuto, e));
  horas.forEach(e => estado.porHora.set(Math.floor(e.minuto / 60), e));
  estado.ordenados = [...estado.porMinuto.values()].sort((a, b) => a.minuto - b.minuto);
  if (!estado.ordenados.length && !estado.porHora.size) throw new Error('planilla vacía');
}

/* ---------- Utilidades ---------- */
const dos = n => String(n).padStart(2, '0');
const fmt = min => `${dos(Math.floor(min / 60))}:${dos(min % 60)}`;
const minutoActual = () => { const d = new Date(); return d.getHours() * 60 + d.getMinutes(); };
const envolver = m => ((m % 1440) + 1440) % 1440;
const eventoPara = min => estado.porMinuto.get(min) || estado.porHora.get(Math.floor(min / 60)) || null;
function vecino(min, dir) {
  const lista = estado.ordenados; if (!lista.length) return null;
  if (dir > 0) return lista.find(e => e.minuto > min) || lista[0];
  for (let i = lista.length - 1; i >= 0; i--) if (lista[i].minuto < min) return lista[i];
  return lista[lista.length - 1];
}
const formatoFecha = new Intl.DateTimeFormat('es-CL', { day: 'numeric', month: 'long', year: 'numeric', timeZone: 'UTC' });
function fecha(iso) {
  const [a, m, d] = iso.split('-').map(Number);
  if (!a || !m || !d) return { texto: iso, hace: '' };
  const anios = new Date().getFullYear() - a;
  return { texto: formatoFecha.format(Date.UTC(a, m - 1, d)), hace: anios > 1 ? `Hace ${anios} años` : anios === 1 ? 'Hace 1 año' : '' };
}
const desplazar = el => el.scrollIntoView({ behavior: sinMovimiento.matches ? 'auto' : 'smooth', block: 'start' });

/* ---------- Fondo ---------- */
const precargadas = new Set();
function precargar(e) {
  const url = e && RH.urlFoto(e.img);
  if (url && !precargadas.has(url)) { precargadas.add(url); new Image().src = url; }
}
// La foto se muestra solo cuando terminó de cargar; si falla, el fondo queda liso
let pedidoFondo = 0;
function ponerFondo(e) {
  const pedido = ++pedidoFondo;
  const url = e ? RH.urlFoto(e.img) : '';
  if (!url) return mostrarCapa('');
  const img = new Image();
  img.onload = () => { if (pedido === pedidoFondo) mostrarCapa(url); };
  img.onerror = () => {
    console.warn(`Reloj Histórico: no carga la foto de las ${fmt(e.minuto)} (${e.titulo}): ${e.img}`);
    if (pedido === pedidoFondo) mostrarCapa('');
  };
  img.src = url;
}
function mostrarCapa(url) {
  const fondo = $('fondo');
  const capa = document.createElement('div');
  capa.className = 'capa';
  if (url) capa.style.backgroundImage = `url("${url.replace(/"/g, '%22')}")`;
  fondo.appendChild(capa);
  requestAnimationFrame(() => requestAnimationFrame(() => capa.classList.add('visible')));
  const antiguas = [...fondo.children].slice(0, -1);
  setTimeout(() => antiguas.forEach(n => n.remove()), 900);
}

/* ---------- Render ---------- */
let tSalida, tFondo;
function render(min, { animar = true } = {}) {
  estado.minuto = min;
  dibujarReloj();
  if (!estado.cargado) return;

  actualizarNavegacion();
  actualizarMarcas();
  actualizarTarjetaActual();

  const e = eventoPara(min);
  if (e === estado.actual) return;
  estado.actual = e;

  const relato = $('relato');
  const llenar = () => {
    $('alcance').textContent = !e ? 'Sin registro' : e.alcance === 'minuto' ? 'En este minuto' : 'En esta hora';
    const cat = $('categoria');
    cat.hidden = !e;
    if (e) { cat.style.setProperty('--cat', e.color); cat.querySelector('span').textContent = e.cat; }
    const f = e ? fecha(e.fecha) : { texto: '', hace: '' };
    $('fechaTexto').textContent = f.texto;
    $('hace').textContent = f.hace;
    $('titulo').textContent = e ? e.titulo : 'Este minuto todavía no tiene un hecho registrado';
    const desc = $('descripcion');
    desc.textContent = e ? e.desc : 'Arrastra las manecillas o usa la línea de 24 horas para ir a otro momento del día.';
    desc.classList.remove('abierta');
    $('mas').textContent = 'Leer la historia completa';
    requestAnimationFrame(() => { $('mas').hidden = desc.scrollHeight <= desc.clientHeight + 2; });
    const notas = [];
    if (e && e.fuente) notas.push(`Fuente: ${e.fuente}`);
    if (e && e.fuente && !e.verificado) notas.push('hora por confirmar');
    if (e && e.img && e.creditos) notas.push(`Foto: ${e.creditos}`);
    $('fuente').textContent = notas.join(' · ');
  };
  clearTimeout(tSalida);
  if (animar && !sinMovimiento.matches) {
    relato.classList.add('saliendo');
    tSalida = setTimeout(() => { llenar(); relato.classList.remove('saliendo'); }, 250);
  } else llenar();

  clearTimeout(tFondo);
  tFondo = setTimeout(() => {
    ponerFondo(e);
    precargar(vecino(min, 1)); precargar(vecino(min, -1));
  }, animar ? 160 : 0);
}

function dibujarReloj() {
  const m = estado.minuto, seg = estado.enVivo ? new Date().getSeconds() : 0;
  $('hora').textContent = fmt(m);
  $('agujaHora').setAttribute('transform', `rotate(${((m / 60) % 12) * 30})`);
  $('agujaMin').setAttribute('transform', `rotate(${(m % 60) * 6 + seg * .1})`);
  $('agujaSeg').setAttribute('transform', `rotate(${seg * 6})`);
  $('cabezal').style.left = `${(m / 1440) * 100}%`;
  for (const id of ['dial', 'pista']) {
    $(id).setAttribute('aria-valuenow', m);
    $(id).setAttribute('aria-valuetext', fmt(m));
  }
}

function actualizarNavegacion() {
  const a = vecino(estado.minuto, -1), s = vecino(estado.minuto, 1);
  $('anteriorTexto').textContent = a ? `${fmt(a.minuto)} ${a.titulo}` : 'Anterior';
  $('siguienteTexto').textContent = s ? `${fmt(s.minuto)} ${s.titulo}` : 'Siguiente';
}

function ponerEnVivo(enVivo) {
  estado.enVivo = enVivo;
  const boton = $('modo');
  boton.dataset.modo = enVivo ? 'vivo' : 'explorar';
  boton.title = enVivo ? 'Estás viendo la hora actual' : 'Volver a la hora actual';
  $('modoTexto').innerHTML = enVivo ? 'En vivo' : 'Volver<span class="largo"> al presente</span>';
  $('agujaSeg').style.opacity = enVivo ? 1 : 0;
  if (enVivo) { history.replaceState(null, '', location.pathname); render(minutoActual()); }
}
function ir(min, opciones) {
  min = envolver(min);
  if (estado.enVivo) ponerEnVivo(false);
  history.replaceState(null, '', `#${fmt(min)}`);
  render(min, opciones);
}
const irVecino = dir => { const e = vecino(estado.minuto, dir); if (e) ir(e.minuto); };

/* ---------- Reloj SVG ---------- */
const NS = 'http://www.w3.org/2000/svg';
function construirReloj() {
  const g = $('marcasMin');
  for (let i = 0; i < 60; i++) {
    const a = i * 6 * Math.PI / 180, mayor = i % 5 === 0;
    const r1 = mayor ? 88 : 94, r2 = 100;
    const l = document.createElementNS(NS, 'line');
    l.setAttribute('x1', r1 * Math.sin(a)); l.setAttribute('y1', -r1 * Math.cos(a));
    l.setAttribute('x2', r2 * Math.sin(a)); l.setAttribute('y2', -r2 * Math.cos(a));
    l.setAttribute('class', 'marca-min' + (mayor ? ' mayor' : ''));
    g.appendChild(l);
  }
}
// Puntos de color en el borde: hechos dentro de la hora que se muestra
function actualizarMarcas() {
  const g = $('marcasEv'); g.replaceChildren();
  const h = Math.floor(estado.minuto / 60);
  estado.ordenados.filter(e => Math.floor(e.minuto / 60) === h).forEach(e => {
    const a = (e.minuto % 60) * 6 * Math.PI / 180;
    const c = document.createElementNS(NS, 'circle');
    c.setAttribute('cx', 81 * Math.sin(a)); c.setAttribute('cy', -81 * Math.cos(a));
    c.setAttribute('r', e.minuto === estado.minuto ? 5 : 3.2);
    c.setAttribute('fill', e.color);
    g.appendChild(c);
  });
}
function configurarReloj() {
  const dial = $('dial');
  let arrastrando = false, ultimo = 0;
  const minutoDelAngulo = ev => {
    const r = dial.getBoundingClientRect();
    const x = ev.clientX - (r.left + r.width / 2), y = ev.clientY - (r.top + r.height / 2);
    let g = Math.atan2(x, -y) * 180 / Math.PI; if (g < 0) g += 360;
    return Math.round(g / 6) % 60;
  };
  const mover = ev => {
    if (!arrastrando) return;
    const m = minutoDelAngulo(ev);
    let delta = m - ultimo;
    if (delta > 30) delta -= 60;   // cruzó las 12 hacia atrás
    if (delta < -30) delta += 60;  // cruzó las 12 hacia adelante
    if (!delta) return;
    ultimo = m;
    ir(estado.minuto + delta);
  };
  dial.addEventListener('pointerdown', ev => {
    arrastrando = true; dial.classList.add('arrastrando'); dial.setPointerCapture(ev.pointerId);
    ultimo = estado.minuto % 60;
    mover(ev);
  });
  dial.addEventListener('pointermove', mover);
  const fin = () => { arrastrando = false; dial.classList.remove('arrastrando'); };
  dial.addEventListener('pointerup', fin); dial.addEventListener('pointercancel', fin);
  dial.addEventListener('keydown', ev => {
    const paso = { ArrowRight: 1, ArrowUp: 1, ArrowLeft: -1, ArrowDown: -1, PageUp: 60, PageDown: -60 }[ev.key];
    if (paso) { ev.preventDefault(); ir(estado.minuto + paso); }
  });
}

/* ---------- Línea de 24 horas ---------- */
function configurarPista() {
  const pista = $('pista'), globo = $('globo'), evs = $('pistaEventos');
  evs.replaceChildren();
  estado.ordenados.forEach(e => {
    const d = document.createElement('div');
    d.className = 'ev'; d.style.left = `${(e.minuto / 1440) * 100}%`; d.style.setProperty('--cat', e.color);
    evs.appendChild(d);
  });
  [0, 3, 6, 9, 12, 15, 18, 21].forEach(h => {
    const s = document.createElement('div');
    s.className = 'marca-hora leyenda-4 cifras'; s.style.left = `${(h / 24) * 100}%`; s.textContent = dos(h);
    evs.appendChild(s);
  });
  if (pista.dataset.listo) return;
  pista.dataset.listo = '1';
  const minutoEn = ev => {
    const r = pista.getBoundingClientRect();
    return Math.max(0, Math.min(1439, Math.round(((ev.clientX - r.left) / r.width) * 1440)));
  };
  // Cerca de un hecho, la línea se "imanta" a él
  const imantar = min => {
    if (!estado.ordenados.length) return min;
    const cerca = estado.ordenados.reduce((m, e) => Math.abs(e.minuto - min) < Math.abs(m.minuto - min) ? e : m);
    const tolerancia = 1440 / pista.getBoundingClientRect().width * 6;
    return Math.abs(cerca.minuto - min) <= tolerancia ? cerca.minuto : min;
  };
  let presionado = false;
  pista.addEventListener('pointerdown', ev => { presionado = true; pista.setPointerCapture(ev.pointerId); ir(imantar(minutoEn(ev))); });
  pista.addEventListener('pointermove', ev => {
    const min = imantar(minutoEn(ev)), e = estado.porMinuto.get(min);
    const ancho = pista.getBoundingClientRect().width;
    globo.hidden = false;
    globo.style.left = `${Math.min(Math.max((min / 1440) * ancho, 100), ancho - 100)}px`;
    globo.replaceChildren();
    const b = document.createElement('b'); b.className = 'cifras'; b.textContent = fmt(min);
    globo.append(b, e ? e.titulo : '');
    if (presionado) ir(min);
  });
  const soltar = () => { presionado = false; };
  pista.addEventListener('pointerup', soltar); pista.addEventListener('pointercancel', soltar);
  pista.addEventListener('pointerleave', () => { globo.hidden = true; });
  pista.addEventListener('keydown', ev => {
    if (ev.key === 'ArrowRight') { ev.preventDefault(); irVecino(1); }
    if (ev.key === 'ArrowLeft') { ev.preventDefault(); irVecino(-1); }
  });
}

/* ---------- Galería ---------- */
function construirGaleria() {
  const lista = estado.ordenados;
  $('conteo').textContent = String(lista.length);

  // Filtros: solo temas presentes, del más al menos frecuente
  const temas = new Map();
  lista.forEach(e => { const t = temas.get(e.clave) || { nombre: e.cat, color: e.color, n: 0 }; t.n++; temas.set(e.clave, t); });
  const filtros = $('filtros'); filtros.replaceChildren();
  const chip = (clave, nombre, n, color) => {
    const b = document.createElement('button');
    b.className = 'chip titulo-4'; b.dataset.clave = clave;
    b.setAttribute('aria-pressed', String(estado.filtro === clave));
    if (color) { const i = document.createElement('i'); i.style.setProperty('--cat', color); b.append(i); }
    const n2 = document.createElement('span'); n2.className = 'n cifras'; n2.textContent = n;
    b.append(nombre + ' ', n2);
    b.addEventListener('click', () => filtrar(clave));
    filtros.append(b);
  };
  chip('todos', 'Todos', lista.length);
  [...temas.entries()].sort((a, b) => b[1].n - a[1].n).forEach(([clave, t]) => chip(clave, t.nombre, t.n, t.color));

  const ul = $('tarjetas'); ul.replaceChildren();
  lista.forEach(e => {
    const li = document.createElement('li');
    li.dataset.clave = e.clave;
    const b = document.createElement('button');
    b.className = 'tarjeta'; b.dataset.minuto = e.minuto;
    const cabeza = document.createElement('span'); cabeza.className = 'tarjeta-cabeza';
    const hora = document.createElement('span'); hora.className = 'tarjeta-hora encabezado-5 cifras'; hora.textContent = fmt(e.minuto);
    const cat = document.createElement('span'); cat.className = 'categoria leyenda-1'; cat.style.setProperty('--cat', e.color);
    cat.append(document.createElement('i'), e.cat);
    cabeza.append(hora, cat);
    const titulo = document.createElement('span'); titulo.className = 'tarjeta-titulo titulo-2'; titulo.textContent = e.titulo;
    const f = document.createElement('span'); f.className = 'tarjeta-fecha leyenda-2'; f.textContent = fecha(e.fecha).texto;
    b.append(cabeza, titulo, f);
    b.addEventListener('click', () => { ir(e.minuto, { animar: false }); desplazar($('inicio')); });
    li.append(b);
    ul.append(li);
  });
  const vacio = document.createElement('li');
  vacio.className = 'vacio'; vacio.id = 'vacio'; vacio.hidden = true;
  const p = document.createElement('p'); p.className = 'cuerpo-3'; p.textContent = 'No hay hechos de este tema todavía.';
  const todos = document.createElement('button'); todos.className = 'boton boton-secundario boton-sm'; todos.textContent = 'Muestra todos los temas';
  todos.addEventListener('click', () => filtrar('todos'));
  vacio.append(p, todos);
  ul.append(vacio);
  actualizarTarjetaActual();
}
function filtrar(clave) {
  estado.filtro = clave;
  $('filtros').querySelectorAll('.chip').forEach(c => c.setAttribute('aria-pressed', String(c.dataset.clave === clave)));
  let visibles = 0;
  $('tarjetas').querySelectorAll('li[data-clave]').forEach(li => {
    const ver = clave === 'todos' || li.dataset.clave === clave;
    li.hidden = !ver; if (ver) visibles++;
  });
  const vacio = $('vacio'); if (vacio) vacio.hidden = visibles > 0;
}
function actualizarTarjetaActual() {
  $('tarjetas').querySelectorAll('.tarjeta').forEach(t => {
    if (Number(t.dataset.minuto) === estado.minuto) t.setAttribute('aria-current', 'true');
    else t.removeAttribute('aria-current');
  });
}

/* ---------- Compartir ---------- */
function aviso(texto) {
  const a = $('aviso'); a.textContent = texto; a.classList.add('visible');
  clearTimeout(aviso.t); aviso.t = setTimeout(() => a.classList.remove('visible'), 2600);
}
async function compartir() {
  const min = estado.minuto, e = estado.actual;
  const url = `${location.origin}${location.pathname}#${fmt(min)}`;
  const texto = e ? `A las ${fmt(min)}: ${e.titulo} (${e.fecha.slice(0, 4)})` : `${fmt(min)} en Reloj Histórico`;
  if (navigator.share) {
    try { await navigator.share({ title: 'Reloj Histórico', text: texto, url }); return; }
    catch (err) { if (err.name === 'AbortError') return; }
  }
  try { await navigator.clipboard.writeText(`${texto}\n${url}`); aviso('Copiamos el enlace de este minuto.'); }
  catch { aviso(`Copia este enlace: ${url}`); }
}

/* ---------- Menú del celular ---------- */
function configurarMenu() {
  const boton = $('menuBoton'), panel = $('menuPanel');
  const abrir = abierto => {
    document.body.classList.toggle('menu-abierto', abierto);
    document.body.style.overflow = abierto ? 'hidden' : '';
    boton.setAttribute('aria-expanded', String(abierto));
    boton.setAttribute('aria-label', abierto ? 'Cerrar menú' : 'Abrir menú');
  };
  boton.addEventListener('click', () => abrir(!document.body.classList.contains('menu-abierto')));
  panel.addEventListener('click', ev => { if (ev.target.closest('a')) abrir(false); });
  document.addEventListener('keydown', ev => { if (ev.key === 'Escape' && document.body.classList.contains('menu-abierto')) { abrir(false); boton.focus(); } });
  matchMedia('(min-width: 761px)').addEventListener('change', ev => { if (ev.matches) abrir(false); });
}

/* ---------- Animaciones al hacer scroll ---------- */
function configurarApariciones() {
  const elementos = document.querySelectorAll('.aparece');
  if (!('IntersectionObserver' in window)) { elementos.forEach(el => el.classList.add('visible')); return; }
  const io = new IntersectionObserver(entradas => entradas.forEach(en => {
    if (en.isIntersecting) { en.target.classList.add('visible'); io.unobserve(en.target); }
  }), { threshold: .15 });
  elementos.forEach(el => io.observe(el));

  // Frase destacada: cada palabra se enciende al cruzar el 60 % de la pantalla
  const frase = $('frase');
  const palabras = frase.textContent.trim().split(/\s+/);
  frase.replaceChildren(...palabras.flatMap((p, i) => {
    const s = document.createElement('span'); s.className = 'palabra'; s.textContent = p;
    return i ? [' ', s] : [s];
  }));
  const ioPalabras = new IntersectionObserver(entradas => entradas.forEach(en => {
    if (en.isIntersecting) { en.target.classList.add('activa'); ioPalabras.unobserve(en.target); }
  }), { rootMargin: '0px 0px -40% 0px' });
  frase.querySelectorAll('.palabra').forEach(s => ioPalabras.observe(s));
}

/* ---------- Inicio ---------- */
function minutoDelEnlace() {
  const m = location.hash.match(/^#(\d{1,2})[:\-](\d{2})$/);
  if (!m) return null;
  const h = +m[1], mi = +m[2];
  return h < 24 && mi < 60 ? h * 60 + mi : null;
}
function mostrarError() {
  $('alcance').textContent = 'Sin conexión con la planilla';
  $('titulo').textContent = 'No pudimos cargar los hechos';
  $('descripcion').textContent = 'Revisa tu conexión a internet y vuelve a intentarlo. El reloj sigue marcando la hora mientras tanto.';
  const ul = $('tarjetas'); ul.replaceChildren();
  const li = document.createElement('li'); li.className = 'vacio';
  const p = document.createElement('p'); p.className = 'cuerpo-3'; p.textContent = 'No pudimos cargar la lista de hechos.';
  const b = document.createElement('button'); b.className = 'boton boton-secundario boton-sm'; b.textContent = 'Vuelve a intentarlo';
  b.addEventListener('click', () => { ul.replaceChildren(...Array.from({ length: 4 }, () => Object.assign(document.createElement('li'), { className: 'esqueleto' }))); iniciarDatos(); });
  li.append(p, b); ul.append(li);
}
async function iniciarDatos() {
  try { await cargar(); }
  catch (err) { console.error('Reloj Histórico: no se pudo leer la planilla', err); mostrarError(); return; }
  estado.cargado = true;
  configurarPista();
  construirGaleria();
  render(estado.minuto, { animar: false });
}

// El sitio anterior (Flutter) instalaba un service worker que guardaba copias de la app.
// Se elimina para que nadie quede viendo la versión antigua.
function limpiarVersionAnterior() {
  if (!('serviceWorker' in navigator)) return;
  navigator.serviceWorker.getRegistrations().then(rs => rs.forEach(r => r.unregister())).catch(() => {});
  if ('caches' in window) caches.keys().then(ks => ks.filter(k => k.startsWith('flutter')).forEach(k => caches.delete(k))).catch(() => {});
}

function iniciar() {
  limpiarVersionAnterior();
  construirReloj();
  configurarReloj();
  configurarMenu();
  configurarApariciones();

  $('modo').addEventListener('click', () => { if (!estado.enVivo) ponerEnVivo(true); });
  $('compartir').addEventListener('click', compartir);
  $('anterior').addEventListener('click', () => irVecino(-1));
  $('siguiente').addEventListener('click', () => irVecino(1));
  $('mas').addEventListener('click', () => {
    const abierta = $('descripcion').classList.toggle('abierta');
    $('mas').textContent = abierta ? 'Mostrar menos' : 'Leer la historia completa';
  });
  document.addEventListener('keydown', ev => {
    if (ev.altKey || ev.ctrlKey || ev.metaKey || !estado.cargado) return;
    if (ev.target.closest('.dial, .pista, input, textarea, select, summary') || document.body.classList.contains('menu-abierto')) return;
    if (ev.key === 'ArrowRight') irVecino(1);
    if (ev.key === 'ArrowLeft') irVecino(-1);
    if (ev.key === 'Escape' && !estado.enVivo) ponerEnVivo(true);
  });
  // Deslizar sobre el texto en el celular: hecho anterior o siguiente
  let x0 = null;
  $('relato').addEventListener('touchstart', ev => { x0 = ev.touches[0].clientX; }, { passive: true });
  $('relato').addEventListener('touchend', ev => {
    if (x0 === null || !estado.cargado) return;
    const dx = ev.changedTouches[0].clientX - x0; x0 = null;
    if (Math.abs(dx) > 50) irVecino(dx < 0 ? 1 : -1);
  });
  window.addEventListener('hashchange', () => { const m = minutoDelEnlace(); if (m !== null && m !== estado.minuto) ir(m); });

  const delEnlace = minutoDelEnlace();
  if (delEnlace !== null) { ponerEnVivo(false); render(delEnlace, { animar: false }); }
  else render(minutoActual(), { animar: false });

  setInterval(() => {
    if (!estado.enVivo) return;
    const m = minutoActual();
    if (m !== estado.minuto) render(m); else dibujarReloj();
  }, 1000);

  iniciarDatos();
}
iniciar();
