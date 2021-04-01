import UIKit

class ActivityIndicator: UIActivityIndicatorView {
    override init(style: UIActivityIndicatorView.Style) {
        super.init(style: .medium)
        
        configure()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

extension ActivityIndicator {
    private func configure() {
        self.color = .white
        self.hidesWhenStopped = true
        self.startAnimating()
    }
}
