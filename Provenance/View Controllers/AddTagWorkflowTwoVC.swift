import UIKit
import FLAnimatedImage
import TinyConstraints
import Rswift

final class AddTagWorkflowTwoVC: UIViewController {
    // MARK: - Properties

    var transaction: TransactionResource!
    var fromTransactionTags: Bool = false

    private enum Section {
        case main
    }

    private typealias DataSource = UICollectionViewDiffableDataSource<Section, TagResource>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, TagResource>
    private typealias TagCell = UICollectionView.CellRegistration<TagCollectionViewListCell, TagResource>

    private lazy var dataSource = makeDataSource()
    private lazy var editingItem = UIBarButtonItem(title: isEditing ? "Cancel" : "Select", style: .plain, target: self, action: #selector(toggleEditing))
    private lazy var addItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(openAddWorkflow))
    private lazy var selectionItem = UIBarButtonItem(title: "Deselect All" , style: .plain, target: self, action: #selector(selectionAction))
    private lazy var selectionLabelItem = UIBarButtonItem(title: "\(collectionView.indexPathsForSelectedItems?.count.description ?? "0") of 6 selected")
    private lazy var nextItem = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(nextAction))

    private let tagsPagination = Pagination(prev: nil, next: nil)
    private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewCompositionalLayout.list(using: UICollectionLayoutListConfiguration(appearance: .grouped)))
    private let collectionRefreshControl = RefreshControl(frame: .zero)
    private let searchController = SearchController(searchResultsController: nil)
    private let cellRegistration = TagCell { cell, indexPath, tag in
        var content = cell.defaultContentConfiguration()

        content.textProperties.font = R.font.circularStdBook(size: UIFont.labelFontSize)!
        content.textProperties.numberOfLines = 0
        content.text = tag.id

        cell.contentConfiguration = content

        cell.selectedBackgroundView = selectedBackgroundCellView
        cell.accessories = [.multiselect(displayed: .whenEditing)]
    }

    private var noTags: Bool = false
    private var tags: [TagResource] = [] {
        didSet {
            noTags = tags.isEmpty
            applySnapshot()
            updateToolbarItems()
            collectionView.refreshControl?.endRefreshing()
            searchController.searchBar.placeholder = "Search \(tags.count.description) \(tags.count == 1 ? "Tag" : "Tags")"
        }
    }
    private var tagsError: String = ""
    private var filteredTags: [TagResource] {
        tags.filter { tag in
            searchController.searchBar.text!.isEmpty || tag.id.localizedStandardContains(searchController.searchBar.text!)
        }
    }
    private var filteredTagsList: Tag {
        Tag(data: filteredTags, links: tagsPagination)
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(collectionView)

        configureProperties()
        configureNavigation()
        configureToolbar()
        configureSearch()
        configureRefreshControl()
        configureCollectionView()

        applySnapshot()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        collectionView.frame = view.bounds
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        fetchTags()
        
        if fromTransactionTags {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeWorkflow))
        }
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
        editingItem = UIBarButtonItem(title: editing ? "Cancel" : "Select", style: .plain, target: self, action: #selector(toggleEditing))
        addItem.isEnabled = !editing

        navigationItem.rightBarButtonItems = [addItem, editingItem]
        navigationItem.title = editing ? "Select Tags" : "Select Tag"
        navigationController?.setToolbarHidden(!editing, animated: true)
    }
}

// MARK: - Configuration

private extension AddTagWorkflowTwoVC {
    private func configureProperties() {
        title = "Tag Selection"
        definesPresentationContext = true

        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    private func configureNavigation() {
        navigationItem.title = "Loading"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    private func configureToolbar() {
        selectionItem.tintColor = R.color.accentColour()
        selectionLabelItem.tintColor = .label
        nextItem.tintColor = R.color.accentColour()

        setToolbarItems([selectionItem, .flexibleSpace(), selectionLabelItem, .flexibleSpace(), nextItem], animated: false)
    }
    
    private func configureSearch() {
        searchController.searchBar.delegate = self
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
    }
}

// MARK: - Actions

private extension AddTagWorkflowTwoVC {
    @objc private func appMovedToForeground() {
        fetchTags()
    }

    @objc private func closeWorkflow() {
        navigationController?.dismiss(animated: true)
    }

    @objc private func selectionAction() {
        collectionView.indexPathsForSelectedItems?.forEach { path in
            collectionView.deselectItem(at: path, animated: false)
        }

        updateToolbarItems()
    }

    @objc private func nextAction() {
        if let tags = collectionView.indexPathsForSelectedItems?.map { index in
            dataSource.itemIdentifier(for: index)
        } {
            let tagsObject = tags.map { tag in
                TagResource(id: tag!.id)
            }

            let vc = AddTagWorkflowThreeVC()

            vc.transaction = transaction
            vc.tags = tagsObject

            navigationController?.pushViewController(vc, animated: true)
        }
    }

    @objc private func addTagsTextFieldChanged() {
        if let alert = presentedViewController as? UIAlertController,
           let action = alert.actions.last {
            let text = alert.textFields?.map { field in
                field.text ?? ""
            }.joined() ?? ""

            action.isEnabled = text.count > 0
        }
    }

    @objc private func openAddWorkflow() {
        let ac = UIAlertController(title: "Create Tags", message: "You can add a maximum of six tags to a transaction.", preferredStyle: .alert)

        let fields = Array(0...5)

        fields.forEach { field in
            ac.addTextField { [self] textField in
                textField.delegate = self
                textField.autocapitalizationType = .none
                textField.autocorrectionType = .no
                textField.tintColor = R.color.accentColour()
                textField.addTarget(self, action: #selector(addTagsTextFieldChanged), for: .editingChanged)
            }
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        cancelAction.setValue(R.color.accentColour(), forKey: "titleTextColor")

        let submitAction = UIAlertAction(title: "Next", style: .default) { [self] _ in
            let answers = ac.textFields?.map { tfield in
                TagResource(id: tfield.text ?? "")
            }

            if let fanswers = answers?.filter { answer in
                !answer.id.isEmpty
            } {
                let vc = AddTagWorkflowThreeVC()

                vc.transaction = transaction
                vc.tags = fanswers

                navigationController?.pushViewController(vc, animated: true)
            }
        }

        submitAction.setValue(R.color.accentColour(), forKey: "titleTextColor")
        submitAction.isEnabled = false

        ac.addAction(cancelAction)
        ac.addAction(submitAction)

        present(ac, animated: true)
    }

    @objc private func refreshTags() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
            fetchTags()
        }
    }

    @objc private func toggleEditing() {
        setEditing(!isEditing, animated: true)
    }

    private func updateToolbarItems() {
        selectionItem.isEnabled = collectionView.indexPathsForSelectedItems != nil && collectionView.indexPathsForSelectedItems != []
        selectionLabelItem.title = "\(collectionView.indexPathsForSelectedItems?.count.description ?? "0") of 6 selected"
        nextItem.isEnabled = collectionView.indexPathsForSelectedItems != nil && collectionView.indexPathsForSelectedItems != []
    }

    private func makeDataSource() -> DataSource {
        DataSource(collectionView: collectionView) { [self] collectionView, indexPath, tag in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: tag)
        }
    }

    private func applySnapshot(animate: Bool = false) {
        var snapshot = Snapshot()

        snapshot.appendSections([.main])
        snapshot.appendItems(filteredTagsList.data, toSection: .main)

        if snapshot.itemIdentifiers.isEmpty && tagsError.isEmpty {
            if tags.isEmpty && !noTags {
                collectionView.backgroundView = {
                    let view = UIView(frame: collectionView.bounds)

                    let loadingIndicator = FLAnimatedImageView()

                    view.addSubview(loadingIndicator)

                    loadingIndicator.centerInSuperview()
                    loadingIndicator.width(100)
                    loadingIndicator.height(100)
                    loadingIndicator.animatedImage = upZapSpinTransparentBackground

                    return view
                }()
            } else {
                collectionView.backgroundView = {
                    let view = UIView(frame: collectionView.bounds)

                    let icon = UIImageView(image: R.image.xmarkDiamond())

                    icon.width(70)
                    icon.height(64)
                    icon.tintColor = .secondaryLabel

                    let label = UILabel()

                    label.translatesAutoresizingMaskIntoConstraints = false
                    label.textAlignment = .center
                    label.textColor = .secondaryLabel
                    label.font = R.font.circularStdBook(size: 23)
                    label.text = "No Tags"

                    let vStack = UIStackView(arrangedSubviews: [icon, label])

                    view.addSubview(vStack)

                    vStack.horizontalToSuperview(insets: .horizontal(16))
                    vStack.centerInSuperview()
                    vStack.axis = .vertical
                    vStack.alignment = .center
                    vStack.spacing = 10

                    return view
                }()
            }
        } else {
            if !tagsError.isEmpty {
                collectionView.backgroundView = {
                    let view = UIView(frame: collectionView.bounds)

                    let label = UILabel()

                    view.addSubview(label)

                    label.horizontalToSuperview(insets: .horizontal(16))
                    label.centerInSuperview()
                    label.textAlignment = .center
                    label.textColor = .secondaryLabel
                    label.font = R.font.circularStdBook(size: UIFont.labelFontSize)
                    label.numberOfLines = 0
                    label.text = tagsError

                    return view
                }()
            } else {
                if collectionView.backgroundView != nil {
                    collectionView.backgroundView = nil
                }
            }
        }

        dataSource.apply(snapshot, animatingDifferences: animate)
    }

    private func fetchTags() {
        upApi.listTags { result in
            switch result {
                case .success(let tags):
                    DispatchQueue.main.async { [self] in
                        tagsError = ""
                        self.tags = tags

                        if navigationItem.title != "Select Tag" || navigationItem.title != "Select Tags" {
                            navigationItem.title = isEditing ? "Select Tags" : "Select Tag"
                        }
                        if navigationItem.rightBarButtonItems == nil {
                            navigationItem.setRightBarButtonItems([addItem, editingItem], animated: true)
                        }
                    }
                case .failure(let error):
                    DispatchQueue.main.async { [self] in
                        tagsError = errorString(for: error)
                        tags = []
                        setEditing(false, animated: false)

                        if navigationItem.title != "Error" {
                            navigationItem.title = "Error"
                        }
                        if navigationItem.rightBarButtonItems != nil {
                            navigationItem.setRightBarButtonItems(nil, animated: true)
                        }
                    }
            }
        }
    }
}

// MARK: - UICollectionViewDelegate

extension AddTagWorkflowTwoVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch isEditing {
            case true:
                updateToolbarItems()
            case false:
                collectionView.deselectItem(at: indexPath, animated: true)

                if let tag = dataSource.itemIdentifier(for: indexPath)?.id {
                    let vc = AddTagWorkflowThreeVC()

                    vc.transaction = transaction
                    vc.tags = [TagResource(id: tag)]

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
                guard let tag = dataSource.itemIdentifier(for: indexPath)?.id else {
                    return nil
                }

                return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                    UIMenu(children: [
                        UIAction(title: "Copy", image: R.image.docOnClipboard()) { _ in
                            UIPasteboard.general.string = tag
                        }
                    ])
                }
        }
    }
}

// MARK: - UITextFieldDelegate

extension AddTagWorkflowTwoVC: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""

        guard let stringRange = Range(range, in: textField.text ?? "") else {
            return false
        }

        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)

        return updatedText.count <= 30
    }
}

// MARK: - UISearchBarDelegate

extension AddTagWorkflowTwoVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        applySnapshot(animate: true)
        updateToolbarItems()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if !searchBar.text!.isEmpty {
            searchBar.text = ""
            applySnapshot(animate: true)
        }
    }
}
