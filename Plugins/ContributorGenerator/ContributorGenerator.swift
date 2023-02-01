import PackagePlugin
import Foundation

@main
struct ContributorGenerator: CommandPlugin {

//    func performCommand(context: PluginContext, arguments: [String]) throws {
//        print("Command plugin execution for Swift package \(context.package.displayName)")
//    }
    
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = ["log", "--pretty=format:- %an <%ae>%n"]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        try process.run()
        process.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: outputData, as: UTF8.self)

        let contributors = Set(output.components(separatedBy: CharacterSet.newlines)).sorted().filter { !$0.isEmpty }
        try contributors.joined(separator: "\n").write(toFile: "CONTRIBUTORS.txt", atomically: true, encoding: .utf8)
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension ContributorGenerator: XcodeCommandPlugin {

    /// 👇 This entry point is called when operating on an Xcode project.
    func performCommand(context: XcodePluginContext, arguments: [String]) throws {
        print("Command plugin execution for Xcode project \(context.xcodeProject.displayName)")
    }
}
#endif

