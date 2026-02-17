import AppKit
import Foundation
import Observation

@Observable
@MainActor
final class DialogCoordinator {
    let questions: [Question]
    let cwd: String?
    var answerStates: [AnswerState]
    var focusedQuestion: Int = 0
    var focusedOption: Int = 0
    var isEditingOtherText: Bool = false
    var completion: (@MainActor (Result) -> Void)?

    private var keyMonitor: Any?

    enum Result: Sendable {
        case submitted([QuestionAnswer])
        case cancelled
    }

    init(questions: [Question], cwd: String?) {
        self.questions = questions
        self.cwd = cwd
        self.answerStates = questions.map { q in
            let state = AnswerState()
            if !q.multiSelect && !q.options.isEmpty {
                state.selectedIndices = [0]
            }
            return state
        }
    }

    func installKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            let keyCode = event.keyCode
            guard let self else { return event }

            if self.isEditingOtherText {
                switch keyCode {
                case 126: // up arrow — leave text field
                    self.isEditingOtherText = false
                    self.moveFocusUp()
                    return nil
                case 125: // down arrow — leave text field
                    self.isEditingOtherText = false
                    self.moveFocusDown()
                    return nil
                default:
                    return event
                }
            }

            switch keyCode {
            case 126: // up arrow
                self.moveFocusUp()
                return nil
            case 125: // down arrow
                self.moveFocusDown()
                return nil
            case 49: // space
                self.activateFocused()
                return nil
            default:
                return event
            }
        }
    }

    func removeKeyMonitor() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }

    func optionCount(for questionIndex: Int) -> Int {
        questions[questionIndex].options.count + 1
    }

    func moveFocusUp() {
        if focusedOption > 0 {
            focusedOption -= 1
        } else if focusedQuestion > 0 {
            focusedQuestion -= 1
            focusedOption = optionCount(for: focusedQuestion) - 1
        }
    }

    func moveFocusDown() {
        if focusedOption < optionCount(for: focusedQuestion) - 1 {
            focusedOption += 1
        } else if focusedQuestion < questions.count - 1 {
            focusedQuestion += 1
            focusedOption = 0
        }
    }

    func activateFocused() {
        toggle(questionIndex: focusedQuestion, optionIndex: focusedOption)
        if focusedOption == otherIndex(for: focusedQuestion) &&
            isSelected(questionIndex: focusedQuestion, optionIndex: focusedOption) {
            isEditingOtherText = true
        }
    }

    func otherIndex(for questionIndex: Int) -> Int {
        questions[questionIndex].options.count
    }

    func isSelected(questionIndex: Int, optionIndex: Int) -> Bool {
        answerStates[questionIndex].selectedIndices.contains(optionIndex)
    }

    func toggle(questionIndex: Int, optionIndex: Int) {
        let state = answerStates[questionIndex]
        let isMulti = questions[questionIndex].multiSelect

        if isMulti {
            if state.selectedIndices.contains(optionIndex) {
                state.selectedIndices.remove(optionIndex)
            } else {
                state.selectedIndices.insert(optionIndex)
            }
        } else {
            state.selectedIndices = [optionIndex]
        }
    }

    func isOtherSelected(questionIndex: Int) -> Bool {
        isSelected(questionIndex: questionIndex, optionIndex: otherIndex(for: questionIndex))
    }

    var canConfirm: Bool {
        for (i, state) in answerStates.enumerated() {
            if state.selectedIndices.isEmpty { return false }
            if state.selectedIndices.contains(otherIndex(for: i)) &&
                state.otherText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return false
            }
        }
        return true
    }

    func submit() {
        removeKeyMonitor()
        var answers: [QuestionAnswer] = []
        for (i, question) in questions.enumerated() {
            let state = answerStates[i]
            let otherIdx = otherIndex(for: i)
            var labels: [String] = []
            for idx in state.selectedIndices.sorted() where idx < question.options.count {
                labels.append(question.options[idx].label)
            }
            let otherText = state.selectedIndices.contains(otherIdx)
                ? state.otherText.trimmingCharacters(in: .whitespacesAndNewlines)
                : nil
            answers.append(QuestionAnswer(
                header: question.header,
                questionText: question.question,
                selectedLabels: labels,
                otherText: otherText
            ))
        }
        completion?(.submitted(answers))
    }

    func cancel() {
        removeKeyMonitor()
        completion?(.cancelled)
    }
}
