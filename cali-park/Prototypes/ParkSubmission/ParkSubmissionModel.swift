#if DEBUG
// PROTOTYPE — throwaway. In-memory state of the whole Submission flow. Nothing is saved or sent.

import CoreLocation
import Observation
import SwiftUI

enum SubmissionLayout: String, CaseIterable, Identifiable {
    case steps
    case sheet

    var id: String { rawValue }

    var title: String {
        switch self {
        case .steps: "A · Kroki"
        case .sheet: "B · Jeden arkusz"
        }
    }

    var other: SubmissionLayout { self == .steps ? .sheet : .steps }
}

/// Pages of the form after the pin is placed. The steps layout pushes each one;
/// the sheet layout shows the first four on one screen and pushes only `.summary` and `.sent`.
enum SubmissionStep: Hashable {
    case equipment, photos, name, details, summary, sent
}

enum SubmissionMapPhase {
    case browsing, placing
}

@Observable
@MainActor
final class ParkSubmissionPrototypeModel {
    var layout: SubmissionLayout
    var mapPhase: SubmissionMapPhase = .browsing
    var draft: SubmissionDraft
    /// A known Park within 50 m of the pin. Drives the warning sheet.
    var duplicate: MapLookPark?
    /// Park opened from the duplicate warning.
    var openedPark: MapLookPark?
    var isFormPresented = false
    var isMinePresented = false
    var isCameraPresented = false
    var path: [SubmissionStep] = []
    var minePath: [PrototypeSubmission] = []
    var submissions = SubmissionSampleData.submissions
    var lastSentID: Int?
    /// Screenshot helper: section id to scroll to when a form screen appears.
    var scrollTarget: String?
    /// Where the map should fly next; `cameraRequest` bumps on every request so repeats still move it.
    var cameraTarget: CLLocationCoordinate2D?
    var cameraRequest = 0

    init(layout: SubmissionLayout) {
        self.layout = layout
        draft = SubmissionDraft(coordinate: SubmissionSampleData.userLocation)
    }

    // MARK: Map

    func recenter(on coordinate: CLLocationCoordinate2D?) {
        cameraTarget = coordinate
        cameraRequest += 1
    }

    func startAdding() {
        openedPark = nil
        draft = SubmissionDraft(coordinate: SubmissionSampleData.userLocation)
        recenter(on: SubmissionSampleData.userLocation)
        mapPhase = .placing
    }

    func cancelAdding() {
        mapPhase = .browsing
    }

    func movePin(to coordinate: CLLocationCoordinate2D) {
        draft.coordinate = coordinate
    }

    func confirmPin() {
        if let nearby = SubmissionSampleData.nearbyPark(to: draft.coordinate) {
            duplicate = nearby.park
        } else {
            openForm()
        }
    }

    func openDuplicate() {
        openedPark = duplicate
        duplicate = nil
        mapPhase = .browsing
        recenter(on: openedPark?.coordinate)
    }

    func continueDespiteDuplicate() {
        duplicate = nil
        openForm()
    }

    private func openForm() {
        mapPhase = .browsing
        path = []
        isFormPresented = true
    }

    // MARK: Form

    func toggle(_ item: SubmissionEquipment) {
        if draft.equipment.contains(item) {
            draft.equipment.remove(item)
            if item == .horizontalBar { draft.barCount = nil; draft.barHeights = [] }
            if item == .parallelBars { draft.parallelBarsCount = nil }
        } else {
            draft.equipment.insert(item)
        }
    }

    func takePhoto() {
        guard draft.photos.count < SubmissionDraft.maxPhotos else { return }
        draft.photos.append((draft.photos.last ?? -1) + 1)
    }

    func removePhoto(_ photo: Int) {
        draft.photos.removeAll { $0 == photo }
    }

    func edit(_ step: SubmissionStep) {
        switch layout {
        case .steps:
            let order: [SubmissionStep] = [.photos, .name, .details]
            path = step == .equipment ? [] : Array(order.prefix { $0 != step }) + [step]
        case .sheet:
            path = []
        }
    }

    func editLocation() {
        isFormPresented = false
        mapPhase = .placing
        recenter(on: draft.coordinate)
    }

    func send() {
        let id = (submissions.map(\.id).max() ?? 0) + 1
        let submission = PrototypeSubmission(
            id: id,
            name: draft.generatedName,
            proposedName: draft.trimmedPlaqueName,
            equipment: draft.sortedEquipment,
            photoCount: draft.photos.count,
            status: .pending,
            sentAt: SubmissionSampleData.now
        )
        submissions.insert(submission, at: 0)
        lastSentID = id
        path.append(.sent)
    }

    func finish(showingMine: Bool) {
        isFormPresented = false
        path = []
        draft = SubmissionDraft(coordinate: SubmissionSampleData.userLocation)
        minePath = []
        isMinePresented = showingMine
    }
}

// MARK: - Screenshot presets

extension ParkSubmissionPrototypeModel {
    /// Puts the flow straight onto one screen, for `-SubmissionScreen <name>`.
    func apply(screen: String) {
        func fillRequired() {
            draft.equipment = [.horizontalBar, .parallelBars, .wallBars, .fitnessPole]
            draft.barCount = 3
            draft.barHeights = [.medium, .high]
            draft.photos = [0, 1]
        }
        func form(_ steps: [SubmissionStep]) {
            isFormPresented = true
            // The sheet layout shows the form steps on one screen and pushes only the summary.
            path = layout == .steps ? steps : steps.filter { $0 == .summary || $0 == .sent }
        }
        switch screen {
        case "place":
            mapPhase = .placing
        case "duplicate":
            mapPhase = .placing
            draft.coordinate = SubmissionSampleData.duplicateDemoLocation
            recenter(on: SubmissionSampleData.duplicateDemoLocation)
            duplicate = SubmissionSampleData.nearbyPark(to: SubmissionSampleData.duplicateDemoLocation)?.park
        case "opened":
            openedPark = SubmissionSampleData.nearbyPark(to: SubmissionSampleData.duplicateDemoLocation)?.park
            recenter(on: openedPark?.coordinate)
        case "equipment-empty":
            form([])
        case "equipment-missing":
            draft.equipment = [.rings, .wallBars]
            form([])
        case "equipment":
            fillRequired()
            form([])
        case "photos-empty":
            fillRequired()
            draft.photos = []
            form([.photos])
        case "camera":
            fillRequired()
            draft.photos = [0]
            form([.photos])
            isCameraPresented = true
        case "photos":
            fillRequired()
            form([.photos])
        case "name":
            fillRequired()
            form([.photos, .name])
        case "name-typed":
            fillRequired()
            draft.plaqueName = "Strefa Street Workout Kamionek"
            form([.photos, .name])
        case "name-invalid":
            fillRequired()
            draft.plaqueName = "MÓJ PARK 💪"
            form([.photos, .name])
        case "details":
            fillRequired()
            draft.surface = .rubber
            draft.lit = .yes
            form([.photos, .name, .details])
        case "summary":
            fillRequired()
            draft.plaqueName = "Strefa Street Workout Kamionek"
            draft.surface = .rubber
            draft.lit = .yes
            form([.photos, .name, .details, .summary])
        case "sent":
            fillRequired()
            send()
            isFormPresented = true
            path = [.sent]
        case "mine":
            fillRequired()
            send()
            finish(showingMine: true)
        case "mine-rejected", "mine-pending":
            fillRequired()
            send()
            finish(showingMine: true)
            let wanted: (PrototypeSubmission) -> Bool = screen == "mine-pending"
                ? { $0.id == self.lastSentID }
                : { if case .rejected = $0.status { return true } else { return false } }
            if let item = submissions.first(where: wanted) { minePath = [item] }
        case "sheet-filled":
            fillRequired()
            draft.photos = []
            form([])
        default:
            break
        }
    }
}
#endif
