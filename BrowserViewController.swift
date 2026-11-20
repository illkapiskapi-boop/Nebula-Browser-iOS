import UIKit
import WebKit

private struct NebulaPalette {
    let background: UIColor
    let surface: UIColor
    let surfaceRaised: UIColor
    let accent: UIColor
    let accentSoft: UIColor
    let border: UIColor
    let text: UIColor
    let secondaryText: UIColor

    static func palette(for theme: NebulaTheme) -> NebulaPalette {
        switch theme {
        case .violet:
            return NebulaPalette(
                background: UIColor(hex: 0x090610), surface: UIColor(hex: 0x160F22),
                surfaceRaised: UIColor(hex: 0x211431), accent: UIColor(hex: 0xB77AFF),
                accentSoft: UIColor(hex: 0x7141A8), border: UIColor(hex: 0x57377D),
                text: UIColor(hex: 0xF7F1FF), secondaryText: UIColor(hex: 0xB9A9CC))
        case .auroraBlue:
            return NebulaPalette(
                background: UIColor(hex: 0x07101B), surface: UIColor(hex: 0x0E1B2A),
                surfaceRaised: UIColor(hex: 0x14283A), accent: UIColor(hex: 0x69C7FF),
                accentSoft: UIColor(hex: 0x347BAA), border: UIColor(hex: 0x285B7C),
                text: UIColor(hex: 0xF0F8FF), secondaryText: UIColor(hex: 0xA6C3D8))
        case .cosmicRose:
            return NebulaPalette(
                background: UIColor(hex: 0x160911), surface: UIColor(hex: 0x24111E),
                surfaceRaised: UIColor(hex: 0x35192B), accent: UIColor(hex: 0xFF8FC7),
                accentSoft: UIColor(hex: 0xA94B7C), border: UIColor(hex: 0x713451),
                text: UIColor(hex: 0xFFF3F8), secondaryText: UIColor(hex: 0xD5AABD))
        }
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}

final class BrowserViewController: UIViewController, UITextFieldDelegate, WKNavigationDelegate, WKUIDelegate, WKDownloadDelegate {
    private let duckDuckGo = "https://duckduckgo.com/"
    private var data = BrowserDataStore.load()
    private var currentWebView: WKWebView?
    private var currentDownloadURL: URL?

    private let rootStack = UIStackView()
    private let headerStack = UIStackView()
    private let tabsScrollView = UIScrollView()
    private let tabsStack = UIStackView()
    private let addressBar = UIView()
    private let addressField = UITextField()
    private let webContainer = UIView()
    private let bottomBar = UIStackView()
    private var palette = NebulaPalette.palette(for: .violet)
    private var glowLayer: CABasicAnimation?

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        data.normalize()
        palette = .palette(for: data.theme)
        buildInterface()
        renderTabs()
        loadActiveTab()
        applyTheme(animated: false)
        NotificationCenter.default.addObserver(self, selector: #selector(saveForBackground), name: UIApplication.willResignActiveNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func saveForBackground() {
        saveCurrentTabState()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        saveCurrentTabState()
    }

    private func buildInterface() {
        view.backgroundColor = palette.background

        rootStack.axis = .vertical
        rootStack.spacing = 9
        rootStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rootStack)
        NSLayoutConstraint.activate([
            rootStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            rootStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            rootStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 7),
            rootStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -7)
        ])

        buildHeader()
        buildTabs()
        buildAddressBar()

        webContainer.translatesAutoresizingMaskIntoConstraints = false
        webContainer.backgroundColor = UIColor(hex: 0xFFFFFF)
        webContainer.layer.cornerRadius = 13
        webContainer.layer.masksToBounds = true
        rootStack.addArrangedSubview(webContainer)
        webContainer.heightAnchor.constraint(greaterThanOrEqualToConstant: 160).isActive = true

        buildBottomBar()
    }

    private func buildHeader() {
        headerStack.axis = .horizontal
        headerStack.alignment = .center
        headerStack.spacing = 9
        headerStack.translatesAutoresizingMaskIntoConstraints = false

        let logo = UIImageView(image: UIImage(named: "NebulaMark"))
        logo.contentMode = .scaleAspectFit
        logo.layer.cornerRadius = 10
        logo.clipsToBounds = true
        logo.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([logo.widthAnchor.constraint(equalToConstant: 34), logo.heightAnchor.constraint(equalToConstant: 34)])

        let titleStack = UIStackView()
        titleStack.axis = .vertical
        titleStack.spacing = 0
        let title = UILabel()
        title.text = "NEBULA"
        title.font = .systemFont(ofSize: 15, weight: .heavy)
        title.textColor = palette.text
        titleStack.addArrangedSubview(title)
        let subtitle = UILabel()
        subtitle.text = "B R O W S E R"
        subtitle.font = .systemFont(ofSize: 8, weight: .bold)
        subtitle.textColor = palette.secondaryText
        titleStack.addArrangedSubview(subtitle)

        headerStack.addArrangedSubview(logo)
        headerStack.addArrangedSubview(titleStack)
        headerStack.addArrangedSubview(UIView())
        headerStack.addArrangedSubview(iconButton("plus", action: #selector(createNewTab), accessibility: "New tab"))
        headerStack.addArrangedSubview(iconButton("gearshape", action: #selector(openSettings), accessibility: "Settings"))
        rootStack.addArrangedSubview(headerStack)
        headerStack.heightAnchor.constraint(equalToConstant: 39).isActive = true
    }

    private func buildTabs() {
        tabsScrollView.showsHorizontalScrollIndicator = false
        tabsScrollView.alwaysBounceHorizontal = true
        tabsScrollView.translatesAutoresizingMaskIntoConstraints = false
        tabsStack.axis = .horizontal
        tabsStack.alignment = .center
        tabsStack.spacing = 7
        tabsStack.translatesAutoresizingMaskIntoConstraints = false
        tabsScrollView.addSubview(tabsStack)
        NSLayoutConstraint.activate([
            tabsStack.leadingAnchor.constraint(equalTo: tabsScrollView.contentLayoutGuide.leadingAnchor),
            tabsStack.trailingAnchor.constraint(equalTo: tabsScrollView.contentLayoutGuide.trailingAnchor),
            tabsStack.topAnchor.constraint(equalTo: tabsScrollView.contentLayoutGuide.topAnchor),
            tabsStack.bottomAnchor.constraint(equalTo: tabsScrollView.contentLayoutGuide.bottomAnchor),
            tabsStack.heightAnchor.constraint(equalTo: tabsScrollView.frameLayoutGuide.heightAnchor)
        ])
        rootStack.addArrangedSubview(tabsScrollView)
        tabsScrollView.heightAnchor.constraint(equalToConstant: 39).isActive = true
    }

    private func buildAddressBar() {
        addressBar.translatesAutoresizingMaskIntoConstraints = false
        addressBar.layer.cornerRadius = 17
        addressBar.layer.borderWidth = 1
        addressBar.layer.masksToBounds = false

        let lock = UIImageView(image: UIImage(systemName: "lock.fill"))
        lock.tintColor = palette.secondaryText
        lock.contentMode = .scaleAspectFit
        lock.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([lock.widthAnchor.constraint(equalToConstant: 13), lock.heightAnchor.constraint(equalToConstant: 15)])

        addressField.placeholder = "Search or enter website"
        addressField.textColor = palette.text
        addressField.tintColor = palette.accent
        addressField.font = .systemFont(ofSize: 14, weight: .medium)
        addressField.autocapitalizationType = .none
        addressField.autocorrectionType = .no
        addressField.spellCheckingType = .no
        addressField.keyboardType = .URL
        addressField.returnKeyType = .go
        addressField.delegate = self
        addressField.clearButtonMode = .whileEditing

        let bookmark = iconButton("bookmark", action: #selector(addBookmark), accessibility: "Bookmark page")
        let go = UIButton(type: .system)
        go.setImage(UIImage(systemName: "arrow.right"), for: .normal)
        go.tintColor = .white
        go.backgroundColor = palette.accentSoft
        go.layer.cornerRadius = 13
        go.addTarget(self, action: #selector(goToAddress), for: .touchUpInside)
        go.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([go.widthAnchor.constraint(equalToConstant: 30), go.heightAnchor.constraint(equalToConstant: 30)])

        let stack = UIStackView(arrangedSubviews: [lock, addressField, bookmark, go])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 9
        stack.translatesAutoresizingMaskIntoConstraints = false
        addressBar.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: addressBar.leadingAnchor, constant: 13),
            stack.trailingAnchor.constraint(equalTo: addressBar.trailingAnchor, constant: -8),
            stack.topAnchor.constraint(equalTo: addressBar.topAnchor, constant: 7),
            stack.bottomAnchor.constraint(equalTo: addressBar.bottomAnchor, constant: -7)
        ])
        rootStack.addArrangedSubview(addressBar)
        addressBar.heightAnchor.constraint(equalToConstant: 46).isActive = true
    }

    private func buildBottomBar() {
        bottomBar.axis = .horizontal
        bottomBar.alignment = .center
        bottomBar.distribution = .equalSpacing
        bottomBar.spacing = 5
        bottomBar.addArrangedSubview(iconButton("chevron.left", action: #selector(goBack), accessibility: "Back"))
        bottomBar.addArrangedSubview(iconButton("chevron.right", action: #selector(goForward), accessibility: "Forward"))
        bottomBar.addArrangedSubview(iconButton("arrow.clockwise", action: #selector(reloadPage), accessibility: "Reload"))
        bottomBar.addArrangedSubview(iconButton("house", action: #selector(goHome), accessibility: "Home"))
        bottomBar.addArrangedSubview(iconButton("clock", action: #selector(openHistory), accessibility: "History"))
        bottomBar.addArrangedSubview(iconButton("bookmark", action: #selector(openBookmarks), accessibility: "Bookmarks"))
        rootStack.addArrangedSubview(bottomBar)
        bottomBar.heightAnchor.constraint(equalToConstant: 43).isActive = true
    }

    private func iconButton(_ symbol: String, action: Selector, accessibility: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: symbol), for: .normal)
        button.tintColor = palette.secondaryText
        button.backgroundColor = palette.surface
        button.layer.cornerRadius = 13
        button.addTarget(self, action: action, for: .touchUpInside)
        button.accessibilityLabel = accessibility
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([button.widthAnchor.constraint(equalToConstant: 38), button.heightAnchor.constraint(equalToConstant: 38)])
        return button
    }

    private func applyTheme(animated: Bool) {
        palette = .palette(for: data.theme)
        let changes = {
            self.view.backgroundColor = self.palette.background
            self.addressBar.backgroundColor = self.palette.surface
            self.addressBar.layer.borderColor = self.palette.border.cgColor
            self.addressField.textColor = self.palette.text
            self.tabsScrollView.backgroundColor = .clear
            self.bottomBar.arrangedSubviews.compactMap { $0 as? UIButton }.forEach {
                $0.tintColor = self.palette.secondaryText
                $0.backgroundColor = self.palette.surface
            }
            self.renderTabs()
        }
        if animated { UIView.animate(withDuration: 0.22, animations: changes) } else { changes() }

        addressBar.layer.removeAnimation(forKey: "nebulaGlow")
        if data.animationsEnabled && data.glowIntensity > 0.02 {
            let animation = CABasicAnimation(keyPath: "shadowOpacity")
            animation.fromValue = 0.08
            animation.toValue = Float(0.15 + data.glowIntensity * 0.55)
            animation.duration = 2.2
            animation.autoreverses = true
            animation.repeatCount = .infinity
            addressBar.layer.shadowColor = palette.accent.cgColor
            addressBar.layer.shadowRadius = 12 * data.glowIntensity
            addressBar.layer.shadowOffset = .zero
            addressBar.layer.add(animation, forKey: "nebulaGlow")
        } else {
            addressBar.layer.shadowOpacity = 0
        }
    }

    private func renderTabs() {
        tabsStack.arrangedSubviews.forEach { view in
            tabsStack.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        for tab in data.tabs {
            let chip = TabChipView(title: tab.title, selected: tab.id == data.activeTabID, palette: palette)
            chip.onSelect = { [weak self] in self?.selectTab(tab.id) }
            chip.onClose = { [weak self] in self?.closeTab(tab.id) }
            tabsStack.addArrangedSubview(chip)
        }
    }

    private func createWebView(configuration: WKWebViewConfiguration = WKWebViewConfiguration()) -> WKWebView {
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.allowsBackForwardNavigationGestures = true
        webView.backgroundColor = .white
        webView.isOpaque = true
        webView.translatesAutoresizingMaskIntoConstraints = false
        webContainer.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: webContainer.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: webContainer.trailingAnchor),
            webView.topAnchor.constraint(equalTo: webContainer.topAnchor),
            webView.bottomAnchor.constraint(equalTo: webContainer.bottomAnchor)
        ])
        return webView
    }

    private func loadActiveTab() {
        guard let tab = activeTab else { return }
        currentWebView?.stopLoading()
        currentWebView?.removeFromSuperview()
        currentWebView = createWebView()
        addressField.text = tab.url
        if let url = URL(string: tab.url) { currentWebView?.load(URLRequest(url: url)) }
        updateNavigationButtons()
    }

    private var activeTab: BrowserTab? {
        guard let id = data.activeTabID else { return data.tabs.first }
        return data.tabs.first(where: { $0.id == id })
    }

    private func saveCurrentTabState() {
        guard let webView = currentWebView,
              let index = data.tabs.firstIndex(where: { $0.id == data.activeTabID }) else { return }
        if let url = webView.url?.absoluteString { data.tabs[index].url = url }
        if let title = webView.title, !title.isEmpty { data.tabs[index].title = title }
        BrowserDataStore.save(data)
    }

    private func selectTab(_ id: UUID) {
        guard id != data.activeTabID, data.tabs.contains(where: { $0.id == id }) else { return }
        saveCurrentTabState()
        data.activeTabID = id
        BrowserDataStore.save(data)
        renderTabs()
        loadActiveTab()
        addressField.resignFirstResponder()
    }

    private func closeTab(_ id: UUID) {
        if id == data.activeTabID { saveCurrentTabState() }
        data.tabs.removeAll { $0.id == id }
        if data.tabs.isEmpty {
            data.tabs = [BrowserTab()]
        }
        if data.activeTabID == id {
            data.activeTabID = data.tabs.first?.id
            loadActiveTab()
        }
        BrowserDataStore.save(data)
        renderTabs()
    }

    private func addTab(url: String = "https://duckduckgo.com/", title: String = "New Tab", configuration: WKWebViewConfiguration? = nil) -> WKWebView? {
        saveCurrentTabState()
        currentWebView?.stopLoading()
        currentWebView?.removeFromSuperview()
        let tab = BrowserTab(title: title, url: url)
        data.tabs.append(tab)
        data.activeTabID = tab.id
        currentWebView = createWebView(configuration: configuration ?? WKWebViewConfiguration())
        addressField.text = url
        BrowserDataStore.save(data)
        renderTabs()
        return currentWebView
    }

    private func addHistoryEntry(url: String, title: String) {
        guard let parsed = URL(string: url), ["http", "https"].contains(parsed.scheme?.lowercased() ?? "") else { return }
        data.history.insert(HistoryRecord(title: title.isEmpty ? url : title, url: url), at: 0)
        if data.history.count > 500 { data.history = Array(data.history.prefix(500)) }
        BrowserDataStore.save(data)
    }

    private func resolveAddress(_ input: String) -> URL? {
        let value = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        if value.contains(" ") || (!value.contains(".") && !value.hasPrefix("http")) {
            var components = URLComponents(string: duckDuckGo)
            components?.queryItems = [URLQueryItem(name: "q", value: value)]
            return components?.url
        }
        if let url = URL(string: value), url.scheme != nil { return url }
        return URL(string: "https://" + value)
    }

    private func open(_ url: URL) {
        guard let webView = currentWebView else { return }
        addressField.text = url.absoluteString
        webView.load(URLRequest(url: url))
        addressField.resignFirstResponder()
    }

    private func updateNavigationButtons() {
        // Button availability is reflected by the WebKit history itself. Keeping all controls
        // visible makes the compact toolbar consistent across iPhone and iPad sizes.
    }

    @objc private func createNewTab() {
        _ = addTab()
        if let url = URL(string: duckDuckGo) { currentWebView?.load(URLRequest(url: url)) }
    }

    @objc private func goToAddress() {
        guard let url = resolveAddress(addressField.text ?? "") else { return }
        open(url)
    }

    @objc private func goBack() { currentWebView?.goBack() }
    @objc private func goForward() { currentWebView?.goForward() }
    @objc private func reloadPage() { currentWebView?.reload() }
    @objc private func goHome() { if let url = URL(string: duckDuckGo) { open(url) } }

    @objc private func addBookmark() {
        guard let url = currentWebView?.url?.absoluteString else { return }
        let title = currentWebView?.title ?? url
        if data.bookmarks.contains(where: { $0.url == url }) {
            showMessage("Already bookmarked", message: "This page is already in your bookmarks.")
            return
        }
        data.bookmarks.insert(BookmarkRecord(title: title, url: url), at: 0)
        BrowserDataStore.save(data)
        showMessage("Saved to bookmarks", message: title)
    }

    @objc private func openHistory() {
        let rows = data.history.map { LibraryRow(id: $0.id, title: $0.title, url: $0.url, date: $0.visitedAt) }
        let controller = LibraryViewController(title: "History", rows: rows, allowsClear: true)
        controller.onOpen = { [weak self] url in self?.navigateFromLibrary(url) }
        controller.onDelete = { [weak self] id in
            self?.data.history.removeAll { $0.id == id }
            if let data = self?.data { BrowserDataStore.save(data) }
        }
        controller.onClear = { [weak self] in
            self?.data.history.removeAll()
            if let data = self?.data { BrowserDataStore.save(data) }
        }
        present(UINavigationController(rootViewController: controller), animated: true)
    }

    @objc private func openBookmarks() {
        let rows = data.bookmarks.map { LibraryRow(id: $0.id, title: $0.title, url: $0.url, date: $0.addedAt) }
        let controller = LibraryViewController(title: "Bookmarks", rows: rows, allowsClear: false)
        controller.onOpen = { [weak self] url in self?.navigateFromLibrary(url) }
        controller.onDelete = { [weak self] id in
            self?.data.bookmarks.removeAll { $0.id == id }
            if let data = self?.data { BrowserDataStore.save(data) }
        }
        present(UINavigationController(rootViewController: controller), animated: true)
    }

    private func navigateFromLibrary(_ string: String) {
        dismiss(animated: true) { [weak self] in
            guard let self, let url = URL(string: string) else { return }
            self.open(url)
        }
    }

    @objc private func openSettings() {
        let controller = SettingsViewController(theme: data.theme, animationsEnabled: data.animationsEnabled, glowIntensity: data.glowIntensity)
        controller.onSave = { [weak self] theme, animations, glow in
            guard let self else { return }
            self.data.theme = theme
            self.data.animationsEnabled = animations
            self.data.glowIntensity = glow
            BrowserDataStore.save(self.data)
            self.applyTheme(animated: true)
        }
        present(UINavigationController(rootViewController: controller), animated: true)
    }

    private func showMessage(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        goToAddress()
        return true
    }

    // MARK: WKNavigationDelegate

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        guard webView === currentWebView else { return }
        if let url = webView.url { addressField.text = url.absoluteString }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard webView === currentWebView else { return }
        let url = webView.url?.absoluteString ?? activeTab?.url ?? duckDuckGo
        let title = webView.title ?? url
        addressField.text = url
        if let index = data.tabs.firstIndex(where: { $0.id == data.activeTabID }) {
            data.tabs[index].url = url
            data.tabs[index].title = title
        }
        addHistoryEntry(url: url, title: title)
        BrowserDataStore.save(data)
        renderTabs()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        guard webView === currentWebView else { return }
        NSLog("Nebula Browser navigation failed: %@", error.localizedDescription)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { decisionHandler(.allow); return }
        let scheme = (url.scheme ?? "").lowercased()
        if !["http", "https", "about", "file", "blob", "data", "javascript"].contains(scheme) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse,
            decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if !navigationResponse.canShowMIMEType { decisionHandler(.download) }
        else { decisionHandler(.allow) }
    }

    func webView(_ webView: WKWebView, navigationResponse: WKNavigationResponse, didBecome download: WKDownload) {
        download.delegate = self
    }

    // MARK: WKUIDelegate

    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.targetFrame == nil else { return nil }
        let url = navigationAction.request.url?.absoluteString ?? duckDuckGo
        let newWebView = addTab(url: url, title: "New Tab", configuration: configuration)
        return newWebView
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alert = UIAlertController(title: webView.title ?? "Website", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
        present(alert, animated: true)
    }

    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: webView.title ?? "Website", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
        present(alert, animated: true)
    }

    // MARK: WKDownloadDelegate

    func download(_ download: WKDownload, decideDestinationUsing response: URLResponse,
            suggestedFilename: String, completionHandler: @escaping (URL?) -> Void) {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = documents.appendingPathComponent("Downloads", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            let safeName = suggestedFilename.isEmpty ? "download" : suggestedFilename
            let destination = folder.appendingPathComponent(safeName)
            currentDownloadURL = destination
            completionHandler(destination)
        } catch {
            completionHandler(nil)
            showMessage("Download failed", message: error.localizedDescription)
        }
    }

    func downloadDidFinish(_ download: WKDownload) {
        guard let fileURL = currentDownloadURL else { return }
        let activity = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        if let popover = activity.popoverPresentationController { popover.sourceView = view; popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1) }
        present(activity, animated: true)
    }

    func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
        showMessage("Download failed", message: error.localizedDescription)
    }
}

private final class TabChipView: UIView {
    var onSelect: (() -> Void)?
    var onClose: (() -> Void)?
    private let selectButton = UIButton(type: .system)
    private let closeButton = UIButton(type: .system)

    init(title: String, selected: Bool, palette: NebulaPalette) {
        super.init(frame: .zero)
        backgroundColor = selected ? palette.surfaceRaised : palette.surface
        layer.cornerRadius = 13
        layer.borderWidth = selected ? 1 : 0.6
        layer.borderColor = (selected ? palette.accent : palette.border).cgColor

        selectButton.setTitle(title.isEmpty ? "New Tab" : title, for: .normal)
        selectButton.setTitleColor(palette.text, for: .normal)
        selectButton.titleLabel?.font = .systemFont(ofSize: 12, weight: selected ? .semibold : .medium)
        selectButton.titleLabel?.lineBreakMode = .byTruncatingTail
        selectButton.contentHorizontalAlignment = .leading
        selectButton.addTarget(self, action: #selector(selectTapped), for: .touchUpInside)

        closeButton.setTitle("×", for: .normal)
        closeButton.setTitleColor(palette.secondaryText, for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        closeButton.widthAnchor.constraint(equalToConstant: 23).isActive = true

        let stack = UIStackView(arrangedSubviews: [selectButton, closeButton])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 1
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 9),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -5),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
            widthAnchor.constraint(greaterThanOrEqualToConstant: 95),
            widthAnchor.constraint(lessThanOrEqualToConstant: 205)
        ])
        selectButton.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func selectTapped() { onSelect?() }
    @objc private func closeTapped() { onClose?() }
}
