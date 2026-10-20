import Foundation
import Testing
@testable import Core

extension AllCoreTests {
    struct OneClickExtractionTests {
        @Test func missingOrUnknownDestinationUsesArchiveFolder() throws {
            let suite = "OneClickExtractionTests.\(UUID().uuidString)"
            let defaults = try #require(UserDefaults(suiteName: suite))
            defer { defaults.removePersistentDomain(forName: suite) }

            #expect(OneClickExtractionDestination.saved(in: defaults) == .archiveFolder)
            defaults.set("unknown", forKey: Keys.oneClickExtractionDestination)
            #expect(OneClickExtractionDestination.saved(in: defaults) == .archiveFolder)

            defaults.set(OneClickExtractionDestination.chooseFolder.rawValue,
                         forKey: Keys.oneClickExtractionDestination)
            defaults.set(false, forKey: Keys.oneClickExtraction)
            #expect(OneClickExtractionDestination.saved(in: defaults) == .chooseFolder)
        }

        @Test func explicitDestinationsAndCompoundNames() throws {
            let parent = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            let archive = parent.appendingPathComponent("Photos.TAR.GZ")
            let detector = ArchiveTypeDetector(catalog: ArchiveTypeCatalog())

            #expect(OneClickExtractionDestination.sameFolder.directory(for: archive, detector: detector)?.path == parent.path)
            #expect(OneClickExtractionDestination.archiveFolder.directory(for: archive, detector: detector)?.lastPathComponent == "Photos")
            #expect(OneClickExtractionDestination.chooseFolder.directory(for: archive, detector: detector) == nil)
            #expect(!FileManager.default.fileExists(atPath: parent.path), "Resolving a destination must not create it")
        }

        @Test func namedFolderPreservesExistingOutput() throws {
            let parent = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at: parent.appendingPathComponent("Photos (2)"), withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: parent) }
            // A file as well as a directory can occupy the desired folder name.
            try Data("keep me".utf8).write(to: parent.appendingPathComponent("Photos"))

            let destination = OneClickExtractionDestination.archiveFolder.directory(
                for: parent.appendingPathComponent("Photos.ZIP"),
                detector: ArchiveTypeDetector(catalog: ArchiveTypeCatalog()))

            #expect(destination?.lastPathComponent == "Photos (3)")
            #expect(try Data(contentsOf: parent.appendingPathComponent("Photos")) == Data("keep me".utf8))
        }

        @Test func extensionlessArchiveGetsItsOwnFolder() throws {
            let parent = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
            defer { try? FileManager.default.removeItem(at: parent) }
            let fixture = try #require(Bundle.module.url(forResource: "defaultArchives", withExtension: nil))
                .appendingPathComponent("defaultArchive.zip")
            let archive = parent.appendingPathComponent("Photos")
            try FileManager.default.copyItem(at: fixture, to: archive)
            let detector = ArchiveTypeDetector(catalog: ArchiveTypeCatalog())

            #expect(detector.detect(for: archive) != nil)
            #expect(OneClickExtractionDestination.archiveFolder.directory(for: archive, detector: detector)?.lastPathComponent == "Photos (2)")
        }
    }
}
