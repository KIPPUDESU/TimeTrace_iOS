import SwiftUI
import SwiftData
import UniformTypeIdentifiers

// 备份与恢复

struct BackupFlow: ViewModifier {
    @Binding var isPresented: Bool

    @Environment(\.modelContext) private var context
    @Query(sort: \DateEvent.id) private var events: [DateEvent]

    // 把包做好放这
    @State private var document: BackupDocument?
    @State private var showExporter = false
    // 导入前确认
    @State private var showImportWarning = false
    @State private var showImporter = false
    // 结果提示
    @State private var resultMessage: String?
    @State private var resultIsError = false

    func body(content: Content) -> some View {
        content
            // 导出 导入
            .alert(L("backup_restore"), isPresented: $isPresented) {
                Button(L("backup_export")) { startExport() }
                Button(L("backup_import")) { showImportWarning = true }
                Button(L("cancel"), role: .cancel) {}
            }
            // 导入会替换全部数据
            // 那我就提前和你说一声 ^ ^
            .alert(L("confirm_import"), isPresented: $showImportWarning) {
                Button(L("confirm_import_button"), role: .destructive) { showImporter = true }
                Button(L("cancel"), role: .cancel) {}
            } message: {
                Text(L("import_warning"))
            }
            .fileExporter(
                isPresented: $showExporter,
                document: document,
                contentType: .zip,
                defaultFilename: "backup_\(Int(Date().timeIntervalSince1970 * 1000))"
            ) { result in
                if case .failure(let error) = result {
                    show(String(format: L("backup_failed"), error.localizedDescription), isError: true)
                } else {
                    show(L("backup_success"), isError: false)
                }
            }
            .fileImporter(isPresented: $showImporter, allowedContentTypes: [.zip]) { result in
                switch result {
                case .success(let url): runImport(from: url)
                case .failure(let error):
                    show(String(format: L("restore_failed"), error.localizedDescription), isError: true)
                }
            }
            .alert(resultIsError ? L("error") : L("complete"), isPresented: resultBinding) {
                Button(L("confirm"), role: .cancel) {}
            } message: {
                Text(resultMessage ?? "")
            }
    }

    // 把当前全部记录打包
    private func startExport() {
        do {
            document = BackupDocument(data: try BackupManager.exportArchive(events: events))
            showExporter = true
        } catch {
            show(String(format: L("backup_failed"), error.localizedDescription), isError: true)
        }
    }

    // 读包 清空现有数据 全量写回
    private func runImport(from url: URL) {
        // 先取得访问权限
        let needsRelease = url.startAccessingSecurityScopedResource()
        defer { if needsRelease { url.stopAccessingSecurityScopedResource() } }

        do {
            let imported = try BackupManager.importArchive(from: url)
            try context.delete(model: DateEvent.self)
            for event in imported {
                context.insert(event)
            }
            try context.save()
            // 新记录的编号要接在导入的最大编号后面，否则会跟已有记录撞号
            EventIDGenerator.ensureAtLeast((imported.map(\.id).max() ?? 0) + 1)
            // 同名背景图已经被换掉了，旧的解码结果不能再用
            BackgroundImageCache.clear()
            show(String(format: L("restore_success"), imported.count), isError: false)
        } catch {
            show(String(format: L("restore_failed"), error.localizedDescription), isError: true)
        }
    }

    private func show(_ message: String, isError: Bool) {
        resultIsError = isError
        resultMessage = message
    }

    private var resultBinding: Binding<Bool> {
        Binding(get: { resultMessage != nil }, set: { if !$0 { resultMessage = nil } })
    }
}

extension View {
    // 挂上备份与恢复的交互，传进来的开关一打开就弹出选择
    func backupFlow(isPresented: Binding<Bool>) -> some View {
        modifier(BackupFlow(isPresented: isPresented))
    }
}

// 给系统存储面板
struct BackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.zip] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
