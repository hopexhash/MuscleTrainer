import CoreTransferable
import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// A video picked from the photo library, delivered as a temporary file.
struct PickedVideo: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { video in
            SentTransferredFile(video.url)
        } importing: { received in
            let ext = received.file.pathExtension.isEmpty ? "mov" : received.file.pathExtension
            let destination = URL.temporaryDirectory.appending(path: "picked-\(UUID().uuidString).\(ext)")
            try FileManager.default.copyItem(at: received.file, to: destination)
            return PickedVideo(url: destination)
        }
    }
}

/// Stores per-workout cover videos in the app's Documents directory,
/// named by the workout's UUID so they survive renames.
enum WorkoutCoverStore {

    static var directory: URL {
        let dir = URL.documentsDirectory.appending(path: "workout-covers")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func url(for fileName: String?) -> URL? {
        guard let fileName, !fileName.isEmpty else { return nil }
        let url = directory.appending(path: fileName)
        return FileManager.default.fileExists(atPath: url.path()) ? url : nil
    }

    /// Moves a picked video into place and points the workout at it.
    @discardableResult
    static func saveCover(from tempURL: URL, for workout: Workout) -> Bool {
        let ext = tempURL.pathExtension.isEmpty ? "mov" : tempURL.pathExtension
        let fileName = "\(workout.id.uuidString)-\(Int(Date.now.timeIntervalSince1970)).\(ext)"
        let destination = directory.appending(path: fileName)
        do {
            try FileManager.default.moveItem(at: tempURL, to: destination)
        } catch {
            return false
        }
        removeFiles(for: workout, keeping: fileName)
        workout.coverVideoFileName = fileName
        return true
    }

    static func deleteCover(for workout: Workout) {
        removeFiles(for: workout, keeping: nil)
        workout.coverVideoFileName = nil
    }

    private static func removeFiles(for workout: Workout, keeping: String?) {
        let prefix = workout.id.uuidString
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: directory.path()) else { return }
        for file in files where file.hasPrefix(prefix) && file != keeping {
            try? FileManager.default.removeItem(at: directory.appending(path: file))
        }
    }
}
