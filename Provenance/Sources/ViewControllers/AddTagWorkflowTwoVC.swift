import UIKit
import FLAnimatedImage
import SwiftyBeaver
import NotificationBannerSwift
import TinyConstraints
import Rswift

final class AddTagWorkflowTwoVC: UIViewController {
    // MARK: - Properties

    private var transaction: TransactionResource

    private var fromTransactionTags: Bool

    private typealias Snapshot = NSDiffableDataSourceSnapshot<SortedTags, TagResource>

    private lazy var dataSource = makeDataSource()

    private lazy var editingBarButtonItem = UIBarButtonItem(title: isEditing ? "Cancel" : "Select", style: isEditing ? .done : .plain, target: self, action: #selector(toggleEditing))

    private lazy var addBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(openAddWorkflow))

    private lazy var selectionBarButtonItem = UIBarButtonItem(title: "Deselect All", style: .plain, target: self, action: #selector(selectionAction))

    private lazy var selectionLabelBarButtonItem = UIBarButtonItem(title: "\(tableView.indexPathsForSelectedRows?.count.description ?? "0") of 6 selected")

    private lazy var nextBarButtonItem = UIBarButtonItem(title: "Next", style: .plain, target: self, action: #selector(nextAction))

    private let tableView = UITableView(frame: .zero, style: .plain)

    private let tableRefreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(refreshTags), for: .valueChanged)
        return rc
    }()

    private let searchController = SearchController(searchResultsController: nil)

    private var showingBanner: Bool = false

    private var noTags: Bool = false

    private var tags: [TagResource] = [] {
        didSet {
            log.info("didSet tags: \(tags.count.description)")

            noTags = tags.isEmpty
            applySnapshot()
            updateToolbarItems()
            tableView.refreshControl?.endRefreshing()
            searchController.searchBar.placeholder = "Search \(tags.count.description) \(tags.count == 1 ? "Tag" : "Tags")"
        }
    }

    private var tagsError: String = ""

    private var filteredTags: [TagResource] {
        tags.filter { tag in
            searchController.searchBar.text!.isEmpty || tag.id.localizedStandardContains(searchController.searchBar.text!)
        }
    }

    private var groupedTags: [String: [TagResource]] {
        Dictionary(
            grouping: filteredTags,
            by: { String($0.id.prefix(1)) }
        )
    }

    private var keys: [String] {
        return groupedTags.keys.sorted()
    }

    private var sortedTags: [(key: String, value: [TagResource])] {
        return groupedTags.sorted { $0.key < $1.key }
    }

    private var sections: [SortedTags] = []

    // UITableViewDiffableDataSource
    private class DataSource: UITableViewDiffableDataSource<SortedTags, TagResource> {
        weak var parent: AddTagWorkflowTwoVC! = nil

        override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
            return parent.isEditing
        }

        override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
            guard let firstTag = itemIdentifier(for: IndexPath(item: 0, section: section)) else { return nil }

            guard let section = snapshot().sectionIdentifier(containingItem: firstTag) else { return nil }

            return section.id.capitalized
        }

        override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
            return parent.keys.map { $0.capitalized }
        }
    }

    // MARK: - Life Cycle

    init(transaction: TransactionResource, fromTransactionTags: Bool = false) {
        self.transaction = transaction
        self.fromTransactionTags = fromTransactionTags
        super.init(nibName: nil, bundle: nil)
        log.debug("init(transaction: \(transaction.attributes.transactionDescription), fromTransactionTags: \(fromTransactionTags.description))")
        dataSource.parent = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        log.debug("deinit")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        log.debug("viewDidLoad")
        view.addSubview(tableView)
        configureProperties()
        configureNavigation()
        configureToolbar()
        configureSearch()
        configureTableView()
        applySnapshot()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        log.debug("viewDidLayoutSubviews")
        tableView.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        log.debug("viewWillAppear(animated: \(animated.description))")
        fetchTags()

        if fromTransactionTags {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeWorkflow))
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        log.debug("viewDidAppear(animated: \(animated.description))")
        navigationController?.setToolbarHidden(!isEditing, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        log.debug("viewWillDisappear(animated: \(animated.description))")
        navigationController?.setToolbarHidden(true, animated: false)
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        log.debug("setEditing(editing: \(editing.description), animated: \(animated.description))")
        tableView.setEditing(editing, animated: animated)

        updateToolbarItems()
        addBarButtonItem.isEnabled = !editing
        editingBarButtonItem = UIBarButtonItem(title: editing ? "Cancel" : "Select", style: editing ? .done : .plain, target: self, action: #selector(toggleEditing))

        navigationItem.rightBarButtonItems = [addBarButtonItem, editingBarButtonItem]
        navigationItem.title = editing ? "Select Tags" : "Select Tag"

        navigationController?.setToolbarHidden(!editing, animated: true)
    }
}

// MARK: - Configuration

private extension AddTagWorkflowTwoVC {
    private func configureProperties() {
        log.verbose("configureProperties")

        title = "Tag Selection"
        definesPresentationContext = true

        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }

    private func configureNavigation() {
        log.verbose("configureNavigation")

        navigationItem.title = "Loading"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.backButtonDisplayMode = .minimal
    }

    private func configureToolbar() {
        log.verbose("configureToolbar")

        selectionLabelBarButtonItem.tintColor = .label

        setToolbarItems([selectionBarButtonItem, .flexibleSpace(), selectionLabelBarButtonItem, .flexibleSpace(), nextBarButtonItem], animated: false)
    }

    private func configureSearch() {
        log.verbose("configureSearch")

        searchController.searchBar.delegate = self
    }

    private func configureTableView() {
        log.verbose("configureTableView")

        tableView.dataSource = dataSource
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "tagCell")
        tableView.refreshControl = tableRefreshControl
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        tableView.tintColor = R.color.accentColor()
    }
}

// MARK: - Actions

private extension AddTagWorkflowTwoVC {
    @objc private func appMovedToForeground() {
        log.verbose("appMovedToForeground")

        fetchTags()
    }

    @objc private func closeWorkflow() {
        log.verbose("closeWorkflow")

        navigationController?.dismiss(animated: true)
    }

    @objc private func selectionAction() {
        log.verbose("selectionAction")

        tableView.indexPathsForSelectedRows?.forEach { tableView.deselectRow(at: $0, animated: false) }

        updateToolbarItems()
    }

    @objc private func nextAction() {
        log.verbose("nextAction")

        if let tags = tableView.indexPathsForSelectedRows?.map { dataSource.itemIdentifier(for: $0) } {
            let tagsObject = tags.map { TagResource(id: $0!.id) }

            navigationController?.pushViewController(AddTagWorkflowThreeVC(transaction: transaction, tags: tagsObject), animated: true)
        }
    }

    @objc private func addTagsTextFieldChanged() {
        log.verbose("addTagsTextFieldChanged")

        if let alert = presentedViewController as? UIAlertController, let action = alert.actions.last {
            let text = alert.textFields?.map { $0.text ?? "" }.joined() ?? ""

            action.isEnabled = text.isEmpty
        }
    }

    @objc private func openAddWorkflow() {
        log.verbose("openAddWorkflow")

        let ac = UIAlertController(title: "Create Tags", message: "You can add a maximum of 6 tags to a transaction.", preferredStyle: .alert)

        let fields = Array(0...5)

        fields.forEach { _ in
            ac.addTextField { [self] textField in
                textField.delegate = self
                textField.autocapitalizationType = .none
                textField.autocorrectionType = .no
                textField.tintColor = R.color.accentColor()
                textField.addTarget(self, action: #selector(addTagsTextFieldChanged), for: .editingChanged)
            }
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        cancelAction.setValue(R.color.accentColor(), forKey: "titleTextColor")

        let submitAction = UIAlertAction(title: "Next", style: .default) { [self] _ in
            let answers = ac.textFields?.map { TagResource(id: $0.text ?? "") }

            if let fanswers = answers?.filter { !$0.id.isEmpty } {
                navigationController?.pushViewController(AddTagWorkflowThreeVC(transaction: transaction, tags: fanswers), animated: true)
            }
        }

        submitAction.setValue(R.color.accentColor(), forKey: "titleTextColor")
        submitAction.isEnabled = false

        ac.addAction(cancelAction)
        ac.addAction(submitAction)

        present(ac, animated: true)
    }

    @objc private func refreshTags() {
        log.verbose("refreshTags")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
            fetchTags()
        }
    }

    @objc private func toggleEditing() {
        log.verbose("toggleEditing")

        setEditing(!isEditing, animated: true)
    }

    private func updateToolbarItems() {
        log.verbose("updateToolbarItems")

        selectionBarButtonItem.isEnabled = tableView.indexPathsForSelectedRows != nil
        selectionLabelBarButtonItem.title = "\(tableView.indexPathsForSelectedRows?.count.description ?? "0") of 6 selected"
        selectionLabelBarButtonItem.style = tableView.indexPathsForSelectedRows?.count == 6 ? .done : .plain
        nextBarButtonItem.isEnabled = tableView.indexPathsForSelectedRows != nil
    }

    private func makeDataSource() -> DataSource {
        log.verbose("makeDataSource")

        let dataSource = DataSource(
            tableView: tableView,
            cellProvider: { tableView, indexPath, tag in
                let cell = tableView.dequeueReusableCell(withIdentifier: "tagCell", for: indexPath)

                cell.selectedBackgroundView = selectedBackgroundCellView
                cell.textLabel?.font = R.font.circularStdBook(size: UIFont.labelFontSize)
                cell.textLabel?.textAlignment = .left
                cell.textLabel?.numberOfLines = 0
                cell.textLabel?.text = tag.id

                return cell
            }
        )

        dataSource.defaultRowAnimation = .middle

        return dataSource
    }

    private func applySnapshot(animate: Bool = true) {
        log.verbose("applySnapshot(animate: \(animate.description))")

        sections = sortedTags.map { SortedTags(id: $0.key, tags: $0.value) }

        var snapshot = Snapshot()

        snapshot.appendSections(sections)

        sections.forEach { snapshot.appendItems($0.tags, toSection: $0) }

        if snapshot.itemIdentifiers.isEmpty && tagsError.isEmpty {
            if tags.isEmpty && !noTags {
                tableView.backgroundView = {
                    let view = UIView(frame: tableView.bounds)

                    let loadingIndicator = FLAnimatedImageView()

                    view.addSubview(loadingIndicator)

                    loadingIndicator.centerInSuperview()
                    loadingIndicator.width(100)
                    loadingIndicator.height(100)
                    loadingIndicator.animatedImage = upZapSpinTransparentBackground

                    return view
                }()
            } else {
                tableView.backgroundView = {
                    let view = UIView(frame: tableView.bounds)

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
                tableView.backgroundView = {
                    let view = UIView(frame: tableView.bounds)

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
                if tableView.backgroundView != nil {
                    tableView.backgroundView = nil
                }
            }
        }

        dataSource.apply(snapshot, animatingDifferences: animate)
    }

    private func fetchTags() {
        log.verbose("fetchTags")

        Up.listTags { [self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let tags):
                    display(tags)
                case .failure(let error):
                    display(error)
                }
            }
        }
    }

    private func display(_ tags: [TagResource]) {
        log.verbose("display(tags: \(tags.count.description))")

        tagsError = ""
        self.tags = tags

        if navigationItem.title != "Select Tag" || navigationItem.title != "Select Tags" {
            navigationItem.title = isEditing ? "Select Tags" : "Select Tag"
        }

        if navigationItem.rightBarButtonItems == nil {
            navigationItem.setRightBarButtonItems([addBarButtonItem, editingBarButtonItem], animated: true)
        }
    }

    private func display(_ error: NetworkError) {
        log.verbose("display(error: \(errorString(for: error)))")

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

// MARK: - UITableViewDelegate

extension AddTagWorkflowTwoVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        log.debug("tableView(willSelectRowAt indexPath: \(indexPath))")

        guard let paths = tableView.indexPathsForSelectedRows else { return indexPath }

        switch paths.count {
        case 6:
            if !showingBanner {
                let nb = FloatingNotificationBanner(title: "Forbidden", subtitle: "You can only select a maximum of 6 tags.", style: .danger)

                nb.delegate = self
                nb.duration = 0.5

                nb.show(bannerPosition: .bottom, cornerRadius: 10, shadowBlurRadius: 5, shadowCornerRadius: 20)
            }

            return nil
        default:
            return indexPath
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        log.debug("tableView(didSelectRowAt indexPath: \(indexPath))")

        switch isEditing {
        case true:
            updateToolbarItems()
        case false:
            tableView.deselectRow(at: indexPath, animated: true)

            if let tag = dataSource.itemIdentifier(for: indexPath)?.id {
                navigationController?.pushViewController(AddTagWorkflowThreeVC(transaction: transaction, tags: [TagResource(id: tag)]), animated: true)
            }
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        log.debug("tableView(didDeselectRowAt indexPath: \(indexPath))")

        switch isEditing {
        case true:
            updateToolbarItems()
        case false:
            break
        }
    }

    func tableView(_ tableView: UITableView, shouldBeginMultipleSelectionInteractionAt indexPath: IndexPath) -> Bool {
        return isEditing
    }

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        switch isEditing {
        case true:
            return nil
        case false:
            guard let tag = dataSource.itemIdentifier(for: indexPath)?.id else { return nil }

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

        guard let stringRange = Range(range, in: textField.text ?? "") else { return false }

        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)

        return updatedText.count <= 30
    }
}

// MARK: - UISearchBarDelegate

extension AddTagWorkflowTwoVC: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        log.debug("searchBar(textDidChange searchText: \(searchText))")

        applySnapshot()
        updateToolbarItems()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        log.debug("searchBarCancelButtonClicked")

        if !searchBar.text!.isEmpty {
            searchBar.text = ""
            applySnapshot()
        }
    }
}

// MARK: - NotificationBannerDelegate

extension AddTagWorkflowTwoVC: NotificationBannerDelegate {
    func notificationBannerWillAppear(_ banner: BaseNotificationBanner) {
        log.debug("notificationBannerWillAppear(banner: \(banner.titleLabel))")

        showingBanner = true
    }

    func notificationBannerWillDisappear(_ banner: BaseNotificationBanner) {
        log.debug("notificationBannerWillDisappear(banner: \(banner.titleLabel))")
    }

    func notificationBannerDidAppear(_ banner: BaseNotificationBanner) {
        log.debug("notificationBannerDidAppear(banner: \(banner.titleLabel))")
    }

    func notificationBannerDidDisappear(_ banner: BaseNotificationBanner) {
        log.debug("notificationBannerDidDisappear(banner: \(banner.titleLabel))")

        showingBanner = false
    }
}
