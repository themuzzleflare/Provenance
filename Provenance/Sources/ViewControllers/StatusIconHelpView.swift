import UIKit
import SnapKit

final class StatusIconHelpView: ViewController {
  // MARK: - Properties

  private let configuration = UIImage.SymbolConfiguration(pointSize: 21)
  private let verticalStack = UIStackView()
  private let heldStack = UIStackView()
  private let settledStack = UIStackView()
  private let heldImage = UIImageView()
  private let settledImage = UIImageView()
  private let heldLabel = UILabel()
  private let settledLabel = UILabel()

  // MARK: - Life Cycle

  override func viewDidLoad() {
    super.viewDidLoad()
    configure()
  }
}

// MARK: - Configuration

private extension StatusIconHelpView {
  private func configure() {
    title = "Transaction Status Icons"
    navigationItem.title = "Transaction Status Icons"
    navigationItem.largeTitleDisplayMode = .never
    navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeWorkflow))
    view.addSubview(verticalStack)
    verticalStack.snp.makeConstraints { (make) in
      make.center.equalToSuperview()
    }
    verticalStack.addArrangedSubview(heldStack)
    verticalStack.addArrangedSubview(settledStack)
    verticalStack.axis = .vertical
    verticalStack.alignment = .center
    verticalStack.spacing = 15
    heldStack.addArrangedSubview(heldImage)
    heldStack.addArrangedSubview(heldLabel)
    heldStack.alignment = .center
    heldStack.spacing = 5
    heldImage.image = .clock.withConfiguration(configuration)
    heldImage.tintColor = .systemYellow
    heldLabel.font = .circularStdMedium(size: 23)
    heldLabel.text = "Held"
    settledStack.addArrangedSubview(settledImage)
    settledStack.addArrangedSubview(settledLabel)
    settledStack.alignment = .center
    settledStack.spacing = 5
    settledImage.image = .checkmarkCircle.withConfiguration(configuration)
    settledImage.tintColor = .systemGreen
    settledLabel.font = .circularStdMedium(size: 23)
    settledLabel.text = "Settled"
  }
}

// MARK: - Actions

private extension StatusIconHelpView {
  @objc private func closeWorkflow() {
    navigationController?.dismiss(animated: true)
  }
}
