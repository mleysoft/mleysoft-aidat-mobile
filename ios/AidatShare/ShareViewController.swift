import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
    private let appGroup = "group.com.mleysoft.aidat"
    private let allowed = ["xls", "xlsx", "csv", "mt940", "sta", "txt"]
    private let statusLabel = UILabel()
    private let openButton = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)
    private var imported = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        buildUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !imported { importFirstSupportedFile() }
    }

    private func buildUI() {
        let title = UILabel()
        title.text = "MleySoft Aidat"
        title.font = .systemFont(ofSize: 24, weight: .bold)
        title.textAlignment = .center

        statusLabel.text = "Banka ekstresi hazırlanıyor…"
        statusLabel.font = .systemFont(ofSize: 16, weight: .medium)
        statusLabel.textColor = .secondaryLabel
        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .center

        openButton.setTitle("MleySoft Aidat'ı Aç", for: .normal)
        openButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        openButton.isEnabled = false
        openButton.addTarget(self, action: #selector(openMainApp), for: .touchUpInside)

        closeButton.setTitle("Kapat", for: .normal)
        closeButton.addTarget(self, action: #selector(closeExtension), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [title, statusLabel, openButton, closeButton])
        stack.axis = .vertical
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func importFirstSupportedFile() {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else { showError("Paylaşılan dosya alınamadı."); return }
        let providers = items.flatMap { $0.attachments ?? [] }
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) || $0.hasItemConformingToTypeIdentifier(UTType.data.identifier) }) else { showError("Desteklenen bir ekstre dosyası bulunamadı."); return }
        let type = provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) ? UTType.fileURL.identifier : UTType.data.identifier
        provider.loadItem(forTypeIdentifier: type, options: nil) { [weak self] item, _ in
            guard let self else { return }
            var source: URL?
            if let url = item as? URL { source = url }
            else if let data = item as? Data {
                let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("banka_ekstresi.xls")
                try? data.write(to: tmp)
                source = tmp
            }
            guard let source else { self.showError("Dosya içeriği okunamadı."); return }
            let ext = source.pathExtension.lowercased()
            guard self.allowed.contains(ext) else { self.showError("Bu dosya türü desteklenmiyor: .\(ext)"); return }
            guard let root = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: self.appGroup) else { self.showError("Ortak uygulama alanına erişilemedi."); return }
            let dir = root.appendingPathComponent("PendingBankImports", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let target = dir.appendingPathComponent("\(UUID().uuidString).\(ext)")
            let accessed = source.startAccessingSecurityScopedResource()
            defer { if accessed { source.stopAccessingSecurityScopedResource() } }
            do {
                try FileManager.default.copyItem(at: source, to: target)
                UserDefaults(suiteName: self.appGroup)?.set(target.path, forKey: "pending_bank_statement")
                self.imported = true
                DispatchQueue.main.async {
                    self.statusLabel.text = "\(source.lastPathComponent) hazır. Dosya MleySoft Aidat'a aktarıldı."
                    self.statusLabel.textColor = .label
                    self.openButton.isEnabled = true
                    self.tryOpenMainAppAutomatically()
                }
            } catch { self.showError("Dosya uygulamaya aktarılamadı: \(error.localizedDescription)") }
        }
    }

    private func tryOpenMainAppAutomatically() {
        guard let url = URL(string: "mleysoftaidat://bank-import") else { return }
        extensionContext?.open(url) { [weak self] success in
            DispatchQueue.main.async {
                guard let self else { return }
                if success {
                    self.extensionContext?.completeRequest(returningItems: nil)
                } else {
                    // Share Extension noktası iOS'ta containing app'i foreground'a getirmeyi garanti etmez.
                    // Dosya App Group'ta kalır ve ana uygulama bir sonraki açılışta doğrudan içe aktarma ekranını açar.
                    self.statusLabel.text = "Dosya MleySoft Aidat'a aktarıldı. iOS uygulamayı otomatik öne getirmediyse paylaşım penceresini kapatıp MleySoft Aidat'ı açın; ekstre ekranı otomatik açılacaktır."
                }
            }
        }
    }

    @objc private func openMainApp() {
        guard let url = URL(string: "mleysoftaidat://bank-import") else { return }
        extensionContext?.open(url) { [weak self] success in
            DispatchQueue.main.async {
                if success { self?.extensionContext?.completeRequest(returningItems: nil) }
                else { self?.statusLabel.text = "iOS bu paylaşım ekranından uygulamayı öne getirmeye izin vermedi. Dosya kaydedildi; Kapat deyip MleySoft Aidat'ı açın." }
            }
        }
    }

    @objc private func closeExtension() {
        extensionContext?.completeRequest(returningItems: nil)
    }

    private func showError(_ message: String) {
        DispatchQueue.main.async {
            self.statusLabel.text = message
            self.statusLabel.textColor = .systemRed
            self.openButton.isEnabled = false
        }
    }
}
