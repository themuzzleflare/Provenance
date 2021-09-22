import Foundation

struct TransactionRelationship: Codable {
  var account: TransactionRelationshipAccount
  
  var transferAccount: TransactionRelationshipTransferAccount
  
  var category: TransactionRelationshipCategory
  
  var parentCategory: TransactionRelationshipCategory
  
  var tags: TransactionRelationshipTag
}
