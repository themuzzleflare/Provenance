import UIKit

class TableViewController: UITableViewController {
    // MARK: - Life Cycle

    override init(style: UITableView.Style) {
        super.init(style: .grouped)
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configure()
    }
}

// MARK: - Configuration

private extension TableViewController {
    private func configure() {
        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = false

        navigationItem.backButtonDisplayMode = .minimal
        navigationItem.hidesSearchBarWhenScrolling = false
    }
}

// MARK: - UITableViewDelegate

extension TableViewController {
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
}
