# Package Import Contract Status

This table records the allowed imports for current SPM targets. Domain targets
own their pure logic. Implementation targets stay thin and concrete. Composition
and facade targets are the exceptions.

| Target | Allowed imports | Current state |
|---|---|---|
| `TileCore` | none | matches |
| `TileContent` | `TileCore` | matches |
| `TileMarkdown` | `Foundation`, `TileCore` | matches |
| `TileService` | `Foundation`, `TileCore` | matches |
| `TileServiceForm` | `Foundation`, `TileCore`, `TileService`, `TileTile` | matches |
| `TileSource` | `Foundation`, `TileCore` | matches |
| `TileTemplate` | `Foundation`, `TileCore` | matches |
| `TileTile` | `Foundation`, `TileCore` | matches |
| `TileSite` | `TileCore`, `TileMarkdown`, `TileSource`, `TileTemplate`, `TileTile` | matches |
| `TileSiteImpl` | `Foundation`, `TileCore`, `TileSite` | matches |
| `TileKit` | re-exports `TileCore`, `TileContent`, `TileMarkdown`, `TileService`, `TileServiceForm`, `TileSite`, `TileSiteImpl`, `TileSource`, `TileTemplate`, `TileTile` | matches |
| `TiledownCLI` | `Foundation`, `TileKit` | matches |
