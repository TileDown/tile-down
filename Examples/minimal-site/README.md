# Minimal Site

A small Tiledown demo site using the built-in `system` theme, top navigation,
footer social links, and RSS output.

Build it from the repository root:

```sh
cd Packages
swift run tiledown build-site ../Examples/minimal-site/content ../Examples/minimal-site/dist
```

The build writes HTML pages, `styles.css`, and `feed.xml` into
`Examples/minimal-site/dist/`.

The demo omits `baseURL` so local builds link `/styles.css` and work from a
simple local web server. Set `baseURL` in `content/tiledown.yml` before
publishing so RSS links are absolute.
