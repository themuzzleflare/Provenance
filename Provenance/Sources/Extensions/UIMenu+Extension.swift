import Foundation
import UIKit

extension UIMenu {
  static func transactionsFilterMenu(filter: CategoryFilter, showSettledOnly: Bool, completion: @escaping (FilterMenuAction) -> Void) -> UIMenu {
    return UIMenu(children: [
      UIMenu(
        title: "Category",
        image: filter == .all ? .trayFull : .trayFullFill,
        children: CategoryFilter.allCases.map { (category) in
          UIAction(
            title: category.name,
            state: filter == category ? .on : .off,
            handler: { (_) in
              completion(.category(category))
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
