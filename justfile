# Miru — macOS Markdown Quick Look extension

app_name  := "Miru"
build_dir := "build"
config    := "Release"

# List available recipes
default:
    @just --list

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

# Install to /Applications and register the extension
install: build
    rm -rf /Applications/{{app_name}}.app
    cp -R {{build_dir}}/Build/Products/{{config}}/{{app_name}}.app /Applications/
    open /Applications/{{app_name}}.app          # first launch registers the extension
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
