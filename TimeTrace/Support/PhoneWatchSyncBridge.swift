import Foundation
import WatchConnectivity
import UIKit

/// iPhone → Watch：活跃 + 定格事件整份下发覆写；失败静默忽略
@MainActor
final class PhoneWatchSyncBridge: NSObject, WCSessionDelegate {
    static let shared = PhoneWatchSyncBridge()

    private var pendingEvents: [DateEvent] = []
    private var lastPayloadSignature: String?

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        if session.delegate == nil {
            session.delegate = self
        }
        if session.activationState != .activated {
            session.activate()
        }
    }

    func sync(events: [DateEvent]) {
        pendingEvents = events
        activate()
        pushIfPossible()
    }

    private func eventsForSync(from events: [DateEvent]) -> [DateEvent] {
        let active = events.filter { !$0.isStopped }
        let stopped = events.filter(\.isStopped)
        let orderedActive = active.filter(\.isPinned) + active.filter { !$0.isPinned }
        let orderedStopped = stopped.filter(\.isPinned) + stopped.filter { !$0.isPinned }
        return orderedActive + orderedStopped
    }

    private func pushIfPossible() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }
        guard session.isPaired, session.isWatchAppInstalled else { return }

        let source = eventsForSync(from: pendingEvents)
        let payload = buildPayload(from: source)
        let signature = payloadSignature(payload.events, files: payload.fileNames)
        guard signature != lastPayloadSignature else { return }

        guard let json = WatchSyncCodec.encode(payload.events) else { return }
        try? session.updateApplicationContext([
            WatchSyncKey.eventsJSON: json,
            WatchSyncKey.updatedAt: Date().timeIntervalSince1970
        ])
        transferBackgrounds(payload.files)
        lastPayloadSignature = signature
    }

    private func forcePush() {
        lastPayloadSignature = nil
        pushIfPossible()

        let payload = buildPayload(from: eventsForSync(from: pendingEvents))
        if let json = WatchSyncCodec.encode(payload.events),
           WCSession.default.isReachable {
            WCSession.default.sendMessage(
                [
                    WatchSyncKey.eventsJSON: json,
                    WatchSyncKey.updatedAt: Date().timeIntervalSince1970
                ],
                replyHandler: { _ in },
                errorHandler: { _ in }
            )
        }
        transferBackgrounds(payload.files)
        lastPayloadSignature = payloadSignature(payload.events, files: payload.fileNames)
    }

    private struct BuiltPayload {
        var events: [WatchSyncEvent]
        var files: [(name: String, data: Data)]
        var fileNames: [String] { files.map(\.name) }
    }

    private func buildPayload(from events: [DateEvent]) -> BuiltPayload {
        var synced: [WatchSyncEvent] = []
        var files: [(name: String, data: Data)] = []

        for event in events {
            var backgroundName: String?
            if let sourceName = event.backgroundImageName,
               let image = ImageUtils.loadBackground(named: sourceName),
               let jpeg = WatchBackgroundStore.watchJPEG(from: image) {
                let name = "bg-\(event.id).jpg"
                backgroundName = name
                files.append((name, jpeg))
            }

            let reference = event.referenceNow
            synced.append(
                WatchSyncEvent(
                    id: event.id,
                    title: event.title,
                    targetDate: event.targetDate.timeIntervalSince1970,
                    isFuture: event.targetDate > reference,
                    mode: event.mode == .accumulate ? "accumulate" : "countDown",
                    backgroundFileName: backgroundName,
                    isPinned: event.isPinned,
                    maskOpacity: event.maskOpacity,
                    position: event.position,
                    stoppedAt: event.stoppedAt?.timeIntervalSince1970
                )
            )
        }
        return BuiltPayload(events: synced, files: files)
    }

    private func transferBackgrounds(_ files: [(name: String, data: Data)]) {
        let session = WCSession.default
        let tempRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("WatchSyncOut", isDirectory: true)
        try? FileManager.default.createDirectory(at: tempRoot, withIntermediateDirectories: true)

        for file in files {
            let url = tempRoot.appendingPathComponent(file.name)
            guard (try? file.data.write(to: url, options: .atomic)) != nil else { continue }
            session.transferFile(
                url,
                metadata: [WatchSyncKey.backgroundFileName: file.name]
            )
        }
    }

    private func payloadSignature(_ events: [WatchSyncEvent], files: [String]) -> String {
        let eventPart = events.map {
            "\($0.id):\($0.title):\($0.targetDate):\($0.isPinned):\($0.maskOpacity):\($0.backgroundFileName ?? ""):\($0.stoppedAt ?? -1)"
        }.joined(separator: "|")
        return eventPart + "#" + files.sorted().joined(separator: ",")
    }

    // MARK: - WCSessionDelegate

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            guard error == nil, activationState == .activated else { return }
            pushIfPossible()
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            if message[WatchSyncKey.requestSync] != nil {
                forcePush()
            }
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        Task { @MainActor in
            if message[WatchSyncKey.requestSync] != nil {
                let payload = buildPayload(from: eventsForSync(from: pendingEvents))
                let json = WatchSyncCodec.encode(payload.events) ?? Data()
                replyHandler([
                    WatchSyncKey.eventsJSON: json,
                    WatchSyncKey.updatedAt: Date().timeIntervalSince1970
                ])
                transferBackgrounds(payload.files)
                lastPayloadSignature = payloadSignature(payload.events, files: payload.fileNames)
            } else {
                replyHandler([:])
            }
        }
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in
            pushIfPossible()
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            if session.isReachable {
                pushIfPossible()
            }
        }
    }
}
