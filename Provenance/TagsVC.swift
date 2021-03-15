import UIKit
import Rswift

class TagsVC: TableViewController {
    var transaction: TransactionResource!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.clearsSelectionOnViewWillAppear = true
        
        self.title = "Tags"
        self.navigationItem.title = "Tags"
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "tagCell")
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
        
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.font = R.font.circularStdBook(size: UIFont.labelFontSize)
        cell.textLabel?.text = tag.id
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tag = transaction.relationships.tags.data[indexPath.row]
        let vc = TransactionsByTagVC()
        vc.tag = TagResource(type: "tags", id: tag.id)
        navigationController?.pushViewController(vc, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let tag = transaction.relationships.tags.data[indexPath.row]
        
        let copy = UIAction(title: "Copy", image: UIImage(systemName: "doc.on.clipboard")) { _ in
            UIPasteboard.general.string = tag.id
        }
        
        return UIContextMenuConfiguration(identifier: nil,
                                          previewProvider: nil) { _ in
            UIMenu(title: "", children: [copy])
        }
    }
}
