import Foundation

/// Build-time configuration.
enum AppConfig {
    /// The media server every installed copy of the app streams exercise
    /// videos from — this is what makes YOUR uploaded videos appear for all
    /// users, with no setup on their side.
    ///
    /// Set it to your deployed server before shipping, e.g.
    ///   "https://muscletrainer-media.<your-subdomain>.workers.dev"
    /// Upload/replace videos any time via the server's admin page; the app
    /// refreshes its manifest on every launch, so new videos show up without
    /// an app update.
    ///
    /// Leave empty during development if you're testing against a local
    /// server via Profile → Exercise videos (that field overrides this).
    static let defaultMediaServerURL = ""
}
