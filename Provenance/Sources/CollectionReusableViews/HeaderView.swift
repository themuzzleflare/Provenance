import UIKit

final class HeaderView: UICollectionReusableView {
  private let dateLabel = UILabel()
  
  var dateText: String? {
    get {
      return dateLabel.text
    }
    set {
      dateLabel.text = newValue
    }
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    configure()
  }
  
  required init?(coder: NSCoder) {
    fatalError("Not implemented")
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    dateLabel.frame = bounds.inset(by: .sectionHeader)
  }
  
  private func configure() {
    addSubview(dateLabel)
    backgroundColor = .secondarySystemGroupedBackground
    dateLabel.font = .circularStdBook(size: .labelFontSize)
  }
}
