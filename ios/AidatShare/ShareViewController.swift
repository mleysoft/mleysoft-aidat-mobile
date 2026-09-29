import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private let appGroup = "group.com.mleysoft.aidat"
    private let allowed = ["xls", "xlsx", "csv", "mt940", "sta", "txt"]

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        importFirstSupportedFile()
    }

    private func importFirstSupportedFile() {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else { finish(false); return }
        let providers = items.flatMap { $0.attachments ?? [] }
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.data.identifier) || $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) else { finish(false); return }
        let type = provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) ? UTType.fileURL.identifier : UTType.data.identifier
        provider.loadItem(forTypeIdentifier: type, options: nil) { [weak self] item, _ in
            guard let self else { return }
            var source: URL?
            if let url = item as? URL { source = url }
            else if let data = item as? Data {
                let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("banka_ekstresi.xls")
                try? data.write(to: tmp); source = tmp
            }
            guard let source else { self.finish(false); return }
            let ext = source.pathExtension.lowercased()
            guard self.allowed.contains(ext) else { self.finish(false); return }
            guard let root = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: self.appGroup) else { self.finish(false); return }
            let dir = root.appendingPathComponent("PendingBankImports", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let target = dir.appendingPathComponent("\(UUID().uuidString).\(ext)")
            let accessed = source.startAccessingSecurityScopedResource()
            defer { if accessed { source.stopAccessingSecurityScopedResource() } }
            do {
                try FileManager.default.copyItem(at: source, to: target)
                UserDefaults(suiteName: self.appGroup)?.set(target.path, forKey: "pending_bank_statement")
                DispatchQueue.main.async {
                    if let url = URL(string: "mleysoftaidat://bank-import") {
                        self.extensionContext?.open(url) { _ in self.finish(true) }
                    } else { self.finish(true) }
                }
            } catch { self.finish(false) }
        }
    }

    private func finish(_ success: Bool) {
        DispatchQueue.main.async {
            self.extensionContext?.completeRequest(returningItems: nil)
        }
    }
}
