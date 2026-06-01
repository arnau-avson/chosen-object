
# 🎨 Chosen Object — Style Guide

> Basado en el diseño de la aplicación `app-complete.html`  
> Fecha de extracción: 2026-06-01

## 1. Paleta de colores

### Colores primarios (marca)
| Variable | Hex | Uso |
|---|---|---|
| `--ink` | `#2E2520` | Texto principal, fondos oscuros |
| `--bone` | `#F2EBE0` | Fondo general de la app |
| `--surface` | `#FFFEFB` | Superficies (tarjetas, formularios) |

### Colores de acento
| Variable | Hex | Uso |
|---|---|---|
| `--accent` | `#B8543C` | Botones primarios, enlaces |
| `--gold` | `#A8893E` | Insignias "verified", dorado |
| `--sage` | `#6B7A5A` | Acento secundario (verde) |

### Tonos neutros (texto y bordes)
| Variable | Hex | Uso |
|---|---|---|
| `--ink-strong` | `#1F1810` | Texto muy oscuro |
| `--ink-soft` | `#4A3F35` | Texto secundario |
| `--muted` | `#9A8C7B` | Texto deshabilitado, etiquetas |
| `--muted-2` | `#C2B5A2` | Fondo de elementos desactivados |
| `--hairline` | `#E0D6C4` | Bordes sutiles |
| `--hairline-2` | `#EBE2D0` | Bordes mas claros |

### Colores semanticos (feedback)
| Variable | Hex | Uso |
|---|---|---|
| `--danger` | `#B5342E` | Errores, acciones destructivas |
| `--success` | `#4A7A4D` | Exito, confirmacion |

### Paletas de fondo (placeholder / gradientes)
Se usan como imagenes de fondo o placeholders. Clases CSS disponibles:

`.p-clay`, `.p-sage`, `.p-blue`, `.p-rose`, `.p-moss`, `.p-amber`, `.p-stone`, `.p-bone`, `.p-ink`.

Ejemplo (`.p-clay`):

```css
background: radial-gradient(circle at 30% 22%, rgba(255, 250, 240, 0.45), transparent 40%),
            radial-gradient(circle at 78% 80%, rgba(110, 72, 42, 0.30), transparent 50%),
            linear-gradient(160deg, #EAD3B8 0%, #C99C70 50%, #8C6342 100%);
```

## 2. Tipografia

### Fuentes
| Variable | Valor | Uso |
|---|---|---|
| `--serif` | `"Fraunces", Georgia, serif` | Titulos, nombres de marca |
| `--sans` | `"Inter", -apple-system, "Helvetica Neue", Arial, sans-serif` | Cuerpo de texto, interfaces |

### Jerarquia visual
| Elemento / Clase | Tamano / Peso | Uso |
|---|---|---|
| `body` | `15px / 1.55` | Texto base |
| `.serif` | `font-family: var(--serif); font-weight: 400;` | Titulos |
| `.stamp` | `11px; letter-spacing: 0.14em; color: var(--muted);` | Texto pequeno (metadatos) |
| `h1, h2` | `clamp(22px, 3.4vw, 32px)` | Titulos principales |
| `.btn` | `12.5px / 500` | Botones |

## 3. Espaciado

Sistema en multiplos de 4px (variables `--s-1` a `--s-10`):

| Variable | Valor | Uso tipico |
|---|---|---|
| `--s-1` | `4px` | Margen minimo, iconos pequenos |
| `--s-2` | `8px` | Separacion entre elementos |
| `--s-3` | `12px` | Padding de inputs, chips |
| `--s-4` | `16px` | Padding general de contenedores |
| `--s-5` | `20px` | Separacion en listas |
| `--s-6` | `24px` | Espaciado entre secciones |
| `--s-7` | `32px` | Padding de modales |
| `--s-8` | `40px` | Margenes grandes |
| `--s-9` | `56px` | Separacion de bloques |
| `--s-10` | `72px` | Espaciado hero |

## 4. Bordes y radios

| Variable | Valor | Uso |
|---|---|---|
| `--r-1` | `2px` | Bordes de inputs pequenos |
| `--r-2` | `4px` | Bordes estandar (tarjetas, modales) |
| `--r-3` | `8px` | Bordes de paneles grandes |
| `--r-pill` | `999px` | Botones redondeados, chips, etiquetas |

## 5. Sombras

No hay variables CSS, pero se usan dos sombras concretas:

```css
/* Toast */
box-shadow: 0 12px 30px rgba(46, 37, 32, 0.18);

/* Pines del mapa */
box-shadow: 0 4px 10px rgba(46, 37, 32, 0.08);
```

## 6. Animaciones y transiciones

| Variable | Valor | Uso |
|---|---|---|
| `--ease` | `cubic-bezier(.4,0,.2,1)` | Curva estandar |
| `--dur-1` | `160ms` | Hover / focus |
| `--dur-2` | `240ms` | Transiciones de elementos |
| `--dur-3` | `360ms` | Entrada/salida de pagina |

## 7. Layout (medidas estructurales)

| Variable | Valor | Uso |
|---|---|---|
| `--topbar-h` | `60px` | Altura de la barra superior |
| `--bottomnav-h` | `76px` | Altura de la navegacion movil inferior |
| `--sidebar-w` | `240px` | Ancho del sidebar en escritorio |
| `--container` | `1280px` | Ancho maximo del contenido principal |

## 8. Componentes base (extracto)

### Boton (`.btn`)

```css
padding: 12px 22px;
border-radius: var(--r-2);
border: 1px solid var(--ink);
font-size: 12.5px;
font-weight: 500;
cursor: pointer;
transition: transform var(--dur-1) var(--ease);
```

Variantes: `.btn-primary` (fondo `--ink`), `.btn-ghost` (fondo transparente).  
Hover: `transform: translateY(-1px);`  
Active: `transform: scale(.98);`

### Chip (`.chip`)

```css
display: inline-flex;
padding: 7px 14px;
border-radius: var(--r-pill);
border: 1px solid var(--hairline);
background: var(--surface);
font-size: 12px;
```

Activo: `background: var(--ink); color: var(--bone);`

### Tarjeta (`.card`)

```css
display: block;
cursor: pointer;
background: transparent;
```

La imagen tiene `aspect-ratio: 4/5`.  
En hover: `.card:hover .photo .img { transform: scale(1.04); }`

### Formulario (`.field`)

```css
margin-bottom: 18px;
```

Label (`.lab`): `font-size: 10px; text-transform: uppercase; letter-spacing: .14em;`  
Input: `padding: 12px 14px; border: 1px solid var(--hairline); border-radius: var(--r-2);`  
Focus: `border-color: var(--ink);`

## 9. Accesibilidad y microinteracciones

- Los elementos interactivos tienen `cursor: pointer`.
- Los inputs tienen `:focus` visible.
- Los modales usan `backdrop-filter: blur(6px)` y animacion de escala.
- Los toasts tienen desvanecimiento automatico y soporte para lectores de pantalla (texto plano).

