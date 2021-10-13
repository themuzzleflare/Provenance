import UIKit

extension UIContextMenuConfiguration {
  convenience init(previewProvider: UIContextMenuContentPreviewProvider? = nil, elements: [UIMenuElement]) {
    self.init(identifier: nil, previewProvider: previewProvider, actionProvider: { (_) in
      UIMenu(children: elements)
    })
  }
}
