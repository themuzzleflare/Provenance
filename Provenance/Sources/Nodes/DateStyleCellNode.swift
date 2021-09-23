import AsyncDisplayKit

final class DateStyleCellNode: ASCellNode {
  private let dateStyleTextNode = ASTextNode()
  private let segmentedControlNode = SegmentedControlNode()
  
  private var styleSelection: AppDateStyle = ProvenanceApp.userDefaults.appDateStyle {
    didSet {
      if ProvenanceApp.userDefaults.dateStyle != styleSelection.rawValue {
        ProvenanceApp.userDefaults.dateStyle = styleSelection.rawValue
      }
      if segmentedControlNode.selectedSegmentIndex != styleSelection.rawValue {
        segmentedControlNode.selectedSegmentIndex = styleSelection.rawValue
      }
    }
  }
  
  private var dateStyleObserver: NSKeyValueObservation?
  
  override init() {
    super.init()
    
    automaticallyManagesSubnodes = true
    
    selectionStyle = .none
    
    dateStyleTextNode.attributedText = "Date Style".styled(with: .leftText)
  }
  
  deinit {
    removeObserver()
  }
  
  override func didLoad() {
    super.didLoad()
    configureObserver()
    AppDateStyle.allCases.forEach { segmentedControlNode.insertSegment(withTitle: $0.description, at: $0.rawValue, animated: false) }
    segmentedControlNode.selectedSegmentIndex = styleSelection.rawValue
    segmentedControlNode.addTarget(self, action: #selector(changedSelection), forControlEvents: .valueChanged)
  }
  
  override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
    let horizontalStack = ASStackLayoutSpec(
      direction: .horizontal,
      spacing: 0,
      justifyContent: .spaceBetween,
      alignItems: .center,
      children: [
        dateStyleTextNode,
        segmentedControlNode
      ]
    )
    
    return ASInsetLayoutSpec(insets: .cellNode, child: horizontalStack)
  }
}

extension DateStyleCellNode {
  private func configureObserver() {
    dateStyleObserver = ProvenanceApp.userDefaults.observe(\.dateStyle, options: .new) { [weak self] (_, change) in
      guard let weakSelf = self, let value = change.newValue, let dateStyle = AppDateStyle(rawValue: value) else { return }
      weakSelf.styleSelection = dateStyle
    }
  }
  
  private func removeObserver() {
    dateStyleObserver?.invalidate()
    dateStyleObserver = nil
  }
  
  @objc private func changedSelection() {
    if let dateStyle = AppDateStyle(rawValue: segmentedControlNode.selectedSegmentIndex) {
      styleSelection = dateStyle
    }
  }
}
