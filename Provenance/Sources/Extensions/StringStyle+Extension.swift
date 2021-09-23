import BonMot

typealias StringStyle = BonMot.StringStyle

extension StringStyle {
  static var provenance: StringStyle {
    return StringStyle(
      .font(.circularStdBook(size: .labelFontSize)),
      .color(.label),
      .alignment(.left)
    )
  }
  
  static var transactionDescription: StringStyle {
    return StringStyle(
      .font(.circularStdBold(size: .labelFontSize)),
      .color(.label),
      .alignment(.left)
    )
  }
  
  static var transactionCreationDate: StringStyle {
    return StringStyle(
      .font(.circularStdBookItalic(size: .smallSystemFontSize)),
      .color(.secondaryLabel),
      .alignment(.left)
    )
  }
  
  static var transactionAmount: StringStyle {
    return StringStyle(
      .font(.circularStdBook(size: .labelFontSize)),
      .color(.label),
      .alignment(.right)
    )
  }
  
  static var accountBalance: StringStyle {
    return StringStyle(
      .font(.circularStdBold(size: 32)),
      .color(.accentColor),
      .alignment(.center)
    )
  }
  
  static var accountDisplayName: StringStyle {
    return StringStyle(
      .font(.circularStdBook(size: .labelFontSize)),
      .color(.label),
      .alignment(.center)
    )
  }
  
  static var categoryName: StringStyle {
    return StringStyle(
      .font(.circularStdBook(size: .labelFontSize)),
      .color(.label),
      .alignment(.center)
    )
  }
  
  static var aboutName: StringStyle {
    return StringStyle(
      .font(.circularStdBold(size: 32)),
      .color(.label),
      .alignment(.center)
    )
  }
  
  static var aboutDescription: StringStyle {
    return StringStyle(
      .font(.circularStdBook(size: .labelFontSize)),
      .color(.secondaryLabel),
      .alignment(.left)
    )
  }
  
  static var leftText: StringStyle {
    return StringStyle(
      .font(.circularStdMedium(size: .labelFontSize)),
      .color(.label),
      .alignment(.left)
    )
  }
  
  static var rightText: StringStyle {
    return StringStyle(
      .font(.circularStdBook(size: .labelFontSize)),
      .color(.secondaryLabel),
      .alignment(.right)
    )
  }
  
  static var bottomText: StringStyle {
    return StringStyle(
      .font(.circularStdBook(size: .smallSystemFontSize)),
      .color(.secondaryLabel),
      .alignment(.left)
    )
  }
  
  static var addingWidgetTitle: StringStyle {
    return StringStyle(
      .font(.circularStdBold(size: 23)),
      .color(.accentColor),
      .alignment(.center)
    )
  }
}
