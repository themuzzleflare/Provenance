import UIKit
import NotificationBannerSwift
import Rswift

class TagsVC: TableViewController {
    // MARK: - Properties

    var transaction: TransactionResource! {
        didSet {
            if transaction.relationships.tags.data.isEmpty {
                navigationController?.popViewController(animated: true)
            } else {
                applySnapshot()
                updateToolbarItems()
                refreshControl?.endRefreshing()
            }
        }
    }

    private enum Section {
        case main
    }

    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, RelationshipData>

    private lazy var dataSource = makeDataSource()
    private lazy var addItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(openAddWorkflow))
    private lazy var selectionItem = UIBarButtonItem(title: "Select All" , style: .plain, target: self, action: #selector(selectionAction))
    private lazy var removeAllItem = UIBarButtonItem(title: "Remove All" , style: .plain, target: self, action: #selector(removeAllTags))
    private lazy var removeItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(removeTags))

    private let tableRefreshControl = RefreshControl(frame: .zero)

    // UITableViewDiffableDataSource
    private class DataSource: UITableViewDiffableDataSource<Section, RelationshipData> {
        weak var parent: TagsVC! = nil

        override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            true
        }

        override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            let tag = itemIdentifier(for: indexPath)!
            if editingStyle == .delete {
                let ac = UIAlertController(title: nil, message: "Are you sure you want to remove \"\(tag.id)\" from \"\(parent.transaction.attributes.description)\"?", preferredStyle: .actionSheet)
                let confirmAction = UIAlertAction(title: "Remove", style: .destructive) { [unowned self] _ in
                    let tagObject = TagResource(type: "tags", id: tag.id)
                    upApi.modifyTags(removing: tagObject, from: parent.transaction) { error in
                        switch error {
                            case .none:
                                DispatchQueue.main.async {
                                    let notificationBanner = NotificationBanner(title: "Success", subtitle: "\(tag.id) was removed from \(parent.transaction.attributes.description).", style: .success)
                                    notificationBanner.duration = 2
                                    notificationBanner.show()
                                    parent.fetchTransaction()
                                }
                            default:
                                DispatchQueue.main.async {
                                    let notificationBanner = NotificationBanner(title: "Failed", subtitle: errorString(for: error!), style: .danger)
                                    notificationBanner.duration = 2
                                    notificationBanner.show()
                                }
                        }
                    }
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                cancelAction.setValue(R.color.accentColour(), forKey: "titleTextColor")
                ac.addAction(confirmAction)
                ac.addAction(cancelAction)
                parent.present(ac, animated: true)
            }
        }
    }

    // MARK: - View Life Cycle

    override init(style: UITableView.Style) {
        super.init(style: style)
        dataSource.parent = self
        configureProperties()
        configureNavigation()
        configureToolbar()
        configureRefreshControl()
        configureTableView()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchTransaction()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.setToolbarHidden(!isEditing, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setToolbarHidden(true, animated: false)
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        updateToolbarItems()
        navigationController?.setToolbarHidden(!editing, animated: true)
        addItem.isEnabled = !editing
    }
}

// MARK: - Configuration

private extension TagsVC {
    private func configureProperties() {
        title = "Transaction Tags"
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    private func configureNavigation() {
        navigationItem.title = "Tags"
        navigationItem.backBarButtonItem = UIBarButtonItem(image: R.image.tag())
        navigationItem.rightBarButtonItems = [addItem, editButtonItem]
    }

    private func configureToolbar() {
        selectionItem.tintColor = R.color.accentColour()
        removeAllItem.tintColor = R.color.accentColour()
        removeItem.tintColor = R.color.accentColour()
        setToolbarItems([selectionItem, removeAllItem, .flexibleSpace(), removeItem], animated: true)
    }

    private func updateToolbarItems() {
        selectionItem.title = tableView.indexPathsForSelectedRows?.count == transaction.relationships.tags.data.count ? "Deselect All" : "Select All"
        removeItem.isEnabled = tableView.indexPathsForSelectedRows != nil
    }

    private func configureRefreshControl() {
        tableRefreshControl.addTarget(self, action: #selector(refreshTags), for: .valueChanged)
    }
    
    private func configureTableView() {
        tableView.refreshControl = tableRefreshControl
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.register(BasicTableViewCell.self, forCellReuseIdentifier: "tagCell")
    }
}

// MARK: - Actions

private extension TagsVC {
    @objc private func appMovedToForeground() {
        fetchTransaction()
    }

    @objc private func openAddWorkflow() {
        present({let vc = NavigationController(rootViewController: {let vc = AddTagWorkflowTwoVC(style: .insetGrouped);vc.transaction = transaction;vc.fromTransactionTags = true;return vc}());vc.modalPresentationStyle = .fullScreen;return vc}(), animated: true)
    }

    @objc private func refreshTags() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.fetchTransaction()
        }
    }

    @objc private func selectionAction() {
        switch tableView.indexPathsForSelectedRows?.count {
            case transaction.relationships.tags.data.count:
                tableView.indexPathsForSelectedRows?.forEach { path in
                    tableView.deselectRow(at: path, animated: false)
                }
            default:
                let indexes = transaction.relationships.tags.data.map { tag in
                    dataSource.indexPath(for: tag)
                }
                indexes.forEach { index in
                    tableView.selectRow(at: index, animated: false, scrollPosition: .none)
                }
        }
        updateToolbarItems()
    }

    @objc private func removeTags() {
        if let tags = tableView.indexPathsForSelectedRows?.map { index in
            dataSource.itemIdentifier(for: index)
        } {
            let tagIds = tags.map { tag in
                tag!.id
            }.joined(separator: ", ")

            let ac = UIAlertController(title: nil, message: "Are you sure you want to remove \"\(tagIds)\" from \"\(transaction.attributes.description)\"?", preferredStyle: .actionSheet)
            let confirmAction = UIAlertAction(title: "Remove", style: .destructive) { [unowned self] _ in
                let tagsObject: [TagResource] = tags.map { tag in
                    TagResource(type: "tags", id: tag!.id)
                }
                upApi.modifyTags(removing: tagsObject, from: transaction) { error in
                    switch error {
                        case .none:
                            DispatchQueue.main.async {
                                let notificationBanner = NotificationBanner(title: "Success", subtitle: "\(tagIds) was removed from \(transaction.attributes.description).", style: .success)
                                notificationBanner.duration = 2
                                notificationBanner.show()
                                fetchTransaction()
                            }
                        default:
                            DispatchQueue.main.async {
                                let notificationBanner = NotificationBanner(title: "Failed", subtitle: errorString(for: error!), style: .danger)
                                notificationBanner.duration = 2
                                notificationBanner.show()
                            }
                    }
                }
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            cancelAction.setValue(R.color.accentColour(), forKey: "titleTextColor")
            ac.addAction(confirmAction)
            ac.addAction(cancelAction)
            present(ac, animated: true)
        }
    }

    @objc private func removeAllTags() {
        let tags = transaction.relationships.tags.data
        let tagIds = tags.map { tag in
            tag.id
        }.joined(separator: ", ")

        let ac = UIAlertController(title: nil, message: "Are you sure you want to remove \"\(tagIds)\" from \"\(transaction.attributes.description)\"?", preferredStyle: .actionSheet)
        let confirmAction = UIAlertAction(title: "Remove", style: .destructive) { [unowned self] _ in
            let tagsObject: [TagResource] = tags.map { tag in
                TagResource(type: "tags", id: tag.id)
            }
            
            upApi.modifyTags(removing: tagsObject, from: transaction) { error in
                switch error {
                    case .none:
                        DispatchQueue.main.async {
                            let notificationBanner = NotificationBanner(title: "Success", subtitle: "\(tagIds) was removed from \(transaction.attributes.description).", style: .success)
                            notificationBanner.duration = 2
                            notificationBanner.show()
                            fetchTransaction()
                        }
                    default:
                        DispatchQueue.main.async {
                            let notificationBanner = NotificationBanner(title: "Failed", subtitle: errorString(for: error!), style: .danger)
                            notificationBanner.duration = 2
                            notificationBanner.show()
                        }
                }
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        cancelAction.setValue(R.color.accentColour(), forKey: "titleTextColor")
        ac.addAction(confirmAction)
        ac.addAction(cancelAction)
        present(ac, animated: true)
    }

    private func makeDataSource() -> DataSource {
        DataSource(
            tableView: tableView,
            cellProvider: { tableView, indexPath, tag in
            let cell = tableView.dequeueReusableCell(withIdentifier: "tagCell", for: indexPath) as! BasicTableViewCell
            cell.separatorInset = .zero
            cell.selectedBackgroundView = selectedBackgroundCellView
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.font = R.font.circularStdBook(size: UIFont.labelFontSize)
            cell.textLabel?.textAlignment = .left
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = tag.id
            return cell
        }
        )
    }

    private func applySnapshot() {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(transaction.relationships.tags.data, toSection: .main)
        dataSource.apply(snapshot)
    }

    private func fetchTransaction() {
        upApi.retrieveTransaction(for: transaction) { result in
            switch result {
                case .success(let transaction):
                    DispatchQueue.main.async {
                        self.transaction = transaction
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.refreshControl?.endRefreshing()
                    }
                    print(errorString(for: error))
            }
        }
    }
}

// MARK: - UITableViewDelegate

extension TagsVC {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch isEditing {
            case true:
                updateToolbarItems()
            case false:
                tableView.deselectRow(at: indexPath, animated: true)
                navigationController?.pushViewController({let vc = TransactionsByTagVC(style: .insetGrouped);vc.tag = TagResource(type: "tags", id: dataSource.itemIdentifier(for: indexPath)!.id);return vc}(), animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if isEditing {
            updateToolbarItems()
        }
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
            .delete
    }

    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        "Remove"
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        switch isEditing {
            case true:
                return nil
            case false:
                let tag = dataSource.itemIdentifier(for: indexPath)!
                return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                    UIMenu(children: [
                        UIAction(title: "Copy", image: R.image.docOnClipboard()) { action in
                        UIPasteboard.general.string = tag.id
                    },
                        UIAction(title: "Remove", image: R.image.trash(), attributes: .destructive) { action in
                        let ac = UIAlertController(title: nil, message: "Are you sure you want to remove \"\(tag.id)\" from \"\(self.transaction.attributes.description)\"?", preferredStyle: .actionSheet)
                        let confirmAction = UIAlertAction(title: "Remove", style: .destructive) { [unowned self] _ in
                            let tagObject = TagResource(type: "tags", id: tag.id)
                            upApi.modifyTags(removing: tagObject, from: transaction) { error in
                                switch error {
                                    case .none:
                                        DispatchQueue.main.async {
                                            let notificationBanner = NotificationBanner(title: "Success", subtitle: "\(tag.id) was removed from \(transaction.attributes.description).", style: .success)
                                            notificationBanner.duration = 2
                                            notificationBanner.show()
                                            fetchTransaction()
                                        }
                                    default:
                                        DispatchQueue.main.async {
                                            let notificationBanner = NotificationBanner(title: "Failed", subtitle: errorString(for: error!), style: .danger)
                                            notificationBanner.duration = 2
                                            notificationBanner.show()
                                        }
                                }
                            }
                        }
                        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
                        cancelAction.setValue(R.color.accentColour(), forKey: "titleTextColor")
                        ac.addAction(confirmAction)
                        ac.addAction(cancelAction)
                        self.present(ac, animated: true)
                    }
                    ])
                }
        }
    }
}
