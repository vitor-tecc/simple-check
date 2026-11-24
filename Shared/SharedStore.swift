import Foundation
import SwiftData

/// Opens the task database in a place both the app and the widget can read.
///
/// The app and the widget share data through an App Group. When the app is
/// re-signed by a sideloading tool, the App Group may be renamed (or dropped),
/// so instead of trusting one hard-coded name we try every group this build
/// was actually granted.
enum SharedStore {
    static let declaredAppGroup = "group.com.example.checklist"
    private static let storeName = "Checklist.store"

    /// The shared App Group folder, or nil when this build has no usable App Group.
    static let groupContainerURL: URL? = {
        let fileManager = FileManager.default
        for group in candidateAppGroups() {
            if let url = fileManager.containerURL(forSecurityApplicationGroupIdentifier: group) {
                return url
            }
        }
        return nil
    }()

    static func makeContainer() throws -> ModelContainer {
        let schema = Schema([TodoItem.self])
        if let folder = groupContainerURL {
            let url = folder.appending(path: storeName)
            copyLegacyStoreIfNeeded(to: url)
            let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
            return try ModelContainer(for: schema, configurations: [configuration])
        }
        // No App Group: keep using the app's private store, as before the widget existed.
        let configuration = ModelConfiguration(schema: schema, groupContainer: .none, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    // MARK: - Finding the App Group

    /// The declared group first, then AltStore-style `ALTAppGroups`, then the groups
    /// listed in this bundle's own provisioning profile (where re-signers put renamed groups).
    private static func candidateAppGroups(bundle: Bundle = .main) -> [String] {
        var groups = [declaredAppGroup]
        if let altGroups = bundle.object(forInfoDictionaryKey: "ALTAppGroups") as? [String] {
            groups += altGroups
        }
        groups += provisionedAppGroups(bundle: bundle)
        var seen = Set<String>()
        return groups.filter { seen.insert($0).inserted }
    }

    private static func provisionedAppGroups(bundle: Bundle) -> [String] {
        guard let url = bundle.url(forResource: "embedded", withExtension: "mobileprovision"),
              let data = try? Data(contentsOf: url),
              let start = data.range(of: Data("<?xml".utf8)),
              let end = data.range(of: Data("</plist>".utf8), options: .backwards),
              start.lowerBound < end.upperBound
        else { return [] }

        // The profile is a signed envelope around a plain XML plist; read just the plist.
        let plistData = data.subdata(in: start.lowerBound..<end.upperBound)
        guard let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any],
              let entitlements = plist["Entitlements"] as? [String: Any]
        else { return [] }
        return entitlements["com.apple.security.application-groups"] as? [String] ?? []
    }

    // MARK: - Moving tasks saved before the widget existed

    /// Earlier versions kept tasks in the app's private `default.store`. Copy it into the
    /// shared folder the first time, so no tasks are lost. The old file is left in place.
    private static func copyLegacyStoreIfNeeded(to destination: URL) {
        let fileManager = FileManager.default
        guard !fileManager.fileExists(atPath: destination.path(percentEncoded: false)) else { return }

        let legacy = URL.applicationSupportDirectory.appending(path: "default.store")
        guard fileManager.fileExists(atPath: legacy.path(percentEncoded: false)) else { return }

        // Copy the side files first and the main file last, so a half-finished copy is never used.
        for suffix in ["-wal", "-shm", ""] {
            let source = URL(filePath: legacy.path(percentEncoded: false) + suffix)
            let target = URL(filePath: destination.path(percentEncoded: false) + suffix)
            guard fileManager.fileExists(atPath: source.path(percentEncoded: false)) else { continue }
            try? fileManager.copyItem(at: source, to: target)
        }
    }
}
