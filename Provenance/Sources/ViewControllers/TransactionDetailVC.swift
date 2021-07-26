import UIKit
import FLAnimatedImage
import MarqueeLabel
import SwiftyBeaver
import TinyConstraints
import Rswift

final class TransactionDetailVC: UIViewController {
    // MARK: - Properties

    private var transaction: TransactionResource {
        didSet {
            log.info("didSet transaction: \(transaction.attributes.transactionDescription)")

            fetchingTasks()
        }
    }

    private typealias DataSource = UITableViewDiffableDataSource<DetailSection, DetailAttribute>

    private typealias Snapshot = NSDiffableDataSourceSnapshot<DetailSection, DetailAttribute>

    private lazy var dataSource = makeDataSource()

    private let tableRefreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()

        rc.addTarget(
            self,
            action: #selector(refreshTransaction),
            for: .valueChanged
        )

        return rc
    }()

    private let scrollingTitle = MarqueeLabel()

    private let tableView = UITableView(
        frame: .zero,
        style: .grouped
    )

    private var sections: [DetailSection] = []

    private var filteredSections: [DetailSection] {
        return sections.filter {
            !$0.attributes.allSatisfy {
                $0.value.isEmpty ||
                ($0.id == "Tags" && $0.value == "0")
            }
        }
    }

    private var account: AccountResource? {
        didSet {
            applySnapshot()
        }
    }

    private var transferAccount: AccountResource? {
        didSet {
            applySnapshot()
        }
    }

    private var parentCategory: CategoryResource? {
        didSet {
            applySnapshot()
        }
    }

    private var category: CategoryResource? {
        didSet {
            applySnapshot()
        }
    }

    private var holdTransValue: String {
        switch transaction.attributes.holdInfo {
        case nil: return ""
        default:
            switch transaction.attributes.holdInfo!.amount.value {
            case transaction.attributes.amount.value: return ""
            default: return transaction.attributes.holdInfo!.amount.valueLong
            }
        }
    }

    private var holdForeignTransValue: String {
        switch transaction.attributes.holdInfo?.foreignAmount {
        case nil: return ""
        default:
            switch transaction.attributes.holdInfo!.foreignAmount!.value {
            case transaction.attributes.foreignAmount!.value: return ""
            default: return transaction.attributes.holdInfo!.foreignAmount!.valueLong
            }
        }
    }

    private var foreignTransValue: String {
        switch transaction.attributes.foreignAmount {
        case nil: return ""
        default: return transaction.attributes.foreignAmount!.valueLong
        }
    }

    // MARK: - Life Cycle

    init(transaction: TransactionResource) {
        self.transaction = transaction

        super.init(
            nibName: nil,
            bundle: nil
        )

        log.debug("init(transaction: \(transaction.attributes.transactionDescription))")
    }

    required init?(coder: NSCoder) { fatalError("Not implemented") }

    deinit { log.debug("deinit") }

    override func viewDidLoad() {
        super.viewDidLoad()

        log.debug("viewDidLoad")

        view.addSubview(tableView)

        configureProperties()
        configureTableView()
        configureScrollingTitle()
        configureNavigation()
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

        fetchTransaction()
    }
}

// MARK: - Configuration

private extension TransactionDetailVC {
    private func configureProperties() {
        log.verbose("configureProperties")

        title = "Transaction Details"

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appMovedToForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }

    private func configureTableView() {
        log.verbose("configureTableView")

        tableView.dataSource = dataSource
        tableView.delegate = self

        tableView.register(
            AttributeTableViewCell.self,
            forCellReuseIdentifier: AttributeTableViewCell.reuseIdentifier
        )

        tableView.refreshControl = tableRefreshControl

        tableView.autoresizingMask = [
            .flexibleWidth,
            .flexibleHeight
        ]

        tableView.showsVerticalScrollIndicator = false
    }

    private func configureScrollingTitle() {
        log.verbose("configureScrollingTitle")

        scrollingTitle.translatesAutoresizingMaskIntoConstraints = false
        scrollingTitle.speed = .rate(65)
        scrollingTitle.fadeLength = 20
        scrollingTitle.textAlignment = .center
        scrollingTitle.font = .boldSystemFont(ofSize: UIFont.labelFontSize)
        scrollingTitle.text = transaction.attributes.transactionDescription
    }

    private func configureNavigation() {
        log.verbose("configureNavigation")

        navigationItem.title = transaction.attributes.transactionDescription
        navigationItem.titleView = scrollingTitle
        navigationItem.largeTitleDisplayMode = .never

        navigationItem.setRightBarButton(
            UIBarButtonItem(
                image: transaction.attributes.statusIcon,
                style: .plain,
                target: self,
                action: #selector(openStatusIconHelpView)
            ),
            animated: false
        )

        navigationItem.rightBarButtonItem?.tintColor = transaction.attributes.isSettled
            ? .systemGreen
            : .systemYellow
    }
}

// MARK: - Actions

private extension TransactionDetailVC {
    @objc private func appMovedToForeground() {
        log.verbose("appMovedToForeground")

        fetchTransaction()
    }

    @objc private func openStatusIconHelpView() {
        log.verbose("openStatusIconHelpView")

        present(
            NavigationController(rootViewController: StatusIconHelpView()),
            animated: true
        )
    }

    @objc private func refreshTransaction() {
        log.verbose("refreshTransaction")

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 1,
            execute: {
                [self] in
                fetchTransaction()
            }
        )
    }

    private func fetchingTasks() {
        log.verbose("fetchingTasks")

        UpFacade.retrieveAccount(for: transaction.relationships.account.data.id) {
            (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let account): self.account = account
                case .failure: break
                }
            }
        }

        if let tAccount = transaction.relationships.transferAccount.data {
            UpFacade.retrieveAccount(for: tAccount.id) {
                (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let account): self.transferAccount = account
                    case .failure: break
                    }
                }
            }
        }

        if let pCategory = transaction.relationships.parentCategory.data {
            UpFacade.retrieveCategory(for: pCategory.id) {
                (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let category): self.parentCategory = category
                    case .failure: break
                    }
                }
            }
        } else {
            self.parentCategory = nil
        }

        if let category = transaction.relationships.category.data {
            UpFacade.retrieveCategory(for: category.id) {
                (result) in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let category): self.category = category
                    case .failure: break
                    }
                }
            }
        } else {
            self.category = nil
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now() + 1,
            execute: {
                [self] in
                tableView.refreshControl?.endRefreshing()
                configureScrollingTitle()
                configureNavigation()
            }
        )
    }

    private func makeDataSource() -> DataSource {
        log.verbose("makeDataSource")

        return DataSource(
            tableView: tableView,
            cellProvider: {
                (tableView, indexPath, attribute) in
                guard let cell = tableView.dequeueReusableCell(
                        withIdentifier: AttributeTableViewCell.reuseIdentifier,
                        for: indexPath) as? AttributeTableViewCell
                else {
                    fatalError("Unable to dequeue reusable cell with identifier: \(AttributeTableViewCell.reuseIdentifier)")
                }

                var cellSelectionStyle: UITableViewCell.SelectionStyle {
                    switch attribute.id {
                    case "Account", "Transfer Account", "Parent Category", "Category", "Tags": return .default
                    default: return .none
                    }
                }

                var cellAccessoryType: UITableViewCell.AccessoryType {
                    switch attribute.id {
                    case "Account", "Transfer Account", "Parent Category", "Category", "Tags": return .disclosureIndicator
                    default: return .none
                    }
                }

                cell.selectionStyle = cellSelectionStyle

                cell.accessoryType = cellAccessoryType

                cell.leftLabel.text = attribute.id

                cell.rightLabel.font = attribute.id == "Raw Text"
                    ? R.font.sfMonoRegular(size: UIFont.labelFontSize)
                    : R.font.circularStdBook(size: UIFont.labelFontSize)

                cell.rightLabel.text = attribute.value

                return cell
            }
        )
    }

    private func applySections() {
        log.verbose("applySections")

        sections = [
            DetailSection(
                id: 1,
                attributes: [
                    DetailAttribute(
                        id: "Status",
                        value: transaction.attributes.statusString
                    ),
                    DetailAttribute(
                        id: "Account",
                        value: account?.attributes.displayName ?? ""
                    ),
                    DetailAttribute(
                        id: "Transfer Account",
                        value: transferAccount?.attributes.displayName ?? ""
                    )
                ]
            ),
            DetailSection(
                id: 2,
                attributes: [
                    DetailAttribute(
                        id: "Description",
                        value: transaction.attributes.transactionDescription
                    ),
                    DetailAttribute(
                        id: "Raw Text",
                        value: transaction.attributes.rawText ?? ""
                    ),
                    DetailAttribute(
                        id: "Message",
                        value: transaction.attributes.message ?? ""
                    )
                ]
            ),
            DetailSection(
                id: 3,
                attributes: [
                    DetailAttribute(
                        id: "Hold \(transaction.attributes.holdInfo?.amount.transactionType ?? "")",
                        value: holdTransValue
                    ),
                    DetailAttribute(
                        id: "Hold Foreign \(transaction.attributes.holdInfo?.foreignAmount?.transactionType ?? "")",
                        value: holdForeignTransValue
                    ),
                    DetailAttribute(
                        id: "Foreign \(transaction.attributes.foreignAmount?.transactionType ?? "")",
                        value: foreignTransValue
                    ),
                    DetailAttribute(
                        id: transaction.attributes.amount.transactionType,
                        value: transaction.attributes.amount.valueLong
                    )
                ]
            ),
            DetailSection(
                id: 4,
                attributes: [
                    DetailAttribute(
                        id: "Creation Date",
                        value: transaction.attributes.creationDate
                    ),
                    DetailAttribute(
                        id: "Settlement Date",
                        value: transaction.attributes.settlementDate ?? ""
                    )
                ]
            ),
            DetailSection(
                id: 5,
                attributes: [
                    DetailAttribute(
                        id: "Parent Category",
                        value: parentCategory?.attributes.name ?? ""
                    ),
                    DetailAttribute(
                        id: "Category",
                        value: category?.attributes.name ?? ""
                    )
                ]
            ),
            DetailSection(
                id: 6,
                attributes: [
                    DetailAttribute(
                        id: "Tags",
                        value: transaction.relationships.tags.data.count.description
                    )
                ]
            )
        ]
    }

    private func applySnapshot(animate: Bool = true) {
        log.verbose("applySnapshot(animate: \(animate.description))")

        applySections()

        var snapshot = Snapshot()

        snapshot.appendSections(filteredSections)

        filteredSections.forEach {
            snapshot.appendItems(
                $0.attributes.filter { !$0.value.isEmpty },
                toSection: $0
            )
        }

        if snapshot.itemIdentifiers.isEmpty {
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
        } else if tableView.backgroundView != nil {
            tableView.backgroundView = nil
        }

        dataSource.apply(
            snapshot,
            animatingDifferences: animate
        )
    }

    private func fetchTransaction() {
        log.verbose("fetchTransaction")

        UpFacade.retrieveTransaction(for: transaction) {
            [self] (result) in
            DispatchQueue.main.async {
                switch result {
                case .success(let transaction): display(transaction)
                case .failure(let error): display(error)
                }
            }
        }
    }

    private func display(_ transaction: TransactionResource) {
        log.verbose("display(transaction: \(transaction.attributes.transactionDescription))")

        self.transaction = transaction
    }

    private func display(_ error: NetworkError) {
        log.verbose("display(error: \(errorString(for: error)))")

        tableView.refreshControl?.endRefreshing()
    }
}

// MARK: - UITableViewDelegate

extension TransactionDetailVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        log.debug("tableView(didSelectRowAt indexPath: \(indexPath))")

        if let attribute = dataSource.itemIdentifier(for: indexPath) {
            switch attribute.id {
            case "Account":
                tableView.deselectRow(
                    at: indexPath,
                    animated: true
                )

                if let account = account {
                    navigationController?.pushViewController(
                        TransactionsByAccountVC(account: account),
                        animated: true
                    )
                }
            case "Transfer Account":
                tableView.deselectRow(
                    at: indexPath,
                    animated: true
                )

                if let transferAccount = transferAccount {
                    navigationController?.pushViewController(
                        TransactionsByAccountVC(account: transferAccount),
                        animated: true
                    )
                }
            case "Parent Category":
                tableView.deselectRow(
                    at: indexPath,
                    animated: true
                )

                if let parentCategory = parentCategory {
                    navigationController?.pushViewController(
                        TransactionsByCategoryVC(category: parentCategory),
                        animated: true
                    )
                }
            case "Category":
                tableView.deselectRow(
                    at: indexPath,
                    animated: true
                )

                if let category = category {
                    navigationController?.pushViewController(
                        TransactionsByCategoryVC(category: category),
                        animated: true
                    )
                }
            case "Tags":
                tableView.deselectRow(
                    at: indexPath,
                    animated: true
                )

                navigationController?.pushViewController(
                    TransactionTagsVC(transaction: transaction),
                    animated: true
                )
            default: break
            }
        }
    }

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let attribute = dataSource.itemIdentifier(for: indexPath)
        else { return nil }

        switch attribute.id {
        case "Tags": return nil
        default:
            return UIContextMenuConfiguration(
                identifier: nil,
                previewProvider: nil,
                actionProvider: {
                    (_) in
                    UIMenu(
                        children: [
                            UIAction(
                                title: "Copy \(attribute.id)",
                                image: R.image.docOnClipboard(),
                                handler: {
                                    (_) in
                                    UIPasteboard.general.string = attribute.value
                                }
                            )
                        ]
                    )
                }
            )
        }
    }
}
