import Foundation
import os

// MARK: - JSONFileStoreError
/// Why a store file that exists could not be turned into a value. In every
/// case the file on disk is left untouched and the store refuses to write over
/// it, so a read failure can never become data loss.
nonisolated enum JSONFileStoreError: Error {
    /// The file exists but could not be read (I/O error, permissions, data
    /// protection while the device is locked).
    case unreadable(file: URL, underlying: any Error)
    /// The file was read but its contents could not be decoded. `preservedCopy`
    /// is the quarantine copy next to it, or `nil` if making the copy failed.
    case undecodable(file: URL, preservedCopy: URL?, underlying: any Error)
    /// The file carries a schema version this build does not know, e.g. it was
    /// written by a newer app version before a downgrade.
    case unsupportedSchemaVersion(Int, file: URL, preservedCopy: URL?)
}

// MARK: - JSONFileStore
/// The one JSON file store the typed `File…Store`s are built on.
///
/// - A missing file reads as `nil` (first launch).
/// - An unreadable or undecodable file throws `JSONFileStoreError`. Its bytes
///   are copied aside to `<name>.corrupt-<timestamp>.<ext>` once, and every
///   later write is refused while the file stays that way, so the original is
///   never overwritten with empty state.
/// - New writes use a versioned envelope, `{"schemaVersion": N, "payload": …}`,
///   where N is the store's `schemaVersion` (1 unless the store bumped it).
///   Reads accept every version from 1 up to N, plus the bare legacy format
///   (the payload alone) that versions before the envelope wrote, which reads
///   as version 1. The payload's decoder carries the stored version in
///   `userInfo[JSONFileFormat.schemaVersionKey]`, so a payload type can decode
///   an older shape and migrate it in memory. The file itself is rewritten in
///   the current version on the next write.
/// - Writes are atomic. Dates are ISO 8601 with whole seconds.
nonisolated struct JSONFileStore<Value: Codable>: Sendable {
    let fileURL: URL
    /// The version this store writes; reads accept `1...schemaVersion`.
    let schemaVersion: Int
    private let logger: Logger
    private let now: @Sendable () -> Date
    private let decoderUserInfo: [CodingUserInfoKey: any Sendable]

    /// - Parameters:
    ///   - logCategory: the `os.Logger` category, one per store.
    ///   - schemaVersion: the payload format version this store writes. Bump
    ///     it when the payload shape changes, and teach the payload's decoder
    ///     to read the older versions.
    ///   - decoderUserInfo: extra `userInfo` for the payload's decoder, e.g.
    ///     the calendar an older format needs to migrate.
    ///   - now: clock for quarantine file names; injectable for tests.
    init(fileURL: URL,
         logCategory: String,
         schemaVersion: Int = JSONFileFormat.currentSchemaVersion,
         decoderUserInfo: [CodingUserInfoKey: any Sendable] = [:],
         now: @escaping @Sendable () -> Date = { .now }) {
        precondition(schemaVersion >= 1, "Schema versions start at 1")
        self.fileURL = fileURL
        self.schemaVersion = schemaVersion
        self.decoderUserInfo = decoderUserInfo
        self.logger = AppLog.logger(category: logCategory)
        self.now = now
    }

    // MARK: Read
    /// The stored value, or `nil` when the file does not exist yet.
    func read() throws -> Value? {
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile {
            return nil
        } catch {
            logger.error("Cannot read \(fileURL.lastPathComponent, privacy: .public): \(String(describing: error), privacy: .public)")
            throw JSONFileStoreError.unreadable(file: fileURL, underlying: error)
        }
        return try decode(data)
    }

    // MARK: Write
    /// Replaces the stored value. Refused (throws) while the existing file is
    /// unreadable or undecodable.
    func write(_ value: Value) throws {
        _ = try read()
        try encodeAndWrite(value)
    }

    /// Read-modify-write: loads the current value (`initial` when the file is
    /// missing), applies `transform` and writes the result. Refused (throws)
    /// while the existing file is unreadable or undecodable.
    func update(initial: Value, _ transform: (inout Value) throws -> Void) throws {
        var value = try read() ?? initial
        try transform(&value)
        try encodeAndWrite(value)
    }

    /// Deletes the stored value, so the next read returns `nil`. Refused
    /// (throws) while the existing file is unreadable or undecodable; a missing
    /// file is already removed.
    func remove() throws {
        guard try read() != nil else { return }
        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            logger.error("Cannot remove \(fileURL.lastPathComponent, privacy: .public): \(String(describing: error), privacy: .public)")
            throw error
        }
    }

    // MARK: Format
    private func decode(_ data: Data) throws -> Value {
        do {
            if let header = try? JSONFileFormat.decoder.decode(JSONFileFormat.Header.self, from: data) {
                guard (1...schemaVersion).contains(header.schemaVersion) else {
                    let copy = preserveCopy(of: data)
                    logger.error("""
                        Unsupported schema version \(header.schemaVersion, privacy: .public) in \
                        \(fileURL.lastPathComponent, privacy: .public); writes refused
                        """)
                    throw JSONFileStoreError.unsupportedSchemaVersion(
                        header.schemaVersion, file: fileURL, preservedCopy: copy
                    )
                }
                let decoder = JSONFileFormat.decoder(forSchemaVersion: header.schemaVersion, userInfo: decoderUserInfo)
                return try decoder.decode(JSONFileFormat.Envelope<Value>.self, from: data).payload
            }
            // No envelope: the legacy bare format, which is version 1.
            return try JSONFileFormat.decoder(forSchemaVersion: 1, userInfo: decoderUserInfo).decode(Value.self, from: data)
        } catch let error as JSONFileStoreError {
            throw error
        } catch {
            let copy = preserveCopy(of: data)
            logger.error("""
                Cannot decode \(fileURL.lastPathComponent, privacy: .public); writes refused, \
                copy at \(copy?.lastPathComponent ?? "none", privacy: .public): \(String(describing: error), privacy: .public)
                """)
            throw JSONFileStoreError.undecodable(file: fileURL, preservedCopy: copy, underlying: error)
        }
    }

    private func encodeAndWrite(_ value: Value) throws {
        let envelope = JSONFileFormat.Envelope(schemaVersion: schemaVersion, payload: value)
        do {
            let data = try JSONFileFormat.encoder.encode(envelope)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            logger.error("Cannot write \(fileURL.lastPathComponent, privacy: .public): \(String(describing: error), privacy: .public)")
            throw error
        }
    }

    // MARK: Quarantine
    /// Copies `data` next to the store file as `<name>.corrupt-<timestamp>.<ext>`
    /// and returns the copy's URL. Reuses an existing copy with the same bytes,
    /// so repeated reads of the same broken file leave one copy, not one per read.
    private func preserveCopy(of data: Data) -> URL? {
        let directory = fileURL.deletingLastPathComponent()
        let base = fileURL.deletingPathExtension().lastPathComponent
        let ext = fileURL.pathExtension
        let prefix = "\(base).corrupt-"
        let fileManager = FileManager.default

        let siblings = (try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        if let existing = siblings.first(where: {
            $0.lastPathComponent.hasPrefix(prefix) && (try? Data(contentsOf: $0)) == data
        }) {
            return existing
        }

        let stamp = now().formatted(JSONFileFormat.quarantineStamp)
        for attempt in 0..<100 {
            let suffix = attempt == 0 ? "" : "-\(attempt)"
            let name = prefix + stamp + suffix + (ext.isEmpty ? "" : ".\(ext)")
            let url = directory.appending(path: name)
            do {
                try data.write(to: url, options: .withoutOverwriting)
                return url
            } catch let error as CocoaError where error.code == .fileWriteFileExists {
                continue
            } catch {
                logger.error("Cannot copy \(fileURL.lastPathComponent, privacy: .public) aside: \(String(describing: error), privacy: .public)")
                return nil
            }
        }
        return nil
    }
}

// MARK: - JSONFileFormat
/// The on-disk format shared by every `JSONFileStore`. Kept outside the
/// generic type so the coders are created once, and so tests can use them.
nonisolated enum JSONFileFormat {
    /// The version new writes carry, unless a store sets its own.
    static let currentSchemaVersion = 1

    /// `userInfo` key under which a store's decoder carries the schema version
    /// of the file being read (an `Int`). Absent when a value is decoded
    /// outside a store; payload types then read their current format.
    static let schemaVersionKey = CodingUserInfoKey(rawValue: "calipark.schemaVersion")!

    /// The schema version of the file being decoded, or `nil` when the value is
    /// not being read by a `JSONFileStore`.
    static func schemaVersion(of decoder: any Decoder) -> Int? {
        decoder.userInfo[schemaVersionKey] as? Int
    }

    struct Envelope<Payload: Codable>: Codable {
        let schemaVersion: Int
        let payload: Payload
    }

    /// Decodes only the version, to tell an envelope from the bare legacy format.
    struct Header: Decodable {
        let schemaVersion: Int
    }

    /// ISO 8601 dates (whole seconds) keep the files human-readable and stable.
    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    /// A decoder that tells the payload which schema version it is reading.
    /// A fresh instance per read, because `userInfo` is mutable state.
    static func decoder(forSchemaVersion version: Int,
                        userInfo: [CodingUserInfoKey: any Sendable] = [:]) -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        for (key, value) in userInfo {
            decoder.userInfo[key] = value
        }
        decoder.userInfo[schemaVersionKey] = version
        return decoder
    }

    /// `20261103T211500Z`: no colons, so quarantine names are safe everywhere.
    static let quarantineStamp = Date.ISO8601FormatStyle(
        dateSeparator: .omitted,
        dateTimeSeparator: .standard,
        timeSeparator: .omitted,
        timeZone: .gmt
    )
}
