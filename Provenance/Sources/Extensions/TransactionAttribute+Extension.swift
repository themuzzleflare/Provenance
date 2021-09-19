import Foundation
import UIKit

extension TransactionAttribute {
  var statusIcon: UIImage {
    switch isSettled {
    case true:
      return .checkmark
    case false:
      return .clock
    }
  }
}
