# Code Blocks

One fenced block for every language in the bundled highlight.js build,
plus an untagged block to exercise `highlightAuto`.

## swift

```swift
final class Greeter {
    let name: String
    init(name: String) { self.name = name }
    func greet() -> String { "Hello, \(name)!" }
}
```

## python

```python
def fib(n):
    a, b = 0, 1
    while a < n:
        print(a, end=' ')
        a, b = b, a + b
    print()
```

## javascript

```javascript
export async function fetchAll(urls) {
  const results = await Promise.allSettled(urls.map(u => fetch(u)));
  return results.filter(r => r.status === 'fulfilled');
}
```

## typescript

```typescript
type Result<T> = { ok: true; value: T } | { ok: false; error: string };

function unwrap<T>(r: Result<T>): T {
  if (r.ok) return r.value;
  throw new Error(r.error);
}
```

## bash

```bash
#!/usr/bin/env bash
set -euo pipefail
for f in test-fixtures/*.md; do
  echo "checking $f"
done
```

## json

```json
{
  "name": "miru",
  "version": "1.0.0",
  "deps": ["marked", "highlight.js", "mermaid"]
}
```

## yaml

```yaml
targets:
  MiruPreview:
    type: app-extension
    platform: macOS
    deployment: 12.0
```

## rust

```rust
fn main() {
    let names = vec!["alpha", "beta"];
    for (i, n) in names.iter().enumerate() {
        println!("{i}: {n}");
    }
}
```

## go

```go
package main

import "fmt"

func main() {
    fmt.Println("hello, 世界")
}
```

## ruby

```ruby
class Greeter
  def initialize(name) = @name = name
  def greet = "Hello, #{@name}!"
end
```

## sql

```sql
SELECT id, title, updated_at
FROM documents
WHERE title LIKE '%miru%'
ORDER BY updated_at DESC
LIMIT 10;
```

## xml

```xml
<?xml version="1.0"?>
<document type="com.apple.dt.Xcode.workspace" version="1.0">
  <name>Miru</name>
</document>
```

## css

```css
:root { --accent: #0969da; }
.card:hover { border-color: var(--accent); }
```

## markdown

```markdown
# A markdown example
- item one
- item two with **bold**
```

## no language

```
plain text with no language tag — must fall back to highlightAuto
without throwing or producing empty output.
```
