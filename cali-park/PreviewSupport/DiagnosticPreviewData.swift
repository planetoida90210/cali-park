#if DEBUG
import Foundation

// MARK: - DiagnosticPreviewData
/// Sample MetricKit payloads in Apple's documented JSON shape, for previews
/// and for the Debug launch argument `-SimulateMetricKitPayloads` (MetricKit
/// delivers nothing on the Simulator). Not real reports: the frames and
/// values are made up.
nonisolated enum DiagnosticPreviewData {
    static let crashAndHang = """
        {
          "timeStampBegin" : "2026-11-03 18:42:00 +0000",
          "timeStampEnd" : "2026-11-03 18:42:00 +0000",
          "crashDiagnostics" : [{
            "version" : "1.0.0",
            "callStackTree" : {
              "callStackPerThread" : true,
              "callStacks" : [{
                "threadAttributed" : true,
                "callStackRootFrames" : [{
                  "binaryName" : "libswiftCore.dylib", "binaryUUID" : "4F0B2E91-7D3A-3A1E-8B64-2C9E5F1D0A22",
                  "offsetIntoBinaryTextSegment" : 1210384, "address" : 7395021840, "sampleCount" : 1,
                  "subFrames" : [{
                    "binaryName" : "CaliPark", "binaryUUID" : "E3D5A1C7-2B4F-3E8D-9A16-5F7C0B2D4E33",
                    "offsetIntoBinaryTextSegment" : 165304, "address" : 4302390456, "sampleCount" : 1,
                    "subFrames" : [{
                      "binaryName" : "SwiftUI", "binaryUUID" : "A7C2E4F1-9B3D-3F5A-8E21-6D4B1C0F2A44",
                      "offsetIntoBinaryTextSegment" : 23488812, "address" : 7412345676, "sampleCount" : 1
                    }]
                  }]
                }]
              }]
            },
            "diagnosticMetaData" : {
              "appVersion" : "1.0", "appBuildVersion" : "7", "osVersion" : "iPhone OS 26.1 (23B85)",
              "deviceType" : "iPhone17,1", "exceptionType" : 6, "exceptionCode" : 1, "signal" : 5,
              "terminationReason" : "Namespace SIGNAL, Code 5 Trace/BPT trap: 5"
            }
          }],
          "hangDiagnostics" : [{
            "version" : "1.0.0",
            "callStackTree" : { "callStackPerThread" : true, "callStacks" : [] },
            "diagnosticMetaData" : {
              "appVersion" : "1.0", "appBuildVersion" : "7", "osVersion" : "iPhone OS 26.1 (23B85)",
              "deviceType" : "iPhone17,1", "hangDuration" : "2.4 sec"
            }
          }]
        }
        """

    static let cpuException = """
        {
          "timeStampBegin" : "2026-11-01 09:10:00 +0000",
          "timeStampEnd" : "2026-11-01 09:13:00 +0000",
          "cpuExceptionDiagnostics" : [{
            "version" : "1.0.0",
            "callStackTree" : { "callStackPerThread" : false, "callStacks" : [] },
            "diagnosticMetaData" : {
              "appVersion" : "1.0", "appBuildVersion" : "6", "osVersion" : "iPhone OS 26.1 (23B85)",
              "deviceType" : "iPhone17,1", "totalCPUTime" : "92 sec", "totalSampledTime" : "180 sec"
            }
          }]
        }
        """

    static let metrics = """
        {
          "appVersion" : "1.0",
          "timeStampBegin" : "2026-11-02 00:00:00 +0000",
          "timeStampEnd" : "2026-11-02 23:59:00 +0000",
          "metaData" : { "appBuildVersion" : "7", "osVersion" : "iPhone OS 26.1 (23B85)", "deviceType" : "iPhone17,1" },
          "applicationTimeMetrics" : { "cumulativeForegroundTime" : "1,260 sec", "cumulativeBackgroundTime" : "40 sec" },
          "memoryMetrics" : { "peakMemoryUsage" : "182,000 kB" },
          "diskIOMetrics" : { "cumulativeLogicalWrites" : "2,400 kB" },
          "applicationExitMetrics" : {
            "foregroundExitData" : { "cumulativeNormalAppExitCount" : 9, "cumulativeAppWatchdogExitCount" : 1 },
            "backgroundExitData" : { "cumulativeNormalAppExitCount" : 14, "cumulativeMemoryPressureExitCount" : 5 }
          }
        }
        """

    /// The three samples as MetricKit hands them over.
    static let payloads: [MetricKitPayload] = [
        .diagnostic(Data(crashAndHang.utf8)),
        .metrics(Data(metrics.utf8)),
        .diagnostic(Data(cpuException.utf8))
    ]

    /// The samples parsed, received a few hours after each period ended.
    static let reports: [DiagnosticReport] = payloads.enumerated().compactMap { index, payload in
        let receivedAt = Date(timeIntervalSince1970: 1_793_740_500 - Double(index) * 86_400)
        return DiagnosticReportParser.report(from: payload, receivedAt: receivedAt)
    }
}
#endif
