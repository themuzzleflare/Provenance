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
        navigationItem.backButtonDisplayMode = .minimal
        navigationItem.hidesSearchBarWhenScrolling = false
        #if !targetEnvironment(macCatalyst)
        tableView.showsVerticalScrollIndicator = false
        #endif
    }
}
