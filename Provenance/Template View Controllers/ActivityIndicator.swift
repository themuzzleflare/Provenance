import UIKit

class ActivityIndicator: UIActivityIndicatorView {
    override init(style: UIActivityIndicatorView.Style) {
        super.init(style: .medium)
        self.color = .white
        self.hidesWhenStopped = true
        self.startAnimating()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
