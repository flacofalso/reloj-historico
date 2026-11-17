# Reloj Histórico

Sitio web que muestra, para cada minuto del día, un hecho histórico que ocurrió a esa misma hora.

**Sitio publicado:** https://flacofalso.github.io/reloj-historico/

## Dónde está cada cosa

| Carpeta o archivo | Qué es |
|---|---|
| `docs/` | El sitio publicado. GitHub Pages sirve esta carpeta desde la rama `main`. HTML, CSS y JavaScript sin pasos de compilación. |
| `docs/index.html` | La página principal. |
| `docs/styles.css` | Todo el diseño: colores, tipografía, espaciados. Los valores están como variables al inicio del archivo. |
| `docs/datos.js` | Lectura de la planilla y reglas de las fotos. |
| `docs/app.js` | El reloj, la línea de 24 horas, la galería y el resto de la interacción. |
| `docs/revisar-fotos.html` | Página de trabajo para revisar las fotos de fondo (ver más abajo). |
| `datos/` | Respaldos en CSV de la planilla. El sitio no los usa. |
| `lib/`, `android/`, `ios/`, `web/`… | La versión anterior hecha en Flutter. Ya no se publica. |

## Los hechos

Los hechos se leen en vivo desde una planilla pública de Google Sheets con dos hojas:

- **EventosPorMinutos:** hechos con hora exacta.
- **EventosPorHora:** un hecho de respaldo para cada hora, que se muestra cuando el minuto no tiene uno propio.

Columnas, en este orden: `Hora | Fecha | Título | Descripción | Categoría | ImagenURL | Fuente | Verificado`.

- **Hora:** `8:46` o `08:46`.
- **Fecha:** `2001-09-11`.
- **Verificado:** `TRUE` si la hora está confirmada. Con `FALSE` el sitio agrega "hora por confirmar".

Los cambios en la planilla se ven al recargar el sitio. No hay que tocar el repositorio.

## Cómo cambiar las fotos de fondo

La foto de cada hecho sale de la columna **ImagenURL** de la planilla. Hay dos formas de cambiarla.

### Opción 1: enlace a una foto en internet

Pega en ImagenURL el enlace directo a la imagen, por ejemplo una de Unsplash:

```
https://images.unsplash.com/photo-1518818419601-72c8673f5852?w=1920&h=1080&fit=crop&q=80
```

Si la foto es de Unsplash, el sitio la pide al tamaño de cada pantalla, así que en el celular pesa mucho menos. Los parámetros `w`, `h` y `fit` del enlace se ajustan solos.

### Opción 2: foto guardada en el repositorio

1. En GitHub, entra a la carpeta `docs/`, elige **Add file → Upload files** y sube la foto dentro de una carpeta `fotos/`. Por ejemplo, `docs/fotos/0846.webp`.
2. En ImagenURL escribe la ruta sin `docs/`: `fotos/0846.webp`.
3. GitHub Pages tarda cerca de un minuto en publicar la foto nueva.

Nombrar cada foto con su hora (`0846.webp`) ayuda a encontrarla después.

### Qué foto funciona mejor

- **Horizontal**, de al menos **1920 × 1080 px**.
- **JPG o WebP de menos de 500 KB.** Las fotos pesadas hacen lenta la carga en el celular.
- **El motivo principal al centro o a la derecha.** El texto va abajo a la izquierda y en el celular la foto se recorta por los lados.
- El sitio oscurece la foto un 75 % para que el texto siempre se lea. Las fotos muy oscuras quedan casi negras.
- **Derechos:** usa fotos con licencia que permita publicarlas (Unsplash, Wikimedia Commons, archivos públicos).

### Créditos de la foto (opcional)

Agrega una columna llamada **Créditos** después de la columna Verificado, en las dos hojas. Lo que escribas ahí se muestra junto a la fuente: "Foto: Nombre Apellido / Wikimedia Commons". Las fotos de Wikimedia Commons casi siempre piden este crédito.

### Sin foto

Si ImagenURL está vacía o tiene la foto genérica de montañas que venía en la planilla, el fondo queda liso. Lo mismo pasa si el enlace está roto: el sitio nunca muestra una imagen rota.

### Revisar las fotos

Abre **https://flacofalso.github.io/reloj-historico/revisar-fotos.html** después de hacer cambios. Muestra cada hecho con su foto y separa las que tienen foto propia, las que tienen la genérica, las que no tienen y las que **no cargan** (enlace roto). Con el filtro "Por cambiar" ves solo las pendientes. Al tocar una foto se abre ese minuto en el reloj.

Esta página no aparece en buscadores ni está enlazada desde el sitio.

## Probar el sitio en tu computador

Desde la carpeta `docs/`:

```
python -m http.server 8000
```

Luego abre http://localhost:8000.
