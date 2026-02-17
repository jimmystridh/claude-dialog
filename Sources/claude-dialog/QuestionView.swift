import SwiftUI

struct QuestionView: View {
    let question: Question
    let questionIndex: Int
    @Bindable var coordinator: DialogCoordinator
    var otherTextFocused: FocusState<Bool>.Binding

    private var isFocusedQuestion: Bool {
        coordinator.focusedQuestion == questionIndex
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            headerBadge
            Text(question.question)
                .font(.title3)
                .fontWeight(.medium)

            VStack(spacing: 6) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { optIndex, option in
                    OptionRow(
                        label: option.label,
                        description: option.description,
                        isMulti: question.multiSelect,
                        isSelected: coordinator.isSelected(questionIndex: questionIndex, optionIndex: optIndex),
                        isFocused: isFocusedQuestion && coordinator.focusedOption == optIndex
                    ) {
                        coordinator.focusedQuestion = questionIndex
                        coordinator.focusedOption = optIndex
                        coordinator.toggle(questionIndex: questionIndex, optionIndex: optIndex)
                    }
                }

                otherRow
            }
        }
    }

    private var headerBadge: some View {
        Text(question.header)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.secondary.opacity(0.12))
            )
    }

    private var otherRow: some View {
        let otherIdx = coordinator.otherIndex(for: questionIndex)
        let isOther = coordinator.isSelected(questionIndex: questionIndex, optionIndex: otherIdx)
        let isOtherFocused = isFocusedQuestion && coordinator.focusedOption == otherIdx

        return VStack(alignment: .leading, spacing: 6) {
            OptionRow(
                label: "Other",
                description: nil,
                isMulti: question.multiSelect,
                isSelected: isOther,
                isFocused: isOtherFocused
            ) {
                coordinator.focusedQuestion = questionIndex
                coordinator.focusedOption = otherIdx
                coordinator.toggle(questionIndex: questionIndex, optionIndex: otherIdx)
            }

            if isOther {
                TextField("Type your answer...", text: Bindable(coordinator.answerStates[questionIndex]).otherText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.leading, 32)
                    .focused(otherTextFocused)
            }
        }
    }
}

struct OptionRow: View {
    let label: String
    let description: String?
    let isMulti: Bool
    let isSelected: Bool
    var isFocused: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: iconName)
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .font(.body)
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .foregroundStyle(.primary)
                    if let description {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.blue.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(isFocused ? Color.accentColor : Color.clear, lineWidth: 2)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var iconName: String {
        if isMulti {
            return isSelected ? "checkmark.square.fill" : "square"
        } else {
            return isSelected ? "largecircle.fill.circle" : "circle"
        }
    }
}
