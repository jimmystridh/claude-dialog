import SwiftUI

struct DialogView: View {
    @Bindable var coordinator: DialogCoordinator
    @FocusState private var otherTextFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            Divider()
            questionsArea
            Divider()
            actionBar
        }
        .onChange(of: coordinator.isEditingOtherText) { _, editing in
            otherTextFocused = editing
        }
        .onChange(of: otherTextFocused) { _, focused in
            if !focused && coordinator.isEditingOtherText {
                coordinator.isEditingOtherText = false
            }
        }
    }

    private var headerBar: some View {
        HStack {
            Image(systemName: "bubble.left.fill")
                .foregroundStyle(.blue)
                .font(.title3)
            VStack(alignment: .leading, spacing: 1) {
                Text("Claude Code")
                    .font(.headline)
                if let cwd = coordinator.cwd {
                    Text(abbreviatePath(cwd))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private func abbreviatePath(_ path: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }

    private var questionsArea: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(Array(coordinator.questions.enumerated()), id: \.offset) { index, question in
                    QuestionView(
                        question: question,
                        questionIndex: index,
                        coordinator: coordinator,
                        otherTextFocused: $otherTextFocused
                    )
                }
            }
            .padding(20)
        }
    }

    private var actionBar: some View {
        HStack {
            Button("Cancel") {
                coordinator.cancel()
            }
            .keyboardShortcut(.cancelAction)

            Spacer()

            Button("Confirm") {
                coordinator.submit()
            }
            .keyboardShortcut(.defaultAction)
            .disabled(!coordinator.canConfirm)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }
}
