import Foundation
import UIKit
import BonMot

typealias StringStyle = BonMot.StringStyle

extension StringStyle {
  static let provenance = StringStyle(
    .font(.circularStdBook(size: .labelFontSize)),
    .color(.label),
    .alignment(.left)
  )

  static let transactionDescription = StringStyle(
    .font(.circularStdBold(size: .labelFontSize)),
    .color(.label),
    .alignment(.left)
  )

  static let transactionCreationDate = StringStyle(
    .font(.circularStdBook(size: .smallSystemFontSize)),
    .color(.secondaryLabel),
    .alignment(.left)
  )

  static let transactionAmount = StringStyle(
    .font(.circularStdBook(size: .labelFontSize)),
    .color(.label),
    .alignment(.right)
  )

  static let accountBalance = StringStyle(
    .font(.circularStdBold(size: 32)),
    .color(.accentColor),
    .alignment(.center)
  )

  static let accountDisplayName = StringStyle(
    .font(.circularStdBook(size: .labelFontSize)),
    .color(.label),
    .alignment(.center)
  )

  static let categoryName = StringStyle(
    .font(.circularStdBook(size: .labelFontSize)),
    .color(.label),
    .alignment(.center)
  )

  static let aboutName = StringStyle(
    .font(.circularStdBold(size: 32)),
    .color(.label),
    .alignment(.center)
  )

  static let aboutDescription = StringStyle(
    .font(.circularStdBook(size: .labelFontSize)),
    .color(.secondaryLabel),
    .alignment(.left)
  )

  static let leftText = StringStyle(
    .font(.circularStdMedium(size: .labelFontSize)),
    .color(.label),
    .alignment(.left)
  )

  static let rightText = StringStyle(
    .font(.circularStdBook(size: .labelFontSize)),
    .color(.secondaryLabel),
    .alignment(.right)
  )

  static let bottomText = StringStyle(
    .font(.circularStdBook(size: .smallSystemFontSize)),
    .color(.secondaryLabel),
    .alignment(.left)
  )

  static let addingWidgetTitle = StringStyle(
    .font(.circularStdBold(size: 23)),
    .color(.accentColor),
    .alignment(.center)
  )
}
