import UIKit
import Rswift

final class AccountDetailVC: UIViewController {
    // MARK: - Properties

    private var account: AccountResource {
        didSet {
            applySnapshot()
            tableView.refreshControl?.endRefreshing()
        }
    }
    private var transaction: TransactionResource? {
        didSet {
            applySnapshot()
            tableView.refreshControl?.endRefreshing()
        }
    }
    
    private typealias DataSource = UITableViewDiffableDataSource<Section, DetailAttribute>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, DetailAttribute>

    private lazy var dataSource = makeDataSource()

    private let tableRefreshControl = RefreshControl(frame: .zero)
    private let tableView = UITableView(frame: .zero, style: .grouped)

    private var dateStyleObserver: NSKeyValueObservation?
    private var sections: [Section]!

    // MARK: - Life Cycle

    init(account: AccountResource, transaction: TransactionResource? = nil) {
        self.account = account
        self.transaction = transaction

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(tableView)

        configureProperties()
        configureNavigation()
        configureRefreshControl()
        configureTableView()        
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        tableView.frame = view.bounds
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        fetchAccount()
        fetchTransaction()
    }
}

// MARK: - Configuration

private extension AccountDetailVC {
    private func configureProperties() {
        title = "Account Details"

        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)

        dateStyleObserver = appDefaults.observe(\.dateStyle, options: .new) { [self] object, change in
            DispatchQueue.main.async {
                applySnapshot()
            }
        }
    }
    
    private func configureNavigation() {
        navigationItem.title = account.attributes.displayName
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeWorkflow))
    }

    private func configureRefreshControl() {
        tableRefreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    }
    
    private func configureTableView() {
        tableView.dataSource = dataSource
        tableView.delegate = self
        tableView.register(AttributeTableViewCell.self, forCellReuseIdentifier: AttributeTableViewCell.reuseIdentifier)
        tableView.refreshControl = tableRefreshControl
        tableView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
}

// MARK: - Actions

private extension AccountDetailVC {
    @objc private func appMovedToForeground() {
        fetchAccount()
        fetchTransaction()
    }

    @objc private func refreshData() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [self] in
            fetchAccount()
            fetchTransaction()
        }
    }

    @objc private func closeWorkflow() {
        navigationController?.dismiss(animated: true)
    }

    private func makeDataSource() -> DataSource {
        DataSource(
            tableView: tableView,
            cellProvider: { tableView, indexPath, attribute in
                let cell = tableView.dequeueReusableCell(withIdentifier: AttributeTableViewCell.reuseIdentifier, for: indexPath) as! AttributeTableViewCell

                cell.leftLabel.text = attribute.key
                cell.rightLabel.font = attribute.key == "Account ID" ? R.font.sfMonoRegular(size: UIFont.labelFontSize)! : R.font.circularStdBook(size: UIFont.labelFontSize)!
                cell.rightLabel.text = attribute.value

                return cell
            }
        )
    }

    private func applySnapshot() {
        sections = [
            Section(title: "Section 1", detailAttributes: [
                DetailAttribute(
                    key: "Account Balance",
                    value: account.attributes.balance.valueLong
                ),
                DetailAttribute(
                    key: "Latest Transaction",
                    value: transaction?.attributes.description ?? ""
                ),
                DetailAttribute(
                    key: "Account ID",
                    value: account.id
                ),
                DetailAttribute(
                    key: "Creation Date",
                    value: account.attributes.creationDate
                )
            ])
        ]

        var snapshot = Snapshot()

        snapshot.appendSections(sections)
        sections.forEach { section in
            snapshot.appendItems(section.detailAttributes.filter { attribute in
                !attribute.value.isEmpty
            }, toSection: section)
        }

        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private func fetchAccount() {
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
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        guard let attribute = dataSource.itemIdentifier(for: indexPath) else {
            return nil
        }

        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(children: [
                UIAction(title: "Copy \(attribute.key)", image: R.image.docOnClipboard()) { _ in
                    UIPasteboard.general.string = attribute.value
                }
            ])
        }
    }
}
