#if DEBUG
// PROTOTYPE — throwaway. Ticket: docs/wayfinder/calipark-1.0/tickets/013-submission-form.md
//
// Clickable Park Submission flow in map variant A ("Wyciszona") styling. Two form layouts:
// A "Kroki" (one question per screen) and B "Jeden arkusz" (one scrolling form).
//
// Launch arguments (DEBUG builds only):
//   -PrototypeParkSubmission       show this prototype instead of the app
//   -SubmissionLayout steps|sheet  pick the form layout (default: steps)
//   -SubmissionScreen <name>       jump to one screen, used for screenshots
//                                  (see ParkSubmissionPrototypeModel.apply(screen:))
//   -SubmissionScroll <section>    sheet layout only: scroll to equipment|photos|name|details|send
//   -SubmissionClean               hide the prototype switcher pill, used for screenshots

import SwiftUI

struct ParkSubmissionLaunchOptions {
    let isEnabled: Bool
    let layout: SubmissionLayout
    let screen: String?
    let scrollTarget: String?
    let hidesSwitcher: Bool

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        func value(after flag: String) -> String? {
            guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else { return nil }
            return arguments[index + 1]
        }
        isEnabled = arguments.contains("-PrototypeParkSubmission")
        layout = value(after: "-SubmissionLayout").flatMap(SubmissionLayout.init(rawValue:)) ?? .steps
        screen = value(after: "-SubmissionScreen")
        scrollTarget = value(after: "-SubmissionScroll")
        hidesSwitcher = arguments.contains("-SubmissionClean")
    }
}

struct ParkSubmissionPrototypeRoot: View {
    let options: ParkSubmissionLaunchOptions
    @State private var model: ParkSubmissionPrototypeModel

    init(options: ParkSubmissionLaunchOptions) {
        self.options = options
        let model = ParkSubmissionPrototypeModel(layout: options.layout)
        model.scrollTarget = options.scrollTarget
        if let screen = options.screen { model.apply(screen: screen) }
        _model = State(initialValue: model)
    }

    var body: some View {
        SubmissionMapScreen(model: model)
            .safeAreaInset(edge: .top, spacing: 0) {
                if !options.hidesSwitcher {
                    SubmissionSwitcherPill(model: model)
                }
            }
            .fullScreenCover(isPresented: $model.isFormPresented) {
                SubmissionFormHost(model: model)
            }
            .sheet(isPresented: $model.isMinePresented) {
                MySubmissionsView(model: model)
            }
            .preferredColorScheme(.dark)
    }
}

private struct SubmissionFormHost: View {
    @Bindable var model: ParkSubmissionPrototypeModel

    var body: some View {
        Group {
            switch model.layout {
            case .steps: SubmissionStepsLayout(model: model)
            case .sheet: SubmissionSheetLayout(model: model)
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $model.isCameraPresented) {
            SubmissionCameraView(model: model)
        }
    }
}

/// Deliberately looks unlike the app (white pill) so it reads as prototype chrome.
private struct SubmissionSwitcherPill: View {
    @Bindable var model: ParkSubmissionPrototypeModel

    var body: some View {
        HStack(spacing: 8) {
            Button("Zmień układ formularza", systemImage: "arrow.left.arrow.right") {
                model.layout = model.layout.other
            }
            .labelStyle(.iconOnly)
            Text("Układ: \(model.layout.title)")
                .font(.footnote.monospaced())
            if model.mapPhase == .placing {
                Divider().frame(height: 16)
                Button("Demo: obok Parku") {
                    model.recenter(on: SubmissionSampleData.duplicateDemoLocation)
                }
                .font(.footnote.monospaced())
            }
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.black)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.white, in: .capsule)
        .shadow(color: .black.opacity(0.4), radius: 6, y: 2)
        .frame(maxWidth: .infinity)
        .padding(.bottom, 4)
    }
}
#endif
