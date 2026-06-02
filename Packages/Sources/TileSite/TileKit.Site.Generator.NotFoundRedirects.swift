import TileCore

extension TileKit.Site.Generator {
    func notFoundRedirectScript(
        redirects: TileKit.Site.NotFoundRedirects,
    ) -> String {
        guard !redirects.isEmpty else {
            return ""
        }
        let exact = redirects.exact
            .sorted { $0.source < $1.source }
            .map { "[\(jsString($0.source.lowercased())), \(jsString($0.target))]" }
            .joined(separator: ",")
        let prefixes = redirects.prefixes
            .sorted {
                if $0.source.count == $1.source.count {
                    return $0.source < $1.source
                }
                return $0.source.count > $1.source.count
            }
            .map { "[\(jsString($0.source.lowercased())), \(jsString($0.target))]" }
            .joined(separator: ",")

        return """
        <script>
        (function () {
          var path = window.location.pathname.toLowerCase();
          var suffix = (window.location.search || '') + (window.location.hash || '');
          var exact = [\(exact)];
          for (var i = 0; i < exact.length; i++) {
            if (path === exact[i][0]) {
              window.location.replace(exact[i][1] + suffix);
              return;
            }
          }
          var prefixes = [\(prefixes)];
          for (var j = 0; j < prefixes.length; j++) {
            if (path.indexOf(prefixes[j][0]) === 0) {
              window.location.replace(prefixes[j][1] + suffix);
              return;
            }
          }
        })();
        </script>
        """
    }

    func injectNotFoundRedirectScript(
        into html: String,
        redirects: TileKit.Site.NotFoundRedirects,
    ) -> String {
        let script = notFoundRedirectScript(redirects: redirects)
        guard !script.isEmpty else {
            return html
        }
        guard let bodyEnd = html.range(of: "</body>", options: [.caseInsensitive, .backwards]) else {
            return html + "\n" + script
        }
        return String(html[..<bodyEnd.lowerBound])
            + script
            + "\n"
            + String(html[bodyEnd.lowerBound...])
    }

    private func jsString(
        _ value: String,
    ) -> String {
        var result = "\""
        for character in value {
            switch character {
            case "\\":
                result += "\\\\"
            case "\"":
                result += "\\\""
            case "\n":
                result += "\\n"
            case "\r":
                result += "\\r"
            case "<":
                result += "\\u003C"
            case ">":
                result += "\\u003E"
            case "&":
                result += "\\u0026"
            default:
                result.append(character)
            }
        }
        result += "\""
        return result
    }
}
