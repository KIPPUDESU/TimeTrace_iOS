import Combine
import Foundation
import WatchConnectivity
import SwiftUI

/// Watch 侧：向 iPhone 请求同步；事件 + 所需背景图都到位后才整份覆写
@MainActor
final class WatchSyncStore: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSyncStore()

    @Published private(set) var events: [WatchSyncEvent] = []
    @Published private(set) var backgroundRevision: Int = 0

    /// 尚未提交的快照（缺图时先挂起）
    private var pendingEvents: [WatchSyncEvent]?
    private let storageKey = "WatchSyncStore.eventsJSON"

    private override init() {
        super.init()
        loadCached()
    }

    func activateAndRequestSync() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        if session.delegate == nil {
            session.delegate = self
        }
        if session.activationState != .activated {
            session.activate()
        } else {
            requestSync()
        }
    }

    func requestSync() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated else { return }

        receivePayload(session.receivedApplicationContext)

        guard session.isReachable else { return }
        session.sendMessage(
            [WatchSyncKey.requestSync: true],
            replyHandler: { [weak self] reply in
                Task { @MainActor in
                    self?.receivePayload(reply)
                }
            },
            errorHandler: { _ in }
        )
    }

    private func loadCached() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        events = WatchSyncCodec.ordered(WatchSyncCodec.decode(data))
    }

    private func persistCommitted() {
        if let data = WatchSyncCodec.encode(events) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
        var keeping = Set(events.compactMap(\.backgroundFileName))
        if let pendingEvents {
            keeping.formUnion(pendingEvents.compactMap(\.backgroundFileName))
        }
        WatchBackgroundStore.removeAll(except: keeping)
    }

    /// 收到 iPhone 快照：所需图片都在本地才算完成本次同步并覆写
    private func receivePayload(_ message: [String: Any]) {
        guard let data = message[WatchSyncKey.eventsJSON] as? Data else { return }
        pendingEvents = WatchSyncCodec.ordered(WatchSyncCodec.decode(data))
        tryCommitPending()
    }

    private func requiredBackgroundNames(in events: [WatchSyncEvent]) -> [String] {
        events.compactMap(\.backgroundFileName).filter { !$0.isEmpty }
    }

    private func isPayloadComplete(_ events: [WatchSyncEvent]) -> Bool {
        requiredBackgroundNames(in: events).allSatisfy { WatchBackgroundStore.exists(named: $0) }
    }

    private func tryCommitPending() {
        guard let pending = pendingEvents else { return }
        guard isPayloadComplete(pending) else { return }
        events = pending
        pendingEvents = nil
        persistCommitted()
        backgroundRevision += 1
    }

    private func ingestTransferredFile(at url: URL, metadata: [String: Any]?) {
        let name = (metadata?[WatchSyncKey.backgroundFileName] as? String) ?? url.lastPathComponent
        guard let data = try? Data(contentsOf: url) else { return }
        WatchBackgroundStore.save(data, named: name)
        backgroundRevision += 1
        try? FileManager.default.removeItem(at: url)
        tryCommitPending()
    }

    // MARK: - WCSessionDelegate

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            guard error == nil, activationState == .activated else { return }
            receivePayload(session.receivedApplicationContext)
            requestSync()
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        Task { @MainActor in
            receivePayload(applicationContext)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            receivePayload(message)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        Task { @MainActor in
            receivePayload(message)
            replyHandler([:])
        }
    }

    nonisolated func session(_ session: WCSession, didReceive file: WCSessionFile) {
        let url = file.fileURL
        let metadata = file.metadata
        Task { @MainActor in
            ingestTransferredFile(at: url, metadata: metadata)
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            if session.isReachable {
                requestSync()
            }
        }
    }
}
