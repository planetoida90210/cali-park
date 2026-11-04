import Foundation
import MetricKit

// MARK: - MetricKitDiagnosticsSource
/// The MetricKit subscriber. MetricKit calls it on a background queue with
/// payload objects that are not `Sendable`, so it turns each one into its JSON
/// right there and hands the JSON to the `DiagnosticsService` actor.
///
/// `MXMetricManager` is the API every supported iOS version has (the app runs
/// on iOS 18.4+); its iOS 27 successor `MetricManager` can replace it once
/// that is the deployment target.
nonisolated final class MetricKitDiagnosticsSource: NSObject, MXMetricManagerSubscriber, Sendable {
    private let service: DiagnosticsService

    init(service: DiagnosticsService) {
        self.service = service
    }

    func subscribe() {
        MXMetricManager.shared.add(self)
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        let json = payloads.map { MetricKitPayload.diagnostic($0.jsonRepresentation()) }
        Task { await service.record(json) }
    }

    func didReceive(_ payloads: [MXMetricPayload]) {
        let json = payloads.map { MetricKitPayload.metrics($0.jsonRepresentation()) }
        Task { await service.record(json) }
    }
}
