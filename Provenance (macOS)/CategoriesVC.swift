import Cocoa

class CategoriesVC: NSViewController {
    @IBOutlet var tableView: NSTableView!
    @IBOutlet var stackView: NSStackView!
    @IBOutlet var searchField: NSSearchField!
    
    lazy var categories: [CategoryResource] = []
    lazy var filteredCategories: [CategoryResource] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        stackView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        stackView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.leftAnchor.constraint(equalTo: stackView.leftAnchor, constant: 16).isActive = true
        searchField.rightAnchor.constraint(equalTo: stackView.rightAnchor, constant: -16).isActive = true
        
        searchField.delegate = self
        
        tableView.delegate = self
        tableView.dataSource = self
        
        listCategories()
    }
    
    override func viewWillAppear() {
        tableView.reloadData()
    }
    
    private func listCategories() {
        let url = URL(string: "https://api.up.com.au/api/v1/categories")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer up:yeah:okHM67Kh3ibpXihwYHgtd2CRVvtv6J2TnvbZG6DVQYYKCrrYr49nHEOZ1WKRkSVLz8aayTVVNDlj9Q6alPxyEJGcXRW0kf3OgTEghgEMhA6iUNcIqOzKqRhmS3LE6Pj5", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                if let decodedResponse = try? JSONDecoder().decode(Category.self, from: data!) {
                    DispatchQueue.main.async {
                        print("Categories JSON Decoding Succeeded!")
                        self.categories = decodedResponse.data
                        self.filteredCategories = self.categories.filter({self.searchField.stringValue.isEmpty || $0.attributes.name.localizedStandardContains(self.searchField.stringValue)})
                        self.tableView.reloadData()
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
            DispatchQueue.main.async {
                self.searchField.placeholderString = "Search \(self.categories.count.description) \(self.categories.count == 1 ? "Category" : "Categories")"
            }
        }
        .resume()
    }
}

extension CategoriesVC: NSSearchFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        let searchObject = obj.object as! NSSearchField
        
        let text = searchObject.stringValue
        
        filteredCategories = self.categories.filter({text.isEmpty || $0.attributes.name.localizedStandardContains(text)})
        
        self.tableView.reloadData()
    }
}

extension CategoriesVC: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return filteredCategories.count
    }
}

extension CategoriesVC: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let category = filteredCategories[row]
        
        let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "nameCell")
        
        guard let cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView else { return nil }
        
        cellView.textField?.stringValue = category.attributes.name
        
        return cellView
    }
}
