import Combine
import Foundation
import WatchConnectivity
import SwiftUI

/// Watch 侧：事件快照立刻覆写；背景图稍后单独落盘，互不打断
@MainActor
final class WatchSyncStore: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchSyncStore()

    @Published private(set) var events: [WatchSyncEvent] = []
    @Published private(set) var backgroundRevision: Int = 0

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

        applyPayload(session.receivedApplicationContext)

        guard session.isReachable else { return }
        session.sendMessage(
            [WatchSyncKey.requestSync: true],
            replyHandler: { [weak self] reply in
                Task { @MainActor in
                    self?.applyPayload(reply)
                }
            },
            errorHandler: { _ in }
        )
    }

    func isBackgroundReady(for event: WatchSyncEvent) -> Bool {
        let _ = backgroundRevision
        guard let name = event.backgroundFileName, !name.isEmpty else { return true }
        return WatchBackgroundStore.exists(named: name)
    }

    private func loadCached() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else { return }
        events = WatchSyncCodec.ordered(WatchSyncCodec.decode(data))
    }

    /// 事件数据立刻保存；仅清理新快照不再引用的背景文件
    private func applyPayload(_ message: [String: Any]) {
        guard let data = message[WatchSyncKey.eventsJSON] as? Data else { return }
        let decoded = WatchSyncCodec.ordered(WatchSyncCodec.decode(data))
        events = decoded
        if let encoded = WatchSyncCodec.encode(decoded) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
        let keeping = Set(decoded.compactMap(\.backgroundFileName).filter { !$0.isEmpty })
        WatchBackgroundStore.removeAll(except: keeping)
    }

    private func ingestTransferredFile(at url: URL, metadata: [String: Any]?) {
        let name = (metadata?[WatchSyncKey.backgroundFileName] as? String) ?? url.lastPathComponent
        guard let data = try? Data(contentsOf: url) else { return }
        WatchBackgroundStore.save(data, named: name)
        backgroundRevision += 1
        try? FileManager.default.removeItem(at: url)
    }

    // MARK: - WCSessionDelegate

    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        Task { @MainActor in
            guard error == nil, activationState == .activated else { return }
            applyPayload(session.receivedApplicationContext)
            requestSync()
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveApplicationContext applicationContext: [String: Any]
    ) {
        Task { @MainActor in
            applyPayload(applicationContext)
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        Task { @MainActor in
            applyPayload(message)
        }
    }

    nonisolated func session(
        _ session: WCSession,
        didReceiveMessage message: [String: Any],
        replyHandler: @escaping ([String: Any]) -> Void
    ) {
        Task { @MainActor in
            applyPayload(message)
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
