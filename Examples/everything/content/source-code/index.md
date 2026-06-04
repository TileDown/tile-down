---
title: Source Code
description: Static syntax highlighting examples across supported languages.
weight: 20
---
# Source Code

TileDown highlights fenced source code at build time. These examples are static
HTML spans plus CSS, with no runtime highlighter.

```bash
#!/usr/bin/env bash
set -euo pipefail
# Build the static example.
echo "build"
```

```c
#include <stdio.h>

int main(void) {
    printf("hello\n");
    return 0;
}
```

```cpp
#include <vector>

auto count_items(const std::vector<int>& values) -> int {
    return static_cast<int>(values.size());
}
```

```csharp
public sealed class Job {
    public string Name { get; init; } = "build";
}
```

```css
.td-panel {
    display: grid;
    color: var(--td-ink);
}
```

```go
package main

func main() {
    println("build")
}
```

```html
<article class="card">
  <h2>Source</h2>
</article>
```

```java
final class Job {
    String name() {
        return "build";
    }
}
```

```javascript
const task = { name: "build", done: false };
console.log(task.name);
```

```json
{
  "name": "build",
  "done": false
}
```

```kotlin
data class Job(val name: String, val done: Boolean = false)
```

```python
def build(name: str) -> str:
    return f"build {name}"
```

```ruby
def build(name)
  "build #{name}"
end
```

```rust
fn build(name: &str) -> String {
    format!("build {name}")
}
```

```sql
SELECT title, published_at
FROM posts
WHERE draft = false;
```

```swift
struct Job {
    let name: String
    let label = "build"
    let done = false
}
```

```typescript
type Job = {
    name: string;
    done: boolean;
};
```

```xml
<job name="build">
  <done>false</done>
</job>
```

```yaml
name: build
done: false
steps:
  - test
  - publish
```
