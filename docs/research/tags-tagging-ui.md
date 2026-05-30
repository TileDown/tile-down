# Research: tags and tag-based navigation UI

Evidence for how Tiledown should surface and navigate tags (per-post tag pills,
the per-tag listing page, ordering, readability). Gathered 2026-05-31. Reference
material for issue #50 (tags with filtering) and any tag-UI decision.

## Question

Once posts declare tags and the generator produces a page per tag, how should
tags be presented so a reader can actually see and filter by them? Specifically:
must tags be shown at the content, in what order, with what typography, and
should a tag link to a filtered listing rather than just decorate?

## Scientific and peer-reviewed evidence (best first)

- **Sinclair, J., & Cardew-Hall, M. (2008). "The folksonomy tag cloud: when is it
  useful?" Journal of Information Science, 34(1), 15 to 29.** Evaluated a tag cloud
  against a search box for information-seeking tasks. Finding: the cloud helped for
  broad, open-ended browsing, but for specific information-seeking participants
  preferred and performed better with search. Implication for us: tags are a
  browsing aid layered on top of content, not a replacement for finding a known
  item; they must be present where the user already is, not behind a separate
  destination.
  https://www.researchgate.net/publication/255607959_Using_tag_clouds_to_facilitate_search_An_evaluation

- **Schrammel, J., Leitner, M., & Tscheligi, M. (2009). "Semantically structured
  tag clouds: an empirical evaluation of clustered presentation approaches." CHI
  2009.** Eye-tracking / layout study. Findings: **alphabetical ordering aids
  finding a known tag**; semantic clustering helps for some tasks; and tag position
  matters more than font size for locating a specific tag. Implication: order tags
  predictably (alphabetical), do not rely on size-by-frequency for findability.
  https://www.researchgate.net/publication/221054142_Visual_Search_Strategies_of_Tag_Clouds-_Results_from_an_Eyetracking_Study

- **Lohmann, S., Ziegler, J., & Tetzlaff, L. (2009). "Comparison of tag cloud
  layouts: task-related performance and visual exploration." INTERACT 2009.**
  Compared layouts (alphabetic, frequency, semantic, circular). Findings: tags in
  the **typical reading direction (horizontal, left-to-right) are found faster**;
  larger font size draws attention but does not help finding a specific tag;
  alphabetic layout is best for targeted search. Implication: keep tag labels
  horizontal and readable; do not tilt or vertical-set the text.
  https://ieeexplore.ieee.org/document/4577920/

- **Helic, D., Trattner, C., Strohmaier, M., & Andrews, K. (2011). "Are tag clouds
  useful for navigation? A network-theoretic analysis." International Journal of
  Social Computing and Cyber-Physical Systems, 1(1).** Network analysis of whether
  tag clouds support navigation. Finding: tag-resource networks are navigable in
  principle, but common UI choices, especially **pagination plus reverse-chronological
  resource lists, significantly impair navigability**. Implication: a tag must lead
  to a real, complete listing of that tag's resources (a filter), and that listing
  should not bury items behind pagination.
  https://www.researchgate.net/publication/228566560_Are_tag_clouds_useful_for_navigation_A_network-theoretic_analysis

- **Quintarelli, E., Resmini, A., & Rosati, L. (2007). "Facetag: integrating
  bottom-up and top-down classification in a social tagging system." Bulletin of
  ASIS&T, 33(5).** Argues for combining free tags with faceted structure. In a
  controlled comparison, integrated faceted-plus-tag browsing let users complete
  more exploratory tasks than tag-only interfaces. Implication: tags should behave
  as a facet (click a tag, get exactly the items with that tag), which is precisely
  the per-tag listing page.
  https://asistdl.onlinelibrary.wiley.com/doi/full/10.1002/bult.2007.1720330506

- **Kuo, B. Y.-L., Hentrich, T., Good, B. M., & Wilkinson, M. D., and follow-on
  "What a difference a tag cloud makes" (Information Research, 14(4), 2009).** Task
  and cognitive-ability study of adding a tag cloud beside a result list. Finding:
  the value of a tag overview depends on task type and the user; it helps
  exploration more than known-item lookup. Implication: present tags as an optional
  exploratory affordance alongside the main content, not as the primary path.
  https://arxiv.org/html/1004.2222 ; https://informationr.net/ir/14-4/paper414.html

Note: several of the full texts above are paywalled or anti-bot protected;
citations and findings are taken from the publication records, abstracts, and
secondary summaries, not from fetched PDFs.

## Scope caveat

Most of this literature studies **tag clouds**: large aggregate tag sets (often
>100 tags) where font-size-by-frequency, scaling, and clustering dominate. A blog
typically has small per-post tag sets (here 3 to 4 tags per post, 16 distinct
tags total). The cloud-scaling findings (size encoding, >100-tag navigation) are
therefore only weakly relevant. What transfers cleanly to the small-set case:

1. Surface tags **at the content** (on the post and in the listing), not behind a
   separate page the reader must already know to visit.
2. Order tags **predictably**; alphabetical aids targeted finding.
3. Keep labels **horizontal** and readable.
4. Make each tag a **link to a filtered listing** of that tag's items (faceted
   behaviour), not a decorative label.

## Conclusion for Tiledown (issue #50)

The evidence supports the visible, filterable design now implemented:

- **Tag pills are rendered on every post page and on every card in a post
  listing**, so tags are visible at the content (addresses the core failure mode:
  a tag page that nothing links to is invisible).
- **Each pill links to `/tags/<slug>/`**, a page that lists exactly that tag's
  posts, newest first. That is the faceted filter the literature favours over
  decorative tags. (The reverse-chronological caveat from Helic et al. applies if
  a single tag ever grows large enough to need pagination; Tiledown does not
  paginate, so the full set is always shown.)
- **Tags render as horizontal-text pills in source order** (the per-post order the
  author wrote, which for the site-wide `site.tags` aggregate is slug-alphabetical).
  Horizontal text matches the readability finding; alphabetical aggregate ordering
  matches the targeted-finding result.

### Decision: wrapped horizontal pills

The per-post pills render as a **wrapped horizontal row** (`flex-wrap: wrap`),
left-to-right in the typical reading direction, wrapping to a second line only
when they exceed the content width. This is the research-backed layout: Lohmann
et al. found tags in the typical reading direction are found faster than other
arrangements, and Schrammel et al. found a horizontal ordered row supports
targeted finding of a specific tag. A vertical stack was tried and rejected: it
breaks the reading flow into a slower top-to-bottom scan with no compensating
benefit at this set size.

### Not yet built (possible follow-ups)

- A **`/tags/` index page** listing every tag with post counts (a small tag cloud
  or alphabetical list); supported by the browsing-aid findings.
- **Semantic grouping** of related tags; only worth it if the tag set grows large
  (Schrammel et al.), which a personal blog rarely reaches.
