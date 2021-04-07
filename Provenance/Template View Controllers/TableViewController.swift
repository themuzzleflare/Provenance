import UIKit
import Rswift

class TableViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
}

extension TableViewController {
    private func configure() {
        tableView.separatorInset = .zero
        tableView.showsHorizontalScrollIndicator = false
        
        #if !targetEnvironment(macCatalyst)
        tableView.showsVerticalScrollIndicator = false
        #endif
    }
}
