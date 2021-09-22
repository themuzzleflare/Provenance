import Foundation
import SwiftDate

class TransactionAttribute: Codable {
  let creationDate: String
  
    /// The current processing status of this transaction, according to whether or not this transaction has settled or is still held.
  let status: TransactionStatusEnum
  
    /// The original, unprocessed text of the transaction. This is often not a perfect indicator of the actual merchant, but it is useful for reconciliation purposes in some cases.
  let rawText: String?
  
    /// A short description for this transaction. Usually the merchant name for purchases.
  let description: String
  
    /// Attached message for this transaction, such as a payment message, or a transfer note.
  let message: String?
  
    /// If this transaction is currently in the HELD status, or was ever in the HELD status, the amount and foreignAmount of the transaction while HELD.
  let holdInfo: HoldInfoObject?
  
    /// Details of how this transaction was rounded-up. If no Round Up was applied this field will be null.
  let roundUp: RoundUpObject?
  
    /// If all or part of this transaction was instantly reimbursed in the form of cashback, details of the reimbursement.
  let cashback: CashbackObject?
  
    /// The amount of this transaction in Australian dollars. For transactions that were once HELD but are now SETTLED, refer to the holdInfo field for the original amount the transaction was HELD at.
  let amount: MoneyObject
  
    /// The foreign currency amount of this transaction. This field will be null for domestic transactions. The amount was converted to the AUD amount reflected in the amount of this transaction. Refer to the holdInfo field for the original foreignAmount the transaction was HELD at.
  let foreignAmount: MoneyObject?
  
    /// The date-time at which this transaction settled. This field will be null for transactions that are currently in the HELD status.
  let settledAt: String?
  
    /// The date-time at which this transaction was first encountered.
  let createdAt: String
  
  enum CodingKeys: String, CodingKey {
    case status
    case rawText
    case description
    case message
    case holdInfo
    case roundUp
    case cashback
    case amount
    case foreignAmount
    case settledAt
    case createdAt
  }
  
  required init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    status = try values.decode(TransactionStatusEnum.self, forKey: .status)
    rawText = try values.decodeIfPresent(String.self, forKey: .rawText)
    description = try values.decode(String.self, forKey: .description)
    message = try values.decodeIfPresent(String.self, forKey: .message)
    holdInfo = try values.decodeIfPresent(HoldInfoObject.self, forKey: .holdInfo)
    roundUp = try values.decodeIfPresent(RoundUpObject.self, forKey: .roundUp)
    cashback = try values.decodeIfPresent(CashbackObject.self, forKey: .cashback)
    amount = try values.decode(MoneyObject.self, forKey: .amount)
    foreignAmount = try values.decodeIfPresent(MoneyObject.self, forKey: .foreignAmount)
    settledAt = try values.decodeIfPresent(String.self, forKey: .settledAt)
    createdAt = try values.decode(String.self, forKey: .createdAt)
    creationDate = ProvenanceApp.formatDate(for: createdAt, dateStyle: ProvenanceApp.userDefaults.appDateStyle)
  }
}

extension TransactionAttribute {
  var createdAtDateComponents: DateComponents? {
    return createdAt.toDate()?.dateComponents
  }
  
  var settledAtDateComponents: DateComponents? {
    return settledAt?.toDate()?.dateComponents
  }
  
  var settlementDate: String? {
    if let settledAt = settledAt {
      return ProvenanceApp.formatDate(for: settledAt, dateStyle: ProvenanceApp.userDefaults.appDateStyle)
    } else {
      return nil
    }
  }
  
  var holdValue: String {
    guard let holdInfo = holdInfo, holdInfo.amount.value != amount.value else {
      return .emptyString
    }
    return holdInfo.amount.valueLong
  }
  
  var holdForeignValue: String {
    guard let holdForeignAmount = holdInfo?.foreignAmount, holdForeignAmount.value != foreignAmount?.value else {
      return .emptyString
    }
    return holdForeignAmount.valueLong
  }
  
  var foreignValue: String {
    if let foreignAmount = foreignAmount {
      return foreignAmount.valueLong
    } else {
      return .emptyString
    }
  }
}
