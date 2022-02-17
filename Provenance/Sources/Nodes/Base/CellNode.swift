import UIKit
import AsyncDisplayKit

class CellNode: ASCellNode {
  deinit {
#if DEBUG
    print("\(#function) \(String(describing: type(of: self)))")
#endif
  }
}
