import Cocoa

class AllTagsVC: NSViewController {
    @IBOutlet var tableView: NSTableView!
    @IBOutlet var bsView: NSScrollView!
    
    lazy var tags: [TagResource] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        bsView.translatesAutoresizingMaskIntoConstraints = false
        bsView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        bsView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        bsView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        bsView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
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
        }
        .resume()
    }
}

extension AllTagsVC: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return tags.count
    }
}

extension AllTagsVC: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let tag = tags[row]
        
        let cellIdentifier = NSUserInterfaceItemIdentifier(rawValue: "nameCell")
        
        guard let cellView = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView else { return nil }
        
        cellView.textField?.stringValue = tag.id
        
        return cellView
    }
}
