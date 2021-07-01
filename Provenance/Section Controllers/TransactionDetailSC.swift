import UIKit
import IGListKit
import Rswift

final class TransactionDetailSC: ListSectionController {
    private var model: Section!

    var transaction: TransactionResource!
    var account: AccountResource?
    var transferAccount: AccountResource?
    var parentCategory: CategoryResource?
    var category: CategoryResource?

    override init() {
        super.init()
        inset = UIEdgeInsets(top: 0, left: 0, bottom: 40, right: 0)
    }

    override func numberOfItems() -> Int {
        model.detailAttributes.count
    }

    override func sizeForItem(at index: Int) -> CGSize {
        CGSize(width: collectionContext!.containerSize.width, height: 100)
    }

    override func cellForItem(at index: Int) -> UICollectionViewCell {
        let cell = collectionContext?.dequeueReusableCell(
            of: AttributeCollectionViewCell.self,
            for: self,
            at: index
        ) as! AttributeCollectionViewCell

        let attribute = model.detailAttributes[index]

        cell.leftLabel.text = attribute.key
        cell.rightLabel.font = attribute.key == "Raw Text" ? R.font.sfMonoRegular(size: UIFont.labelFontSize)! : R.font.circularStdBook(size: UIFont.labelFontSize)!
        cell.rightLabel.text = attribute.value
        
        return cell
    }

    override func didUpdate(to object: Any) {
        self.model = object as? Section
    }

    override func didSelectItem(at index: Int) {
        let attribute = model.detailAttributes[index]

        collectionContext?.deselectItem(at: index, sectionController: self, animated: true)

        switch attribute.key {
            case "Account":
                let vc = TransactionsByAccountVC()

                vc.account = account
                
                viewController?.navigationController?.pushViewController(vc, animated: true)
            case "Transfer Account":
                let vc = TransactionsByAccountVC()

                vc.account = transferAccount
                
                viewController?.navigationController?.pushViewController(vc, animated: true)
            case "Parent Category", "Category":
                let vc = TransactionsByCategoryVC()
                
                switch attribute.key {
                    case "Parent Category":
                        vc.category = parentCategory
                    case "Category":
                        vc.category = category
                    default:
                        break
                }

                viewController?.navigationController?.pushViewController(vc, animated: true)
            case "Tags":
                let vc = TagsCVC()

                vc.transaction = transaction

                viewController?.navigationController?.pushViewController(vc, animated: true)
            default:
                break
        }
    }
}
