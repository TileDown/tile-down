# Internal page/post references in Markdown: research

How should a Tiledown author link to another page or post in the same project,
so the link resolves to the correct URL and does not rot when files move? This
note surveys the scientific literature first, then current static-site-generator
practice, then maps both onto a recommended design.

## 1. Scientific literature (hypertext / hypermedia)

### Links as first-class objects (open hypermedia)
A recurring principle across decades of hypermedia research is that a link is a
*managed object resolved against a model*, not a raw address embedded in the
document text. Microcosm and the Dexter reference model treat links and anchors
as data the system owns, separate from the content, so the system can resolve,
validate, and update them. For a static generator this maps cleanly: the author
writes a *logical reference*, and the engine resolves it to a URL at build time
against its page model (which Tiledown already has).

- Fountain, Hall, Heath, Davis. *MICROCOSM: An Open Model for Hypermedia With
  Dynamic Linking.*
- Halasz, Schwartz. *The Dexter Hypertext Reference Model.*

### Link integrity (the broken-link problem)
Davis and Ashman frame the field: "when the object at one end of a link is not
present, or is not the object intended by the link author, the link is broken."
Three strategies exist: prevent links from breaking, detect and correct them, or
ignore them. A static build is uniquely positioned to *prevent*: every reference
is resolved at build time, so a broken one can stop the build before it ships.

- Davis. *Hypertext Link Integrity*, ACM Computing Surveys.
- Ingham, Caughey, Little. *Fixing the broken-link problem: the W3Objects
  approach.*

### Persistent, location-independent identifiers
The persistent-identifier literature (URN, PURL, DOI/Handle, ARK) and link-rot
studies converge on one lesson: an identifier *decoupled from location* survives
moves and reorganization, whereas a location-based URL rots. PIDs depend on a
resolution service; in a static build the page set itself is the resolver. This
is the strongest signal on the "id versus path" choice: a file path is
location-based and therefore rot-prone (move the file, break the link); a stable
logical id is the durable choice.

- *Persistent identifier*, overview; *20 Years of Persistent Identifiers*, Data
  Science Journal.
- URL-decay studies (e.g. MEDLINE abstract link rot).

### Information scent (link labeling)
Pirolli and Card's information-foraging work shows navigation success depends on
link-label quality: the anchor text must "smell like" the destination. Design
consequence: the reference syntax must let the author set the visible link text,
not only emit the target page's title.

- Pirolli, Card. *Information Foraging Theory*; *Information Scent and Web
  Navigation.*

### Wiki model and red links
MediaWiki performs existence detection on every wikilink; a link to a
nonexistent page renders as a "red link" that invites creation. This is the
documented precedent for the "surface broken references visibly" stance, as
opposed to failing the build. For a *published* site the red link is usually
unwanted, so failing the build is the safer default, with warn-and-mark as the
alternative.

- Wikipedia: *Red link*; MediaWiki existence detection.

## 2. Current SSG practice

| Tool | Syntax | Identified by | Broken ref |
|---|---|---|---|
| Hugo | `[t]({{< relref "page.md" >}})` / `ref` | path or filename | error by default (`refLinksErrorLevel`) |
| Zola | `[t](@/path/to/page.md)` | path from content root | error by default (`internal_level`) |
| Docusaurus | `[t](./other.md)` relative file path | source file path | `onBrokenLinks: throw` default |
| MkDocs | `[t](other.md)` relative path | source file path | warn/error via validation config |
| mdBook | relative `.md` path | source file path | broken-link check |
| Eleventy + interlinker | `[[id|alias]]` wikilink | slug / front-matter alias | tracks existence, backlinks |
| Obsidian/Foam/Dendron | `[[note]]` / `[[note|alias]]` | note name / id / alias | red-link style |
| Jekyll | `{% link f.md %}`, `{% post_url slug %}` | path / post slug | error if missing |

Two families: **path-based** (Hugo, Zola, Docusaurus, MkDocs, mdBook: the path is
the id, resolved to a URL, location-based and rot-prone) and **name/id-based**
(wiki tools: a stable name or alias, location-independent). Modern tools across
both families default to failing or flagging broken references.

## 3. Mapping to Tiledown

- **Identifier:** prefer a stable `id` (location-independent, the URN lesson),
  falling back to the page slug for zero-config. Avoid path-only, which is the
  rot-prone kind the PID literature warns against.
- **Syntax:** must support custom anchor text (information scent). Both
  `[text][id]` (standard CommonMark reference style) and `[[id|text]]` (wiki
  lineage) satisfy this. Reference style is closest to plain CommonMark and to
  the author's stated example; wiki style is terser and familiar from notes
  tools.
- **Resolution:** resolve at build against the page model (links as first-class
  objects), not by emitting raw hrefs the author maintains by hand.
- **Broken reference:** prevention wins for a published site. Fail the build by
  default, naming the bad id and the file; offer warn-and-mark (the red-link
  model) as the documented alternative.

## Sources
- [Hypertext Link Integrity (ACM Computing Surveys)](https://dl.acm.org/doi/10.1145/345966.346026)
- [Fixing the broken-link problem: the W3Objects approach](https://www.sciencedirect.com/science/article/abs/pii/0169755296000694)
- [MICROCOSM: An Open Model for Hypermedia With Dynamic Linking](https://www.researchgate.net/publication/2713081_MICROCOSM_An_Open_Model_for_Hypermedia_With_Dynamic_Linking)
- [Toward a Dexter-Based Model for Open Hypermedia](https://www.researchgate.net/publication/221266985_Toward_a_Dexter-Based_Model_for_Open_Hypermedia_Unifying_Embedded_References_and_Link_Objects)
- [Persistent identifier (overview)](https://en.wikipedia.org/wiki/Persistent_identifier)
- [20 Years of Persistent Identifiers (Data Science Journal)](https://datascience.codata.org/articles/10.5334/dsj-2017-009)
- [URL decay in MEDLINE abstracts](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC2435527/)
- [Information Scent and Web Navigation (Pirolli, Semantic Scholar)](https://www.semanticscholar.org/paper/Information-Scent-and-Web-Navigation:-Theory,-and-Pirolli/5a232dc72dae072b852c1a93df971368d3b7c2ac)
- [SNIF-ACT: A Model of Information Foraging on the Web](https://www.peterpirolli.com/ewExternalFiles/Pirolli-Fu%20UM2003.pdf)
- [Wikipedia: Red link](https://en.wikipedia.org/wiki/Wikipedia:Red_link)
- [Hugo relref shortcode](https://gohugo.io/shortcodes/relref/)
- [Zola internal links & deep linking](https://www.getzola.org/documentation/content/linking/)
- [Docusaurus Markdown links](https://docusaurus.io/docs/markdown-features/links)
- [eleventy-plugin-interlinker](https://github.com/photogabble/eleventy-plugin-interlinker)
