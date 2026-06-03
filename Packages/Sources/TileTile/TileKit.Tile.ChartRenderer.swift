import TileCore

public extension TileKit.Tile {
    /// A static SVG chart tile backed by Markdown-authored labels and series data.
    ///
    /// Reads `type`, `labels`, one or more `series.<name>` properties, and
    /// optional `title`, `height`, and `legend` properties.
    struct ChartRenderer: Rendering {
        public static let typeID = "chart"

        public init() {}

        public func render(
            _ tile: Instance,
        ) throws -> Rendered {
            guard tile.typeID == Self.typeID else {
                throw ChartRendererError.invalidTileType(actual: tile.typeID)
            }

            let chart = try ChartData(tile)
            return .init(
                html: ChartSVGRenderer().render(chart, interactive: true),
                css: Self.css,
                javascript: Self.javascript,
            )
        }

        /// The interactive tile ships a small tooltip runtime; the static Markdown
        /// ` ```chart ` fence renders the same SVG with native `<title>` tooltips
        /// and no script. Browser JavaScript is allowed only for client-side tiles.
        static let javascript = """
        (function () {
          var charts = document.querySelectorAll('.td-chart[data-td-chart-interactive]:not([data-td-chart-bound])');
          if (charts.length === 0) return;
          var tip = document.querySelector('.td-chart-tip');
          if (!tip) {
            tip = document.createElement('div');
            tip.className = 'td-chart-tip';
            tip.setAttribute('role', 'status');
            document.body.appendChild(tip);
          }
          function hide() { tip.style.opacity = '0'; }
          function show(text) { tip.textContent = text; tip.style.opacity = '1'; }
          charts.forEach(function (chart) {
            chart.setAttribute('data-td-chart-bound', 'true');
            var marks = chart.querySelectorAll('.td-chart-bar, .td-chart-slice, .td-chart-point');
            marks.forEach(function (mark) {
              var node = mark.querySelector('title');
              var text = node ? node.textContent : '';
              if (node) { node.remove(); }
              if (!text) { return; }
              mark.setAttribute('tabindex', '0');
              mark.addEventListener('pointerenter', function () { show(text); });
              mark.addEventListener('pointermove', function (event) {
                tip.style.left = (event.clientX + 12) + 'px';
                tip.style.top = (event.clientY + 12) + 'px';
              });
              mark.addEventListener('pointerleave', hide);
              mark.addEventListener('focus', function () {
                var box = mark.getBoundingClientRect();
                tip.style.left = box.left + 'px';
                tip.style.top = Math.max(8, box.top - 8) + 'px';
                show(text);
              });
              mark.addEventListener('blur', hide);
            });
          });
        })();
        """

        /// Shared by the property-authored chart tile and the Markdown ` ```chart `
        /// fence renderer so both emit one identical stylesheet.
        static let css = """
        .td-chart {
          margin-block: 1.75rem;
        }
        .td-chart-caption {
          color: var(--td-ink);
          font-weight: 700;
          margin: 0 0 0.75rem;
        }
        .td-chart-frame {
          background: var(--td-surface);
          border: 1px solid var(--td-border);
          border-radius: var(--td-radius);
          overflow-x: auto;
          padding: 1rem;
        }
        .td-chart-svg {
          display: block;
          height: auto;
          min-width: 34rem;
          width: 100%;
        }
        .td-chart-grid {
          stroke: var(--td-border);
          stroke-width: 1;
        }
        .td-chart-axis {
          stroke: var(--td-muted);
          stroke-width: 1.25;
        }
        .td-chart-label,
        .td-chart-value,
        .td-chart-legend-text {
          fill: var(--td-muted);
          font-size: 16px;
          font-weight: 400;
          font-synthesis: none;
        }
        .td-chart-value {
          font-variant-numeric: tabular-nums;
        }
        .td-chart-bar,
        .td-chart-slice {
          fill: currentColor;
        }
        .td-chart-line {
          fill: none;
          stroke: currentColor;
          stroke-linecap: round;
          stroke-linejoin: round;
          stroke-width: 3;
        }
        .td-chart-point {
          fill: var(--td-surface);
          stroke: currentColor;
          stroke-width: 3;
        }
        .td-chart-series-0 { color: #0a84ff; }
        .td-chart-series-1 { color: #34c759; }
        .td-chart-series-2 { color: #ff9f0a; }
        .td-chart-series-3 { color: #ff375f; }
        .td-chart-series-4 { color: #af52de; }
        .td-chart-series-5 { color: #5e5ce6; }
        [data-theme="dark"] .td-chart-series-0 { color: #64d2ff; }
        [data-theme="dark"] .td-chart-series-1 { color: #30d158; }
        [data-theme="dark"] .td-chart-series-2 { color: #ffd60a; }
        [data-theme="dark"] .td-chart-series-3 { color: #ff453a; }
        [data-theme="dark"] .td-chart-series-4 { color: #bf5af2; }
        [data-theme="dark"] .td-chart-series-5 { color: #7d7aff; }
        .td-chart-bar, .td-chart-slice, .td-chart-point, .td-chart-line {
          transition: filter 0.12s ease, stroke-width 0.12s ease;
        }
        .td-chart-bar:hover, .td-chart-slice:hover { filter: brightness(1.15); }
        .td-chart-point:hover { stroke-width: 5; }
        .td-chart-line:hover { stroke-width: 4; }
        .td-chart[data-td-chart-interactive] :is(.td-chart-bar, .td-chart-slice, .td-chart-point) { cursor: pointer; }
        .td-chart-tip {
          position: fixed;
          z-index: 40;
          left: 0;
          top: 0;
          pointer-events: none;
          opacity: 0;
          transition: opacity 0.1s ease;
          background: var(--td-ink);
          color: var(--td-surface);
          padding: 0.32rem 0.55rem;
          border-radius: 0.45rem;
          font-size: 0.8rem;
          font-weight: 600;
          line-height: 1.3;
          max-width: 18rem;
          box-shadow: 0 6px 18px rgba(0,0,0,0.28);
        }
        """
    }
}
