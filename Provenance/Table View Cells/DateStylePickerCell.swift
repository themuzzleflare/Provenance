import UIKit

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
        
        contentView.topAnchor.constraint(equalTo: horizontalStack.topAnchor, constant: -13).isActive = true
        contentView.bottomAnchor.constraint(equalTo: horizontalStack.bottomAnchor, constant: 13).isActive = true
    }
    
    private func setupLabel() {
        label.translatesAutoresizingMaskIntoConstraints = false
        
        label.font = UIFont(name: "CircularStd-Book", size: UIFont.labelFontSize)
        label.textAlignment = .left
        label.textColor = .darkGray
        label.numberOfLines = 1
        label.text = "Date Style"
    }
    
    private func setupSegmentedControl() {
        segmentedControl.insertSegment(withTitle: "Absolute", at: 0, animated: true)
        segmentedControl.insertSegment(withTitle: "Relative", at: 1, animated: true)
        
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        
        segmentedControl.selectedSegmentTintColor = UIColor(named: "AccentColor")
        segmentedControl.backgroundColor = UIColor(named: "bgColour")
        
        segmentedControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont(name: "CircularStd-Book", size: 14)!], for: .normal)
    }
    
    private func setupHorizontalStackView() {
        horizontalStack.addArrangedSubview(label)
        horizontalStack.addArrangedSubview(segmentedControl)
        
        horizontalStack.translatesAutoresizingMaskIntoConstraints = false
        horizontalStack.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 16).isActive = true
        horizontalStack.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -16).isActive = true
        
        horizontalStack.axis = .horizontal
        horizontalStack.alignment = .center
        horizontalStack.distribution = .equalSpacing
    }
}
