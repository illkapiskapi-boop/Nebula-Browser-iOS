import UIKit

final class SettingsViewController: UIViewController {
    private var selectedTheme: NebulaTheme
    private let animationsSwitch = UISwitch()
    private let glowSlider = UISlider()
    private let themeControl = UISegmentedControl(items: NebulaTheme.allCases.map { $0.displayName })
    private let glowValueLabel = UILabel()

    var onSave: ((NebulaTheme, Bool, Double) -> Void)?

    init(theme: NebulaTheme, animationsEnabled: Bool, glowIntensity: Double) {
        self.selectedTheme = theme
        super.init(nibName: nil, bundle: nil)
        animationsSwitch.isOn = animationsEnabled
        glowSlider.value = Float(glowIntensity)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Nebula Settings"
        view.backgroundColor = UIColor(hex: 0x0D0815)
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(close))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(save))

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(hex: 0x160F22)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = UIColor(hex: 0xB77AFF)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24)
        ])

        let heading = UILabel()
        heading.text = "Make your browser yours"
        heading.font = .systemFont(ofSize: 23, weight: .bold)
        heading.textColor = .white
        stack.addArrangedSubview(heading)

        stack.addArrangedSubview(sectionLabel("COLOR THEME"))
        themeControl.selectedSegmentIndex = NebulaTheme.allCases.firstIndex(of: selectedTheme) ?? 0
        themeControl.selectedSegmentTintColor = UIColor(hex: 0x7141A8)
        themeControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        themeControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        themeControl.addTarget(self, action: #selector(themeChanged), for: .valueChanged)
        stack.addArrangedSubview(themeControl)

        stack.addArrangedSubview(sectionLabel("ANIMATIONS"))
        let animationRow = UIStackView()
        animationRow.axis = .horizontal
        animationRow.alignment = .center
        let animationText = makeBodyLabel("Animated violet glow")
        animationRow.addArrangedSubview(animationText)
        animationRow.addArrangedSubview(UIView())
        animationsSwitch.onTintColor = UIColor(hex: 0xA855F7)
        animationRow.addArrangedSubview(animationsSwitch)
        stack.addArrangedSubview(animationRow)

        let glowHeader = UIStackView()
        glowHeader.axis = .horizontal
        let glowTitle = sectionLabel("GLOW INTENSITY")
        glowHeader.addArrangedSubview(glowTitle)
        glowHeader.addArrangedSubview(UIView())
        glowValueLabel.textColor = UIColor(hex: 0xCDAAFF)
        glowValueLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        glowValueLabel.text = "\(Int(glowSlider.value * 100))%"
        glowHeader.addArrangedSubview(glowValueLabel)
        stack.addArrangedSubview(glowHeader)
        glowSlider.minimumTrackTintColor = UIColor(hex: 0xA855F7)
        glowSlider.maximumTrackTintColor = UIColor(hex: 0x39264D)
        glowSlider.addTarget(self, action: #selector(glowChanged), for: .valueChanged)
        stack.addArrangedSubview(glowSlider)

        let note = UILabel()
        note.text = "Nebula keeps one active web view at a time to reduce memory use. When you switch tabs, the selected page is reopened at its last address. Unsaved page state may not be preserved."
        note.numberOfLines = 0
        note.font = .systemFont(ofSize: 12)
        note.textColor = UIColor(hex: 0xB9A9CC)
        stack.addArrangedSubview(note)
    }

    private func sectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 11, weight: .bold)
        label.textColor = UIColor(hex: 0xB9A9CC)
        return label
    }

    private func makeBodyLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .white
        return label
    }

    @objc private func themeChanged() {
        selectedTheme = NebulaTheme.allCases[max(0, themeControl.selectedSegmentIndex)]
    }

    @objc private func glowChanged() { glowValueLabel.text = "\(Int(glowSlider.value * 100))%" }

    @objc private func close() { dismiss(animated: true) }

    @objc private func save() {
        onSave?(selectedTheme, animationsSwitch.isOn, Double(glowSlider.value))
        dismiss(animated: true)
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}
