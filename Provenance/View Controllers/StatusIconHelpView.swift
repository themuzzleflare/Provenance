import UIKit
import TinyConstraints
import Rswift

class StatusIconHelpView: ViewController {
    // MARK: - Properties

    private let configuration = UIImage.SymbolConfiguration(pointSize: 21)
    private let verticalStack = UIStackView()
    private let heldStack = UIStackView()
    private let settledStack = UIStackView()
    private let heldImage = UIImageView()
    private let settledImage = UIImageView()
    private let heldLabel = UILabel()
    private let settledLabel = UILabel()

    // MARK: - View Life Cycle

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        configure()
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }
}

// MARK: - Configuration

private extension StatusIconHelpView {
    private func configure() {
        title = "Transaction Status Icons"
        navigationItem.title = "Transaction Status Icons"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeWorkflow))
        view.addSubview(verticalStack)
        verticalStack.edges(to: view, excluding: [.top, .bottom, .leading, .trailing], insets: .horizontal(16))
        verticalStack.center(in: view)
        verticalStack.addArrangedSubview(heldStack)
        verticalStack.addArrangedSubview(settledStack)
        verticalStack.axis = .vertical
        verticalStack.alignment = .center
        verticalStack.spacing = 15
        heldStack.translatesAutoresizingMaskIntoConstraints = false
        heldStack.addArrangedSubview(heldImage)
        heldStack.addArrangedSubview(heldLabel)
        heldStack.alignment = .center
        heldStack.spacing = 5
        heldImage.translatesAutoresizingMaskIntoConstraints = false
        heldImage.image = R.image.clock()?.withConfiguration(configuration)
        heldImage.tintColor = .systemYellow
        heldLabel.translatesAutoresizingMaskIntoConstraints = false
        heldLabel.font = R.font.circularStdMedium(size: 23)
        heldLabel.text = "Held"
        settledStack.translatesAutoresizingMaskIntoConstraints = false
        settledStack.addArrangedSubview(settledImage)
        settledStack.addArrangedSubview(settledLabel)
        settledStack.alignment = .center
        settledStack.spacing = 5
        settledImage.translatesAutoresizingMaskIntoConstraints = false
        settledImage.image = R.image.checkmarkCircle()?.withConfiguration(configuration)
        settledImage.tintColor = .systemGreen
        settledLabel.translatesAutoresizingMaskIntoConstraints = false
        settledLabel.font = R.font.circularStdMedium(size: 23)
        settledLabel.text = "Settled"
    }
}

// MARK: - Actions

private extension StatusIconHelpView {
    @objc private func closeWorkflow() {
        navigationController?.dismiss(animated: true)
    }
}
