import UIKit
import TinyConstraints
import Rswift

class DateStylePickerCell: UITableViewCell {
    static let reuseIdentifier = "datePickerCell"
    
    let label = UILabel()
    let segmentedControl = UISegmentedControl()
    let horizontalStack = UIStackView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        setupCell()
        setupContentView()
        setupLabel()
        setupSegmentedControl()
        setupHorizontalStackView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

extension DateStylePickerCell {
    private func setupCell() {
        selectionStyle = .none
        accessoryType = .none
        separatorInset = .zero
    }
    
    private func setupContentView() {
        contentView.addSubview(horizontalStack)
    }
    
    private func setupLabel() {
        label.translatesAutoresizingMaskIntoConstraints = false
        
        label.font = R.font.circularStdBook(size: UIFont.labelFontSize)
        label.textAlignment = .left
        label.textColor = .darkGray
        label.numberOfLines = 1
        label.text = "Date Style"
    }
    
    private func setupSegmentedControl() {
        segmentedControl.insertSegment(withTitle: "Absolute", at: 0, animated: false)
        segmentedControl.insertSegment(withTitle: "Relative", at: 1, animated: false)
        
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        
        segmentedControl.selectedSegmentTintColor = R.color.accentColor()
        segmentedControl.backgroundColor = R.color.bgColour()
        
        segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: R.font.circularStdBook(size: 14)!], for: .normal)
    }
    
    private func setupHorizontalStackView() {
        horizontalStack.addArrangedSubview(label)
        horizontalStack.addArrangedSubview(segmentedControl)
        
        horizontalStack.edges(to: contentView, insets: .horizontal(16) + .vertical(13))
        
        horizontalStack.axis = .horizontal
        horizontalStack.alignment = .center
        horizontalStack.distribution = .equalSpacing
    }
}
