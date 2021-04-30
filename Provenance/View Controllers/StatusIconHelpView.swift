import UIKit
import TinyConstraints
import Rswift

class StatusIconHelpView: ViewController {
    let configuration = UIImage.SymbolConfiguration(pointSize: 21)
    let verticalStack = UIStackView()
    let heldStack = UIStackView()
    let settledStack = UIStackView()
    let heldImage = UIImageView()
    let settledImage = UIImageView()
    let heldLabel = UILabel()
    let settledLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
}

private extension StatusIconHelpView {
    @objc private func closeWorkflow() {
        navigationController?.dismiss(animated: true)
    }
    
    private func configure() {
        title = "Transaction Status Icons"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.title = "Transaction Status Icons"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeWorkflow))
        view.addSubview(verticalStack)
        verticalStack.edges(to: view, excluding: [.top, .bottom, .leading, .trailing], insets: .horizontal(16))
        verticalStack.center(in: view)
        verticalStack.addArrangedSubview(heldStack)
        verticalStack.addArrangedSubview(settledStack)
        verticalStack.axis = .vertical
        verticalStack.alignment = .center
        verticalStack.distribution = .fill
        verticalStack.spacing = 15
        heldStack.translatesAutoresizingMaskIntoConstraints = false
        heldStack.addArrangedSubview(heldImage)
        heldStack.addArrangedSubview(heldLabel)
        heldStack.axis = .horizontal
        heldStack.alignment = .center
        heldStack.distribution = .fill
        heldStack.spacing = 5
        heldImage.translatesAutoresizingMaskIntoConstraints = false
        heldImage.image = R.image.clock()?.withConfiguration(configuration)
        heldImage.tintColor = .systemYellow
        heldLabel.translatesAutoresizingMaskIntoConstraints = false
        heldLabel.font = R.font.proximaNovaRegular(size: 23)
        heldLabel.text = "Held"
        settledStack.translatesAutoresizingMaskIntoConstraints = false
        settledStack.addArrangedSubview(settledImage)
        settledStack.addArrangedSubview(settledLabel)
        settledStack.axis = .horizontal
        settledStack.alignment = .center
        settledStack.distribution = .fill
        settledStack.spacing = 5
        settledImage.translatesAutoresizingMaskIntoConstraints = false
        settledImage.image = R.image.checkmarkCircle()?.withConfiguration(configuration)
        settledImage.tintColor = .systemGreen
        settledLabel.translatesAutoresizingMaskIntoConstraints = false
        settledLabel.font = R.font.proximaNovaRegular(size: 23)
        settledLabel.text = "Settled"
    }
}