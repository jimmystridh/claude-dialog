import Foundation
import Observation

// MARK: - Hook Input (from stdin)

struct HookInput: Decodable {
    let sessionId: String?
    let cwd: String?
    let toolName: String
    let toolInput: ToolInput

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case cwd
        case toolName = "tool_name"
        case toolInput = "tool_input"
    }
}

struct ToolInput: Decodable {
    let questions: [Question]
}

struct Question: Decodable {
    let question: String
    let header: String
    let options: [Option]
    let multiSelect: Bool
}

struct Option: Decodable {
    let label: String
    let description: String?
    let markdown: String?
}

// MARK: - Hook Output (to stdout)

struct HookOutput: Encodable {
    let hookSpecificOutput: HookSpecificOutput
}

struct HookSpecificOutput: Encodable {
    let hookEventName = "PreToolUse"
    let permissionDecision = "deny"
    let permissionDecisionReason: String
}

// MARK: - Internal State

@Observable
@MainActor
final class AnswerState {
    var selectedIndices: Set<Int> = []
    var otherText: String = ""
}

struct QuestionAnswer {
    let header: String
    let questionText: String
    let selectedLabels: [String]
    let otherText: String?
}
