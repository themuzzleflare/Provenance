import UIKit
import WidgetKit
import TinyConstraints
import Rswift

class DateStyleTableViewCell: UITableViewCell {
    static let reuseIdentifier = "dateStyleTableViewCell"

    private var dateStyleObserver: NSKeyValueObservation?
    
    private let label = UILabel()
    private let segmentedControl = UISegmentedControl()
    private let horizontalStack = UIStackView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        dateStyleObserver = appDefaults.observe(\.dateStyle, options: .new) { object, change in
            if change.newValue == "Absolute" {
                self.segmentedControl.selectedSegmentIndex = 0
            } else if change.newValue == "Relative" {
                self.segmentedControl.selectedSegmentIndex = 1
            }
            WidgetCenter.shared.reloadAllTimelines()
        }
        configureCell()
        configureContentView()
        configureLabel()
        configureSegmentedControl()
        configureHorizontalStackView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
}

private extension DateStyleTableViewCell {
    private func configureCell() {
        selectionStyle = .none
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
        label.text = "Date Style"
    }
    
    private func configureSegmentedControl() {
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.insertSegment(withTitle: "Absolute", at: 0, animated: false)
        segmentedControl.insertSegment(withTitle: "Relative", at: 1, animated: false)
        if appDefaults.dateStyle == "Absolute" {
            segmentedControl.selectedSegmentIndex = 0
        } else if appDefaults.dateStyle == "Relative" {
            segmentedControl.selectedSegmentIndex = 1
        }
        segmentedControl.addTarget(self, action: #selector(switchDateStyle), for: .valueChanged)
    }

    @objc private func switchDateStyle() {
        appDefaults.dateStyle = segmentedControl.titleForSegment(at: segmentedControl.selectedSegmentIndex)!
    }
    
    private func configureHorizontalStackView() {
        horizontalStack.edges(to: contentView, insets: .horizontal(16) + .vertical(13))
        horizontalStack.addArrangedSubview(label)
        horizontalStack.addArrangedSubview(segmentedControl)
        horizontalStack.alignment = .center
        horizontalStack.distribution = .equalSpacing
    }
}
