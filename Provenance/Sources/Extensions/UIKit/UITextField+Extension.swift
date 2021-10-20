import UIKit

extension Array where Element: UITextField {
  var textsJoined: String {
    return self.map { (textField) in
      return textField.text ?? ""
    }.joined()
  }

  var tagResources: [TagResource] {
    return self.map { (textField) in
      return TagResource(id: textField.text ?? "")
    }.filter { (tag) in
      return !tag.id.isEmpty
    }
  }
}
