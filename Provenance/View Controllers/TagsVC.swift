import UIKit
import Rswift

class TagsVC: TableViewController {
    var transaction: TransactionResource!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureProperties()
        configureNavigation()
        configureTableView()
    }
}

extension TagsVC {
    private func configureProperties() {
        title = "Tags"
    }
    
    private func configureNavigation() {
        navigationItem.title = "Tags"
        navigationItem.backBarButtonItem = UIBarButtonItem(image: R.image.tag(), style: .plain, target: self, action: nil)
    }
    
    private func configureTableView() {
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
        
        cell.selectedBackgroundView = bgCellView
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.font = R.font.circularStdBook(size: UIFont.labelFontSize)
        cell.textLabel?.text = tag.id
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        navigationController?.pushViewController({let vc = TransactionsByTagVC(style: .grouped);vc.tag = TagResource(type: "tags", id: transaction.relationships.tags.data[indexPath.row].id);return vc}(), animated: true)
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let copy = UIAction(title: "Copy", image: R.image.docOnClipboard()) { _ in
            UIPasteboard.general.string = self.transaction.relationships.tags.data[indexPath.row].id
        }
        
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(children: [copy])
        }
    }
}
