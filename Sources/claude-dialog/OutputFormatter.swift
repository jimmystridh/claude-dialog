import Foundation

enum OutputFormatter {
    static func formatAnswers(_ answers: [QuestionAnswer]) -> String {
        var parts: [String] = ["User answered via native macOS dialog."]

        for answer in answers {
            var answerParts: [String] = []
            if !answer.selectedLabels.isEmpty {
                answerParts.append(answer.selectedLabels.joined(separator: ", "))
            }
            if let other = answer.otherText, !other.isEmpty {
                answerParts.append("Other: \(other)")
            }
            let combined = answerParts.joined(separator: "; ")
            parts.append("[\(answer.header)] \(answer.questionText) -> \(combined).")
        }

        parts.append("Do NOT re-ask these questions. Treat this as the user's final answer and proceed accordingly.")
        return parts.joined(separator: " ")
    }

    static func buildOutput(answers: [QuestionAnswer]) -> Data {
        let reason = formatAnswers(answers)
        let output = HookOutput(hookSpecificOutput: HookSpecificOutput(permissionDecisionReason: reason))
        return try! JSONEncoder().encode(output)
    }
}
