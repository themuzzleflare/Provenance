import UIKit
import SwiftyBeaver
import TinyConstraints
import Rswift

final class WidgetsVC: ViewController {
    // MARK: - Properties

    private let accountBalanceWidget = UIImageView()
    private let latestTransactionWidget = UIImageView()

    private let instructionTitle = UILabel()
    private let instructionLabel = UILabel()

    private let horizontalStack = UIStackView()
    private let verticalStack = UIStackView()

    private let scrollView = UIScrollView()

    // MARK: - Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        log.debug("viewDidLoad")

        view.addSubview(scrollView)

        configure()
    }
}

// MARK: - Configuration

private extension WidgetsVC {
    private func configure() {
        log.verbose("configure")

        title = "Widgets"

        navigationItem.title = "Widgets"
        navigationItem.largeTitleDisplayMode = .never

        accountBalanceWidget.width(150)
        accountBalanceWidget.height(150)
        accountBalanceWidget.clipsToBounds = true
        accountBalanceWidget.image = R.image.actbalsmall()

        latestTransactionWidget.width(150)
        latestTransactionWidget.height(150)
        latestTransactionWidget.clipsToBounds = true
        latestTransactionWidget.image = R.image.lttrnssmall()

        horizontalStack.translatesAutoresizingMaskIntoConstraints = false
        horizontalStack.addArrangedSubview(accountBalanceWidget)
        horizontalStack.addArrangedSubview(latestTransactionWidget)
        horizontalStack.spacing = 20

        instructionTitle.translatesAutoresizingMaskIntoConstraints = false
        instructionTitle.textAlignment = .center
        instructionTitle.textColor = R.color.accentColor()
        instructionTitle.font = R.font.circularStdBold(size: 23)
        instructionTitle.text = "Adding a Widget"

        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel.textAlignment = .left
        instructionLabel.font = R.font.circularStdBook(size: UIFont.labelFontSize)
        instructionLabel.numberOfLines = 0
        instructionLabel.text = "1. Long-press an empty area on your Home Screen until the apps jiggle.\n\n2. Tap the plus button in the upper-right corner to bring up the widget picker.\n\n3. Find Provenance in the list.\n\n4. Tap the Add Widget button or drag the widget to the desired spot on your Home Screen."

        scrollView.edgesToSuperview()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        scrollView.addSubview(verticalStack)

        verticalStack.edges(
            to: scrollView,
            insets: .horizontal(16) + .vertical(13)
        )

        verticalStack.width(
            to: scrollView,
            offset: -32
        )

        verticalStack.addArrangedSubview(horizontalStack)
        verticalStack.addArrangedSubview(instructionTitle)
        verticalStack.addArrangedSubview(instructionLabel)
        verticalStack.axis = .vertical
        verticalStack.alignment = .center

        verticalStack.setCustomSpacing(
            30,
            after: horizontalStack
        )

        verticalStack.setCustomSpacing(
            5,
            after: instructionTitle
        )
    }
}
