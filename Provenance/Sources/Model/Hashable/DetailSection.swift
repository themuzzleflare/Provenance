import Foundation

struct DetailSection {
  let id: Int
  let items: [DetailItem]
}

// MARK: - Hashable

extension DetailSection: Hashable {
  static func == (lhs: DetailSection, rhs: DetailSection) -> Bool {
    return lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

// MARK: -

extension Array where Element == DetailSection {
  static func transactionDetail(transaction: TransactionResource,
                                account: AccountResource?,
                                transferAccount: AccountResource?,
                                parentCategory: CategoryResource?,
                                category: CategoryResource?) -> [DetailSection] {
    return [
      DetailSection(
        id: 1,
        items: [
          DetailItem(
            id: "Status",
            value: transaction.attributes.status.description
          ),
          DetailItem(
            id: "Account",
            value: account?.attributes.displayName ?? ""
          ),
          DetailItem(
            id: "Transfer Account",
            value: transferAccount?.attributes.displayName ?? ""
          )
        ]
      ),
      DetailSection(
        id: 2,
        items: [
          DetailItem(
            id: "Description",
            value: transaction.attributes.description
          ),
          DetailItem(
            id: "Raw Text",
            value: transaction.attributes.rawText ?? ""
          ),
          DetailItem(
            id: "Message",
            value: transaction.attributes.message ?? ""
          )
        ]
      ),
      DetailSection(
        id: 3,
        items: [
          DetailItem(
            id: "Hold \(transaction.attributes.holdInfo?.amount.transactionType.description ?? TransactionAmountType.amount.description)",
            value: transaction.attributes.holdValue
          ),
          DetailItem(
            id: "Hold Foreign \(transaction.attributes.holdInfo?.foreignAmount?.transactionType.description ?? TransactionAmountType.amount.description)",
            value: transaction.attributes.holdForeignValue
          ),
          DetailItem(
            id: "Foreign \(transaction.attributes.foreignAmount?.transactionType.description ?? TransactionAmountType.amount.description)",
            value: transaction.attributes.foreignValue
          ),
          DetailItem(
            id: transaction.attributes.amount.transactionType.description,
            value: transaction.attributes.amount.valueLong
          )
        ]
      ),
      DetailSection(
        id: 4,
        items: [
          DetailItem(
            id: "Creation Date",
            value: transaction.attributes.creationDate
          ),
          DetailItem(
            id: "Settlement Date",
            value: transaction.attributes.settlementDate ?? ""
          )
        ]
      ),
      DetailSection(
        id: 5,
        items: [
          DetailItem(
            id: "Parent Category",
            value: parentCategory?.attributes.name ?? ""
          ),
          DetailItem(
            id: "Category",
            value: category?.attributes.name ?? ""
          )
        ]
      ),
      DetailSection(
        id: 6,
        items: [
          DetailItem(
            id: "Tags",
            value: transaction.relationships.tags.data.count.description
          )
        ]
      )
    ]
  }

  static func accountDetail(account: AccountResource, transaction: TransactionResource?) -> [DetailSection] {
    return [
      DetailSection(
        id: 1,
        items: [
          DetailItem(
            id: "Account Balance",
            value: account.attributes.balance.valueLong
          ),
          DetailItem(
            id: "Latest Transaction",
            value: transaction?.attributes.description ?? ""
          )
        ]
      ),
      DetailSection(
        id: 2,
        items: [
          DetailItem(
            id: "Account ID",
            value: account.id
          ),
          DetailItem(
            id: "Account Type",
            value: account.attributes.accountType.description
          ),
          DetailItem(
            id: "Ownership Type",
            value: account.attributes.ownershipType.description
          ),
          DetailItem(
            id: "Creation Date",
            value: account.attributes.creationDate
          )
        ]
      )
    ]
  }

  static var diagnostics: [DetailSection] {
    return [
      DetailSection(
        id: 1,
        items: [
          DetailItem(
            id: "Version",
            value: Store.provenance.appVersion
          ),
          DetailItem(
            id: "Build",
            value: Store.provenance.appBuild
          )
        ]
      )
    ]
  }

  var filtered: [DetailSection] {
    return self.filter { (section) in
      return !section.items.allSatisfy { (item) in
        return item.value.isEmpty || (item.id == "Tags" && item.value == "0")
      }
    }.map { (section) in
      return DetailSection(id: section.id, items: section.items.filter { (item) in
        return !item.value.isEmpty
      })
    }
  }
}
