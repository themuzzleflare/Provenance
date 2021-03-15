import UIKit
import Rswift

class TransactionsVC: ViewController, UISearchBarDelegate, UISearchControllerDelegate {
    let fetchingView = ActivityIndicator(style: .medium)
    let tableViewController = TableViewController(style: .insetGrouped)
    
    let circularStdBook = R.font.circularStdBook(size: UIFont.labelFontSize)
    let circularStdBold = R.font.circularStdBold(size: UIFont.labelFontSize)
    
    private var filterButton: UIBarButtonItem!
    
    let refreshControl = RefreshControl(frame: .zero)
    lazy var searchController: UISearchController = UISearchController(searchResultsController: nil)
    private var prevFilteredTransactions: [TransactionResource] = []
    
    lazy var transactions: [TransactionResource] = []
    lazy var transactionsErrorResponse: [ErrorObject] = []
    lazy var transactionsError: String = ""
    
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
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if self.filteredTransactions != self.prevFilteredTransactions {
            self.tableViewController.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        }
        self.prevFilteredTransactions = self.filteredTransactions
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.text != "" {
            searchBar.text = ""
            self.prevFilteredTransactions = self.filteredTransactions
            self.tableViewController.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
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
    
    private func categoryNameTransformed(_ category: FilterCategory) -> String {
        switch category {
            case .gamesAndSoftware: return "Apps, Games & Software"
            case .carInsuranceAndMaintenance: return "Car Insurance, Rego & Maintenance"
            case .tvAndMusic: return "TV, Music & Streaming"
            default: return category.rawValue.replacingOccurrences(of: "and", with: "&").replacingOccurrences(of: "-", with: " ").capitalized
        }
    }
    
    private var showSettledOnly: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        super.addChild(tableViewController)
        
        self.searchController.delegate = self
        self.searchController.obscuresBackgroundDuringPresentation = false
        self.searchController.searchBar.searchBarStyle = .minimal
        self.searchController.searchBar.placeholder = "Search"
        self.searchController.hidesNavigationBarDuringPresentation = true
        self.searchController.searchBar.delegate = self
        
        self.definesPresentationContext = true
        
        self.title = "Transactions"
        self.navigationItem.title = "Loading"
        self.navigationItem.searchController = searchController
        self.navigationItem.hidesSearchBarWhenScrolling = false
        
        #if targetEnvironment(macCatalyst)
        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshTransactions)), animated: true)
        #endif
        
        self.navigationController?.navigationBar.prefersLargeTitles = true
        
        self.tableViewController.clearsSelectionOnViewWillAppear = true
        
        self.tableViewController.refreshControl = refreshControl
        self.refreshControl.addTarget(self, action: #selector(refreshTransactions), for: .valueChanged)
        
        self.filterButton = UIBarButtonItem(image: R.image.sliderHorizontal3(), style: .plain, target: self, action: nil)
        self.filterButton.menu = filterMenu()
        
        self.setupFetchingView()
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
            self.tableViewController.tableView.reloadData()
        }
        
        return UIMenu(image: R.image.sliderHorizontal3(), options: .displayInline, children: [categoriesMenu, settledOnlyFilter])
    }
    
    @objc private func switchDateStyle() {
        if UserDefaults.standard.string(forKey: "dateStyle") == "Absolute" || UserDefaults.standard.string(forKey: "dateStyle") == nil {
            UserDefaults.standard.setValue("Relative", forKey: "dateStyle")
        } else if UserDefaults.standard.string(forKey: "dateStyle") == "Relative" {
            UserDefaults.standard.setValue("Absolute", forKey: "dateStyle")
        }
        self.tableViewController.tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableViewController.tableView.reloadData()
        self.listTransactions()
        self.listCategories()
        self.listAccounts()
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
    
    func setupFetchingView() {
        view.addSubview(fetchingView)
        
        fetchingView.translatesAutoresizingMaskIntoConstraints = false
        fetchingView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        fetchingView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        fetchingView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        fetchingView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true        
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
                            self.navigationItem.setLeftBarButtonItems([UIBarButtonItem(image: R.image.arrowUpArrowDown(), style: .plain, target: self, action: #selector(self.switchDateStyle)), self.filterButton], animated: true)
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
                        self.navigationItem.setLeftBarButtonItems(nil, animated: true)
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
                        self.navigationItem.setLeftBarButtonItems(nil, animated: true)
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
                    self.navigationItem.setLeftBarButtonItems(nil, animated: true)
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
        let transactionCell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.transactionCell, for: indexPath)!
        
        let noTransactionsCell = tableView.dequeueReusableCell(withIdentifier: "noTransactionsCell", for: indexPath)
        
        let errorStringCell = tableView.dequeueReusableCell(withIdentifier: "errorStringCell", for: indexPath)
        
        let errorObjectCell = tableView.dequeueReusableCell(withIdentifier: "errorObjectCell", for: indexPath) as! SubtitleTableViewCell
        
        if self.filteredTransactions.isEmpty && self.transactionsError.isEmpty && self.transactionsErrorResponse.isEmpty && !self.refreshControl.isRefreshing {
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
            } else if !self.transactionsErrorResponse.isEmpty {
                let error = transactionsErrorResponse[indexPath.row]
                errorObjectCell.selectionStyle = .none
                errorObjectCell.textLabel?.textColor = .red
                errorObjectCell.textLabel?.font = circularStdBold
                errorObjectCell.textLabel?.text = error.title
                errorObjectCell.detailTextLabel?.numberOfLines = 0
                errorObjectCell.detailTextLabel?.font = R.font.circularStdBook(size: UIFont.smallSystemFontSize)
                errorObjectCell.detailTextLabel?.text = error.detail
                return errorObjectCell
            } else {
                let transaction = filteredTransactions[indexPath.row]
                
                let bgView = UIView()
                bgView.backgroundColor = R.color.accentColor()
                transactionCell.selectedBackgroundView = bgView
                
                transactionCell.leftLabel.text = transaction.attributes.description
                transactionCell.leftSubtitle.text = transaction.attributes.creationDate
                
                if transaction.attributes.amount.valueInBaseUnits.signum() == -1 {
                    transactionCell.rightLabel.textColor = .black
                } else {
                    transactionCell.rightLabel.textColor = R.color.greenColour()
                }
                
                transactionCell.rightLabel.text = transaction.attributes.amount.valueShort
                
                return transactionCell
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
            let transaction = filteredTransactions[indexPath.row]
            
            let copy = UIAction(title: "Copy", image: R.image.docOnClipboard()) { _ in
                UIPasteboard.general.string = transaction.attributes.description
            }
            
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                UIMenu(children: [copy])
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
                        print("Categories JSON Decoding succeeded")
                        self.categories = decodedResponse.data
                    }
                } else {
                    DispatchQueue.main.async {
                        print("Categories JSON Decoding failed")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    print(error?.localizedDescription ?? "Unknown error")
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
                        print("Accounts JSON Decoding succeeded")
                        self.accounts = decodedResponse.data
                    }
                } else {
                    DispatchQueue.main.async {
                        print("Accounts JSON Decoding failed")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    print(error?.localizedDescription ?? "Unknown error")
                }
            }
        }
        .resume()
    }
}
