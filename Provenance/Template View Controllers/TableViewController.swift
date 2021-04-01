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
        
        configure()
    }
}

extension TableViewController {
    private func configure() {
        tableView.backgroundColor = R.color.bgColour()
        tableView.separatorColor = R.color.bgColour()
        tableView.separatorInset = .zero
        tableView.indicatorStyle = .white
        tableView.showsHorizontalScrollIndicator = false
        
        #if !targetEnvironment(macCatalyst)
        tableView.showsVerticalScrollIndicator = false
        #endif
    }
}
