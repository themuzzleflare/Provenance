import UIKit
import TinyConstraints
import Rswift

final class TransactionsHeaderView: UICollectionReusableView {
    // MARK: - Properties

    var date: String! {
        didSet {
            label.text = date
        }
    }

    private let label = UILabel()

    // MARK: - Life Cycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
}

// MARK: - Configuration

private extension TransactionsHeaderView {
    private func configure() {
        backgroundColor = .secondarySystemGroupedBackground

        addSubview(label)

        label.centerInSuperview()
        label.textAlignment = .center
        label.font = R.font.circularStdBook(size: UIFont.labelFontSize)
    }
}
