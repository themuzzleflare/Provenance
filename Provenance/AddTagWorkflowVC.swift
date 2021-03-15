import UIKit
import Rswift

class AddTagWorkflowVC: ViewController, UITableViewDelegate, UISearchBarDelegate, UISearchControllerDelegate {
    let fetchingView = ActivityIndicator(style: .medium)
    let tableViewController = TableViewController(style: .insetGrouped)
    
    let circularStdBook = R.font.circularStdBook(size: UIFont.labelFontSize)
    let circularStdBold = R.font.circularStdBold(size: UIFont.labelFontSize)
    
    let refreshControl = RefreshControl(frame: .zero)
    lazy var searchController: UISearchController = UISearchController(searchResultsController: nil)
    
    private var prevFilteredTransactions: [TransactionResource] = []
    
    lazy var transactions: [TransactionResource] = []
    lazy var transactionsErrorResponse: [ErrorObject] = []
    lazy var transactionsError: String = ""
    
    private var filteredTransactions: [TransactionResource] {
        transactions.filter { transaction in
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
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeWorkflow))
        self.navigationItem.searchController = searchController
        self.navigationItem.hidesSearchBarWhenScrolling = false
        self.navigationItem.backButtonDisplayMode = .minimal
        
        self.tableViewController.clearsSelectionOnViewWillAppear = true
        self.tableViewController.refreshControl = refreshControl
        self.refreshControl.addTarget(self, action: #selector(refreshTransactions), for: .valueChanged)
        
        self.setupFetchingView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableViewController.tableView.reloadData()
        self.listTransactions()
    }
    
    @objc private func refreshTransactions() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.listTransactions()
        }
    }
    
    @objc private func closeWorkflow() {
        self.dismiss(animated: true)
    }
    
    func setupFetchingView() {
        self.view.addSubview(fetchingView)
        
        self.fetchingView.translatesAutoresizingMaskIntoConstraints = false
        self.fetchingView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        self.fetchingView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        self.fetchingView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        self.fetchingView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
    }
    
    func setupTableView() {
        self.view.addSubview(tableViewController.tableView)
        
        self.tableViewController.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.tableViewController.tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        self.tableViewController.tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        self.tableViewController.tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        self.tableViewController.tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        self.tableViewController.tableView.dataSource = self
        self.tableViewController.tableView.delegate = self
        
        self.tableViewController.tableView.register(R.nib.transactionCell)
        self.tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "noTransactionsCell")
        self.tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "errorStringCell")
        self.tableViewController.tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: "errorObjectCell")
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
                        self.navigationItem.title = "Select Transaction"
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
                    self.fetchingView.stopAnimating()
                    self.fetchingView.removeFromSuperview()
                    self.setupTableView()
                    self.tableViewController.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                }
            }
            DispatchQueue.main.async {
                self.searchController.searchBar.placeholder = "Search \(self.transactions.count.description) \(self.transactions.count == 1 ? "Transaction" : "Transactions")"
            }
        }
        .resume()
    }
}

extension AddTagWorkflowVC: UITableViewDataSource {
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
            noTransactionsCell.textLabel?.textColor = .white
            noTransactionsCell.textLabel?.textAlignment = .center
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
            let vc = AddTagWorkflowTwoVC()
            vc.transaction = filteredTransactions[indexPath.row]
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

class AddTagWorkflowTwoVC: ViewController, UITableViewDelegate, UISearchBarDelegate, UISearchControllerDelegate, UITextFieldDelegate {
    var transaction: TransactionResource!
    
    let fetchingView = ActivityIndicator(style: .medium)
    let tableViewController = TableViewController(style: .insetGrouped)
    
    let circularStdBook = R.font.circularStdBook(size: UIFont.labelFontSize)
    let circularStdBold = R.font.circularStdBold(size: UIFont.labelFontSize)
    
    private var prevFilteredTags: [TagResource] = []
    
    let refreshControl = RefreshControl(frame: .zero)
    lazy var searchController: UISearchController = UISearchController(searchResultsController: nil)
    
    lazy var tags: [TagResource] = []
    lazy var tagsErrorResponse: [ErrorObject] = []
    lazy var tagsError: String = ""
    
    private var filteredTags: [TagResource] {
        tags.filter { tag in
            searchController.searchBar.text!.isEmpty || tag.id.localizedStandardContains(searchController.searchBar.text!)
        }
    }
    
    weak var submitActionProxy: UIAlertAction?
    private var textDidChangeObserver: NSObjectProtocol!
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if self.filteredTags != self.prevFilteredTags {
            self.tableViewController.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        }
        self.prevFilteredTags = self.filteredTags
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        if searchBar.text != "" {
            searchBar.text = ""
            self.prevFilteredTags = self.filteredTags
            self.tableViewController.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        }
    }
    
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
        
        self.title = "Tags"
        self.navigationItem.title = "Loading"
        self.navigationItem.searchController = searchController
        self.navigationItem.hidesSearchBarWhenScrolling = false
        self.navigationItem.backButtonDisplayMode = .minimal
        
        self.tableViewController.clearsSelectionOnViewWillAppear = true
        self.tableViewController.refreshControl = refreshControl
        self.refreshControl.addTarget(self, action: #selector(refreshTags), for: .valueChanged)
        
        self.setupFetchingView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.listTags()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        
        guard let stringRange = Range(range, in: currentText) else { return false }
        
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        
        return updatedText.count <= 30
    }
    
    @objc private func openAddWorkflow() {
        let ac = UIAlertController(title: "", message: "", preferredStyle: .alert)
        
        let titleFont = [NSAttributedString.Key.font: R.font.circularStdBold(size: 17)!]
        let messageFont = [NSAttributedString.Key.font: R.font.circularStdBook(size: 12)!]
        
        let titleAttrString = NSMutableAttributedString(string: "New Tag", attributes: titleFont)
        let messageAttrString = NSMutableAttributedString(string: "Enter the name of the new tag.", attributes: messageFont)
        
        ac.setValue(titleAttrString, forKey: "attributedTitle")
        ac.setValue(messageAttrString, forKey: "attributedMessage")
        ac.addTextField { textField in
            textField.delegate = self
            textField.autocapitalizationType = .none
            textField.tintColor = R.color.accentColor()
            textField.autocorrectionType = .no
            
            self.textDidChangeObserver = NotificationCenter.default.addObserver(
                forName: UITextField.textDidChangeNotification,
                object: textField,
                queue: OperationQueue.main) { (notification) in
                if let textField = notification.object as? UITextField {
                    if let text = textField.text {
                        self.submitActionProxy!.isEnabled = text.count >= 1
                    } else {
                        self.submitActionProxy!.isEnabled = false
                    }
                }
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        cancelAction.setValue(R.color.accentColor(), forKey: "titleTextColor")
        
        let submitAction = UIAlertAction(title: "Next", style: .default) { _ in
            let answer = ac.textFields![0]
            if answer.text != "" {
                let vc = AddTagWorkflowThreeVC(style: .insetGrouped)
                vc.transaction = self.transaction
                vc.tag = answer.text
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
        submitAction.setValue(R.color.accentColor(), forKey: "titleTextColor")
        submitAction.isEnabled = false
        submitActionProxy = submitAction
        
        ac.addAction(cancelAction)
        ac.addAction(submitAction)
        
        present(ac, animated: true)
    }
    
    @objc private func refreshTags() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.listTags()
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
        
        tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "tagCell")
        tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "noTagsCell")
        tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "errorStringCell")
        tableViewController.tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: "errorObjectCell")
    }
    
    private func listTags() {
        var url = URL(string: "https://api.up.com.au/api/v1/tags")!
        let urlParams = ["page[size]":"200"]
        url = url.appendingQueryParameters(urlParams)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(UserDefaults.standard.string(forKey: "apiKey") ?? "")", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                if let decodedResponse = try? JSONDecoder().decode(Tag.self, from: data!) {
                    DispatchQueue.main.async {
                        print("Tags JSON Decoding Succeeded!")
                        self.tags = decodedResponse.data
                        self.tagsError = ""
                        self.tagsErrorResponse = []
                        self.navigationItem.title = "Select Tag"
                        if self.navigationItem.rightBarButtonItem == nil {
                            self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.openAddWorkflow)), animated: true)
                        }
                        self.fetchingView.stopAnimating()
                        self.fetchingView.removeFromSuperview()
                        self.setupTableView()
                        self.tableViewController.tableView.reloadData()
                        self.refreshControl.endRefreshing()
                    }
                } else if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data!) {
                    DispatchQueue.main.async {
                        print("Tags Error JSON Decoding Succeeded!")
                        self.tagsErrorResponse = decodedResponse.errors
                        self.tagsError = ""
                        self.tags = []
                        self.navigationItem.title = "Errors"
                        self.navigationItem.setRightBarButton(nil, animated: true)
                        self.fetchingView.stopAnimating()
                        self.fetchingView.removeFromSuperview()
                        self.setupTableView()
                        self.tableViewController.tableView.reloadData()
                        self.refreshControl.endRefreshing()
                    }
                } else {
                    DispatchQueue.main.async {
                        print("Tags JSON Decoding Failed!")
                        self.tagsError = "JSON Decoding Failed!"
                        self.tagsErrorResponse = []
                        self.tags = []
                        self.navigationItem.title = "Error"
                        self.navigationItem.setRightBarButton(nil, animated: true)
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
                    self.tagsError = error?.localizedDescription ?? "Unknown Error!"
                    self.tagsErrorResponse = []
                    self.tags = []
                    self.navigationItem.title = "Error"
                    self.navigationItem.setRightBarButton(nil, animated: true)
                    self.fetchingView.stopAnimating()
                    self.fetchingView.removeFromSuperview()
                    self.setupTableView()
                    self.tableViewController.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                }
            }
            DispatchQueue.main.async {
                self.searchController.searchBar.placeholder = "Search \(self.tags.count.description) \(self.tags.count == 1 ? "Tag" : "Tags")"
            }
        }
        .resume()
    }
}

extension AddTagWorkflowTwoVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.filteredTags.isEmpty && self.tagsError.isEmpty && self.tagsErrorResponse.isEmpty {
            return 1
        } else {
            if !self.tagsError.isEmpty {
                return 1
            } else if !self.tagsErrorResponse.isEmpty {
                return tagsErrorResponse.count
            } else {
                return filteredTags.count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tagCell = tableView.dequeueReusableCell(withIdentifier: "tagCell", for: indexPath)
        
        let noTagsCell = tableView.dequeueReusableCell(withIdentifier: "noTagsCell", for: indexPath)
        
        let errorStringCell = tableView.dequeueReusableCell(withIdentifier: "errorStringCell", for: indexPath)
        
        let errorObjectCell = tableView.dequeueReusableCell(withIdentifier: "errorObjectCell", for: indexPath) as! SubtitleTableViewCell
        
        if self.filteredTags.isEmpty && self.tagsError.isEmpty && self.tagsErrorResponse.isEmpty && !self.refreshControl.isRefreshing {
            tableView.separatorStyle = .none
            noTagsCell.selectionStyle = .none
            noTagsCell.textLabel?.textAlignment = .center
            noTagsCell.textLabel?.textColor = .white
            noTagsCell.textLabel?.text = "No Tags"
            noTagsCell.textLabel?.font = circularStdBook
            noTagsCell.backgroundColor = .clear
            return noTagsCell
        } else {
            tableView.separatorStyle = .singleLine
            if !self.tagsError.isEmpty {
                errorStringCell.selectionStyle = .none
                errorStringCell.textLabel?.numberOfLines = 0
                errorStringCell.textLabel?.font = circularStdBook
                errorStringCell.textLabel?.text = tagsError
                return errorStringCell
            } else if !self.tagsErrorResponse.isEmpty {
                let error = tagsErrorResponse[indexPath.row]
                errorObjectCell.selectionStyle = .none
                errorObjectCell.textLabel?.textColor = .red
                errorObjectCell.textLabel?.font = circularStdBold
                errorObjectCell.textLabel?.text = error.title
                errorObjectCell.detailTextLabel?.numberOfLines = 0
                errorObjectCell.detailTextLabel?.font = R.font.circularStdBook(size: UIFont.smallSystemFontSize)
                errorObjectCell.detailTextLabel?.text = error.detail
                return errorObjectCell
            } else {
                let tag = filteredTags[indexPath.row]
                
                let bgView = UIView()
                bgView.backgroundColor = R.color.accentColor()
                tagCell.selectedBackgroundView = bgView
                
                tagCell.accessoryType = .disclosureIndicator
                tagCell.textLabel?.font = circularStdBook
                tagCell.textLabel?.adjustsFontForContentSizeCategory = true
                tagCell.textLabel?.text = tag.id
                return tagCell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.tagsErrorResponse.isEmpty && self.tagsError.isEmpty && !self.filteredTags.isEmpty {
            let vc = AddTagWorkflowThreeVC(style: .insetGrouped)
            vc.transaction = transaction
            vc.tag = filteredTags[indexPath.row].id
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

class AddTagWorkflowThreeVC: TableViewController {
    var transaction: TransactionResource!
    var tag: String!
    
    private func errorAlert(_ statusCode: Int) -> (title: String, content: String) {
        switch statusCode {
            case 403: return (title: "Forbidden", content: "Too many tags added to this transaction. Each transaction may have up to 6 tags.")
            default: return (title: "Failed", content: "The tag was not added to the transaction.")
        }
    }
    
    let circularStdBook = R.font.circularStdBook(size: UIFont.labelFontSize)
    let circularStdBold = R.font.circularStdBold(size: UIFont.labelFontSize)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Confirmation"
        self.navigationItem.title = "Confirmation"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: R.image.checkmark(), style: .plain, target: self, action: #selector(addTag))
        
        self.tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: "attributeCell")
        self.tableView.register(R.nib.transactionCell)
    }
    
    @objc private func addTag() {
        let url = URL(string: "https://api.up.com.au/api/v1/transactions/\(transaction.id)/relationships/tags")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(UserDefaults.standard.string(forKey: "apiKey") ?? "")", forHTTPHeaderField: "Authorization")
        
        let bodyObject: [String : Any] = [
            "data": [
                [
                    "type": "tags",
                    "id": tag
                ]
            ]
        ]
        request.httpBody = try! JSONSerialization.data(withJSONObject: bodyObject, options: [])
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                let statusCode = (response as! HTTPURLResponse).statusCode
                if statusCode != 204 {
                    DispatchQueue.main.async {
                        let ac = UIAlertController(title: "", message: "", preferredStyle: .alert)
                        
                        let titleFont = [NSAttributedString.Key.font: R.font.circularStdBold(size: 17)!]
                        let messageFont = [NSAttributedString.Key.font: R.font.circularStdBook(size: 12)!]
                        
                        let titleAttrString = NSMutableAttributedString(string: self.errorAlert(statusCode).title, attributes: titleFont)
                        let messageAttrString = NSMutableAttributedString(string: self.errorAlert(statusCode).content, attributes: messageFont)
                        
                        ac.setValue(titleAttrString, forKey: "attributedTitle")
                        ac.setValue(messageAttrString, forKey: "attributedMessage")
                        
                        let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: { _ in
                            self.navigationController?.popViewController(animated: true)
                        })
                        dismissAction.setValue(R.color.accentColor(), forKey: "titleTextColor")
                        ac.addAction(dismissAction)
                        self.present(ac, animated: true)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    let ac = UIAlertController(title: "", message: "", preferredStyle: .alert)
                    
                    let titleFont = [NSAttributedString.Key.font: R.font.circularStdBold(size: 17)!]
                    let messageFont = [NSAttributedString.Key.font: R.font.circularStdBook(size: 12)!]
                    
                    let titleAttrString = NSMutableAttributedString(string: "Failed", attributes: titleFont)
                    let messageAttrString = NSMutableAttributedString(string: error?.localizedDescription ?? "\(self.tag!) was not added to \(self.transaction.attributes.description).", attributes: messageFont)
                    
                    ac.setValue(titleAttrString, forKey: "attributedTitle")
                    ac.setValue(messageAttrString, forKey: "attributedMessage")
                    
                    let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: { _ in
                        self.navigationController?.popToRootViewController(animated: true)
                    })
                    dismissAction.setValue(R.color.accentColor(), forKey: "titleTextColor")
                    ac.addAction(dismissAction)
                    self.present(ac, animated: true)
                }
            }
        }
        .resume()
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Adding Tag"
        } else if section == 1 {
            return "To Transaction"
        } else {
            return "Summary"
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 2 {
            return "No more than 6 tags may be present on any single transaction. Duplicate tags are silently ignored."
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if let headerView = view as? UITableViewHeaderFooterView {
            headerView.textLabel?.textColor = .lightGray
            headerView.textLabel?.font = R.font.circularStdBook(size: 13)
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if let footerView = view as? UITableViewHeaderFooterView {
            footerView.textLabel?.textColor = .lightGray
            footerView.textLabel?.font = R.font.circularStdBook(size: 12)
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "attributeCell", for: indexPath) as! SubtitleTableViewCell
        let transactionCell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.transactionCell, for: indexPath)!
        let section = indexPath.section
        
        cell.selectionStyle = .none
        cell.textLabel?.font = circularStdBook
        cell.detailTextLabel?.font = circularStdBook
        
        transactionCell.selectionStyle = .none
        transactionCell.accessoryType = .none
        
        if section == 0 {
            cell.textLabel?.text = tag
            return cell
        } else if section == 1 {
            transactionCell.leftLabel.text = transaction.attributes.description
            transactionCell.leftSubtitle.text = transaction.attributes.creationDate
            
            if transaction.attributes.amount.valueInBaseUnits.signum() == -1 {
                transactionCell.rightLabel.textColor = .black
            } else {
                transactionCell.rightLabel.textColor = R.color.greenColour()
            }
            
            transactionCell.rightLabel.text = transaction.attributes.amount.valueShort
            return transactionCell
        } else {
            
            cell.textLabel?.numberOfLines = 0
            cell.textLabel?.text = "You are adding the tag \"\(tag!)\" to the transaction \"\(transaction.attributes.description)\", which was created \(transaction.attributes.creationDate)."
            return cell
        }
    }
}
