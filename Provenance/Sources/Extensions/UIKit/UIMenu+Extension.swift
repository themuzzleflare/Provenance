import UIKit

extension UIMenu {
  static func transactionsFilterMenu(categoryFilter: TransactionCategory, groupingFilter: TransactionGroupingEnum, showSettledOnly: Bool, completion: @escaping (FilterMenuAction) -> Void) -> UIMenu {
    return UIMenu(children: [
      UIMenu(
        title: "Category",
        image: categoryFilter == .all ? .trayFull : .trayFullFill,
        children: TransactionCategory.allCases.map { (category) in
          UIAction(
            title: category.name,
            state: categoryFilter == category ? .on : .off,
            handler: { (_) in
              completion(.category(category))
            }
          )
        }
      ),
      UIMenu(
        title: "Grouping",
        image: groupingFilter == .all ? .squareStack : .squareStackFill,
        children: TransactionGroupingEnum.allCases.map { (grouping) in
          UIAction(
            title: grouping.description,
            state: groupingFilter == grouping ? .on : .off,
            handler: { (_) in
              completion(.grouping(grouping))
            }
          )
        }
      ),
      UIAction(
        title: "Settled Only",
        image: showSettledOnly ? .checkmarkCircleFill : .checkmarkCircle,
        state: showSettledOnly ? .on : .off,
        handler: { (_) in
          completion(.settledOnly(!showSettledOnly))
        }
      )
    ])
  }
}
