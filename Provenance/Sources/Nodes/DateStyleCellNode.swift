import UIKit
import AsyncDisplayKit

final class DateStyleCellNode: CellNode {
  private let segmentedControlNode = SegmentedControlNode()

  private var dateStyleObserver: NSKeyValueObservation?

  private lazy var styleSelection: AppDateStyle = Store.provenance.appDateStyle {
    didSet {
      if Store.provenance.dateStyle != styleSelection.rawValue {
        Store.provenance.dateStyle = styleSelection.rawValue
      }
      if segmentedControlNode.selectedSegmentIndex != styleSelection.rawValue {
        segmentedControlNode.selectedSegmentIndex = styleSelection.rawValue
      }
    }
  }

  override init() {
    super.init()
    automaticallyManagesSubnodes = true
    selectionStyle = .none
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
    return ASInsetLayoutSpec(insets: .cellNode, child: segmentedControlNode)
  }
}

// MARK: -

extension DateStyleCellNode {
  private func configureObserver() {
    dateStyleObserver = Store.provenance.observe(\.dateStyle, options: .new) { [weak self] (_, change) in
      ASPerformBlockOnMainThread {
        guard let value = change.newValue, let dateStyle = AppDateStyle(rawValue: value) else { return }
        self?.styleSelection = dateStyle
      }
    }
  }

  private func removeObserver() {
    dateStyleObserver?.invalidate()
    dateStyleObserver = nil
  }

  @objc
  private func changedSelection() {
    if let dateStyle = AppDateStyle(rawValue: segmentedControlNode.selectedSegmentIndex) {
      styleSelection = dateStyle
    }
  }
}
