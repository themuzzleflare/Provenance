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
        
        self.tableView.backgroundColor = R.color.bgColour()
        self.tableView.separatorColor = R.color.bgColour()
        self.tableView.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        self.tableView.indicatorStyle = .white
        self.tableView.showsHorizontalScrollIndicator = false
        #if !targetEnvironment(macCatalyst)
        self.tableView.showsVerticalScrollIndicator = false
        #endif
    }
}
