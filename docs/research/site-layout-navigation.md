# Research: site layout and navigation placement

Evidence for Tiledown's built-in site layouts (the layout dimension of a theme:
where primary navigation lives). Gathered 2026-05-30. Reference material for the
upcoming site-theme work (epic #17, issue #20) and any layout decision doc.

## Question

Should Tiledown ship a small fixed set of opinionated layouts (rather than
WordPress-style infinite configurability), and where should the primary
navigation go: top, left, right, footer?

## Scientific evidence (peer-reviewed, best first)

- **Pearson, R., & van Schaik, P. (2003). "The effect of spatial layout of and
  link colour in web pages on performance in a visual search task and an
  interactive search task." International Journal of Human-Computer Studies,
  59(3), 327 to 353.** The strongest single reference: a top peer-reviewed HCI
  journal, it directly manipulates menu position (top / left / right / bottom) and
  measures task performance, not preference. Finding: top and left are reliably
  good; the left-vs-right difference was not statistically significant for the pure
  visual-search task, so the penalty is for unconventional primary-nav placement
  rather than left-vs-right specifically.
  https://www.sciencedirect.com/science/article/abs/pii/S1071581903000454

- **van Schaik, P., & Ling, J. (2001). "The effects of frame layout and
  differential background contrast on visual search performance in web pages."
  Interacting with Computers, 13(5), 513 to 525.** The study Pearson and van
  Schaik built on. Navigation on the right and bottom produced fewer hits and
  significantly longer reaction times than top or left; the authors recommend
  placing navigation on the top or the left.

- **Leuthold, S., Schmutz, P., Bargas-Avila, J. A., Tuch, A. N., & Opwis, K.
  (2011). "Vertical versus dynamic menus on the world wide web: Eye tracking study
  measuring the influence of menu design and task complexity on user performance
  and subjective preference." Computers in Human Behavior.** Lab study (120
  participants, eye tracking): vertical menus required fewer fixations, were faster,
  and were more successful than dynamic (hidden) menus, fitting perception and
  cognition better.
  https://www.sciencedirect.com/science/article/abs/pii/S0747563210002840

- **Kalbach, J., & Bosenick, T. (2003). "Web Page Layout: A Comparison Between
  Left- and Right-justified Site Navigation Menus." Journal of Digital
  Information, 4(1).** Found no significant performance difference between left- and
  right-justified menus, consistent with Pearson and van Schaik's left-vs-right
  null result. https://journals.tdl.org/jodi/index.php/jodi/article/download/94/93

Note: full texts above are paywalled or anti-bot protected; citations and findings
are from the journal records and secondary summaries, not the fetched PDFs.

## Industry and practitioner evidence

- **Nielsen Norman Group, "Left-Side Vertical Navigation on Desktop"
  (nngroup.com/articles/vertical-nav).** Attention follows the F-pattern,
  concentrated at the top and left (about 80% of fixations on the left half).
  Top nav suits a few sections but breaks (cramped labels) with many; left vertical
  nav scales and scans faster (vertical lists need fewer fixations than horizontal).
  Hidden/hamburger nav hurts discoverability; keep nav visible.
- **Layout archetype, the "Holy Grail"** (web.dev/patterns/layout/holy-grail;
  en.wikipedia.org/wiki/Holy_grail_(web_design)). Header + footer + main, with zero,
  one, or two side columns. Every common site layout is a subset; modern CSS Grid
  makes them trivial.
- **SSG convention (Hugo, Eleventy).** A "layout" is the outer wrapper (header +
  nav + footer + optional sidebar) around per-page content. Hugo ships opinionated
  themes; Eleventy ships flexible starters. https://www.11ty.dev/styleguide/

## Conclusion for Tiledown

The peer-reviewed evidence backs a small, opinionated set, and specifically
supports top and left while penalizing right as primary navigation:

- Ship **two primary layouts**: **top-nav** (default, few sections; like Toucan)
  and **left-sidebar nav** (many sections; docs/reference). Both are
  science-supported.
- **Right** is a secondary zone only (table of contents / "on this page"), never
  the primary menu (van Schaik and Ling found right and bottom worse).
- **Footer** is always present, carrying secondary/utility navigation.
- All built from one Holy-Grail CSS Grid; navigation items come from the site's
  top-level sections (a site-structure concept not yet built).

This is the curated, anti-WordPress stance, consistent with the project's
minimal-opinionated philosophy and now grounded in an experiment, not convention.
