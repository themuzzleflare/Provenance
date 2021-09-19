import Foundation
import UIKit

extension UIContextMenuConfiguration {
  convenience init(elements: [UIMenuElement]) {
    self.init(
      identifier: nil,
      previewProvider: nil,
      actionProvider: { (_) in
        UIMenu(children: elements)
      }
    )
  }
}
