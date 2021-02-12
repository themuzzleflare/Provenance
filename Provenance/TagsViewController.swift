import UIKit

class TagsViewController: UITableViewController {
    var transaction: TransactionResource!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        self.title = "Tags"
        
        navigationItem.title = "Tags"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "tagCell")
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transaction.relationships.tags.data.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "tagCell", for: indexPath)
        
        let tag = transaction.relationships.tags.data[indexPath.row]
        
        cell.selectionStyle = .none
        cell.textLabel?.text = tag.id
        return cell
    }
}
