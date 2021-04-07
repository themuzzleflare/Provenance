import UIKit

class ActivityIndicator: UIActivityIndicatorView {
    override init(style: UIActivityIndicatorView.Style) {
        super.init(style: style)
        configure()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ActivityIndicator {
    private func configure() {
        hidesWhenStopped = true
        startAnimating()
    }
}
