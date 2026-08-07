import AVFoundation
import Foundation
import SwiftUI
import UIKit

/// Talks to the self-hosted media server (see `backend/`): fetches the
/// exercise-ID → video URL manifest and resolves streaming URLs. The manifest
/// is cached so previously seen videos keep resolving offline.
@MainActor
@Observable
final class MediaService {
    private static let serverKey = "media.server.url"
    private static let cacheKey = "media.manifest.cache"

    var serverURLString: String {
        didSet { UserDefaults.standard.set(serverURLString, forKey: Self.serverKey) }
    }

    private(set) var videos: [String: String]
    private(set) var isLoading = false
    private(set) var lastError: String?

    init() {
        serverURLString = UserDefaults.standard.string(forKey: Self.serverKey) ?? ""
        if let data = UserDefaults.standard.data(forKey: Self.cacheKey),
           let cached = try? JSONDecoder().decode([String: String].self, from: data) {
            videos = cached
        } else {
            videos = [:]
        }
    }

    var baseURL: URL? {
        let trimmed = serverURLString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let url = URL(string: trimmed), url.scheme != nil, url.host() != nil else {
            return nil
        }
        return url
    }

    var isConfigured: Bool { baseURL != nil }

    /// The user's uploaded video for an exercise, if one exists on the server.
    func videoURL(for exerciseID: String) -> URL? {
        guard let base = baseURL, let path = videos[exerciseID] else { return nil }
        return URL(string: path, relativeTo: base)
    }

    private struct Manifest: Decodable {
        let videos: [String: String]
    }

    func refresh() async {
        guard let base = baseURL else {
            videos = [:]
            lastError = nil
            return
        }
        isLoading = true
        lastError = nil
        defer { isLoading = false }
        do {
            var request = URLRequest(url: base.appending(path: "api/manifest"))
            request.timeoutInterval = 10
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw URLError(.badServerResponse)
            }
            let manifest = try JSONDecoder().decode(Manifest.self, from: data)
            videos = manifest.videos
            if let encoded = try? JSONEncoder().encode(manifest.videos) {
                UserDefaults.standard.set(encoded, forKey: Self.cacheKey)
            }
        } catch {
            lastError = "Couldn't reach the media server. Check the URL and that the server is running."
        }
    }
}

// MARK: - Looping video player

/// Muted, autoplaying, seamlessly looping video — used for exercise demos.
struct LoopingVideoView: UIViewRepresentable {
    let url: URL

    final class Coordinator {
        var player: AVQueuePlayer?
        var looper: AVPlayerLooper?
        var currentURL: URL?
    }

    final class PlayerView: UIView {
        override static var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.playerLayer.videoGravity = .resizeAspectFill
        attachPlayer(to: view, context: context)
        return view
    }

    func updateUIView(_ view: PlayerView, context: Context) {
        if context.coordinator.currentURL != url {
            attachPlayer(to: view, context: context)
        }
    }

    private func attachPlayer(to view: PlayerView, context: Context) {
        let item = AVPlayerItem(url: url)
        let player = AVQueuePlayer()
        player.isMuted = true
        player.preventsDisplaySleepDuringVideoPlayback = false
        context.coordinator.looper = AVPlayerLooper(player: player, templateItem: item)
        context.coordinator.player = player
        context.coordinator.currentURL = url
        view.playerLayer.player = player
        player.play()
    }

    static func dismantleUIView(_ uiView: PlayerView, coordinator: Coordinator) {
        coordinator.player?.pause()
        coordinator.player?.removeAllItems()
        coordinator.player = nil
        coordinator.looper = nil
    }
}
