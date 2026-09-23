# Miru — macOS Markdown Quick Look extension

app_name  := "Miru"
build_dir := "build"
config    := "Release"

# List available recipes
default:
    @just --list

# Read the app version from the XcodeGen spec
version:
    @awk -F '"' '/^    MARKETING_VERSION: / { print $2; found=1; exit } END { if (!found) exit 1 }' project.yml

# Bump the version, commit if changed, and create an annotated tag
bump-version version:
    @printf '%s\n' {{quote(version)}} | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || { echo 'Version must use x.y.z format' >&2; exit 2; }
    @git rev-parse --is-inside-work-tree >/dev/null || { echo 'Run from a Git checkout' >&2; exit 2; }
    @git diff --quiet && git diff --cached --quiet || { echo 'Commit or stash tracked changes first' >&2; exit 2; }
    @if git show-ref --verify --quiet refs/tags/v{{version}}; then echo 'Tag v{{version}} already exists' >&2; exit 2; fi
    @perl -i -pe 's/^    MARKETING_VERSION: "[0-9]+(?:\.[0-9]+){2}"$/    MARKETING_VERSION: "{{version}}"/' project.yml
    @test "$(just version)" = {{quote(version)}}
    git add project.yml
    if ! git diff --cached --quiet; then git commit -m 'chore(release): bump v{{version}}'; fi
    git tag -a 'v{{version}}' -m 'v{{version}}'

# Regenerate the Xcode project from project.yml
gen:
    xcodegen generate

# Download and verify highlight.js before generating the project
fetch-highlight:
    ./scripts/fetch-assets.sh highlight

# Build the app (ad-hoc signed so Quick Look can load the extension)
build: fetch-highlight gen
    xcodebuild \
      -project {{app_name}}.xcodeproj \
      -scheme {{app_name}} \
      -configuration {{config}} \
      -derivedDataPath {{build_dir}} \
      CODE_SIGN_IDENTITY="-" \
      CODE_SIGNING_REQUIRED=YES \
      build

# Install to /Applications and register the extension without launching the app
install: build
    rm -rf /Applications/{{app_name}}.app
    cp -R {{build_dir}}/Build/Products/{{config}}/{{app_name}}.app /Applications/
    pluginkit -a /Applications/{{app_name}}.app/Contents/PlugIns/MiruPreview.appex
    pluginkit -mAvvv -p com.apple.quicklook.preview | grep -i miru || true

# Install and reveal a fixture in Finder (name or path); press Space to preview.
qltest fixture="mixed.md": install
    @p="{{fixture}}"; case "$p" in */*) ;; *) p="test-fixtures/$p" ;; esac; \
    test -f "$p" && open -R "$p" && printf 'Press Space in Finder to preview %s\n' "$p"

# Fetch pinned JS/CSS assets into Resources/
fetch-assets:
    ./scripts/fetch-assets.sh

# Format Swift sources with swift-format (ships with the Swift toolchain)
format:
    find App Extension -name '*.swift' -exec xcrun swift-format format --in-place {} \;

# Check Swift formatting without changing files
format-check:
    xcrun swift-format lint --strict --recursive App Extension

# Reset Quick Look caches (run after Info.plist / UTI changes)
reset:
    qlmanage -r
    qlmanage -r cache
    killall Finder

# Remove build artifacts and generated project
clean:
    rm -rf {{build_dir}} {{app_name}}.xcodeproj

# Clean + reset caches
nuke: clean reset
