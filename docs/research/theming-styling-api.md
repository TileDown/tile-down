# Research: theming and the tile styling API

Evidence behind [docs/decisions/theming.md](../decisions/theming.md). Three
adversarially-verified research passes (web, specs, design systems, peer-reviewed
literature, books, interviews) on 2026-05-30. Each claim below survived a 3-vote
verification; sources are primary unless marked otherwise.

## Pass 1: does cascade layers plus design tokens fit best practice?

**Verdict: yes, it is the exact use case CSS Cascading Level 5 added `@layer` for.**
A later layer beats an earlier layer for normal declarations regardless of
specificity, so `tile-override` reliably beats `theme`. Two load-bearing gotchas:
(1) unlayered normal styles beat all layered styles, so every tile's CSS must sit
inside a layer; (2) `!important` inverts layer order, so a reject must use normal
declarations in the later layer, never `!important`. Tokens and layers are
orthogonal: layers do precedence, tokens (two-tier: primitives then theme-agnostic
semantic aliases) do values, with theme switching via custom-property remapping on
`:root` / `[data-theme]`, not layers. DTCG is a JSON interchange format that emits
no CSS, so Tiledown owns token-to-CSS emission.

Sources: [W3C css-cascade-5](https://www.w3.org/TR/css-cascade-5/),
[MDN @layer](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/@layer),
[Chrome: cascade layers](https://developer.chrome.com/blog/cascade-layers),
[Open Props](https://open-props.style/),
[W3C DTCG draft](https://www.designtokens.org/tr/drafts/format/),
[Astro styling](https://docs.astro.build/en/guides/styling/),
[W3C css-shadow-parts-1](https://www.w3.org/TR/css-shadow-parts-1/).
Adjacent academic (formal CSS, not theming): Cassius (OOPSLA 2016), layout
verification (PLDI 2018), automated CSS analysis (ICSE 2012).

## Pass 2: how much should a tile expose about its styling?

**Verdict: minimal-but-sufficient.** Posture flag (themed-default vs override) plus
a keyed CSS blob the engine places into a layer, plus a small curated set of exposed
custom properties as the themeable contract. Tokens are the default contract because
they cover anticipated knobs cheaply; named hooks (`::part`, MUI-style named slots)
are reserved for open-ended restyling tokens cannot express, and each becomes a
permanent semver-governed public API. Even rich systems keep override to a curated
named set with graduated scope; CVA is the closest match (closed variants plus one
`className` escape hatch). The SSG norm (Astro) is scoped CSS plus opt-in class plus
tokens plus slots, not a rich override API. Caveat: `::part` solves a shadow-DOM
problem; Tiledown emits flat CSS into layers, so it is an analogy for "named hooks as
public API," not an implementation path.

Sources: [W3C css-shadow-parts-1](https://www.w3.org/TR/css-shadow-parts-1/),
[MDN Shadow parts](https://developer.mozilla.org/en-US/docs/Web/CSS/Guides/Shadow_parts),
[Adobe Spectrum styling](https://opensource.adobe.com/spectrum-web-components/guides/styling-components/),
[Salesforce LWC styling hooks](https://developer.salesforce.com/docs/platform/lwc/guide/create-components-css-styling-hooks.html),
[MUI overriding structure](https://mui.com/material-ui/customization/overriding-component-structure/),
[Base UI customization](https://v6.mui.com/base-ui/getting-started/customization/),
[CVA variants](https://cva.style/docs/getting-started/variants),
[Astro components](https://docs.astro.build/en/basics/astro-components/),
[meowni.ca part/theme explainer](https://meowni.ca/posts/part-theme-explainer/).

## Pass 3: API-design science, books, and interviews on minimal surface

**Verdict: the rigorous literature backs minimal surface even harder than the specs
do.** Three peer-reviewed lines:

- **Information hiding**: Parnas, "On the Criteria To Be Used in Decomposing Systems
  into Modules," CACM 15(12), 1972. An interface should "reveal as little as
  possible"; over-exposing even an incidental detail (ordering) is "classified as a
  design error"; hide decisions likely to change.
- **API stability cost**: Hyrum's Law (observable behaviors get depended upon
  regardless of contract); Xavier et al., "Historical and Impact Analysis of API
  Breaking Changes," SANER 2017 (317 Java libraries: median ~15% of API changes
  break compatibility; breakage frequency rises with API size and age).
- **API usability**: Stylos and Myers, FSE 2008; Clarke, Cognitive Dimensions 2005;
  Myers and Stylos, "Improving API Usability," CACM 2016. A minimal, task-matched,
  parameterless default path measurably improves developer success (2.4x to 11.2x
  faster in controlled studies).

Book and vendor canon, all prescribing minimal-by-default with opt-in extensibility:
Joshua Bloch, "How to Design a Good API" / "Effective Java" ("when in doubt, leave
it out"; surface "as small as possible"); Cwalina and Abrams, "Framework Design
Guidelines" (do not expose extensibility without strong reason); Apple WWDC 2022
"Embrace Swift generics" / progressive disclosure ("compose, don't enumerate").
Design-system practitioners: Nolan Lawson on styling web components as public API;
Nathan Curtis (EightShapes) on balancing reuse and customization; Brad Frost on
components vs snowflakes; GreatFrontEnd front-end component-API design.

**Strongest dissent**: not "expose more knobs" but under-exposure. A too-thin surface
forces ugly workarounds or forks, so the deferred escape hatch (keyed CSS into the
`tile-override` layer) must stay expressive enough to prevent fork pressure. Our
design keeps it fully expressive, so the line sits where we drew it.

Mapping the science to our design: an override hook is like a virtual member, a token
is like a minimal entry point, a CSS rendering detail is like a volatile decision to
hide. Caveat: this is general API-design science applied by analogy; CSS-theming
specific academic literature is thin.

Sources: [Parnas, CACM 1972](https://dl.acm.org/doi/10.1145/361598.361623),
[Hyrum's Law](https://www.hyrumslaw.com/),
[Xavier et al., SANER 2017](https://homepages.dcc.ufmg.br/~mtov/pub/2017-saner-breaking-apis.pdf),
[Stylos and Myers, FSE 2008](https://www.cs.cmu.edu/~NatProg/papers/FSE2008-p105-stylos.pdf),
[Myers and Stylos, CACM 2016](https://www.cs.cmu.edu/~NatProg/papers/p62-myers-CACM-API_Usability.pdf),
[Clarke, CogDim 2005](https://www.cl.cam.ac.uk/~afb21/CognitiveDimensions/workshop2005/Clarke_position_paper.pdf),
[Bloch, API design (InfoQ)](https://www.infoq.com/articles/API-Design-Joshua-Bloch/),
[.NET Framework Design Guidelines digest](https://github.com/dotnet/runtime/blob/main/docs/coding-guidelines/framework-design-guidelines-digest.md),
[Apple WWDC22](https://developer.apple.com/videos/play/wwdc2022/10059/),
[Nolan Lawson: styling web components](https://nolanlawson.com/2021/01/03/options-for-styling-web-components/),
[GreatFrontEnd: component API design](https://www.greatfrontend.com/front-end-interview-playbook/user-interface-components-api-design-principles).
