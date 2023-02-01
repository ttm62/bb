// GenerateCodeStats.swift
import Foundation
import PackagePlugin

@main // Plugin's entry point
struct GenerateCodeStats: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        // 1 - Parse all targets from the arguments. These are the targets
        // that the developer has manually chosen
        let targets = try parseTargets(context: context, arguments: arguments)
        let processor = FileStatsProcessor()
        let fm = FileManager.default
        let dirs = targets.isEmpty ? [context.package.directory] : targets.map(\.directory)

        // 2 - Loop through all targets' files
        for dir in dirs {
            guard let files = fm.enumerator(atPath: dir.string) else { continue }

            // 2.1 - Process only swift files
            for case let path as String in files {
                let fullpath = dir.appending([path])
                var isDirectory: ObjCBool = false

                guard
                    fullpath.extension == "swift",
                    fm.fileExists(atPath: fullpath.string, isDirectory: &isDirectory),
                    !isDirectory.boolValue
                else { continue }

                try processor.processFile(at: fullpath)
            }
        }

        let output = context.package.directory.appending(["CodeStats.md"])

        print(processor.stats.description)

        // 3 - Write the stats to a file in the root directory of the package
        try processor.stats.description.write(
            to: URL(fileURLWithPath: output.string),
            atomically: true,
            encoding: .utf8)
    }

    private func parseTargets(
        context: PluginContext,
        arguments: [String]
    ) throws -> [Target] {
        return arguments
            .enumerated()
            .filter { $0.element == "--target" }
            .map { arguments[$0.offset + 1] }
            .compactMap { try? context.package.targets(named: [$0]) }
            .flatMap { $0 }
    }
}

struct CodeStats: CustomStringConvertible {
    var numberOfFiles: Int = 0
    var numberOfLines: Int = 0
    var numberOfClasses: Int = 0
    var numberOfStructs: Int = 0
    var numberOfEnums: Int = 0
    var numberOfProtocols: Int = 0

    var description: String {
        return [
            "## Code statistics\n",
            "Number of files:     \(fmt(numberOfFiles))",
            "Number of lines:     \(fmt(numberOfLines))",
            "Number of classes:   \(fmt(numberOfClasses))",
            "Number of structs:   \(fmt(numberOfStructs))",
            "Number of enums:     \(fmt(numberOfEnums))",
            "Number of protocols: \(fmt(numberOfProtocols))",
        ].joined(separator: "\n")
    }

    private func fmt(_ i: Int) -> String {
        return String(format: "%8d", i)
    }
}

class FileStatsProcessor {
    private(set) var stats = CodeStats()
    private let definitionsRegex: NSRegularExpression = {
        let pattern = #"\b(?<name>protocol|class|struct|enum)\b"#
        return try! NSRegularExpression(pattern: pattern)
    }()
    private let newlinesRegex: NSRegularExpression = {
        return try! NSRegularExpression(pattern: #"$"#, options: [.anchorsMatchLines])
    }()

    func processFile(at path: Path) throws {
        let text = try String(contentsOfFile: path.string)
        let textRange = NSRange(text.startIndex..<text.endIndex, in: text)

        stats.numberOfFiles += 1
        stats.numberOfLines += newlinesRegex.matches(in: text, range: textRange).count

        definitionsRegex.enumerateMatches(in: text, range: textRange) { match, _, _ in
            guard let nsRange = match?.range(withName: "name"),
                  let range = Range(nsRange, in: text)
            else { return }

            switch text[range.lowerBound] {
            case "p": stats.numberOfProtocols += 1
            case "c": stats.numberOfClasses += 1
            case "s": stats.numberOfStructs += 1
            case "e": stats.numberOfEnums += 1
            default: break
            }
        }
    }
}
