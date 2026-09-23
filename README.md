# Miru (見る)

"to see." A macOS Quick Look Preview Extension for Markdown files: press Space
on any `.md` file in Finder to get rendered Markdown with syntax highlighting
and Mermaid diagrams. A segmented control toggles to the raw source view.
Light/dark follow the system appearance.

No Xcode GUI required — the project is generated with `xcodegen`, driven by a
`justfile`, and built with `xcodebuild`.

## Prerequisites

```bash
brew install xcodegen just
xcode-select --install    # Command Line Tools, if not already present
```

## Quick start

```bash
just install            # first build fetches highlight.js; then installs to /Applications
just qltest             # reveal test-fixtures/mixed.md in Finder, then press Space
```

A fresh build needs network access once for the pinned highlight.js bundle. Subsequent
builds reuse it after verifying its SHA-256; the extension remains offline at runtime.

## Recipes

| Recipe | Purpose |
|---|---|
| `just` | list recipes |
| `just gen` | regenerate `Miru.xcodeproj` from `project.yml` |
| `just build` | fetch/verify highlight.js, then build `Miru.app` (ad-hoc signed) |
| `just install` | build, install to `/Applications`, register extension |
| `just qltest [fixture]` | install, reveal a fixture in Finder; press Space (default `mixed.md`) |
| `just fetch-highlight` | fetch/verify only highlight.js (also runs during `just build`) |
| `just fetch-assets` | refresh all pinned JS/CSS in `Resources/` |
| `just reset` | reset Quick Look caches (after UTI/Info.plist changes) |
| `just clean` / `just nuke` | remove build artifacts / also reset caches |

## Layout

- `project.yml` — xcodegen spec, single source of truth. `Miru.xcodeproj` is
  generated and **not** committed.
- `App/` — minimal host app whose only job is registering the extension.
- `Extension/` — `PreviewViewController` (WKWebView + marked + highlight.js +
  mermaid).
- `Resources/` — bundled JS/CSS. marked, mermaid, and theme.css are committed;
  `highlight.min.js` is ignored and fetched on build if missing or invalid.
  Pins and checksum are in `Resources/RESOURCES.md`. If highlight.js is already
  tracked, run `git rm --cached Resources/highlight.min.js` once.
- `test-fixtures/` — manual acceptance fixtures (`just qltest <name>.md`).

## CI

GitHub Actions checks Swift formatting and builds on macOS 15 for relevant pushes,
pull requests, and manual runs. It fetches highlight.js from a clean checkout and
checks that the built extension contains it. Finder previews still need manual
verification with `just qltest`.

## Security notes

- The extension is sandboxed and read-only. WebKit's content process requires
  the `network.client` entitlement even for local HTML; a Content Security Policy
  and navigation delegate block web-page network requests.
- Raw markdown is injected as a `<script type="text/plain">` element with
  `</script` sequences neutralized — never interpolated into JS.
- Raw HTML in the markdown is escaped to literal text (not executed), since
  marked passes it through unescaped by default.

## Adding a highlight.js language

Update `LANGS` and its SHA-256 pin in `scripts/fetch-assets.sh`, then run
`just fetch-assets` to update `Resources/RESOURCES.md`. A hash mismatch reports
its actual value for verification. Do it deliberately — the bundle is a design
constraint.

## Distribution

Out of scope for v1. Set `DEVELOPMENT_TEAM` in `project.yml`, replace ad-hoc
signing in the `build` recipe with a distribution identity, and notarize.
