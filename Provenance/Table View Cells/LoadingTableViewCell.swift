import UIKit

class LoadingTableViewCell: UITableViewCell {
    static let reuseIdentifier = "loadingCell"
    
    let loadingIndicator = ActivityIndicator(style: .medium)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        configureCell()
        configureContentView()
        configureLoadingIndicator()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

extension LoadingTableViewCell {
    private func configureCell() {
        selectionStyle = .none
        accessoryType = .none
        separatorInset = .zero
        backgroundColor = .clear
    }
    
    private func configureContentView() {
        contentView.addSubview(loadingIndicator)
    }
    
    private func configureLoadingIndicator() {
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor).isActive = true
        loadingIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor).isActive = true
    }
}
