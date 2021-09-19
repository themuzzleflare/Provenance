import Foundation
import UIKit

struct ProvenanceApp {
  static let userDefaults = UserDefaults.provenance

  var selectedBackgroundCellView: UIView {
    let view = UIView()
    view.backgroundColor = .accentColor
    return view
  }
}
