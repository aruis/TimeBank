//
//  ReleaseNote.swift
//  TimeBank
//
//  Created by Codex on 2026/3/26.
//

import Foundation

struct ReleaseNote: Identifiable, Equatable {
    let version: String
    let features: [String]

    var id: String { version }
}

enum ReleaseNotesRegistry {
    static let notes: [ReleaseNote] = [
        ReleaseNote(
            version: "1.25.2",
            features: [
                "设置页面改成了更清晰的分组布局",
                "新增了“更多应用”推荐区域，可以直接查看 BookTime 和 PinTime",
                "优化了设置页的品牌展示与通知引导"
            ]
        )
    ]

    static func note(for version: String) -> ReleaseNote? {
        notes.first(where: { $0.version == version })
    }
}

final class ReleaseNotesManager {
    static let shared = ReleaseNotesManager()

    private enum StorageKey {
        static let lastShownVersion = "release_notes.last_shown_version"
        static let lastShownSignature = "release_notes.last_shown_signature"
    }

    private let defaults = UserDefaults.standard

    private init() {}

    func noteToShow(for currentVersion: String) -> ReleaseNote? {
        let lastShownVersion = defaults.string(forKey: StorageKey.lastShownVersion) ?? "0.0.0"
        guard let note = ReleaseNotesRegistry.note(for: currentVersion) else { return nil }

        let lastShownSignature = defaults.string(forKey: StorageKey.lastShownSignature)
        let currentSignature = signature(for: note)

        if isVersion(currentVersion, greaterThan: lastShownVersion) || currentSignature != lastShownSignature {
            return note
        }

        return nil
    }

    func markShown(version: String) {
        defaults.set(version, forKey: StorageKey.lastShownVersion)
        if let note = ReleaseNotesRegistry.note(for: version) {
            defaults.set(signature(for: note), forKey: StorageKey.lastShownSignature)
        }
    }

    private func isVersion(_ lhs: String, greaterThan rhs: String) -> Bool {
        let left = versionComponents(lhs)
        let right = versionComponents(rhs)
        let count = max(left.count, right.count)

        for idx in 0..<count {
            let l = idx < left.count ? left[idx] : 0
            let r = idx < right.count ? right[idx] : 0
            if l != r {
                return l > r
            }
        }

        return false
    }

    private func versionComponents(_ version: String) -> [Int] {
        version.split(separator: ".").map { Int($0) ?? 0 }
    }

    private func signature(for note: ReleaseNote) -> String {
        "\(note.version)|\(note.features.joined(separator: "|"))"
    }
}
