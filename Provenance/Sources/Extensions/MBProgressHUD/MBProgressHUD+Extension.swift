import UIKit
import MBProgressHUD

extension MBProgressHUD {
  convenience init(view: UIView, animationType: MBProgressHUDAnimation) {
    self.init(view: view)
    self.animationType = animationType
  }
}
