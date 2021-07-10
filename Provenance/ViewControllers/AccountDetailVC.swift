import UIKit
import SwiftyBeaver
import Rswift

final class AccountDetailVC: UIViewController {
    // MARK: - Properties

    private var account: AccountResource {
        didSet {
            log.info("didSet account: \(account.attributes.displayName)")

            applySnapshot()
            tableView.refreshControl?.endRefreshing()
        }
    }
    
    private var transaction: TransactionResource? {
        didSet {
            log.info("didSet transaction: \(transaction?.attributes.description ?? "nil")")

            applySnapshot()
            tableView.refreshControl?.endRefreshing()
        }
    }
    
    private typealias DataSource = UITableViewDiffableDataSource<DetailSection, DetailAttribute>
    
    private typealias Snapshot = NSDiffableDataSourceSnapshot<DetailSection, DetailAttribute>

    private lazy var dataSource = makeDataSource()

    private let tableRefreshControl: UIRefreshControl = {
        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        return rc
    }()

    private let tableView = UITableView(frame: .zero, style: .grouped)

    private var sections: [DetailSection] = []

    // MARK: - Life Cycle

    init(account: AccountResource, transaction: TransactionResource? = nil) {
        self.account = account
        self.transaction = transaction
        super.init(nibName: nil, bundle: nil)
        log.debug("init(account: \(account.attributes.displayName), transaction: \(transaction?.attributes.description ?? "nil"))")
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
        configureTableView()
        applySnapshot(animate: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        log.debug("viewDidLayoutSubviews")
        tableView.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        log.debug("viewWillAppear(animated: \(animated.description))")
        fetchingTasks()
    }
}

// MARK: - Configuration

private extension AccountDetailVC {
    private func configureProperties() {
        log.verbose("configureProperties")

        title = "Account Details"

        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    private func configureNavigation() {
        log.verbose("configureNavigation")

        navigationItem.title = account.attributes.displayName
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeWorkflow))
    }
    
    private func configureTableView() {
        log.verbose("configureTableView")

        tableView.dataSource = dataSource
        tableView.delegate = self
        tableView.register(AttributeTableViewCell.self, forCellReuseIdentifier: AttributeTableViewCell.reuseIdentifier)
        tableView.refreshControl = tableRefreshControl
        tableView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        tableView.showsVerticalScrollIndicator = false
    }
}

// MARK: - Actions

private extension AccountDetailVC {
    @objc private func appMovedToForeground() {
        log.verbose("appMovedToForeground")

        fetchingTasks()
    }

    @objc private func refreshData() {
        log.verbose("refreshData")

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
            fetchingTasks()
        }
    }

    @objc private func closeWorkflow() {
        log.verbose("closeWorkflow")

        navigationController?.dismiss(animated: true)
    }

    private func fetchingTasks() {
        fetchAccount()
        fetchTransaction()
    }

    private func makeDataSource() -> DataSource {
        log.verbose("makeDataSource")

        let dataSource = DataSource(
            tableView: tableView,
            cellProvider: { tableView, indexPath, attribute in
            let cell = tableView.dequeueReusableCell(withIdentifier: AttributeTableViewCell.reuseIdentifier, for: indexPath) as! AttributeTableViewCell

            cell.leftLabel.text = attribute.id
            cell.rightLabel.font = attribute.id == "Account ID" ? R.font.sfMonoRegular(size: UIFont.labelFontSize)! : R.font.circularStdBook(size: UIFont.labelFontSize)!
            cell.rightLabel.text = attribute.value

            return cell
        }
        )
        dataSource.defaultRowAnimation = .automatic
        return dataSource
    }

    private func applySnapshot(animate: Bool = true) {
        log.verbose("applySnapshot")

        sections = [
            DetailSection(id: 1, attributes: [
                DetailAttribute(
                    id: "Account Balance",
                    value: account.attributes.balance.valueLong
                ),
                DetailAttribute(
                    id: "Latest Transaction",
                    value: transaction?.attributes.description ?? ""
                ),
                DetailAttribute(
                    id: "Account ID",
                    value: account.id
                ),
                DetailAttribute(
                    id: "Creation Date",
                    value: account.attributes.creationDate
                )
            ])
        ]

        var snapshot = Snapshot()

        snapshot.appendSections(sections)
        sections.forEach { snapshot.appendItems($0.attributes.filter { !$0.value.isEmpty }, toSection: $0) }

        dataSource.apply(snapshot, animatingDifferences: animate)
    }

    private func fetchAccount() {
        log.verbose("fetchAccount")

        if #available(iOS 15.0, *) {
            async {
                do {
                    let account = try await Up.retrieveAccount(for: account)

                    self.account = account
                } catch {
                    print(errorString(for: error as! NetworkError))
                }
            }
        } else {
            Up.retrieveAccount(for: account) { [self] result in
                DispatchQueue.main.async {
                    switch result {
                        case .success(let account):
                            self.account = account
                        case .failure(let error):
                            print(errorString(for: error))
                    }
                }
            }
        }
    }

    private func fetchTransaction() {
        log.verbose("fetchTransaction")

        if #available(iOS 15.0, *) {
            async {
                do {
                    let transactions = try await Up.retrieveLatestTransaction(for: account)

                    transaction = transactions.first
                } catch {
                    print(errorString(for: error as! NetworkError))
                }
            }
        } else {
            Up.retrieveLatestTransaction(for: account) { [self] result in
                DispatchQueue.main.async {
                    switch result {
                        case .success(let transactions):
                            transaction = transactions.first
                        case .failure(let error):
                            print(errorString(for: error))
                    }
                }
            }
        }
    }
}

// MARK: - UITableViewDelegate

extension AccountDetailVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
}
