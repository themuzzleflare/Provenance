import UIKit

final class ActivityIndicator: UIActivityIndicatorView {
    // MARK: - Life Cycle
    
    override init(style: UIActivityIndicatorView.Style) {
        super.init(style: style)
    }
    
    required init(coder: NSCoder) {
        fatalError("Not implemented")
    }
}
