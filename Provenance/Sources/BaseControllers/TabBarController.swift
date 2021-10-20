import AsyncDisplayKit

final class TabBarController: ASTabBarController {
  override func viewDidLoad() {
    super.viewDidLoad()
    setViewControllers(TabBarItem.defaultTabs, animated: false)
  }

  override func restoreUserActivityState(_ activity: NSUserActivity) {
    super.restoreUserActivityState(activity)
    guard activity.activityType == NSUserActivity.addedTagsToTransaction.activityType, let intentResponse = activity.interaction?.intentResponse as? AddTagToTransactionIntentResponse, let transaction = intentResponse.transaction?.identifier else { return }
    Up.retrieveTransaction(for: transaction) { (result) in
      DispatchQueue.main.async {
        switch result {
        case let .success(transaction):
          if let navigationController = self.selectedViewController as? NavigationController {
            let viewController = TransactionTagsVC(transaction: transaction)
            navigationController.pushViewController(viewController, animated: true)
          }
        case .failure:
          break
        }
      }
    }
  }
}
