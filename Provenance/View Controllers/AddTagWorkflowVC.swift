import UIKit
import Alamofire
import TinyConstraints
import Rswift

class AddTagWorkflowVC: TableViewController {
    let tableRefreshControl = RefreshControl(frame: .zero)
    let searchController = UISearchController(searchResultsController: nil)
    
    private typealias DataSource = UITableViewDiffableDataSource<Section, TransactionResource>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, TransactionResource>
    
    private var transactionsStatusCode: Int = 0
    private var transactionsPagination: Pagination = Pagination(prev: nil, next: nil)
    private var transactions: [TransactionResource] = []
    private var transactionsErrorResponse: [ErrorObject] = []
    private var transactionsError: String = ""
    private var filteredTransactions: [TransactionResource] {
        transactions.filter { transaction in
            searchController.searchBar.text!.isEmpty || transaction.attributes.description.localizedStandardContains(searchController.searchBar.text!)
        }
    }
    
    private var filteredTransactionList: Transaction {
        return Transaction(data: filteredTransactions, links: transactionsPagination)
    }
    
    private lazy var dataSource = makeDataSource()
    
    private enum Section: CaseIterable {
        case main
    }
    
    private func makeDataSource() -> DataSource {
        return DataSource(
            tableView: tableView,
            cellProvider: {  tableView, indexPath, transaction in
                let cell = tableView.dequeueReusableCell(withIdentifier: TransactionTableViewCell.reuseIdentifier, for: indexPath) as! TransactionTableViewCell
                
                cell.transaction = transaction
                
                return cell
            }
        )
    }
    
    private func applySnapshot(animate: Bool = false) {
        var snapshot = Snapshot()
        
        snapshot.appendSections(Section.allCases)
        
        snapshot.appendItems(filteredTransactionList.data, toSection: .main)
        
        if snapshot.itemIdentifiers.isEmpty && transactionsError.isEmpty && transactionsErrorResponse.isEmpty  {
            if transactions.isEmpty && transactionsStatusCode == 0 {
                tableView.backgroundView = {
                    let view = UIView()
                    
                    let loadingIndicator = ActivityIndicator(style: .medium)
                    view.addSubview(loadingIndicator)
                    
                    loadingIndicator.center(in: view)
                    
                    loadingIndicator.startAnimating()
                    
                    return view
                }()
            } else {
                tableView.backgroundView = {
                    let view = UIView()
                    
                    let label = UILabel()
                    view.addSubview(label)
                    
                    label.center(in: view)
                    
                    label.textAlignment = .center
                    label.textColor = .label
                    label.font = R.font.circularStdBook(size: UIFont.labelFontSize)
                    label.numberOfLines = 0
                    label.text = "No Transactions"
                    
                    return view
                }()
            }
        } else {
            if !transactionsError.isEmpty {
                tableView.backgroundView = {
                    let view = UIView()
                    
                    let label = UILabel()
                    view.addSubview(label)
                    
                    label.edges(to: view, excluding: [.top, .bottom, .leading, .trailing], insets: .horizontal(16))
                    label.center(in: view)
                    
                    label.textAlignment = .center
                    label.textColor = .label
                    label.font = R.font.circularStdBook(size: UIFont.labelFontSize)
                    label.numberOfLines = 0
                    label.text = transactionsError
                    
                    return view
                }()
            } else if !transactionsErrorResponse.isEmpty {
                tableView.backgroundView = {
                    let view = UIView()
                    
                    let titleLabel = UILabel()
                    let detailLabel = UILabel()
                    let verticalStack = UIStackView()
                    
                    view.addSubview(verticalStack)
                    
                    titleLabel.translatesAutoresizingMaskIntoConstraints = false
                    titleLabel.textAlignment = .center
                    titleLabel.textColor = .systemRed
                    titleLabel.font = R.font.circularStdBold(size: UIFont.labelFontSize)
                    titleLabel.numberOfLines = 0
                    titleLabel.text = transactionsErrorResponse.first?.title
                    
                    detailLabel.translatesAutoresizingMaskIntoConstraints = false
                    detailLabel.textAlignment = .center
                    detailLabel.textColor = .label
                    detailLabel.font = R.font.circularStdBook(size: UIFont.labelFontSize)
                    detailLabel.numberOfLines = 0
                    detailLabel.text = transactionsErrorResponse.first?.detail
                    
                    verticalStack.addArrangedSubview(titleLabel)
                    verticalStack.addArrangedSubview(detailLabel)
                    
                    verticalStack.edges(to: view, excluding: [.top, .bottom, .leading, .trailing], insets: .horizontal(16))
                    verticalStack.center(in: view)
                    
                    verticalStack.axis = .vertical
                    verticalStack.alignment = .center
                    verticalStack.distribution = .fill
                    
                    return view
                }()
            } else {
                tableView.backgroundView = nil
            }
        }
        
        dataSource.apply(snapshot, animatingDifferences: animate)
    }

    @objc private func appMovedToForeground() {
        applySnapshot()
    }
    
    @objc private func refreshTransactions() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.fetchTransactions()
        }
    }
    @objc private func closeWorkflow() {
        performSegue(withIdentifier: R.segue.addTagWorkflowVC.closeWorkflow, sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setProperties()
        setupNavigation()
        setupSearch()
        setupRefreshControl()
        setupTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        applySnapshot()
        
        fetchTransactions()
    }
    
    private func setProperties() {
        title = "Transactions"
        definesPresentationContext = true
        NotificationCenter.default.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    private func setupNavigation() {
        navigationItem.title = "Loading"
        navigationItem.backButtonDisplayMode = .minimal
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeWorkflow))
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    private func setupSearch() {
        searchController.delegate = self
        
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = true
        
        searchController.searchBar.delegate = self
        
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.placeholder = "Search"
    }
    
    private func setupRefreshControl() {
        tableRefreshControl.addTarget(self, action: #selector(refreshTransactions), for: .valueChanged)
    }
    
    private func setupTableView() {
        tableView.refreshControl = tableRefreshControl
        tableView.dataSource = dataSource
        tableView.register(TransactionTableViewCell.self, forCellReuseIdentifier: TransactionTableViewCell.reuseIdentifier)
    }
    
    private func fetchTransactions() {
        let headers: HTTPHeaders = [acceptJsonHeader, authorisationHeader]
        
        AF.request(UpApi.Transactions().listTransactions, method: .get, parameters: pageSize100Param, headers: headers).responseJSON { response in
            self.transactionsStatusCode = response.response?.statusCode ?? 0
            
            switch response.result {
                case .success:
                    if let decodedResponse = try? JSONDecoder().decode(Transaction.self, from: response.data!) {
                        self.transactions = decodedResponse.data
                        self.transactionsPagination = decodedResponse.links
                        self.transactionsError = ""
                        self.transactionsErrorResponse = []
                        
                        if !decodedResponse.data.isEmpty {
                            if self.navigationItem.searchController == nil {
                                self.navigationItem.searchController = self.searchController
                            }
                        } else {
                            if self.navigationItem.searchController != nil {
                                self.navigationItem.searchController = nil
                            }
                        }
                        
                        if self.navigationItem.title != "Select Transaction" {
                            self.navigationItem.title = "Select Transaction"
                        }
                        
                        self.applySnapshot()
                        self.refreshControl?.endRefreshing()
                    } else if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: response.data!) {
                        self.transactionsErrorResponse = decodedResponse.errors
                        self.transactionsError = ""
                        self.transactions = []
                        self.transactionsPagination = Pagination(prev: nil, next: nil)
                        
                        if self.navigationItem.searchController != nil {
                            self.navigationItem.searchController = nil
                        }
                        
                        if self.navigationItem.title != "Errors" {
                            self.navigationItem.title = "Errors"
                        }
                        
                        self.applySnapshot()
                        self.refreshControl?.endRefreshing()
                    } else {
                        self.transactionsError = "JSON Decoding Failed!"
                        self.transactionsErrorResponse = []
                        self.transactions = []
                        self.transactionsPagination = Pagination(prev: nil, next: nil)
                        
                        if self.navigationItem.searchController != nil {
                            self.navigationItem.searchController = nil
                        }
                        
                        if self.navigationItem.title != "Error" {
                            self.navigationItem.title = "Error"
                        }
                        
                        self.applySnapshot()
                        self.refreshControl?.endRefreshing()
                    }
                case .failure:
                    self.transactionsError = response.error?.localizedDescription ?? "Unknown Error!"
                    self.transactionsErrorResponse = []
                    self.transactions = []
                    self.transactionsPagination = Pagination(prev: nil, next: nil)
                    
                    if self.navigationItem.searchController != nil {
                        self.navigationItem.searchController = nil
                    }
                    
                    if self.navigationItem.title != "Error" {
                        self.navigationItem.title = "Error"
                    }
                    
                    self.applySnapshot()
                    self.refreshControl?.endRefreshing()
            }
            self.searchController.searchBar.placeholder = "Search \(self.transactions.count.description) \(self.transactions.count == 1 ? "Transaction" : "Transactions")"
        }
    }
}

extension AddTagWorkflowVC {
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        navigationController?.pushViewController({let vc = AddTagWorkflowTwoVC(style: .grouped);vc.transaction = dataSource.itemIdentifier(for: indexPath);return vc}(), animated: true)
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let transaction = self.dataSource.itemIdentifier(for: indexPath)!
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(children: [
                UIAction(title: "Copy Description", image: R.image.textAlignright()) { _ in
                    UIPasteboard.general.string = transaction.attributes.description
                },
                UIAction(title: "Copy Creation Date", image: R.image.calendarCircle()) { _ in
                    UIPasteboard.general.string = transaction.attributes.creationDate
                },
                UIAction(title: "Copy Amount", image: R.image.dollarsignCircle()) { _ in
                    UIPasteboard.general.string = transaction.attributes.amount.valueShort
                }
            ])
        }
    }
}

extension AddTagWorkflowVC: UISearchControllerDelegate, UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        applySnapshot()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.text != "" {
            searchBar.text = ""
            applySnapshot()
        }
    }
}
