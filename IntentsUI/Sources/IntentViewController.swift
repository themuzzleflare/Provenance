import IntentsUI

final class IntentViewController: UIViewController {
  private var transactions = [TransactionType]()
  
  private let tableView = UITableView(frame: .zero, style: .plain)
  
  override func viewDidLoad() {
    super.viewDidLoad()
    view.addSubview(tableView)
    configureTableView()
  }
  
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    tableView.frame = view.bounds
  }
  
  private func configureTableView() {
    tableView.dataSource = self
    tableView.delegate = self
    tableView.register(TransactionCell.self, forCellReuseIdentifier: TransactionCell.reuseIdentifier)
    tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    tableView.separatorInset = .zero
    tableView.showsVerticalScrollIndicator = false
  }
}

extension IntentViewController: INUIHostedViewControlling {
  func configureView(for parameters: Set<INParameter>, of interaction: INInteraction, interactiveBehavior: INUIInteractiveBehavior, context: INUIHostedViewContext, completion: @escaping (Bool, Set<INParameter>, CGSize) -> Void) {
    guard let response = interaction.intentResponse as? ListTransactionsIntentResponse, let responseTransactions = response.transactions else {
      completion(false, Set(), .zero)
      return
    }
    self.transactions = responseTransactions
    completion(true, parameters, self.desiredSize)
  }
  
  var desiredSize: CGSize {
    return self.extensionContext!.hostedViewMaximumAllowedSize
  }
}

extension IntentViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return transactions.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: TransactionCell.reuseIdentifier, for: indexPath) as? TransactionCell else {
      fatalError("Unable to dequeue reusable cell with identifier: \(TransactionCell.reuseIdentifier)")
    }
    let transaction = transactions[indexPath.row]
    cell.transaction = transaction
    return cell
  }
}

extension IntentViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return UITableView.automaticDimension
  }
}
