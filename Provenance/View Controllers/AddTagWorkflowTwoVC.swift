import UIKit
import FLAnimatedImage
import TinyConstraints
import Rswift

class AddTagWorkflowTwoVC: TableViewController {
    // MARK: - Properties

    var transaction: TransactionResource!
    var fromTransactionTags: Bool = false

    private enum Section {
        case main
    }

    private typealias DataSource = UITableViewDiffableDataSource<Section, TagResource>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, TagResource>

    private lazy var dataSource = makeDataSource()
    private lazy var editingItem = UIBarButtonItem(title: isEditing ? "Cancel" : "Select", style: .plain, target: self, action: #selector(toggleEditing))
    private lazy var addItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(openAddWorkflow))
    private lazy var selectionItem = UIBarButtonItem(title: "Deselect All" , style: .plain, target: self, action: #selector(selectionAction))
    private lazy var selectionLabelItem = UIBarButtonItem(title: "\(tableView.indexPathsForSelectedRows?.count.description ?? "0") of 6 selected")
    private lazy var nextItem = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(nextAction))

    private let tableRefreshControl = RefreshControl(frame: .zero)
    private let searchController = SearchController(searchResultsController: nil)

    private var tagsPagination: Pagination = Pagination(prev: nil, next: nil)
    private var noTags: Bool = false
    private var tags: [TagResource] = [] {
        didSet {
            noTags = tags.isEmpty
            applySnapshot()
            updateToolbarItems()
            refreshControl?.endRefreshing()
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
    
    override init(style: UITableView.Style) {
        super.init(style: style)
        configureProperties()
        configureNavigation()
        configureToolbar()
        configureSearch()
        configureRefreshControl()
        configureTableView()
        applySnapshot()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
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
        updateToolbarItems()
        navigationController?.setToolbarHidden(!editing, animated: true)
        addItem.isEnabled = !editing
        editingItem = UIBarButtonItem(title: editing ? "Cancel" : "Select", style: .plain, target: self, action: #selector(toggleEditing))
        navigationItem.rightBarButtonItems = [addItem, editingItem]
        navigationItem.title = editing ? "Select Tags" : "Select Tag"
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
    }

    private func updateToolbarItems() {
        selectionItem.isEnabled = tableView.indexPathsForSelectedRows != nil
        selectionLabelItem.title = "\(tableView.indexPathsForSelectedRows?.count.description ?? "0") of 6 selected"
        nextItem.isEnabled = tableView.indexPathsForSelectedRows != nil
    }

    private func configureToolbar() {
        selectionItem.tintColor = R.color.accentColour()
        selectionLabelItem.tintColor = .label
        nextItem.tintColor = R.color.accentColour()
        setToolbarItems([selectionItem, .flexibleSpace(), selectionLabelItem, .flexibleSpace(), nextItem], animated: true)
    }
    
    private func configureSearch() {
        searchController.searchBar.delegate = self
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

private extension AddTagWorkflowTwoVC {
    @objc private func appMovedToForeground() {
        fetchTags()
    }

    @objc private func closeWorkflow() {
        navigationController?.dismiss(animated: true)
    }

    @objc private func selectionAction() {
        tableView.indexPathsForSelectedRows?.forEach { path in
            tableView.deselectRow(at: path, animated: false)
        }
        updateToolbarItems()
    }

    @objc private func nextAction() {
        if let tags = tableView.indexPathsForSelectedRows?.map { index in
            dataSource.itemIdentifier(for: index)
        } {
            let tagsObject: [TagResource] = tags.map { tag in
                TagResource(type: "tags", id: tag!.id)
            }
            navigationController?.pushViewController({let vc = AddTagWorkflowThreeVC(style: .insetGrouped);vc.transaction = transaction;vc.tags = tagsObject;return vc}(), animated: true)
        }
    }

    @objc private func textFieldTextDidChange() {
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
            ac.addTextField { textField in
                textField.delegate = self
                textField.autocapitalizationType = .none
                textField.autocorrectionType = .no
                textField.tintColor = R.color.accentColour()
                textField.addTarget(self, action: #selector(self.textFieldTextDidChange), for: .editingChanged)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        cancelAction.setValue(R.color.accentColour(), forKey: "titleTextColor")
        let submitAction = UIAlertAction(title: "Next", style: .default) { [unowned self] _ in
            let answers = ac.textFields?.map { tfield in
                TagResource(type: "tags", id: tfield.text ?? "")
            }
            if let fanswers = answers?.filter { answer in
                !answer.id.isEmpty
            } {
                self.navigationController?.pushViewController({let vc = AddTagWorkflowThreeVC(style: .insetGrouped);vc.transaction = self.transaction;vc.tags = fanswers;return vc}(), animated: true)
            }
        }
        submitAction.setValue(R.color.accentColour(), forKey: "titleTextColor")
        submitAction.isEnabled = false
        ac.addAction(cancelAction)
        ac.addAction(submitAction)
        present(ac, animated: true)
    }

    @objc private func refreshTags() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.fetchTags()
        }
    }

    @objc private func toggleEditing() {
        setEditing(!isEditing, animated: true)
    }

    private func makeDataSource() -> DataSource {
        let dataSource = DataSource(
            tableView: tableView,
            cellProvider: { tableView, indexPath, tag in
            let cell = tableView.dequeueReusableCell(withIdentifier: "tagCell", for: indexPath) as! BasicTableViewCell
            cell.selectedBackgroundView = selectedBackgroundCellView
            cell.separatorInset = .zero
            cell.textLabel?.font = R.font.circularStdBook(size: UIFont.labelFontSize)
            cell.textLabel?.textAlignment = .left
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = tag.id
            return cell
        }
        )
        dataSource.defaultRowAnimation = .fade
        return dataSource
    }

    private func applySnapshot(animate: Bool = false) {
        var snapshot = Snapshot()
        snapshot.appendSections([.main])
        snapshot.appendItems(filteredTagsList.data, toSection: .main)
        if snapshot.itemIdentifiers.isEmpty && tagsError.isEmpty {
            if tags.isEmpty && !noTags {
                tableView.backgroundView = {
                    let view = UIView(frame: CGRect(x: tableView.bounds.midX, y: tableView.bounds.midY, width: tableView.bounds.width, height: tableView.bounds.height))
                    let loadingIndicator = FLAnimatedImageView()
                    loadingIndicator.animatedImage = upZapSpinTransparentBackground
                    loadingIndicator.width(100)
                    loadingIndicator.height(100)
                    view.addSubview(loadingIndicator)
                    loadingIndicator.center(in: view)
                    return view
                }()
            } else {
                tableView.backgroundView = {
                    let view = UIView(frame: CGRect(x: tableView.bounds.midX, y: tableView.bounds.midY, width: tableView.bounds.width, height: tableView.bounds.height))
                    let icon = UIImageView(image: R.image.xmarkDiamond())
                    icon.tintColor = .secondaryLabel
                    icon.width(70)
                    icon.height(64)
                    let label = UILabel()
                    label.translatesAutoresizingMaskIntoConstraints = false
                    label.textAlignment = .center
                    label.textColor = .secondaryLabel
                    label.font = R.font.circularStdBook(size: 23)
                    label.text = "No Tags"
                    let vstack = UIStackView(arrangedSubviews: [icon, label])
                    vstack.axis = .vertical
                    vstack.alignment = .center
                    vstack.spacing = 10
                    view.addSubview(vstack)
                    vstack.edges(to: view, excluding: [.top, .bottom, .leading, .trailing], insets: .horizontal(16))
                    vstack.center(in: view)
                    return view
                }()
            }
        } else {
            if !tagsError.isEmpty {
                tableView.backgroundView = {
                    let view = UIView(frame: CGRect(x: tableView.bounds.midX, y: tableView.bounds.midY, width: tableView.bounds.width, height: tableView.bounds.height))
                    let label = UILabel()
                    view.addSubview(label)
                    label.edges(to: view, excluding: [.top, .bottom, .leading, .trailing], insets: .horizontal(16))
                    label.center(in: view)
                    label.textAlignment = .center
                    label.textColor = .secondaryLabel
                    label.font = R.font.circularStdBook(size: UIFont.labelFontSize)
                    label.numberOfLines = 0
                    label.text = tagsError
                    return view
                }()
            } else {
                if tableView.backgroundView != nil {
                    tableView.backgroundView = nil
                }
            }
        }
        dataSource.apply(snapshot, animatingDifferences: animate)
    }

    private func fetchTags() {
        upApi.listTags { result in
            switch result {
                case .success(let tags):
                    DispatchQueue.main.async {
                        self.tagsError = ""
                        self.tags = tags
                        if self.navigationItem.title != "Select Tag" || self.navigationItem.title != "Select Tags" {
                            self.navigationItem.title = self.isEditing ? "Select Tags" : "Select Tag"
                        }
                        if self.navigationItem.rightBarButtonItems == nil {
                            self.navigationItem.setRightBarButtonItems([self.addItem, self.editingItem], animated: true)
                        }
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.tagsError = errorString(for: error)
                        self.tags = []
                        self.setEditing(false, animated: true)
                        if self.navigationItem.title != "Error" {
                            self.navigationItem.title = "Error"
                        }
                        if self.navigationItem.rightBarButtonItems != nil {
                            self.navigationItem.setRightBarButtonItems(nil, animated: true)
                        }
                    }
            }
        }
    }
}

// MARK: - UITableViewDelegate

extension AddTagWorkflowTwoVC {
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if let paths = tableView.indexPathsForSelectedRows {
            if paths.count == 6 {
                return nil
            }
            return indexPath
        }
        return indexPath
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch isEditing {
            case true:
                updateToolbarItems()
            case false:
                tableView.deselectRow(at: indexPath, animated: true)
                navigationController?.pushViewController({let vc = AddTagWorkflowThreeVC(style: .insetGrouped);vc.transaction = transaction;vc.tags = [TagResource(type: "tags", id: dataSource.itemIdentifier(for: indexPath)!.id)];return vc}(), animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if isEditing {
            updateToolbarItems()
        }
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        switch isEditing {
            case true:
                return nil
            case false:
                return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                    UIMenu(children: [
                        UIAction(title: "Copy", image: R.image.docOnClipboard()) { action in
                        UIPasteboard.general.string = self.dataSource.itemIdentifier(for: indexPath)!.id
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
        guard let stringRange = Range(range, in: textField.text ?? "") else { return false }
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
