import Cocoa
import Quartz
import WebKit

/// Serves bundled scripts without file URLs or network access.
private final class BundleScriptHandler: NSObject, WKURLSchemeHandler {
  func webView(_ webView: WKWebView, start task: WKURLSchemeTask) {
    guard
      let url = task.request.url, url.host == "assets",
      ["marked.min.js", "highlight.min.js", "mermaid.min.js"].contains(url.lastPathComponent),
      let file = Bundle(for: PreviewViewController.self).url(
        forResource: URL(fileURLWithPath: url.lastPathComponent).deletingPathExtension()
          .lastPathComponent,
        withExtension: "js")
    else {
      task.didFailWithError(URLError(.fileDoesNotExist))
      return
    }
    do {
      let data = try Data(contentsOf: file)
      task.didReceive(
        URLResponse(
          url: url, mimeType: "text/javascript", expectedContentLength: data.count,
          textEncodingName: "utf-8"))
      task.didReceive(data)
      task.didFinish()
    } catch {
      task.didFailWithError(error)
    }
  }

  func webView(_ webView: WKWebView, stop task: WKURLSchemeTask) {}
}

/// Quick Look preview controller for Markdown files.
///
/// Renders the file in a WKWebView using bundled marked + highlight.js + mermaid.
/// A segmented control in the top-right toggles between the rendered view and
/// syntax-highlighted raw source.
final class PreviewViewController: NSViewController, QLPreviewingController, WKNavigationDelegate {

  // MARK: - State

  /// Raw markdown text, read once in `preparePreviewOfFile`. Toggles never re-read disk.
  private var source = ""

  private var showSource = false
  private var pageReady = false

  // MARK: - Views

  private let segmentedControl = NSSegmentedControl(
    labels: ["Rendered", "Source"],
    trackingMode: .selectOne,
    target: nil,
    action: nil
  )

  private let webView: WKWebView = {
    let configuration = WKWebViewConfiguration()
    configuration.setURLSchemeHandler(BundleScriptHandler(), forURLScheme: "miru-resource")
    return WKWebView(frame: .zero, configuration: configuration)
  }()

  // MARK: - Lifecycle

  override func loadView() {
    let container = NSView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))

    segmentedControl.target = self
    segmentedControl.action = #selector(toggleMode(_:))
    segmentedControl.selectedSegment = 0
    segmentedControl.setToolTip("Rendered view: Markdown, code and diagrams", forSegment: 0)
    segmentedControl.setToolTip("Raw Markdown with syntax highlighting", forSegment: 1)
    segmentedControl.translatesAutoresizingMaskIntoConstraints = false

    webView.navigationDelegate = self
    webView.translatesAutoresizingMaskIntoConstraints = false

    container.addSubview(segmentedControl)
    container.addSubview(webView)

    NSLayoutConstraint.activate([
      segmentedControl.topAnchor.constraint(
        equalTo: container.topAnchor, constant: 12),
      segmentedControl.trailingAnchor.constraint(
        equalTo: container.trailingAnchor, constant: -16),

      webView.topAnchor.constraint(
        equalTo: segmentedControl.bottomAnchor, constant: 8),
      webView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      webView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      webView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])

    view = container
  }

  /// Called once by Quick Look with the file to preview.
  @objc(preparePreviewOfFileAtURL:completionHandler:)
  func preparePreviewOfFile(
    at url: URL, completionHandler handler: @escaping @Sendable (Error?) -> Void
  ) {
    do {
      source = try String(contentsOf: url, encoding: .utf8)
    } catch {
      do {
        // Fallback for non-UTF-8 files (e.g. Latin-1).
        source = try String(contentsOf: url, encoding: .isoLatin1)
      } catch {
        handler(error)
        return
      }
    }
    showSource = false
    segmentedControl.selectedSegment = 0
    render()
    handler(nil)
  }

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    pageReady = true
    applyMode()
  }

  func webView(
    _ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
    decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
  ) {
    let scheme = navigationAction.request.url?.scheme
    decisionHandler(scheme == "about" || scheme == "miru-resource" ? .allow : .cancel)
  }

  // MARK: - Actions

  @objc private func toggleMode(_ sender: NSSegmentedControl) {
    showSource = sender.selectedSegment == 1
    applyMode()
  }

  // MARK: - Rendering

  private func applyMode() {
    guard pageReady else { return }
    let mode = showSource ? "true" : "false"
    webView.evaluateJavaScript("window.setMode(\(mode))", completionHandler: nil)
  }

  private func render() {
    pageReady = false
    do {
      webView.loadHTMLString(try pageHTML(), baseURL: URL(string: "miru-resource://assets/"))
    } catch {
      webView.loadHTMLString("<p>Miru could not load its bundled assets.</p>", baseURL: nil)
    }
  }

  // MARK: - Page template

  private static let themeCSS: String? = {
    guard
      let url = Bundle(for: PreviewViewController.self).url(
        forResource: "theme", withExtension: "css")
    else { return nil }
    return try? String(contentsOf: url, encoding: .utf8)
  }()

  private func pageHTML() throws -> String {
    guard let themeCSS = Self.themeCSS else { throw CocoaError(.fileReadNoSuchFile) }
    // Neutralize `</script` (any case) so the raw markdown cannot close its
    // own <script type="text/plain"> element. Restored in JS after reading
    // the element's textContent.
    let neutralized =
      source
      .replacingOccurrences(of: "</script", with: "<\\/script", options: .caseInsensitive)

    return #"""
      <!DOCTYPE html>
      <html>
      <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <meta name="color-scheme" content="light dark">
      <meta http-equiv="Content-Security-Policy"
            content="default-src 'none'; script-src 'unsafe-inline' miru-resource:; style-src 'unsafe-inline'; img-src data: miru-resource:; connect-src 'none'">
      <style>\#(themeCSS)</style>
      <script src="marked.min.js"></script>
      <script src="highlight.min.js"></script>
      <style>
        html  { background: #ffffff; }
        body {
          margin: 0; padding: 24px 36px 64px;
          font-family: -apple-system, "Helvetica Neue", Helvetica, sans-serif;
          font-size: 15px; line-height: 1.6;
          color: #1f2328; background: #ffffff;
          overflow-wrap: break-word;
        }
        h1, h2 { border-bottom: 1px solid #d1d9e0; padding-bottom: .3em; }
        a { color: #0969da; }
        blockquote {
          margin: 0; padding: 0 1em;
          color: #59636e; border-left: .25em solid #d1d9e0;
        }
        table { border-collapse: collapse; margin: 8px 0; }
        th, td { border: 1px solid #d1d9e0; padding: 6px 13px; }
        tr:nth-child(2n) { background: #f6f8fa; }
        code, pre {
          font-family: ui-monospace, SFMono-Regular, "SF Mono", Menlo, monospace;
          font-size: 85%;
        }
        code { background: #f6f8fa; padding: .2em .4em; border-radius: 6px; }
        pre {
          background: #f6f8fa; padding: 16px; border-radius: 6px;
          line-height: 1.45; overflow-x: auto;
        }
        pre code { background: transparent; padding: 0; }
        img { max-width: 100%; }
        hr { border: 0; border-top: 1px solid #d1d9e0; }
        .mermaid { text-align: center; }
        [hidden] { display: none !important; }
        @media (prefers-color-scheme: dark) {
          html, body { background: #0d1117; }
          body { color: #e6edf3; }
          h1, h2 { border-color: #3d444d; }
          a { color: #4493f8; }
          blockquote { color: #9198a1; border-color: #3d444d; }
          th, td { border-color: #3d444d; }
          tr:nth-child(2n) { background: #151b23; }
          code, pre { background: #151b23; }
          hr { border-top-color: #3d444d; }
        }
      </style>
      </head>
      <body>
      <noscript>Miru needs JavaScript to render Markdown.</noscript>
      <script type="text/plain" id="src">\#(neutralized)
      </script>
      <div id="rendered"></div>
      <pre id="source-view" hidden><code class="hljs"></code></pre>
      <script>
      const el = document.getElementById('src');
      let src = el.textContent
        .replace(/^\n/, '')                          // leading newline from the template
        .replace(/<[\\]\/script/gi, '<' + '/' + 'script'); // rebuild the tag; a literal close-sequence would truncate this block

      let sourceHighlighted = false;
      let mermaidLoaded = false;
      let mermaidStarted = false;
      function renderDiagrams() {
        if (!mermaidLoaded || mermaidStarted || document.getElementById('rendered').hidden) return;
        mermaidStarted = true;
        try {
          mermaid.run({ querySelector: '.mermaid', suppressErrors: true })
            .catch(err => console.error('mermaid:', err));
        } catch (error) {
          console.error('mermaid:', error);
        }
      }

      window.setMode = function(showSource) {
        const sourceView = document.getElementById('source-view');
        if (showSource && !sourceHighlighted) {
          sourceView.querySelector('code').innerHTML = hljs.highlight(src, { language: 'markdown' }).value;
          sourceHighlighted = true;
        }
        document.getElementById('rendered').hidden = showSource;
        sourceView.hidden = !showSource;
        if (!showSource) renderDiagrams();
      };

      try {
        marked.use({
          // marked v12 renderer methods take positional args (token-object API is v13).
          // Escape raw HTML (block + inline): marked passes it through unescaped, and
          // we will not execute arbitrary HTML from an untrusted file — it is shown
          // as literal text instead.
          renderer: {
            html: (text) => text.replace(/[&<>]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' }[c])),
            code(code, lang) {
              const name = (lang || '').match(/^\S*/)[0] || '';
              if (name === 'mermaid') {
                return `<pre class="mermaid">${code.replace(/[<&]/g, c => c === '<' ? '&lt;' : '&amp;')}</pre>`;
              }
              const value = name && hljs.getLanguage(name)
                ? hljs.highlight(code, { language: name }).value
                : hljs.highlightAuto(code).value;
              return `<pre><code class="hljs">${value}</code></pre>`;
            }
          }
        });

        document.getElementById('rendered').innerHTML = marked.parse(src);
        if (document.querySelector('.mermaid')) {
          // Let the Markdown paint before loading the large Mermaid bundle.
          requestAnimationFrame(() => setTimeout(() => {
            const script = document.createElement('script');
            script.src = 'mermaid.min.js';
            script.onload = () => {
              try {
                // Disable Mermaid's automatic window-load pass even in Source mode.
                mermaid.initialize({
                  startOnLoad: false,
                  theme: matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'default'
                });
                mermaidLoaded = true;
                renderDiagrams();
              } catch (error) {
                console.error('mermaid:', error);
              }
            };
            script.onerror = () => console.error('Miru could not load Mermaid');
            document.head.appendChild(script);
          }, 50));
        }
      } catch (error) {
        document.body.textContent = `Miru could not render: ${error.message}`;
      }
      </script>
      </body>
      </html>
      """#
  }
}
