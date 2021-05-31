import UIKit
import TinyConstraints
import Rswift

class WidgetsVC: ViewController {
    // MARK: - Properties

    private let accountBalanceWidget = UIImageView()
    private let latestTransactionWidget = UIImageView()
    private let instructionTitle = UILabel()
    private let instructionLabel = UILabel()
    private let horizontalStack = UIStackView()
    private let verticalStack = UIStackView()
    private let scrollView = UIScrollView()

    // MARK: - View Life Cycle
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Configuration

private extension WidgetsVC {
    private func configure() {
        title = "Widgets"
        navigationItem.title = "Widgets"
        accountBalanceWidget.image = R.image.actbalsmall()
        accountBalanceWidget.clipsToBounds = true
        accountBalanceWidget.width(150)
        accountBalanceWidget.height(150)
        latestTransactionWidget.image = R.image.lttrnssmall()
        latestTransactionWidget.clipsToBounds = true
        latestTransactionWidget.width(150)
        latestTransactionWidget.height(150)
        horizontalStack.translatesAutoresizingMaskIntoConstraints = false
        horizontalStack.addArrangedSubview(accountBalanceWidget)
        horizontalStack.addArrangedSubview(latestTransactionWidget)
        horizontalStack.spacing = 20
        instructionTitle.translatesAutoresizingMaskIntoConstraints = false
        instructionTitle.textAlignment = .center
        instructionTitle.textColor = R.color.accentColour()
        instructionTitle.font = R.font.circularStdBold(size: 23)
        instructionTitle.text = "Adding a Widget"
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel.textAlignment = .left
        instructionLabel.font = R.font.circularStdBook(size: UIFont.labelFontSize)
        instructionLabel.numberOfLines = 0
        instructionLabel.text = "1. Long-press an empty area on your Home Screen until the apps jiggle.\n\n2. Tap the plus button in the upper-right corner to bring up the widget picker.\n\n3. Find Provenance in the list.\n\n4. Tap the Add Widget button or drag the widget to the desired spot on your Home Screen."
        view.addSubview(scrollView)
        scrollView.edgesToSuperview()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.addSubview(verticalStack)
        verticalStack.edges(to: scrollView, insets: .horizontal(16) + .vertical(13))
        verticalStack.width(to: scrollView, offset: -32)
        verticalStack.addArrangedSubview(horizontalStack)
        verticalStack.addArrangedSubview(instructionTitle)
        verticalStack.addArrangedSubview(instructionLabel)
        verticalStack.axis = .vertical
        verticalStack.alignment = .center
        verticalStack.setCustomSpacing(30, after: horizontalStack)
        verticalStack.setCustomSpacing(5, after: instructionTitle)
    }
}
