import UIKit
import TinyConstraints
import Rswift
import WidgetKit

class TransactionsVC: ViewController {
    let fetchingView = ActivityIndicator(style: .medium)
    let tableViewController = TableViewController(style: .insetGrouped)
    let refreshControl = RefreshControl(frame: .zero)
    let searchController = UISearchController(searchResultsController: nil)
    
    private lazy var dataSource = transactionsDataSource()
    
    private var filterButton: UIBarButtonItem!
    private var transactionList = Transaction(data: [], links: .init(prev: nil, next: nil))
    private var transactions: [TransactionResource] = []
    private var transactionsErrorResponse: [ErrorObject] = []
    private var transactionsError: String = ""
    private var prevFilteredTransactions: [TransactionResource] = []
    private var showSettledOnly: Bool = false
    private var categories: [CategoryResource] = []
    private var accounts: [AccountResource] = []
    private var filter: FilterCategory = .all
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
        return Transaction(data: filteredTransactions, links: transactionList.links)
    }
    
    private enum FilterCategory: String, CaseIterable, Identifiable {
        case all = "All"
        case gamesAndSoftware = "games-and-software"
        case carInsuranceAndMaintenance = "car-insurance-and-maintenance"
        case family = "family"
        case groceries = "groceries"
        case booze = "booze"
        case clothingAndAccessories = "clothing-and-accessories"
        case cycling = "cycling"
        case homewareAndAppliances = "homeware-and-appliances"
        case educationAndStudentLoans = "education-and-student-loans"
        case eventsAndGigs = "events-and-gigs"
        case fuel = "fuel"
        case internet = "internet"
        case fitnessAndWellbeing = "fitness-and-wellbeing"
        case hobbies = "hobbies"
        case homeMaintenanceAndImprovements = "home-maintenance-and-improvements"
        case parking = "parking"
        case giftsAndCharity = "gifts-and-charity"
        case holidaysAndTravel = "holidays-and-travel"
        case pets = "pets"
        case publicTransport = "public-transport"
        case hairAndBeauty = "hair-and-beauty"
        case lotteryAndGambling = "lottery-and-gambling"
        case homeInsuranceAndRates = "home-insurance-and-rates"
        case carRepayments = "car-repayments"
        case healthAndMedical = "health-and-medical"
        case pubsAndBars = "pubs-and-bars"
        case rentAndMortgage = "rent-and-mortgage"
        case taxisAndShareCars = "taxis-and-share-cars"
        case investments = "investments"
        case restaurantsAndCafes = "restaurants-and-cafes"
        case tollRoads = "toll-roads"
        case utilities = "utilities"
        case lifeAdmin = "life-admin"
        case takeaway = "takeaway"
        case mobilePhone = "mobile-phone"
        case tobaccoAndVaping = "tobacco-and-vaping"
        case newsMagazinesAndBooks = "news-magazines-and-books"
        case tvAndMusic = "tv-and-music"
        case adult = "adult"
        case technology = "technology"
        
        var id: FilterCategory {
            return self
        }
    }
    private enum Section: CaseIterable {
        case transactions
    }
    
    private func filterMenu() -> UIMenu {
        let categoryItems = FilterCategory.allCases.map { category in
            UIAction(title: categoryNameTransformed(category), state: self.filter == category ? .on : .off) { _ in
                self.filter = category
                self.filterButton.menu = self.filterMenu()
                self.searchController.searchBar.placeholder = "Search \(self.preFilteredTransactions.count.description) \(self.preFilteredTransactions.count == 1 ? "Transaction" : "Transactions")"
                if self.filter != .all {
                    if self.showSettledOnly {
                        self.navigationItem.prompt = "\(self.categoryNameTransformed(self.filter)) - Settled"
                    } else {
                        self.navigationItem.prompt = self.categoryNameTransformed(self.filter)
                    }
                } else {
                    if self.showSettledOnly {
                        self.navigationItem.prompt = "Settled"
                    } else {
                        self.navigationItem.prompt = nil
                    }
                }
                self.update(with: self.filteredTransactionList)
            }
        }
        
        let categoriesMenu = UIMenu(title: "Category", image: R.image.arrowUpArrowDownCircle(), children: categoryItems)
        
        let settledOnlyFilter = UIAction(title: "Settled Only", image: R.image.checkmarkCircle(), state: self.showSettledOnly ? .on : .off) { _ in
            self.showSettledOnly.toggle()
            self.filterButton.menu = self.filterMenu()
            self.searchController.searchBar.placeholder = "Search \(self.preFilteredTransactions.count.description) \(self.preFilteredTransactions.count == 1 ? "Transaction" : "Transactions")"
            if self.filter != .all {
                if self.showSettledOnly {
                    self.navigationItem.prompt = "\(self.categoryNameTransformed(self.filter)) - Settled"
                } else {
                    self.navigationItem.prompt = self.categoryNameTransformed(self.filter)
                }
            } else {
                if self.showSettledOnly {
                    self.navigationItem.prompt = "Settled"
                } else {
                    self.navigationItem.prompt = nil
                }
            }
            self.update(with: self.filteredTransactionList)
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
    private func transactionsDataSource() -> UITableViewDiffableDataSource<Section, TransactionResource> {
        return UITableViewDiffableDataSource(
            tableView: tableViewController.tableView,
            cellProvider: {  tableView, indexPath, transaction in
                let cell = tableView.dequeueReusableCell(
                    withIdentifier: R.reuseIdentifier.transactionCell,
                    for: indexPath
                )!
                self.tableViewController.tableView.separatorStyle = .singleLine
                
                cell.selectedBackgroundView = bgCellView
                cell.leftLabel.text = transaction.attributes.description
                cell.leftSubtitle.text = transaction.attributes.creationDate
                
                if transaction.attributes.amount.valueInBaseUnits.signum() == -1 {
                    cell.rightLabel.textColor = .black
                } else {
                    cell.rightLabel.textColor = R.color.greenColour()
                }
                
                cell.rightLabel.text = transaction.attributes.amount.valueShort
                
                return cell
            }
        )
    }
    private func update(with list: Transaction, animate: Bool = false) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, TransactionResource>()
        snapshot.appendSections(Section.allCases)
        
        snapshot.appendItems(list.data, toSection: .transactions)
        
        if snapshot.itemIdentifiers.isEmpty {
            tableViewController.tableView.dataSource = self
        } else {
            tableViewController.tableView.dataSource = dataSource
        }
        dataSource.apply(snapshot, animatingDifferences: animate)
    }
    
    @objc private func switchDateStyle() {
        if appDefaults.string(forKey: "dateStyle") == "Absolute" || appDefaults.string(forKey: "dateStyle") == nil {
            appDefaults.setValue("Relative", forKey: "dateStyle")
        } else if appDefaults.string(forKey: "dateStyle") == "Relative" {
            appDefaults.setValue("Absolute", forKey: "dateStyle")
        }
        self.update(with: self.filteredTransactionList)
        WidgetCenter.shared.reloadTimelines(ofKind: "LatestTransaction")
    }
    @objc private func refreshTransactions() {
        #if targetEnvironment(macCatalyst)
        let loadingView = ActivityIndicator(style: .medium)
        navigationItem.setRightBarButton(UIBarButtonItem(customView: loadingView), animated: true)
        #endif
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.listTransactions()
            self.listCategories()
            self.listAccounts()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setProperties()
        setupNavigation()
        setupFilterButton()
        setupSearch()
        setupRefreshControl()
        setupFetchingView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        update(with: filteredTransactionList)
        
        listTransactions()
        listAccounts()
        listCategories()
    }
    
    private func setProperties() {
        title = "Transactions"
    }
    
    private func setupNavigation() {
        navigationItem.title = "Loading"
        navigationController?.navigationBar.prefersLargeTitles = true
        #if targetEnvironment(macCatalyst)
        navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshTransactions)), animated: true)
        #endif
    }
    
    private func setupFilterButton() {
        filterButton = UIBarButtonItem(image: R.image.sliderHorizontal3(), style: .plain, target: self, action: nil)
        filterButton.menu = filterMenu()
    }
    
    private func setupSearch() {
        searchController.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.placeholder = "Search"
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.searchBar.delegate = self
        
        definesPresentationContext = true
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    private func setupRefreshControl() {
        refreshControl.addTarget(self, action: #selector(refreshTransactions), for: .valueChanged)
        tableViewController.refreshControl = refreshControl
    }
    
    private func setupFetchingView() {
        view.addSubview(fetchingView)
        
        fetchingView.edgesToSuperview()
    }
    
    private func setupTableView() {
        super.addChild(tableViewController)
        view.addSubview(tableViewController.tableView)
        
        tableViewController.tableView.edgesToSuperview()
        
        tableViewController.tableView.delegate = self
        
        tableViewController.tableView.register(R.nib.transactionCell)
        tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "noTransactionsCell")
        tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "errorStringCell")
        tableViewController.tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: "errorObjectCell")
    }
    
    private func listTransactions() {
        var url = URL(string: "https://api.up.com.au/api/v1/transactions")!
        let urlParams = ["page[size]":"100"]
        url = url.appendingQueryParameters(urlParams)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(appDefaults.string(forKey: "apiKey") ?? "")", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                if let decodedResponse = try? JSONDecoder().decode(Transaction.self, from: data!) {
                    DispatchQueue.main.async {
                        print("Transactions JSON decoding succeeded")
                        self.transactionList = decodedResponse
                        self.transactions = decodedResponse.data
                        self.transactionsError = ""
                        self.transactionsErrorResponse = []
                        self.navigationItem.title = "Transactions"
                        if self.navigationItem.leftBarButtonItems == nil {
                            self.navigationItem.setLeftBarButtonItems([UIBarButtonItem(image: R.image.arrowUpArrowDown(), style: .plain, target: self, action: #selector(self.switchDateStyle)), self.filterButton], animated: true)
                        }
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshTransactions)), animated: true)
                        #endif
                        self.fetchingView.removeFromSuperview()
                        self.setupTableView()
                        self.update(with: self.filteredTransactionList)
                        self.refreshControl.endRefreshing()
                        WidgetCenter.shared.reloadTimelines(ofKind: "LatestTransaction")
                    }
                } else if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data!) {
                    DispatchQueue.main.async {
                        print("Transactions Error JSON decoding succeeded")
                        self.transactionsErrorResponse = decodedResponse.errors
                        self.transactionsError = ""
                        self.transactions = []
                        self.transactionList = .init(data: [], links: .init(prev: nil, next: nil))
                        self.navigationItem.title = "Errors"
                        self.navigationItem.setLeftBarButtonItems(nil, animated: true)
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshTransactions)), animated: true)
                        #endif
                        self.fetchingView.removeFromSuperview()
                        self.setupTableView()
                        self.update(with: self.filteredTransactionList)
                        self.refreshControl.endRefreshing()
                        WidgetCenter.shared.reloadTimelines(ofKind: "LatestTransaction")
                    }
                } else {
                    DispatchQueue.main.async {
                        print("Transactions JSON decoding failed")
                        self.transactionsError = "JSON Decoding Failed!"
                        self.transactionsErrorResponse = []
                        self.transactions = []
                        self.transactionList = .init(data: [], links: .init(prev: nil, next: nil))
                        self.navigationItem.title = "Error"
                        self.navigationItem.setLeftBarButtonItems(nil, animated: true)
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshTransactions)), animated: true)
                        #endif
                        self.fetchingView.removeFromSuperview()
                        self.setupTableView()
                        self.update(with: self.filteredTransactionList)
                        self.refreshControl.endRefreshing()
                        WidgetCenter.shared.reloadTimelines(ofKind: "LatestTransaction")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    print(error?.localizedDescription ?? "Unknown error")
                    self.transactionsError = error?.localizedDescription ?? "Unknown Error!"
                    self.transactionsErrorResponse = []
                    self.transactions = []
                    self.transactionList = .init(data: [], links: .init(prev: nil, next: nil))
                    self.navigationItem.title = "Error"
                    self.navigationItem.setLeftBarButtonItems(nil, animated: true)
                    #if targetEnvironment(macCatalyst)
                    self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshTransactions)), animated: true)
                    #endif
                    self.fetchingView.removeFromSuperview()
                    self.setupTableView()
                    self.update(with: self.filteredTransactionList)
                    self.refreshControl.endRefreshing()
                    WidgetCenter.shared.reloadTimelines(ofKind: "LatestTransaction")
                }
            }
            DispatchQueue.main.async {
                self.searchController.searchBar.placeholder = "Search \(self.preFilteredTransactions.count.description) \(self.preFilteredTransactions.count == 1 ? "Transaction" : "Transactions")"
            }
        }
        .resume()
    }
    
    private func listCategories() {
        let url = URL(string: "https://api.up.com.au/api/v1/categories")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(appDefaults.string(forKey: "apiKey") ?? "")", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                if let decodedResponse = try? JSONDecoder().decode(Category.self, from: data!) {
                    DispatchQueue.main.async {
                        print("Categories JSON decoding succeeded")
                        self.categories = decodedResponse.data
                    }
                } else {
                    print("Categories JSON decoding failed")
                }
            } else {
                print(error?.localizedDescription ?? "Unknown error")
            }
        }
        .resume()
    }
    
    private func listAccounts() {
        let url = URL(string: "https://api.up.com.au/api/v1/accounts")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(appDefaults.string(forKey: "apiKey") ?? "")", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                if let decodedResponse = try? JSONDecoder().decode(Account.self, from: data!) {
                    DispatchQueue.main.async {
                        print("Accounts JSON decoding succeeded")
                        self.accounts = decodedResponse.data
                    }
                } else {
                    print("Accounts JSON decoding failed")
                }
            } else {
                print(error?.localizedDescription ?? "Unknown error")
            }
        }
        .resume()
    }
}

extension TransactionsVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.filteredTransactions.isEmpty && self.transactionsError.isEmpty && self.transactionsErrorResponse.isEmpty {
            return 1
        } else {
            if !self.transactionsError.isEmpty {
                return 1
            } else if !self.transactionsErrorResponse.isEmpty {
                return transactionsErrorResponse.count
            } else {
                return filteredTransactions.count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let noTransactionsCell = tableView.dequeueReusableCell(withIdentifier: "noTransactionsCell", for: indexPath)
        
        let errorStringCell = tableView.dequeueReusableCell(withIdentifier: "errorStringCell", for: indexPath)
        
        let errorObjectCell = tableView.dequeueReusableCell(withIdentifier: "errorObjectCell", for: indexPath) as! SubtitleTableViewCell
        
        if self.filteredTransactions.isEmpty && self.transactionsError.isEmpty && self.transactionsErrorResponse.isEmpty {
            tableView.separatorStyle = .none
            
            noTransactionsCell.selectionStyle = .none
            noTransactionsCell.textLabel?.font = circularStdBook
            noTransactionsCell.textLabel?.textAlignment = .center
            noTransactionsCell.textLabel?.textColor = .white
            noTransactionsCell.textLabel?.text = "No Transactions"
            noTransactionsCell.backgroundColor = .clear
            
            return noTransactionsCell
        } else {
            tableView.separatorStyle = .singleLine
            
            if !self.transactionsError.isEmpty {
                errorStringCell.selectionStyle = .none
                errorStringCell.textLabel?.numberOfLines = 0
                errorStringCell.textLabel?.font = circularStdBook
                errorStringCell.textLabel?.text = transactionsError
                
                return errorStringCell
            } else {
                let error = transactionsErrorResponse[indexPath.row]
                
                errorObjectCell.selectionStyle = .none
                errorObjectCell.textLabel?.textColor = .red
                errorObjectCell.textLabel?.font = circularStdBold
                errorObjectCell.textLabel?.text = error.title
                errorObjectCell.detailTextLabel?.numberOfLines = 0
                errorObjectCell.detailTextLabel?.font = R.font.circularStdBook(size: UIFont.smallSystemFontSize)
                errorObjectCell.detailTextLabel?.text = error.detail
                
                return errorObjectCell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.transactionsErrorResponse.isEmpty && self.transactionsError.isEmpty && !self.filteredTransactions.isEmpty {
            let vc = TransactionDetailVC(style: .insetGrouped)
            
            vc.transaction = filteredTransactions[indexPath.row]
            vc.categories = self.categories
            vc.accounts = self.accounts
            
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        if self.transactionsErrorResponse.isEmpty && self.transactionsError.isEmpty && !self.filteredTransactions.isEmpty {
            let copy = UIAction(title: "Copy", image: R.image.docOnClipboard()) { _ in
                UIPasteboard.general.string = self.filteredTransactions[indexPath.row].attributes.description
            }
            
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                UIMenu(children: [copy])
            }
        } else {
            return nil
        }
    }
}

extension TransactionsVC: UISearchControllerDelegate, UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if self.filteredTransactions != self.prevFilteredTransactions {
            self.update(with: self.filteredTransactionList)
        }
        self.prevFilteredTransactions = self.filteredTransactions
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.text != "" {
            searchBar.text = ""
            self.prevFilteredTransactions = self.filteredTransactions
            self.update(with: self.filteredTransactionList)
        }
    }
}
