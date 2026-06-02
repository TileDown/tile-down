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
                html: ChartSVGRenderer().render(chart),
                css: Self.css,
            )
        }

        private static let css = """
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
          font-size: 13px;
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
        """
    }
}
