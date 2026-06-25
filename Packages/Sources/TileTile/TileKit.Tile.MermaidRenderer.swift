import Foundation
import TileCore

public extension TileKit.Tile {
    /// A client-side Mermaid diagram tile backed by a Markdown-authored
    /// diagram definition.
    ///
    /// Reads required `definition` and optional `title` string properties.
    /// The renderer escapes the definition into a Mermaid source container and
    /// emits a page-local runtime that loads the pinned Mermaid browser module.
    struct MermaidRenderer: Rendering {
        public static let typeID = "mermaid"

        public init() {}

        public func render(
            _ tile: Instance,
        ) throws -> Rendered {
            guard tile.typeID == Self.typeID else {
                throw MermaidRendererError.invalidTileType(actual: tile.typeID)
            }

            let definition = try Self.requiredString(named: "definition", from: tile)
            let title = Self.string(tile.property(named: "title"))?
                .trimmingCharacters(in: .whitespacesAndNewlines)

            return .init(
                html: Self.html(
                    definition: definition,
                    title: title,
                ),
                css: Self.css,
                javascript: Self.javascript,
            )
        }

        /// Shared with the Markdown ` ```mermaid ` fence renderer so both emit the
        /// same client-runtime container and assets.
        static func html(
            definition: String,
            title: String?,
        ) -> String {
            let caption = if let title, !title.isEmpty {
                "\n<figcaption class=\"td-mermaid-caption\">\(escapeHTML(title))</figcaption>"
            } else {
                ""
            }

            return """
            <figure class="td-mermaid" data-td-mermaid>
            <pre class="mermaid td-mermaid-source">\(escapeHTML(definition))</pre>\(caption)
            </figure>
            """
        }

        static let css = """
        .td-mermaid {
          margin-block: 1.75rem;
        }
        .td-mermaid-source {
          background: var(--td-surface);
          border: 1px solid var(--td-border);
          border-radius: var(--td-radius);
          color: var(--td-ink);
          margin: 0;
          overflow-x: auto;
          padding: 1rem;
        }
        .td-mermaid-source:not([data-td-mermaid-bound]) {
          min-height: 12rem;
        }
        .td-mermaid-caption {
          color: var(--td-muted);
          font-size: 0.95rem;
          margin-top: 0.65rem;
          text-align: center;
        }
        .td-mermaid-source svg {
          display: block;
          height: auto;
          max-width: 100%;
        }
        """

        static let javascript = """
        (function () {
          var selector = '.td-mermaid-source:not([data-td-mermaid-bound])';
          var nodes = Array.prototype.slice.call(document.querySelectorAll(selector));
          if (nodes.length === 0) return;
          nodes.forEach(function (node) {
            node.setAttribute('data-td-mermaid-bound', 'true');
            node.__tdMermaidSource = node.textContent;
          });
          function currentTheme() {
            return document.documentElement.getAttribute('data-theme') === 'dark' ? 'dark' : 'default';
          }
          var activeTheme = currentTheme();
          function markError() {
            document.documentElement.setAttribute('data-td-mermaid-error', 'true');
          }
          function resetNodes() {
            nodes.forEach(function (node) {
              if (typeof node.__tdMermaidSource === 'string') {
                node.textContent = node.__tdMermaidSource;
              }
              node.removeAttribute('data-processed');
            });
          }
          function render(mermaid) {
            mermaid.initialize({
              startOnLoad: false,
              securityLevel: 'strict',
              theme: activeTheme
            });
            return Promise.resolve(mermaid.run({ nodes: nodes })).catch(markError);
          }
          var ready = window.__tdMermaidRuntime;
          if (!ready) {
            var source = 'https://cdn.jsdelivr.net/npm/mermaid@10.9.3/dist/mermaid.esm.min.mjs';
            ready = import(source).then(function (module) {
              return module.default || module;
            });
            window.__tdMermaidRuntime = ready;
          }
          ready.then(function (mermaid) {
            render(mermaid);
            var observer = new MutationObserver(function () {
              var nextTheme = currentTheme();
              if (nextTheme === activeTheme) return;
              activeTheme = nextTheme;
              resetNodes();
              render(mermaid);
            });
            observer.observe(document.documentElement, {
              attributes: true,
              attributeFilter: ['data-theme']
            });
          }).catch(markError);
        })();
        """

        private static func requiredString(
            named key: String,
            from tile: Instance,
        ) throws -> String {
            guard let value = string(tile.property(named: key)),
                  !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            else {
                throw MermaidRendererError.missingProperty(key)
            }

            return value.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        private static func string(
            _ value: Value?,
        ) -> String? {
            guard case let .string(string) = value else {
                return nil
            }
            return string
        }

        private static func escapeHTML(
            _ value: String,
        ) -> String {
            value
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
                .replacingOccurrences(of: "\"", with: "&quot;")
                .replacingOccurrences(of: "'", with: "&#39;")
        }
    }
}
