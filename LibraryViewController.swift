import UIKit

struct LibraryRow {
    let id: UUID
    let title: String
    let url: String
    let date: Date
}

final class LibraryViewController: UITableViewController, UISearchResultsUpdating {
    private let screenTitle: String
    private let allowsClear: Bool
    private var rows: [LibraryRow]
    private var filteredRows: [LibraryRow] = []
    private let searchController = UISearchController(searchResultsController: nil)

    var onOpen: ((String) -> Void)?
    var onDelete: ((UUID) -> Void)?
    var onClear: (() -> Void)?

    init(title: String, rows: [LibraryRow], allowsClear: Bool) {
        self.screenTitle = title
        self.rows = rows
        self.allowsClear = allowsClear
        super.init(style: .insetGrouped)
        self.title = title
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: 0x0D0815)
        tableView.backgroundColor = UIColor(hex: 0x0D0815)
        tableView.separatorColor = UIColor(hex: 0x342444)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 68

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(close))
        if allowsClear {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(clearHistory))
        }

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(hex: 0x160F22)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = UIColor(hex: 0xB77AFF)

        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search title or address"
        searchController.searchBar.tintColor = UIColor(hex: 0xB77AFF)
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
        tableView.reloadData()
    }

    @objc private func close() { dismiss(animated: true) }

    @objc private func clearHistory() {
        let alert = UIAlertController(title: "Clear history?", message: "This removes all saved browsing history.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { [weak self] _ in
            guard let self else { return }
            self.rows.removeAll()
            self.filteredRows.removeAll()
            self.onClear?()
            self.tableView.reloadData()
        })
        present(alert, animated: true)
    }

    func updateSearchResults(for searchController: UISearchController) {
        let query = (searchController.searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty {
            filteredRows = []
        } else {
            filteredRows = rows.filter { $0.title.lowercased().contains(query) || $0.url.lowercased().contains(query) }
        }
        tableView.reloadData()
    }

    private var visibleRows: [LibraryRow] { filteredRows.isEmpty && (searchController.searchBar.text ?? "").isEmpty ? rows : filteredRows }

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { visibleRows.count }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "LibraryCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell(style: .subtitle, reuseIdentifier: identifier)
        let row = visibleRows[indexPath.row]
        var content = cell.defaultContentConfiguration()
        content.text = row.title
        content.secondaryText = row.url + "\n" + DateFormatter.localizedString(from: row.date, dateStyle: .medium, timeStyle: .short)
        content.textProperties.color = .white
        content.textProperties.font = .systemFont(ofSize: 15, weight: .semibold)
        content.secondaryTextProperties.color = UIColor(hex: 0xB9A9CC)
        content.secondaryTextProperties.font = .systemFont(ofSize: 11)
        content.secondaryTextProperties.numberOfLines = 2
        cell.contentConfiguration = content
        cell.backgroundColor = UIColor(hex: 0x160F22)
        cell.accessoryType = .disclosureIndicator
        cell.selectionStyle = .none
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let row = visibleRows[indexPath.row]
        onOpen?(row.url)
    }

    override func tableView(_ tableView: UITableView,
            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let row = visibleRows[indexPath.row]
        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            guard let self else { completion(false); return }
            self.rows.removeAll { $0.id == row.id }
            self.filteredRows.removeAll { $0.id == row.id }
            self.onDelete?(row.id)
            self.tableView.reloadData()
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
}
