import UIKit

class TableViewController: UITableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
}

private extension TableViewController {
    private func configure() {
        tableView.separatorInset = .zero
        tableView.showsHorizontalScrollIndicator = false
        navigationItem.backButtonDisplayMode = .minimal
        navigationItem.hidesSearchBarWhenScrolling = false
        tableView.showsVerticalScrollIndicator = false
    }
}

extension TableViewController {
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
