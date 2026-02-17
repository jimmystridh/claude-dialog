import AppKit
import Foundation

// Read hook JSON from stdin
guard let inputData = FileHandle.standardInput.readDataToEndOfFile() as Data?,
      !inputData.isEmpty else {
    exit(0)
}

let hookInput: HookInput
do {
    hookInput = try JSONDecoder().decode(HookInput.self, from: inputData)
} catch {
    fputs("Failed to decode input: \(error)\n", stderr)
    exit(0)
}

guard !hookInput.toolInput.questions.isEmpty else {
    exit(0)
}

// Set up app as accessory (no dock icon)
let app = NSApplication.shared
app.setActivationPolicy(.accessory)

// Create coordinator and window on main thread
let coordinator = DialogCoordinator(questions: hookInput.toolInput.questions, cwd: hookInput.cwd)

let panel = DialogWindow.create(coordinator: coordinator)

coordinator.completion = { result in
    switch result {
    case .submitted(let answers):
        let data = OutputFormatter.buildOutput(answers: answers)
        FileHandle.standardOutput.write(data)
    case .cancelled:
        break // No output — falls through to terminal widget
    }
    panel.close()
    app.stop(nil)
    // Post a dummy event to unblock the run loop after stop
    let event = NSEvent.otherEvent(
        with: .applicationDefined,
        location: .zero,
        modifierFlags: [],
        timestamp: 0,
        windowNumber: 0,
        context: nil,
        subtype: 0,
        data1: 0,
        data2: 0
    )!
    app.postEvent(event, atStart: true)
}

coordinator.installKeyMonitor()
panel.makeKeyAndOrderFront(nil)
app.activate(ignoringOtherApps: true)

app.run()
exit(0)
