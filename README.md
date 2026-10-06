# Introducing Portolan … for CNG

A five-minute lightning talk for the [Cloud-Native Geospatial](https://cloudnativegeo.org)
conference, built on the
[CNG lightning talk template](https://github.com/cloudnativegeo/lightning-talk-quarto-TEMPLATE)
([Quarto](https://quarto.org/docs/presentations/revealjs/) + RevealJS) and themed to the
Portolan brand.

Nineteen slides. The title and the closing slide sit still; the seventeen in between
auto-advance every 15 seconds, which is 4 minutes 15 seconds of running time.

```bash
uv sync
uv pip install quarto-cli
uv run quarto preview
```

To stop the deck advancing while you edit, put `?autoSlide=0` right after the `/` and
**before** the `#` — `http://localhost:4200/?autoSlide=0#/slide-08`. Anything after the
`#` is ignored. The countdown bar hides itself when auto-advance is off.

## Speaker notes

Press **S** for RevealJS's speaker view: the notes, the next slide, a clock, and an
elapsed timer. Notes are authored in `index.qmd` as `::: {.notes}` blocks, one per
slide, holding the script in the order it is spoken.

The title slide is a special case. Its notes and its `#title-block` markup are authored
above the first `##`, which puts them in a slide of their own; `animations.html` moves
both onto Quarto's title slide before RevealJS initializes and deletes the leftover.

## Layout

| File | What's in it |
|---|---|
| `index.qmd` | Content: every slide, every speaker note |
| `custom.scss` | The Portolan theme and all slide styling |
| `head.html` | Favicon and `@font-face` rules (see below) |
| `animations.html` | Title-slide fix-up and the 15-second countdown bar |
| `media/` | The screen recordings, each cut to 15 seconds |
| `fonts/` | Hanken Grotesk and JetBrains Mono, from `portolan-ops/brand/fonts` |
| `images/brand/` | Portolan logos, from `portolan-ops/brand/logos` |
| `scripts/build-media.sh` | Rebuilds `media/` from the raw recordings |

Two things are worth knowing before you edit:

- **The fonts are declared in `head.html`, not in `custom.scss`.** Quarto compiles the
  theme to `index_files/libs/revealjs/dist/theme/`, five directories down, so a relative
  `url()` in the SCSS resolves against the wrong folder. In the head they resolve
  against `index.html` and keep working under a GitHub Pages subpath.
- **`media/` and `fonts/` are listed under `resources:` in `_quarto.yml`.** They are
  referenced from raw HTML blocks and from CSS, so Quarto does not discover them on its
  own and would otherwise leave them out of `docs/`.

## Brand

The palette, the type, and the standing rules come from
[`portolan-ops/brand`](https://github.com/portolan-sdi/portolan-ops): cream paper
`#fcfcfa`, near-black ink `#16170f`, one accent (`#4163cc`) and no second one, square
corners, flat surfaces, rules instead of cards, no gradients, light mode only. Read
`brand/README.md` there before changing any of it.

## Rebuilding the media

The raw screen recordings are large — several hundred megabytes of GIF — so they are not
in the repo. `scripts/build-media.sh` cuts each one down to the 15 seconds its slide
gets and encodes it as H.264:

```bash
./scripts/build-media.sh "/path/to/raw/recordings"
```

It needs `ffmpeg`, and it expects the raws under their original names. Each cut and the
reason for it is commented in the script.

## Slide shapes

Three kinds of slide, and that is the whole system:

- **Full bleed** (`.bleed`): a screen recording and nothing else — no header, no
  caption, no border. The video is shown at full width, pinned to the top, so
  nothing is ever lost off the sides; a recording wider than 16:9 leaves a band of
  paper at the bottom. Record at 16:9 and the band disappears.
- **Headed** (`.slide-head` + `.slide-body`): a headline, an ink rule, and one
  figure or a short list under it.
- **Statement** (`.center-v`): one sentence, large, centred.

## Still to do

Two slides are deliberately unfinished and will look it on screen:

- `slide-07` wants a vector-in-the-browser recording.
- `slide-12` wants a photo from the sprint, and real numbers in place of **X** and **Y**.

## Publishing

Push to `main`. The workflow in `.github/workflows/publish.yml` re-renders the deck and
pushes the result to the `gh-pages` branch.
