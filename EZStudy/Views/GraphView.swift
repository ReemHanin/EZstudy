import SwiftUI
import Charts
import JavaScriptCore

// MARK: - Math expression evaluator using JavaScriptCore

enum MathEvaluator {
    private static let ctx: JSContext = {
        let c = JSContext()!
        // Expose all Math functions as globals so "sin(x)" works directly
        c.evaluateScript("""
        var sin=Math.sin, cos=Math.cos, tan=Math.tan, asin=Math.asin,
            acos=Math.acos, atan=Math.atan, sinh=Math.sinh, cosh=Math.cosh,
            sqrt=Math.sqrt, cbrt=Math.cbrt, exp=Math.exp, log=Math.log,
            log2=Math.log2, log10=Math.log10, abs=Math.abs,
            floor=Math.floor, ceil=Math.ceil, round=Math.round,
            sign=Math.sign, pow=Math.pow, pi=Math.PI, e=Math.E;
        """)
        return c
    }()

    /// Returns f(x) for the given expression string, or nil if it fails / is non-finite.
    static func evaluate(_ expression: String, x: Double) -> Double? {
        // Replace ^ with ** (JS exponentiation)
        let processed = expression.replacingOccurrences(of: "^", with: "**")
        let script = "(function(){var x=\(x);try{var r=(\(processed));return isFinite(r)?r:NaN;}catch(e){return NaN;}})()"
        guard
            let result = ctx.evaluateScript(script),
            !result.isNull, !result.isUndefined,
            let num = result.toNumber(),
            !num.isNaN, num.isFinite
        else { return nil }
        return num.doubleValue
    }
}

// MARK: - GraphView

struct GraphView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var expressionText = "sin(x)"
    @State private var xMin: Double = -10
    @State private var xMax: Double = 10
    @State private var plotData: [(x: Double, y: Double)] = []
    @State private var errorText: String?
    @State private var animationProgress: Double = 0

    private let presets: [(name: String, expr: String)] = [
        ("sin(x)", "sin(x)"), ("cos(x)", "cos(x)"), ("tan(x)", "tan(x)"),
        ("x²",    "x^2"),     ("x³",    "x^3"),
        ("√x",    "sqrt(x)"), ("e^x",   "exp(x)"),  ("ln(x)", "log(x)"),
        ("1/x",   "1/x"),     ("|x|",   "abs(x)")
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Controls
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Text("f(x) =")
                            .font(.headline.monospaced())
                            .foregroundStyle(.secondary)
                        TextField("e.g. sin(x), x^2 + 2*x", text: $expressionText)
                            .textFieldStyle(.roundedBorder)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        Button("Plot") { plot() }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                    }

                    HStack(spacing: 6) {
                        Text("x:").font(.caption).foregroundStyle(.secondary)
                        Text("\(Int(xMin))").font(.caption.monospacedDigit()).frame(width: 30)
                        Slider(value: $xMin, in: -50...(-1)) { Text("Min") }
                        Text("to").font(.caption).foregroundStyle(.secondary)
                        Slider(value: $xMax, in: 1...50) { Text("Max") }
                        Text("\(Int(xMax))").font(.caption.monospacedDigit()).frame(width: 30)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))

                if let err = errorText {
                    Text(err).font(.caption).foregroundStyle(.red).padding(8)
                }

                // Chart
                if plotData.isEmpty {
                    emptyState
                } else {
                    Chart {
                        let visible = plotData.prefix(Int(Double(plotData.count) * animationProgress))
                        ForEach(Array(visible.enumerated()), id: \.offset) { _, pt in
                            LineMark(x: .value("x", pt.x), y: .value("f(x)", pt.y))
                                .foregroundStyle(.blue.gradient)
                                .lineStyle(StrokeStyle(lineWidth: 2))
                        }
                    }
                    .chartXAxis { AxisMarks(values: .automatic(desiredCount: 7)) }
                    .chartYAxis { AxisMarks(values: .automatic(desiredCount: 6)) }
                    .padding()

                    // Preset chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(presets, id: \.name) { p in
                                Button(p.name) {
                                    expressionText = p.expr
                                    plot()
                                }
                                .font(.caption)
                                .padding(.horizontal, 10).padding(.vertical, 5)
                                .background(Capsule().fill(Color(.secondarySystemBackground)))
                                .overlay(Capsule().stroke(Color.secondary.opacity(0.2)))
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 8)
                }
            }
            .navigationTitle("Graph Viewer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear { plot() }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 64))
                .foregroundStyle(.blue.opacity(0.35))
            Text("Enter a function and tap Plot")
                .font(.subheadline).foregroundStyle(.secondary)
            Spacer()
        }
    }

    private func plot() {
        errorText = nil
        let expr = expressionText.trimmingCharacters(in: .whitespaces)
        guard !expr.isEmpty else { return }
        guard xMax > xMin else { errorText = "x max must be greater than x min"; return }

        let steps = 500
        let step = (xMax - xMin) / Double(steps)
        var points: [(x: Double, y: Double)] = []
        var x = xMin
        while x <= xMax + step * 0.01 {
            if let y = MathEvaluator.evaluate(expr, x: x), abs(y) < 1e7 {
                // Break line at discontinuities (e.g. tan asymptotes)
                if let last = points.last, abs(y - last.y) > 50 {
                    // Skip this point to create a visual gap
                } else {
                    points.append((x, y))
                }
            }
            x += step
        }

        if points.isEmpty {
            errorText = "Could not evaluate "\(expr)". Try: sin(x), x^2, sqrt(x), 1/x"
        } else {
            plotData = points
            animateChart()
        }
    }

    private func animateChart() {
        animationProgress = 0
        withAnimation(.easeOut(duration: 0.8)) {
            animationProgress = 1
        }
    }
}
