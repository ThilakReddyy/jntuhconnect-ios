import Foundation

enum AppLinkPolicy {
    /// The official JNTUH result host serves some result pages only over HTTP.
    /// Preserve HTTPS everywhere else and downgrade only this trusted host.
    static func browserURL(_ url: URL) -> URL {
        guard url.host?.lowercased() == "results.jntuh.ac.in",
              var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }
        components.scheme = "http"
        return components.url ?? url
    }
}
