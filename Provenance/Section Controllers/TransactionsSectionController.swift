import UIKit
import IGListKit

class TransactionsSectionController: ListSectionController {
    private var object: TransactionResource?
    var accounts: [AccountResource]?
    var categories: [CategoryResource]?

    override func sizeForItem(at index: Int) -> CGSize {
        CGSize(width: collectionContext!.containerSize.width, height: 90)
    }

    override func cellForItem(at index: Int) -> UICollectionViewCell {
        let cell = collectionContext!.dequeueReusableCell(of: TransactionCollectionViewCell.self, for: self, at: index) as! TransactionCollectionViewCell
        cell.transaction = object
        return cell

    }

    override func didUpdate(to object: Any) {
        self.object = object as? TransactionResource
    }

    override func didSelectItem(at index: Int) {
        collectionContext?.deselectItem(at: index, sectionController: self, animated: true)
        let vc = TransactionDetailVC(style: .insetGrouped)
        vc.transaction = object
        vc.accounts = accounts
        vc.categories = categories
        viewController?.navigationController?.pushViewController(vc, animated: true)
    }
}
