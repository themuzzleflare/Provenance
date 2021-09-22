import Foundation
import UIKit

extension Array where Element: UITextField {
  var textsJoined: String {
    return self.map { (textField) in
      return textField.text ?? .emptyString
    }.joined()
  }
  
  var tagResources: [TagResource] {
    return self.map { (textField) in
      return TagResource(id: textField.text ?? .emptyString)
    }.filter { (tag) in
      return !tag.id.isEmpty
    }
  }
}
