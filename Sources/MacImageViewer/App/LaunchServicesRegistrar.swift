import Foundation

enum LaunchServicesRegistrar {
    private static let lsregisterPath =
        "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"

    static func registerInstalledBundleIfNeeded() {
        let bundleURL = Bundle.main.bundleURL.resolvingSymlinksInPath()
        let path = bundleURL.path

        guard path.hasPrefix("/Applications/") || path.hasPrefix(NSHomeDirectory() + "/Applications/") else {
            return
        }

        guard FileManager.default.isExecutableFile(atPath: lsregisterPath) else {
            return
        }

        DispatchQueue.global(qos: .utility).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: lsregisterPath)
            process.arguments = ["-f", path]
            process.standardOutput = Pipe()
            process.standardError = Pipe()
            try? process.run()
            process.waitUntilExit()
        }
    }
}
