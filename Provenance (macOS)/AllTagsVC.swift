import Cocoa

class AllTagsVC: NSViewController {
    @IBOutlet var tableView: NSTableView!
    @IBOutlet var stackView: NSStackView!
    @IBOutlet var searchField: NSSearchField!
    
    lazy var tags: [TagResource] = []
    lazy var filteredTags: [TagResource] = []
    
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
        
        listTags()
    }
    
    override func viewWillAppear() {
        tableView.reloadData()
    }
    
    private func listTags() {
        var url = URL(string: "https://api.up.com.au/api/v1/tags")!
        let urlParams = ["page[size]":"200"]
        url = url.appendingQueryParameters(urlParams)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer up:yeah:okHM67Kh3ibpXihwYHgtd2CRVvtv6J2TnvbZG6DVQYYKCrrYr49nHEOZ1WKRkSVLz8aayTVVNDlj9Q6alPxyEJGcXRW0kf3OgTEghgEMhA6iUNcIqOzKqRhmS3LE6Pj5", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                if let decodedResponse = try? JSONDecoder().decode(Tag.self, from: data!) {
                    DispatchQueue.main.async {
                        print("Tags JSON Decoding Succeeded!")
                        self.tags = decodedResponse.data
                        self.filteredTags = self.tags.filter({self.searchField.stringValue.isEmpty || $0.id.localizedStandardContains(self.searchField.stringValue)})
                        self.tableView.reloadData()
                    }
                } else {
                    DispatchQueue.main.async {
                        print("Tags JSON Decoding Failed!")
                    }
                }
            } else {
                DispatchQueue.main.async {
                    print(error?.localizedDescription ?? "Unknown Error!")
                }
            }
            DispatchQueue.main.async {
                self.searchField.placeholderString = "Search \(self.tags.count.description) \(self.tags.count == 1 ? "Tag" : "Tags")"
            }
        }
        .resume()
    }
}

extension AllTagsVC: NSSearchFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        let searchObject = obj.object as! NSSearchField
        
        let text = searchObject.stringValue
        
        filteredTags = self.tags.filter({text.isEmpty || $0.id.localizedStandardContains(text)})
        
        self.tableView.reloadData()
    }
}

extension AllTagsVC: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return filteredTags.count
    }
}

extension AllTagsVC: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let tag = filteredTags[row]
        
        let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "nameCell")
        
        guard let cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView else { return nil }
        
        cellView.textField?.stringValue = tag.id
        
        return cellView
    }
}
