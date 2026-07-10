import Foundation

/// Runs a shell command asynchronously and captures its stdout.
/// `Command=uname -r`. The render loop is never blocked; the value updates
/// when the command finishes. Numeric output also populates `value`.
public final class ShellMeasure: Measure {
    private let command: String
    private let queue = DispatchQueue(label: "rainier.shell", qos: .utility)
    private var running = false
    private var latest: String = ""

    public override init(name: String, options: Options) {
        self.command = options.str("command", default: "")
        super.init(name: name, options: options)
    }

    public override func update() {
        stringOverride = latest
        if let numeric = Double(latest.trimmingCharacters(in: .whitespacesAndNewlines)) {
            value = numeric
        }
        guard !command.isEmpty, !running else { return }
        running = true
        queue.async { [weak self] in
            guard let self else { return }
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/sh")
            process.arguments = ["-c", self.command]
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = FileHandle.nullDevice
            var output = ""
            do {
                try process.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()
                output = String(data: data, encoding: .utf8) ?? ""
            } catch {
                output = ""
            }
            DispatchQueue.main.async {
                self.latest = output.trimmingCharacters(in: .whitespacesAndNewlines)
                self.running = false
            }
        }
    }
}
