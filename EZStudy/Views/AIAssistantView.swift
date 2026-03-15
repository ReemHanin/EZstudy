import SwiftUI

struct AIAssistantView: View {
    var noteContext: String = ""

    @State private var messages: [AIMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false
    @State private var errorText: String?
    @State private var showKeyEntry = false
    @State private var apiKeyInput = ""
    @Environment(\.dismiss) private var dismiss

    private let suggestions = [
        "Summarize my note",
        "Explain the key concepts",
        "Create a quiz from my notes",
        "Give me study tips for this topic"
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !AIService.shared.hasAPIKey || showKeyEntry {
                    apiKeySetup
                } else {
                    chatBody
                }
            }
            .navigationTitle("AI Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showKeyEntry.toggle()
                    } label: {
                        Image(systemName: "key.fill")
                            .font(.callout)
                    }
                }
            }
        }
    }

    // MARK: - API Key Setup

    private var apiKeySetup: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue.gradient)
                    .padding(.top, 40)

                VStack(spacing: 8) {
                    Text("Set Up AI Assistant")
                        .font(.title2.bold())
                    Text("Enter your Anthropic API key to unlock AI-powered study assistance.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                SecureField("sk-ant-api…", text: $apiKeyInput)
                    .textFieldStyle(.roundedBorder)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(.horizontal, 4)

                Button("Save & Enable") {
                    AIService.shared.saveAPIKey(apiKeyInput.trimmingCharacters(in: .whitespaces))
                    showKeyEntry = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(apiKeyInput.trimmingCharacters(in: .whitespaces).isEmpty)

                Link("Get a free API key →", destination: URL(string: "https://console.anthropic.com")!)
                    .font(.footnote)
            }
            .padding(28)
        }
    }

    // MARK: - Chat

    private var chatBody: some View {
        VStack(spacing: 0) {
            if messages.isEmpty {
                emptyChat
            } else {
                messageList
            }

            if let err = errorText {
                Text(err)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
                    .padding(.top, 4)
            }

            inputBar
        }
    }

    private var emptyChat: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer(minLength: 48)
                Image(systemName: "sparkles")
                    .font(.system(size: 52))
                    .foregroundStyle(.blue.opacity(0.55))
                Text("Ask anything about your note,\nor any study question.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: 10) {
                    ForEach(suggestions, id: \.self) { s in
                        Button(s) {
                            inputText = s
                            sendMessage()
                        }
                        .font(.subheadline)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Capsule())
                    }
                }
                Spacer(minLength: 16)
            }
            .padding()
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(messages) { msg in
                        MessageBubble(message: msg).id(msg.id)
                    }
                    if isLoading { TypingIndicator() }
                }
                .padding()
            }
            .onChange(of: messages.count) { _, _ in
                withAnimation { proxy.scrollTo(messages.last?.id, anchor: .bottom) }
            }
            .onChange(of: isLoading) { _, v in
                if v { withAnimation { proxy.scrollTo("typing", anchor: .bottom) } }
            }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask a question…", text: $inputText, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...5)
                .onSubmit { sendMessage() }
            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(inputText.trimmingCharacters(in: .whitespaces).isEmpty
                                     ? Color.secondary : Color.accentColor)
            }
            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
        }
        .padding()
        .background(.bar)
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        messages.append(AIMessage(role: .user, content: text))
        inputText = ""
        isLoading = true
        errorText = nil

        let ctx = noteContext.isEmpty ? "" : "\n\nCurrent note:\n\(noteContext.prefix(3000))"
        let system = "You are a helpful AI study assistant. Be concise and educational.\(ctx)"

        Task {
            do {
                let reply = try await AIService.shared.complete(prompt: text, systemPrompt: system)
                await MainActor.run {
                    messages.append(AIMessage(role: .assistant, content: reply))
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorText = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Sub-views

private struct MessageBubble: View {
    let message: AIMessage
    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 48) }
            if !isUser {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.blue.opacity(0.12)))
            }
            Text(message.content)
                .font(.subheadline)
                .padding(.horizontal, 13)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isUser ? Color.accentColor : Color(.secondarySystemBackground))
                )
                .foregroundStyle(isUser ? .white : .primary)
            if isUser { Spacer(minLength: 0).frame(width: 0) }
            if !isUser { Spacer(minLength: 48) }
        }
    }
}

private struct TypingIndicator: View {
    @State private var phase = false

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 7, height: 7)
                    .scaleEffect(phase ? 1 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.45).repeatForever().delay(Double(i) * 0.15),
                        value: phase
                    )
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemBackground)))
        .id("typing")
        .onAppear { phase = true }
    }
}
