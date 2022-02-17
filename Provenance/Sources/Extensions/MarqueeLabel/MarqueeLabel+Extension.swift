import UIKit
import MarqueeLabel

extension MarqueeLabel {
  convenience init(text: String) {
    self.init()
    self.speed = .duration(8.0)
    self.fadeLength = 10.0
    self.font = .boldSystemFont(ofSize: .labelFontSize)
    self.text = text
  }
}
