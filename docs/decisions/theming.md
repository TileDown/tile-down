# Decision: theming via CSS cascade layers and theme properties

How Tiledown gives a site one consistent look while letting an individual tile
override it.

**Status: decided in principle (2026-05-30), validated by research; several
sub-decisions are open pending a design pass.** The core mechanism (cascade
layers for precedence, theme properties for values) is settled and matches current
web-platform best practice. The tile-facing API, the layer set, and the asset
machinery are not built yet; they land with the future `TileAsset` target and
[NEXT_STEPS](../NEXT_STEPS.md) step 5 (asset declarations and deduplication).
This document graduates into a rule under `docs/rules/` when the first slice
ships.

## The model: two levels

Theming is opinionated **per site, not per page**: one theme is authored for the
whole site and applied to every page.

- **Level 1, the theme (site-wide).** The CSS that exists for every page: a base
  (reset, typography, layout) plus theme properties. Its job is consistency. The
  theme is **forced onto tiles by default**, so a plain tile is not a snowflake.
- **Level 2, per-tile CSS.** Each tile renderer contributes CSS. By default a
  tile defers to the theme (it styles structure and reads theme properties). A tile
  **may reject the theme and impose its own** look when it genuinely needs to.

So: a default-on site theme with a per-tile opt-out. The theme wins unless a tile
explicitly takes the wheel.

## The decision: two orthogonal mechanisms

Precedence and values are separate problems and get separate mechanisms. Cascade
layers decide *who wins*; theme properties carry *what the values are*. Conflating
them is the usual source of theming pain.

### 1. Precedence: CSS cascade layers

Declare a fixed layer order and place CSS into the right layer:

```css
@layer reset, theme, tile-override;
```

For **normal (non-`!important`) declarations, a later layer beats an earlier
layer regardless of selector specificity.** That is exactly the property we want:
the `theme` layer styles tiles by default, and a tile that rejects emits into the
later `tile-override` layer, which wins without any specificity arithmetic.

```css
@layer theme {                 /* site theme, forced on every tile */
  .td-poll { background: var(--td-surface); color: var(--td-ink); }
}

@layer tile-override {         /* only a tile that rejects the theme */
  .td-poll { background: #111; color: #0f0; }   /* wins, same specificity */
}
```

Cascade layers were added to CSS Cascading and Inheritance Level 5 for precisely
this case. They are Baseline (widely available) since 2022.

### 2. Values: theme properties

Tiles must be theme-agnostic, so they never hardcode a palette; they read
**theme properties** (CSS custom properties). They are two-tier:

- **Primitives**: raw values (`--td-gray-900: #1c1917`).
- **Semantic aliases**: theme-agnostic names tiles actually use
  (`--td-surface`, `--td-ink`, `--td-accent`). Tiles reference only these.

Theme switching (light/dark, named themes) is **custom-property remapping scoped
to a selector, not a layer**:

```css
:root            { --td-surface: #fafaf9; --td-ink: #1c1917; }
[data-theme=dark]{ --td-surface: #1c1917; --td-ink: #fafaf9; }
@media (prefers-color-scheme: dark) { :root { /* dark defaults */ } }
```

Reskinning the whole site is then a change to theme-property values in one place, and
every tile follows because it only ever referenced the aliases.

The W3C Design Tokens (DTCG) format is a JSON *interchange* format that emits no
CSS; it delegates output to tools like Style Dictionary. Tiledown owns its
theme-property-to-CSS emission regardless, so DTCG is only relevant later for import
interop.

## Two load-bearing constraints

These are not style preferences; they are how the CSS cascade actually resolves,
and getting either wrong silently breaks the model. (An oversimplified "layer
order alone decides the winner" claim was explicitly refuted in the research for
ignoring exactly these two exceptions.)

### C1. Every tile's CSS must be inside a layer

**Unlayered normal styles beat all layered normal styles, regardless of
specificity and source order.** So if even one tile emits CSS outside a layer, it
overrides both the `theme` and the `tile-override` layers, and the whole scheme
collapses.

Today `TileKit.Output.HTMLRenderer` concatenates each tile's raw CSS string into
`assets.css` with no layer wrapping. That is the unlayered trap. The asset slice
must **wrap every tile's CSS in a layer by construction** and make unlayered tile
CSS impossible to emit: a tile does not hand the engine a raw CSS blob; it
declares CSS that the engine *places* into `theme` (default) or `tile-override`
(reject). The engine owns the `@layer` statement and the placement.

### C2. "Reject" is normal declarations in the later layer, never `!important`

**`!important` inverts layer order:** an `!important` rule in the earlier `theme`
layer beats an `!important` rule in the later `tile-override` layer. So a tile
that tries to reject by shouting `!important` *loses*. The correct override is
plain declarations in `tile-override`. Tile CSS should avoid `!important`
entirely (the engine can strip or reject it), and the documented escape hatch is
"emit normal declarations into the override layer."

## Why layers over the alternatives

- **Source-order scoping (e.g. Astro's auto-scoped component styles)** ranks by
  source order but is defeated the moment an imported rule is more specific than
  the scoped one. That specificity fragility is the exact thing cascade layers
  remove.
- **Shadow DOM `::part()` and CSS-in-JS `ThemeProvider`** are runtime or
  encapsulation mechanisms, not build-time static CSS. They are useful reference
  points but not analogs for a static site generator that emits plain CSS files.

## Open sub-decisions (to settle in the design pass)

- **Tile posture API.** How does a tile declare themed (default) vs override? The
  rendered-output type needs to carry CSS *plus* a layer placement, replacing
  today's single raw `css` string. This is the main thing to design next.
- **Layer set.** `@layer reset, theme, tile-override` is the starting set. Do we
  also need a layer for third-party tile CSS, or a per-page theme override layer?
- **Browser-support floor.** An unsupported `@layer` block is dropped *entirely*,
  which would drop the theme. Lean: accept the Baseline-2022 floor for a
  GitHub-Pages target rather than ship a non-layered fallback. Decide explicitly.
- **Theme-property source format.** Emit `--td-*` custom properties from an internal model
  now; consider DTCG-JSON import later only if interop is wanted.
- **Asset declarations and dedup.** This rides on NEXT_STEPS step 5: a tile
  declares a named, keyed CSS asset so identical tile CSS is emitted once per
  page (and wrapped in its layer). That slice is the prerequisite for all of the
  above.

## How it lands in the architecture

- A future `TileAsset` target owns asset declarations, dedup, the layer wrapping,
  the theme and theme-property model, and the asset behavior registry.
- `TileKit.Output.Assets` (today `{ css, javascript }` raw strings) evolves so CSS
  carries its layer placement instead of being a flat concatenated string.
- The site composition root injects the theme (base + theme properties) once per
  page; the template links or inlines it (delivery mechanism is a separate,
  smaller choice). `Theme.standard` and `Theme.system` are the current built-in
  themes.

## Evidence base

The full cited research (three verified passes) is in
[docs/research/theming-styling-api.md](../research/theming-styling-api.md).

The decision rests on web-platform primary sources: the W3C CSS Cascading and
Inheritance Level 5 spec, MDN and Chrome for Developers documentation on
`@layer`, the W3C Design Tokens draft, Open Props (which confirms the two-tier
theme-property model and selector-scoped theme switching "rather than using layers"), and
the Astro styling docs (for the source-order-scoping contrast).

There is **no peer-reviewed literature** on theming, theme properties, or cascade
layers; they are too new and too much an engineering practice. Real formal-CSS
academic work exists (Cassius, OOPSLA 2016; layout verification, PLDI 2018;
automated CSS-rule analysis, ICSE 2012; Genevès and Layaïda's formal CSS
analysis) but it concerns *verifying* CSS layout and detecting dead or duplicate
rules, not theming-system design. The "structure vs skin" idea behind the
theme-property/component split is OOCSS industry lore. The front-end interview canon for
"design a dark-mode system" matches this decision: `:root` custom properties, a
`[data-theme]` attribute, and theme-property tiers.
