import UIKit
import TinyConstraints
import Rswift

class DateStylePickerTableViewCell: UITableViewCell {
    static let reuseIdentifier = "datePickerTableViewCell"
    
    let label = UILabel()
    let segmentedControl = UISegmentedControl()
    let horizontalStack = UIStackView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureCell()
        configureContentView()
        configureLabel()
        configureSegmentedControl()
        configureHorizontalStackView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension DateStylePickerTableViewCell {
    private func configureCell() {
        selectionStyle = .none
        accessoryType = .none
        separatorInset = .zero
    }
    
    private func configureContentView() {
        contentView.addSubview(horizontalStack)
    }
    
    private func configureLabel() {
        label.translatesAutoresizingMaskIntoConstraints = false
        
        label.font = R.font.circularStdBook(size: UIFont.labelFontSize)
        label.textAlignment = .left
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        label.text = "Date Style"
    }
    
    private func configureSegmentedControl() {
        segmentedControl.insertSegment(withTitle: "Absolute", at: 0, animated: false)
        segmentedControl.insertSegment(withTitle: "Relative", at: 1, animated: false)
        
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false

        segmentedControl.setTitleTextAttributes([NSAttributedString.Key.font: R.font.circularStdBook(size: 14)!], for: .normal)
    }
    
    private func configureHorizontalStackView() {
        horizontalStack.addArrangedSubview(label)
        horizontalStack.addArrangedSubview(segmentedControl)
        
        horizontalStack.edges(to: contentView, insets: .horizontal(16) + .vertical(13))
        
        horizontalStack.axis = .horizontal
        horizontalStack.alignment = .center
        horizontalStack.distribution = .equalSpacing
    }
}
