import UIKit
import WidgetKit
import Alamofire
import TinyConstraints
import Rswift

class TransactionsVC: TableViewController {
    let tableRefreshControl = RefreshControl(frame: .zero)
    let searchController = UISearchController(searchResultsController: nil)
    
    private typealias DataSource = UITableViewDiffableDataSource<Section, TransactionResource>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, TransactionResource>
    
    private var filterButton = UIBarButtonItem()
    private var filter: FilterCategory = .all {
        didSet {
            filterButton.menu = filterMenu()
            searchController.searchBar.placeholder = "Search \(preFilteredTransactions.count.description) \(preFilteredTransactions.count == 1 ? "Transaction" : "Transactions")"
            applySnapshot()
        }
    }
    private var showSettledOnly: Bool = false {
        didSet {
            filterButton.menu = filterMenu()
            searchController.searchBar.placeholder = "Search \(preFilteredTransactions.count.description) \(preFilteredTransactions.count == 1 ? "Transaction" : "Transactions")"
            applySnapshot()
        }
    }
    
    private var transactionsStatusCode: Int = 0
    private var transactions: [TransactionResource] = []
    private var transactionsPagination: Pagination = Pagination(prev: nil, next: nil)
    private var transactionsErrorResponse: [ErrorObject] = []
    private var transactionsError: String = ""
    
    private var categories: [CategoryResource] = []
    
    private var accounts: [AccountResource] = []
    
    private lazy var dataSource = makeDataSource()
    
    private enum Section: CaseIterable {
        case main
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureProperties()
        configureNavigation()
        configureFilterButton()
        configureSearch()
        configureRefreshControl()
        configureTableView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        applySnapshot()
        
        fetchTransactions()
        fetchAccounts()
        fetchCategories()
    }
}

extension TransactionsVC {
    private var preFilteredTransactions: [TransactionResource] {
        transactions.filter { transaction in
            (!showSettledOnly || transaction.attributes.isSettled)
                && (filter == .all || filter.rawValue == transaction.relationships.category.data?.id)
        }
    }
    
    private var filteredTransactions: [TransactionResource] {
        preFilteredTransactions.filter { transaction in
            searchController.searchBar.text!.isEmpty || transaction.attributes.description.localizedStandardContains(searchController.searchBar.text!)
        }
    }
    
    private var filteredTransactionList: Transaction {
        return Transaction(data: filteredTransactions, links: transactionsPagination)
    }
    
    private func filterMenu() -> UIMenu {
        let categoryItems = FilterCategory.allCases.map { category in
            UIAction(title: categoryNameTransformed(category), state: self.filter == category ? .on : .off) { _ in
                self.filter = category
            }
        }
        
        let categoriesMenu = UIMenu(title: "Category", image: R.image.arrowUpArrowDownCircle(), children: categoryItems)
        
        let settledOnlyFilter = UIAction(title: "Settled Only", image: R.image.checkmarkCircle(), state: self.showSettledOnly ? .on : .off) { _ in
            self.showSettledOnly.toggle()
        }
        
        return UIMenu(image: R.image.sliderHorizontal3(), options: .displayInline, children: [categoriesMenu, settledOnlyFilter])
    }
    
    private func categoryNameTransformed(_ category: FilterCategory) -> String {
        switch category {
            case .gamesAndSoftware: return "Apps, Games & Software"
            case .carInsuranceAndMaintenance: return "Car Insurance, Rego & Maintenance"
            case .tvAndMusic: return "TV, Music & Streaming"
            default: return category.rawValue.replacingOccurrences(of: "and", with: "&").replacingOccurrences(of: "-", with: " ").capitalized
        }
    }
    
    private func makeDataSource() -> DataSource {
        let dataSource = DataSource(
            tableView: tableView,
            cellProvider: {  tableView, indexPath, transaction in
                let cell = tableView.dequeueReusableCell(withIdentifier: TransactionTableViewCell.reuseIdentifier, for: indexPath) as! TransactionTableViewCell
                
                cell.transaction = transaction
                
                return cell
            }
        )
        dataSource.defaultRowAnimation = .fade
        return dataSource
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
    
    @objc private func switchDateStyle() {
        if appDefaults.string(forKey: "dateStyle") == "Absolute" || appDefaults.string(forKey: "dateStyle") == nil {
            appDefaults.setValue("Relative", forKey: "dateStyle")
        } else if appDefaults.string(forKey: "dateStyle") == "Relative" {
            appDefaults.setValue("Absolute", forKey: "dateStyle")
        }
        
        applySnapshot()
        
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    @objc private func refreshTransactions() {
        #if targetEnvironment(macCatalyst)
        let loadingView = ActivityIndicator(style: .medium)
        
        navigationItem.setRightBarButton(UIBarButtonItem(customView: loadingView), animated: true)
        #endif
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.fetchTransactions()
            self.fetchCategories()
            self.fetchAccounts()
        }
    }
    
    private func configureProperties() {
        title = "Transactions"
        definesPresentationContext = true
    }
    
    private func configureNavigation() {        
        navigationItem.title = "Loading"
        navigationItem.backBarButtonItem = UIBarButtonItem(image: R.image.dollarsignCircle(), style: .plain, target: self, action: nil)
        
        #if targetEnvironment(macCatalyst)
        navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshTransactions)), animated: true)
        #endif
        
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    private func configureFilterButton() {
        filterButton = UIBarButtonItem(image: R.image.sliderHorizontal3(), style: .plain, target: self, action: nil)
        
        filterButton.menu = filterMenu()
    }
    
    private func configureSearch() {
        searchController.delegate = self
        
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.hidesNavigationBarDuringPresentation = true
        
        searchController.searchBar.delegate = self
        
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.placeholder = "Search"
    }
    
    private func configureRefreshControl() {
        tableRefreshControl.addTarget(self, action: #selector(refreshTransactions), for: .valueChanged)
    }
    
    private func configureTableView() {
        tableView.dataSource = dataSource
        tableView.refreshControl = tableRefreshControl
        tableView.register(TransactionTableViewCell.self, forCellReuseIdentifier: TransactionTableViewCell.reuseIdentifier)
    }
    
    private func fetchTransactions() {
        let headers: HTTPHeaders = [acceptJsonHeader, authorisationHeader]
        
        AF.request(UpApi.Transactions().listTransactions, method: .get, parameters: pageSize100Param, headers: headers).responseJSON { response in
            self.transactionsStatusCode = response.response?.statusCode ?? 0
            
            switch response.result {
                case .success:
                    if let decodedResponse = try? JSONDecoder().decode(Transaction.self, from: response.data!) {
                        print("Transactions JSON decoding succeeded")
                        
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
                        
                        if self.navigationItem.title != "Transactions" {
                            self.navigationItem.title = "Transactions"
                        }
                        
                        if self.navigationItem.leftBarButtonItems == nil {
                            self.navigationItem.setLeftBarButtonItems([UIBarButtonItem(image: R.image.arrowUpArrowDown(), style: .plain, target: self, action: #selector(self.switchDateStyle)), self.filterButton], animated: true)
                        }
                        
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshTransactions)), animated: true)
                        #endif
                        
                        self.applySnapshot()
                        self.refreshControl?.endRefreshing()
                        
                        WidgetCenter.shared.reloadAllTimelines()
                    } else if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: response.data!) {
                        print("Transactions Error JSON decoding succeeded")
                        
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
                        if self.navigationItem.leftBarButtonItems != nil {
                            self.navigationItem.setLeftBarButtonItems(nil, animated: true)
                        }
                        
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshTransactions)), animated: true)
                        #endif
                        
                        self.applySnapshot()
                        self.refreshControl?.endRefreshing()
                        
                        WidgetCenter.shared.reloadAllTimelines()
                    } else {
                        print("Transactions JSON decoding failed")
                        
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
                        if self.navigationItem.leftBarButtonItems != nil {
                            self.navigationItem.setLeftBarButtonItems(nil, animated: true)
                        }
                        
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshTransactions)), animated: true)
                        #endif
                        
                        self.applySnapshot()
                        self.refreshControl?.endRefreshing()
                        
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                case .failure:
                    print(response.error?.localizedDescription ?? "Unknown error")
                    
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
                    if self.navigationItem.leftBarButtonItems != nil {
                        self.navigationItem.setLeftBarButtonItems(nil, animated: true)
                    }
                    
                    #if targetEnvironment(macCatalyst)
                    self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshTransactions)), animated: true)
                    #endif
                    
                    self.applySnapshot()
                    self.refreshControl?.endRefreshing()
                    
                    WidgetCenter.shared.reloadAllTimelines()
            }
            self.searchController.searchBar.placeholder = "Search \(self.preFilteredTransactions.count.description) \(self.preFilteredTransactions.count == 1 ? "Transaction" : "Transactions")"
        }
    }
    
    private func fetchCategories() {
        let headers: HTTPHeaders = [acceptJsonHeader, authorisationHeader]
        
        AF.request(UpApi.Categories().listCategories, method: .get, headers: headers).responseJSON { response in
            switch response.result {
                case .success:
                    if let decodedResponse = try? JSONDecoder().decode(Category.self, from: response.data!) {
                        print("Categories JSON decoding succeeded")
                        
                        self.categories = decodedResponse.data
                    } else {
                        print("Categories JSON decoding failed")
                    }
                case .failure:
                    print(response.error?.localizedDescription ?? "Unknown error")
            }
        }
    }
    
    private func fetchAccounts() {
        let headers: HTTPHeaders = [acceptJsonHeader, authorisationHeader]
        
        AF.request(UpApi.Accounts().listAccounts, method: .get, parameters: pageSize100Param, headers: headers).responseJSON { response in
            switch response.result {
                case .success:
                    if let decodedResponse = try? JSONDecoder().decode(Account.self, from: response.data!) {
                        print("Accounts JSON decoding succeeded")
                        
                        self.accounts = decodedResponse.data
                    } else {
                        print("Accounts JSON decoding failed")
                    }
                case .failure:
                    print(response.error?.localizedDescription ?? "Unknown error")
            }
        }
    }
}

extension TransactionsVC {
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        navigationController?.pushViewController({let vc = TransactionDetailVC(style: .grouped);vc.transaction = dataSource.itemIdentifier(for: indexPath);vc.categories = categories;vc.accounts = accounts;return vc}(), animated: true)
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let copyDescription = UIAction(title: "Copy Description", image: R.image.textAlignright()) { _ in
            UIPasteboard.general.string = self.dataSource.itemIdentifier(for: indexPath)!.attributes.description
        }
        let copyCreationDate = UIAction(title: "Copy Creation Date", image: R.image.calendarCircle()) { _ in
            UIPasteboard.general.string = self.dataSource.itemIdentifier(for: indexPath)!.attributes.creationDate
        }
        let copyAmount = UIAction(title: "Copy Amount", image: R.image.dollarsignCircle()) { _ in
            UIPasteboard.general.string = self.dataSource.itemIdentifier(for: indexPath)!.attributes.amount.valueShort
        }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(children: [copyDescription, copyCreationDate, copyAmount])
        }
    }
}

extension TransactionsVC: UISearchControllerDelegate, UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        applySnapshot(animate: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.text != "" {
            searchBar.text = ""
            applySnapshot(animate: true)
        }
    }
}
