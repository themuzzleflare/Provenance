import UIKit
import SnapKit
import MBProgressHUD
import BonMot

extension UIView {
  static func loading(frame: CGRect, contentType: ContentType) -> UIView {
    let view = UIView(frame: frame)
    let hud = MBProgressHUD(view: view, animationType: .zoomIn)
    hud.label.attributedText = contentType.loadingDescription.styled(with: .provenance)
    view.addSubview(hud)
    hud.show(animated: true)
    return view
  }

  static func noContent(frame: CGRect, type: ContentType) -> UIView {
    let view = UIView(frame: frame)
    let icon = UIImageView(image: .xmarkDiamond)
    icon.snp.makeConstraints { (make) in
      make.width.equalTo(70)
      make.height.equalTo(64)
    }
    icon.tintColor = .secondaryLabel
    let label = UILabel()
    label.textAlignment = .center
    label.textColor = .secondaryLabel
    label.font = .circularStdMedium(size: 23)
    label.text = type.noContentDescription
    let verticalStack = UIStackView(arrangedSubviews: [icon, label])
    view.addSubview(verticalStack)
    verticalStack.snp.makeConstraints { (make) in
      make.center.equalToSuperview()
    }
    verticalStack.axis = .vertical
    verticalStack.alignment = .center
    verticalStack.spacing = 10
    return view
  }

  static func error(frame: CGRect, text: String) -> UIView {
    let view = UIView(frame: frame)
    let label = UILabel()
    view.addSubview(label)
    label.snp.makeConstraints { (make) in
      make.left.right.equalToSuperview().inset(16)
      make.center.equalToSuperview()
    }
    label.textAlignment = .center
    label.textColor = .secondaryLabel
    label.font = .circularStdBook(size: .labelFontSize)
    label.numberOfLines = 0
    label.text = text
    return view
  }

  static func accountTransactionsHeader(frame: CGRect, account: AccountResource) -> UIView {
    let view = UIView(frame: CGRect(x: 0, y: 0, width: frame.width, height: 117))
    let balanceLabel = UILabel()
    let displayNameLabel = UILabel()
    let verticalStack = UIStackView(arrangedSubviews: [balanceLabel, displayNameLabel])
    view.addSubview(verticalStack)
    verticalStack.snp.makeConstraints { (make) in
      make.left.right.equalToSuperview().inset(16)
      make.center.equalToSuperview()
    }
    verticalStack.axis = .vertical
    verticalStack.alignment = .center
    balanceLabel.textColor = .accentColor
    balanceLabel.font = .circularStdBold(size: 32)
    balanceLabel.textAlignment = .center
    balanceLabel.numberOfLines = 0
    balanceLabel.text = account.attributes.balance.valueShort
    displayNameLabel.textColor = .secondaryLabel
    displayNameLabel.font = .circularStdBook(size: 14)
    displayNameLabel.textAlignment = .center
    displayNameLabel.numberOfLines = 0
    displayNameLabel.text = account.attributes.displayName
    return view
  }
}
