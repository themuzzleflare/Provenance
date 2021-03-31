import UIKit
import Rswift

class TableViewController: UITableViewController {
    override init(style: UITableView.Style) {
        super.init(style: .insetGrouped)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableViewStyle()
    }
    
    private func setupTableViewStyle() {
        tableView.backgroundColor = R.color.bgColour()
        tableView.separatorColor = R.color.bgColour()
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        tableView.indicatorStyle = .white
        tableView.showsHorizontalScrollIndicator = false
        
        #if !targetEnvironment(macCatalyst)
        tableView.showsVerticalScrollIndicator = false
        #endif
    }
}
