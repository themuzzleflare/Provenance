import Cocoa

class CategoriesVC: NSViewController {
    @IBOutlet var tableView: NSTableView!
    @IBOutlet var bsView: NSScrollView!
    
    lazy var categories: [CategoryResource] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bsView.translatesAutoresizingMaskIntoConstraints = false
        bsView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        bsView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        bsView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        bsView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
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
        }
        .resume()
    }
}

extension CategoriesVC: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return categories.count
    }
}

extension CategoriesVC: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let category = categories[row]
        
        let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "nameCell")
        
        guard let cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView else { return nil }
        
        cellView.textField?.stringValue = category.attributes.name
        
        return cellView
    }
}
