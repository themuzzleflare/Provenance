import UIKit

class TransactionsVC: UIViewController, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    let fetchingView: UIActivityIndicatorView = UIActivityIndicatorView(style: .medium)
    let tableViewController: UITableViewController = UITableViewController(style: .grouped)
    
    let circularStdBook = UIFont(name: "CircularStd-Book", size: UIFont.labelFontSize)!
    let circularStdBold = UIFont(name: "CircularStd-Bold", size: UIFont.labelFontSize)!
    
    private var filterButton: UIBarButtonItem!
    
    lazy var refreshControl: UIRefreshControl = UIRefreshControl()
    lazy var searchController: UISearchController = UISearchController(searchResultsController: nil)
    
    lazy var transactions: [TransactionResource] = []
    lazy var transactionsErrorResponse: [ErrorObject] = []
    lazy var transactionsError: String = ""
    
    var preFilteredTransactions: [TransactionResource] {
        transactions.filter { transaction in
            (!showSettledOnly || transaction.attributes.isSettled)
                && (filter == .all || filter.rawValue == transaction.relationships.category.data?.id)
        }
    }
    
    var filteredTransactions: [TransactionResource] {
        preFilteredTransactions.filter { transaction in
            searchController.searchBar.text!.isEmpty || transaction.attributes.description.localizedStandardContains(searchController.searchBar.text!)
        }
    }
    
    lazy var categories: [CategoryResource] = []
    
    lazy var accounts: [AccountResource] = []
    
    private var filter: FilterCategory = .all
    
    enum FilterCategory: String, CaseIterable, Identifiable {
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
    
    func categoryNameTransformed(_ category: FilterCategory) -> String {
        switch category {
            case .gamesAndSoftware: return "Apps, Games & Software"
            case .carInsuranceAndMaintenance: return "Car Insurance, Rego & Maintenance"
            case .tvAndMusic: return "TV, Music & Streaming"
            default: return category.rawValue.replacingOccurrences(of: "and", with: "&").replacingOccurrences(of: "-", with: " ").capitalized
        }
    }
    
    private var showSettledOnly: Bool = false
    
    func updateSearchResults(for searchController: UISearchController) {
        tableViewController.tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        super.addChild(tableViewController)
        
        view.backgroundColor = .systemBackground
        
        searchController.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.placeholder = "Search"
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.searchBar.delegate = self
        searchController.searchResultsUpdater = self
        
        definesPresentationContext = true
        
        title = "Transactions"
        navigationItem.title = "Loading"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        #if targetEnvironment(macCatalyst)
        navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshTransactions)), animated: true)
        #endif
        
        navigationController?.navigationBar.prefersLargeTitles = true
        
        tableViewController.clearsSelectionOnViewWillAppear = true
        tableViewController.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshTransactions), for: .valueChanged)
        
        filterButton = UIBarButtonItem(image: UIImage(systemName: "slider.horizontal.3"), style: .plain, target: self, action: nil)
        filterButton.menu = filterMenu()
        
        setupFetchingView()
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
                self.tableViewController.tableView.reloadData()
            }
        }
        
        let categoriesMenu = UIMenu(title: "Category", image: UIImage(systemName: "arrow.up.arrow.down.circle"), children: categoryItems)
        
        let settledOnlyFilter = UIAction(title: "Settled Only", image: UIImage(systemName: "checkmark.circle"), state: self.showSettledOnly ? .on : .off) { _ in
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
            self.tableViewController.tableView.reloadData()
        }
        
        return UIMenu(image: UIImage(systemName: "slider.horizontal.3"), options: .displayInline, children: [categoriesMenu, settledOnlyFilter])
    }
    
    @objc private func switchDateStyle() {
        if UserDefaults.standard.string(forKey: "dateStyle") == "Absolute" || UserDefaults.standard.string(forKey: "dateStyle") == nil {
            UserDefaults.standard.setValue("Relative", forKey: "dateStyle")
        } else if UserDefaults.standard.string(forKey: "dateStyle") == "Relative" {
            UserDefaults.standard.setValue("Absolute", forKey: "dateStyle")
        }
        tableViewController.tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableViewController.tableView.reloadData()
        listTransactions()
        listCategories()
        listAccounts()
    }
    
    @objc private func refreshTransactions() {
        #if targetEnvironment(macCatalyst)
        let loadingView = UIActivityIndicatorView(style: .medium)
        loadingView.startAnimating()
        navigationItem.setRightBarButton(UIBarButtonItem(customView: loadingView), animated: true)
        #endif
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.listTransactions()
            self.listCategories()
            self.listAccounts()
        }
    }
    
    func setupFetchingView() {
        view.addSubview(fetchingView)
        
        fetchingView.translatesAutoresizingMaskIntoConstraints = false
        fetchingView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        fetchingView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        fetchingView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        fetchingView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        fetchingView.hidesWhenStopped = true
        
        fetchingView.startAnimating()
    }
    
    func setupTableView() {
        view.addSubview(tableViewController.tableView)
        
        tableViewController.tableView.translatesAutoresizingMaskIntoConstraints = false
        tableViewController.tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableViewController.tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableViewController.tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableViewController.tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        tableViewController.tableView.dataSource = self
        tableViewController.tableView.delegate = self
        
        tableViewController.tableView.register(UINib(nibName: "TransactionCell", bundle: nil), forCellReuseIdentifier: "transactionCell")
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
        request.addValue("Bearer \(UserDefaults.standard.string(forKey: "apiKey") ?? "")", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                if let decodedResponse = try? JSONDecoder().decode(Transaction.self, from: data!) {
                    DispatchQueue.main.async {
                        print("Transactions JSON Decoding Succeeded!")
                        self.transactions = decodedResponse.data
                        self.transactionsError = ""
                        self.transactionsErrorResponse = []
                        self.navigationItem.title = "Transactions"
                        if self.navigationItem.leftBarButtonItems == nil {
                            self.navigationItem.setLeftBarButtonItems([UIBarButtonItem(image: UIImage(systemName: "arrow.up.arrow.down"), style: .plain, target: self, action: #selector(self.switchDateStyle)), self.filterButton], animated: true)
                        }
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshTransactions)), animated: true)
                        #endif
                        self.fetchingView.stopAnimating()
                        self.fetchingView.removeFromSuperview()
                        self.setupTableView()
                        self.tableViewController.tableView.reloadData()
                        self.refreshControl.endRefreshing()
                    }
                } else if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data!) {
                    DispatchQueue.main.async {
                        print("Transactions Error JSON Decoding Succeeded!")
                        self.transactionsErrorResponse = decodedResponse.errors
                        self.transactionsError = ""
                        self.transactions = []
                        self.navigationItem.title = "Errors"
                        self.navigationItem.setLeftBarButton(nil, animated: true)
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshTransactions)), animated: true)
                        #endif
                        self.fetchingView.stopAnimating()
                        self.fetchingView.removeFromSuperview()
                        self.setupTableView()
                        self.tableViewController.tableView.reloadData()
                        self.refreshControl.endRefreshing()
                    }
                } else {
                    DispatchQueue.main.async {
                        print("Transactions JSON Decoding Failed!")
                        self.transactionsError = "JSON Decoding Failed!"
                        self.transactionsErrorResponse = []
                        self.transactions = []
                        self.navigationItem.title = "Error"
                        self.navigationItem.setLeftBarButton(nil, animated: true)
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshTransactions)), animated: true)
                        #endif
                        self.fetchingView.stopAnimating()
                        self.fetchingView.removeFromSuperview()
                        self.setupTableView()
                        self.tableViewController.tableView.reloadData()
                        self.refreshControl.endRefreshing()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    print(error?.localizedDescription ?? "Unknown Error!")
                    self.transactionsError = error?.localizedDescription ?? "Unknown Error!"
                    self.transactionsErrorResponse = []
                    self.transactions = []
                    self.navigationItem.title = "Error"
                    self.navigationItem.setLeftBarButton(nil, animated: true)
                    #if targetEnvironment(macCatalyst)
                    self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshTransactions)), animated: true)
                    #endif
                    self.fetchingView.stopAnimating()
                    self.fetchingView.removeFromSuperview()
                    self.setupTableView()
                    self.tableViewController.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                }
            }
            DispatchQueue.main.async {
                self.searchController.searchBar.placeholder = "Search \(self.preFilteredTransactions.count.description) \(self.preFilteredTransactions.count == 1 ? "Transaction" : "Transactions")"
            }
        }
        .resume()
    }
}

extension TransactionsVC: UITableViewDataSource, UITableViewDelegate {
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
        let transactionCell = tableView.dequeueReusableCell(withIdentifier: "transactionCell", for: indexPath) as! TransactionCell
        
        let noTransactionsCell = tableView.dequeueReusableCell(withIdentifier: "noTransactionsCell", for: indexPath)
        
        let errorStringCell = tableView.dequeueReusableCell(withIdentifier: "errorStringCell", for: indexPath)
        
        let errorObjectCell = tableView.dequeueReusableCell(withIdentifier: "errorObjectCell", for: indexPath) as! SubtitleTableViewCell
        
        if self.filteredTransactions.isEmpty && self.transactionsError.isEmpty && self.transactionsErrorResponse.isEmpty && !self.refreshControl.isRefreshing {
            noTransactionsCell.selectionStyle = .none
            noTransactionsCell.textLabel?.font = UIFontMetrics.default.scaledFont(for: circularStdBook)
            noTransactionsCell.textLabel?.text = "No Transactions"
            noTransactionsCell.backgroundColor = tableView.backgroundColor
            return noTransactionsCell
        } else {
            if !self.transactionsError.isEmpty {
                errorStringCell.selectionStyle = .none
                errorStringCell.textLabel?.numberOfLines = 0
                errorStringCell.textLabel?.font = UIFontMetrics.default.scaledFont(for: circularStdBook)
                errorStringCell.textLabel?.text = transactionsError
                return errorStringCell
            } else if !self.transactionsErrorResponse.isEmpty {
                let error = transactionsErrorResponse[indexPath.row]
                errorObjectCell.selectionStyle = .none
                errorObjectCell.textLabel?.textColor = .red
                errorObjectCell.textLabel?.font = UIFontMetrics.default.scaledFont(for: circularStdBold)
                errorObjectCell.textLabel?.text = error.title
                errorObjectCell.detailTextLabel?.numberOfLines = 0
                errorObjectCell.detailTextLabel?.font = UIFont(name: "CircularStd-Book", size: UIFont.smallSystemFontSize)
                errorObjectCell.detailTextLabel?.text = error.detail
                return errorObjectCell
            } else {
                let transaction = filteredTransactions[indexPath.row]
                
                var createdDate: String {
                    switch UserDefaults.standard.string(forKey: "dateStyle") {
                        case "Absolute", .none: return transaction.attributes.createdDate
                        case "Relative": return transaction.attributes.createdDateRelative
                        default: return transaction.attributes.createdDate
                    }
                }
                
                transactionCell.leftLabel.text = transaction.attributes.description
                transactionCell.leftSubtitle.text = createdDate
                transactionCell.rightLabel.text = "\(transaction.attributes.amount.valueSymbol)\(transaction.attributes.amount.valueString)"
                return transactionCell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.transactionsErrorResponse.isEmpty && self.transactionsError.isEmpty && !self.filteredTransactions.isEmpty {
            let vc = TransactionDetailVC(style: .grouped)
            vc.transaction = filteredTransactions[indexPath.row]
            vc.categories = self.categories
            vc.accounts = self.accounts
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        if self.transactionsErrorResponse.isEmpty && self.transactionsError.isEmpty && !self.filteredTransactions.isEmpty {
            let transaction = filteredTransactions[indexPath.row]
            
            let copy = UIAction(title: "Copy", image: UIImage(systemName: "doc.on.clipboard")) { _ in
                UIPasteboard.general.string = transaction.attributes.description
            }
            
            return UIContextMenuConfiguration(identifier: nil,
                                              previewProvider: nil) { _ in
                UIMenu(title: "", children: [copy])
            }
        } else {
            return nil
        }
    }
    
    private func listCategories() {
        let url = URL(string: "https://api.up.com.au/api/v1/categories")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(UserDefaults.standard.string(forKey: "apiKey") ?? "")", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                if let decodedResponse = try? JSONDecoder().decode(Category.self, from: data!) {
                    DispatchQueue.main.async {
                        print("Categories JSON Decoding Succeeded!")
                        self.categories = decodedResponse.data
                    }
                } else {
                    DispatchQueue.main.async {
                        print("Categories JSON Decoding Failed!")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    print(error?.localizedDescription ?? "Unknown Error!")
                }
            }
        }
        .resume()
    }
    
    private func listAccounts() {
        let url = URL(string: "https://api.up.com.au/api/v1/accounts")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(UserDefaults.standard.string(forKey: "apiKey") ?? "")", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                if let decodedResponse = try? JSONDecoder().decode(Account.self, from: data!) {
                    DispatchQueue.main.async {
                        print("Accounts JSON Decoding Succeeded!")
                        self.accounts = decodedResponse.data
                    }
                } else {
                    DispatchQueue.main.async {
                        print("Accounts JSON Decoding Failed!")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    print(error?.localizedDescription ?? "Unknown Error!")
                }
            }
        }
        .resume()
    }
}
