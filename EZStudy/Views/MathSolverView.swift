import SwiftUI

struct MathSolverView: View {
    var prefill: String = ""
    @Environment(\.dismiss) private var dismiss

    @State private var problem = ""
    @State private var steps: [String] = []
    @State private var visibleCount = 0
    @State private var isLoading = false
    @State private var errorText: String?
    @State private var stepTimer: Timer?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Input
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        TextField("e.g. Solve: 2x + 5 = 13, or explain Newton's 2nd law…",
                                  text: $problem, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(1...5)
                        Button(action: solve) {
                            Label("Solve", systemImage: "wand.and.stars.inverse")
                                .font(.subheadline.bold())
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.purple)
                        .disabled(problem.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))

                if let err = errorText {
                    Text(err).font(.caption).foregroundStyle(.red).padding(.horizontal)
                }

                ScrollView {
                    if steps.isEmpty && !isLoading {
                        emptyState
                    } else {
                        LazyVStack(alignment: .leading, spacing: 14) {
                            ForEach(0..<visibleCount, id: \.self) { i in
                                StepCard(number: i + 1, text: steps[i])
                                    .transition(
                                        .asymmetric(
                                            insertion: .move(edge: .bottom).combined(with: .opacity),
                                            removal: .opacity
                                        )
                                    )
                            }
                            if isLoading {
                                HStack(spacing: 10) {
                                    ProgressView()
                                    Text("Solving…")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                            }
                        }
                        .padding()
                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: visibleCount)
                    }
                }
            }
            .navigationTitle("Problem Solver")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !steps.isEmpty {
                        Button("Clear") {
                            withAnimation { steps = []; visibleCount = 0 }
                        }
                    }
                }
            }
        }
        .onAppear { if !prefill.isEmpty { problem = prefill } }
        .onDisappear { stepTimer?.invalidate() }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 60)
            Image(systemName: "function")
                .font(.system(size: 64))
                .foregroundStyle(.purple.opacity(0.4))
            VStack(spacing: 6) {
                Text("Enter any problem to solve")
                    .font(.headline)
                Text("Math, science, logic, or any question —\nthe AI will walk you through it step by step.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding()
    }

    private func solve() {
        let trimmed = problem.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        steps = []
        visibleCount = 0
        isLoading = true
        errorText = nil
        stepTimer?.invalidate()

        let prompt = """
        Solve or explain this step by step: \(trimmed)

        Format the response as numbered steps, each on its own line starting with "Step N:".
        End with a clearly labeled answer or conclusion.
        Be concise and educational.
        """

        Task {
            do {
                let result = try await AIService.shared.complete(
                    prompt: prompt,
                    systemPrompt: "You are an expert tutor. Explain everything step by step, clearly and concisely.",
                    maxTokens: 1500
                )
                let parsed = parseSteps(from: result)
                await MainActor.run {
                    steps = parsed
                    isLoading = false
                    animateSteps()
                }
            } catch {
                await MainActor.run {
                    errorText = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func parseSteps(from text: String) -> [String] {
        let lines = text.components(separatedBy: "\n")
        var result: [String] = []
        var current = ""

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }

            let isStepHeader = trimmed.range(
                of: #"^(Step\s+\d+|(\d+)\.|(\d+)\))"#,
                options: .regularExpression
            ) != nil

            if isStepHeader && !current.isEmpty {
                result.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
                current = trimmed
            } else {
                current += (current.isEmpty ? "" : " ") + trimmed
            }
        }
        if !current.isEmpty {
            result.append(current.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        return result.isEmpty ? [text] : result
    }

    private func animateSteps() {
        guard !steps.isEmpty else { return }
        var idx = 0
        stepTimer = Timer.scheduledTimer(withTimeInterval: 0.55, repeats: true) { t in
            guard idx < steps.count else { t.invalidate(); return }
            withAnimation { visibleCount = idx + 1 }
            idx += 1
        }
    }
}

private struct StepCard: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(Color.purple.gradient).frame(width: 30, height: 30)
                Text("\(number)")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}
