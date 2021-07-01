import UIKit
import NotificationBannerSwift
import Rswift

final class TagsCVC: UIViewController {
    // MARK: - Properties

    var transaction: TransactionResource! {
        didSet {
            if transaction.relationships.tags.data.isEmpty {
                navigationController?.popViewController(animated: true)
            } else {
                applySnapshot()
                updateToolbarItems()
                collectionView.refreshControl?.endRefreshing()
            }
        }
    }

    private enum Section {
        case main
    }

    private typealias DataSource = UICollectionViewDiffableDataSource<Section, RelationshipData>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, RelationshipData>
    private typealias TagCell = UICollectionView.CellRegistration<TagCollectionViewListCell, RelationshipData>

    private lazy var dataSource = makeDataSource()
    private lazy var addItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(openAddWorkflow))
    private lazy var selectionItem = UIBarButtonItem(title: "Select All" , style: .plain, target: self, action: #selector(selectionAction))
    private lazy var removeAllItem = UIBarButtonItem(title: "Remove All" , style: .plain, target: self, action: #selector(removeAllTags))
    private lazy var removeItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(removeTags))

    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    private let collectionRefreshControl = RefreshControl(frame: .zero)
    private let cellRegistration = TagCell { cell, indexPath, tag in
        var content = cell.defaultContentConfiguration()

        content.textProperties.font = R.font.circularStdBook(size: UIFont.labelFontSize)!
        content.textProperties.numberOfLines = 0
        content.text = tag.id

        cell.contentConfiguration = content

        cell.selectedBackgroundView = selectedBackgroundCellView
        cell.accessories = [.disclosureIndicator(displayed: .whenNotEditing), .multiselect(displayed: .whenEditing)]
    }

    private var listConfig = UICollectionLayoutListConfiguration(appearance: .grouped)

    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(collectionView)
        
        configureProperties()
        configureNavigation()
        configureToolbar()
        configureRefreshControl()
        configureCollectionView()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        collectionView.frame = view.bounds
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
        
        collectionView.isEditing = editing

        updateToolbarItems()
        addItem.isEnabled = !editing

        navigationController?.setToolbarHidden(!editing, animated: true)
    }
}

// MARK: - Configuration

private extension TagsCVC {
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

        setToolbarItems([selectionItem, removeAllItem, .flexibleSpace(), removeItem], animated: false)
    }

    private func configureRefreshControl() {
        collectionRefreshControl.addTarget(self, action: #selector(refreshTags), for: .valueChanged)
    }

    private func configureCollectionView() {
        collectionView.dataSource = dataSource
        collectionView.delegate = self
        collectionView.refreshControl = collectionRefreshControl
        collectionView.allowsMultipleSelectionDuringEditing = true
        collectionView.autoresizingMask = [.flexibleHeight, .flexibleWidth]

        listConfig.trailingSwipeActionsConfigurationProvider = { [self] indexPath in
            guard let tag = dataSource.itemIdentifier(for: indexPath) else {
                return nil
            }

            return UISwipeActionsConfiguration(actions: [
                UIContextualAction(style: .destructive, title: "Remove") { action, sourceView, completionHandler in
                    let ac = UIAlertController(title: nil, message: "Are you sure you want to remove \"\(tag.id)\" from \"\(transaction.attributes.description)\"?", preferredStyle: .actionSheet)

                    let confirmAction = UIAlertAction(title: "Remove", style: .destructive) { _ in
                        let tagObject = TagResource(id: tag.id)

                        upApi.modifyTags(removing: tagObject, from: transaction) { error in
                            switch error {
                                case .none:
                                    DispatchQueue.main.async {
                                        let notificationBanner = NotificationBanner(title: "Success", subtitle: "\(tag.id) was removed from \(transaction.attributes.description).", style: .success)

                                        notificationBanner.duration = 2

                                        notificationBanner.show()
                                        completionHandler(true)
                                        fetchTransaction()
                                    }
                                default:
                                    DispatchQueue.main.async {
                                        let notificationBanner = NotificationBanner(title: "Failed", subtitle: errorString(for: error!), style: .danger)

                                        notificationBanner.duration = 2

                                        notificationBanner.show()
                                        completionHandler(false)
                                    }
                            }
                        }
                    }

                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
                        completionHandler(false)
                    }

                    cancelAction.setValue(R.color.accentColour(), forKey: "titleTextColor")

                    ac.addAction(confirmAction)
                    ac.addAction(cancelAction)

                    present(ac, animated: true)
                }
            ])
        }

        collectionView.collectionViewLayout = UICollectionViewCompositionalLayout.list(using: listConfig)
    }
}

// MARK: - Actions

private extension TagsCVC {
    @objc private func appMovedToForeground() {
        fetchTransaction()
    }

    @objc private func openAddWorkflow() {
        let vc = AddTagWorkflowTwoVC()

        vc.transaction = transaction
        vc.fromTransactionTags = true

        let vcNav = NavigationController(rootViewController: vc)

        vcNav.modalPresentationStyle = .fullScreen

        present(vcNav, animated: true)
    }

    @objc private func refreshTags() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
            fetchTransaction()
        }
    }

    @objc private func selectionAction() {
        switch collectionView.indexPathsForSelectedItems?.count {
            case transaction.relationships.tags.data.count:
                collectionView.indexPathsForSelectedItems?.forEach { path in
                    collectionView.deselectItem(at: path, animated: false)
                }
            default:
                let indexes = transaction.relationships.tags.data.map { tag in
                    dataSource.indexPath(for: tag)
                }

                indexes.forEach { index in
                    collectionView.selectItem(at: index, animated: false, scrollPosition: .top)
                }
        }

        updateToolbarItems()
    }

    @objc private func removeTags() {
        if let tags = collectionView.indexPathsForSelectedItems?.map { index in
            dataSource.itemIdentifier(for: index)
        } {
            let tagIds = tags.map { tag in
                tag!.id
            }.joined(separator: ", ")

            let ac = UIAlertController(title: nil, message: "Are you sure you want to remove \"\(tagIds)\" from \"\(transaction.attributes.description)\"?", preferredStyle: .actionSheet)

            let confirmAction = UIAlertAction(title: "Remove", style: .destructive) { [self] _ in
                let tagsObject = tags.map { tag in
                    TagResource(id: tag!.id)
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

        let confirmAction = UIAlertAction(title: "Remove", style: .destructive) { [self] _ in
            let tagsObject = tags.map { tag in
                TagResource(id: tag.id)
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

    private func updateToolbarItems() {
        selectionItem.title = collectionView.indexPathsForSelectedItems?.count == transaction.relationships.tags.data.count ? "Deselect All" : "Select All"
        removeItem.isEnabled = collectionView.indexPathsForSelectedItems != nil && collectionView.indexPathsForSelectedItems != []
    }

    private func makeDataSource() -> DataSource {
        DataSource(collectionView: collectionView) { [self] collectionView, indexPath, tag in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: tag)
        }
    }

    private func applySnapshot(animate: Bool = false) {
        var snapshot = Snapshot()

        snapshot.appendSections([.main])
        snapshot.appendItems(transaction.relationships.tags.data, toSection: .main)

        dataSource.apply(snapshot, animatingDifferences: animate)
    }

    private func fetchTransaction() {
        upApi.retrieveTransaction(for: transaction) { result in
            switch result {
                case .success(let transaction):
                    DispatchQueue.main.async {
                        self.transaction = transaction
                    }
                case .failure(let error):
                    DispatchQueue.main.async { [self] in
                        collectionView.refreshControl?.endRefreshing()
                    }
                    print(errorString(for: error))
            }
        }
    }
}

// MARK: - UICollectionViewDelegate

extension TagsCVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, canEditItemAt indexPath: IndexPath) -> Bool {
        true
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch isEditing {
            case true:
                updateToolbarItems()
            case false:
                collectionView.deselectItem(at: indexPath, animated: true)

                if let tag = dataSource.itemIdentifier(for: indexPath)?.id {
                    let vc = TransactionsByTagVC()

                    vc.tag = TagResource(id: tag)

                    navigationController?.pushViewController(vc, animated: true)
                }
        }
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        switch isEditing {
            case true:
                updateToolbarItems()
            case false:
                break
        }
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        switch isEditing {
            case true:
                return nil
            case false:
                guard let tag = dataSource.itemIdentifier(for: indexPath) else {
                    return nil
                }

                return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                    UIMenu(children: [
                        UIAction(title: "Copy", image: R.image.docOnClipboard()) { _ in
                            UIPasteboard.general.string = tag.id
                        },
                        UIAction(title: "Remove", image: R.image.trash(), attributes: .destructive) { [self] _ in
                            let ac = UIAlertController(title: nil, message: "Are you sure you want to remove \"\(tag.id)\" from \"\(transaction.attributes.description)\"?", preferredStyle: .actionSheet)

                            let confirmAction = UIAlertAction(title: "Remove", style: .destructive) { _ in
                                let tagObject = TagResource(id: tag.id)

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
                            
                            present(ac, animated: true)
                        }
                    ])
                }
        }
    }
}
