import UIKit
import TinyConstraints

class LoadingTableViewCell: UITableViewCell {
    static let reuseIdentifier = "loadingTableViewCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension LoadingTableViewCell {
    private func configure() {
        let loadingIndicator = ActivityIndicator(style: .medium)
        contentView.addSubview(loadingIndicator)
        loadingIndicator.center(in: contentView)
        loadingIndicator.startAnimating()
    }
}
