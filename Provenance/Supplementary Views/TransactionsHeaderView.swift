import UIKit
import TinyConstraints
import Rswift

final class TransactionsHeaderView: UICollectionReusableView {
    var date: String! {
        didSet {
            label.text = date
        }
    }

    let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    func configure() {
        backgroundColor = .secondarySystemGroupedBackground

        addSubview(label)
        
        label.centerInSuperview()
        label.font = R.font.circularStdBook(size: UIFont.labelFontSize)
    }
}
