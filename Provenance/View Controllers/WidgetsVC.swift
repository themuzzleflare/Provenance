import UIKit
import TinyConstraints
import Rswift

class WidgetsVC: ViewController {
    let accountBalanceWidget = UIImageView()
    let latestTransactionWidget = UIImageView()
    let instructionTitle = UILabel()
    let instructionLabel = UILabel()
    let horizontalStack = UIStackView()
    let verticalStack = UIStackView()
    let scrollView = UIScrollView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
}

extension WidgetsVC {
    private func configure() {
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
        horizontalStack.axis = .horizontal
        horizontalStack.alignment = .fill
        horizontalStack.distribution = .fill
        horizontalStack.spacing = 20
        
        instructionTitle.translatesAutoresizingMaskIntoConstraints = false
        instructionTitle.textAlignment = .center
        instructionTitle.textColor = R.color.accentColor()
        instructionTitle.font = R.font.circularStdBold(size: 23)
        instructionTitle.numberOfLines = 1
        instructionTitle.text = "Adding a Widget"
        
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        instructionLabel.textAlignment = .left
        instructionLabel.textColor = .label
        instructionLabel.font = R.font.circularStdBook(size: UIFont.labelFontSize)
        instructionLabel.numberOfLines = 0
        instructionLabel.text = """
            1. Long-press an empty area on your Home Screen until the apps jiggle.

            2. Tap the plus button in the upper-left corner to bring up the widget picker.

            3. Find Provenance in the list.

            4. Tap the Add Widget button or drag the widget to the desired spot on your Home Screen.
            """
        
        view.addSubview(scrollView)
        
        scrollView.edgesToSuperview()
        scrollView.isScrollEnabled = true
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
        verticalStack.distribution = .fill
        verticalStack.setCustomSpacing(30, after: horizontalStack)
        verticalStack.setCustomSpacing(5, after: instructionTitle)
    }
}
