import UIKit
import AsyncDisplayKit

final class AboutVC: ASViewController {
  // MARK: - Properties

  private let tableNode = ASTableNode(style: .grouped)

  // MARK: - Life Cycle

  override init() {
    super.init(node: tableNode)
  }

  required init?(coder: NSCoder) {
    fatalError("Not implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    configure()
  }
}

// MARK: - Configuration

private extension AboutVC {
  private func configure() {
    title = "About"
    navigationItem.title = "About"
    navigationItem.largeTitleDisplayMode = .never
    navigationItem.backBarButtonItem = UIBarButtonItem(image: .infoCircle)
    navigationItem.leftBarButtonItem = UIBarButtonItem(image: .chevronLeftSlashChevronRight, style: .plain, target: self, action: #selector(openDiagnostics))
    navigationItem.rightBarButtonItem = UIBarButtonItem(image: .gear, style: .plain, target: self, action: #selector(openSettings))
    tableNode.dataSource = self
    tableNode.delegate = self
    tableNode.view.showsVerticalScrollIndicator = false
  }
}

// MARK: - Actions

private extension AboutVC {
  @objc private func openSettings() {
    present(NavigationController(rootViewController: SettingsVC()), animated: true)
  }

  @objc private func openDiagnostics() {
    present(NavigationController(rootViewController: DiagnosticTableVC()), animated: true)
  }
}

// MARK: - ASTableDataSource

extension AboutVC: ASTableDataSource {
  func numberOfSections(in tableNode: ASTableNode) -> Int {
    return 3
  }

  func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
    switch section {
    case 0:
      return 3
    case 1:
      return 2
    case 2:
      return 2
    default:
      fatalError("Unknown section")
    }
  }

  func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
    let section = indexPath.section
    let row = indexPath.row
    let cell = ASTextCellNode(alignment: .leftAligned)
    return {
      switch section {
      case 0:
        switch row {
        case 0:
          return AboutTopCellNode()
        case 1:
          return RightDetailCellNode(text: "Version", detailText: appDefaults.appVersion)
        case 2:
          return RightDetailCellNode(text: "Build", detailText: appDefaults.appBuild)
        default:
          fatalError("Unknown row")
        }
      case 1:
        cell.accessoryType = .disclosureIndicator
        switch row {
        case 0:
          cell.text = "Widgets"
          return cell
        case 1:
          cell.text = "Stickers"
          return cell
        default:
          fatalError("Unknown row")
        }
      case 2:
        cell.accessoryType = .none
        switch row {
        case 0:
          cell.text = "Contact Developer"
          return cell
        case 1:
          cell.text = "GitHub"
          return cell
        default:
          fatalError("Unknown row")
        }
      default:
        fatalError("Unknown section")
      }
    }
  }

  func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
    switch section {
    case 2:
      return InfoPlist.nsHumanReadableCopyright
    default:
      return nil
    }
  }
}

// MARK: - ASTableDelegate

extension AboutVC: ASTableDelegate {
  func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
    let section = indexPath.section
    let row = indexPath.row
    switch section {
    case 1:
      tableNode.deselectRow(at: indexPath, animated: true)
      switch row {
      case 0:
        navigationController?.pushViewController(WidgetsVC(), animated: true)
      case 1:
        navigationController?.pushViewController(StickersVC(), animated: true)
      default:
        break
      }
    case 2:
      tableNode.deselectRow(at: indexPath, animated: true)
      switch row {
      case 0:
        UIApplication.shared.open(.feedback)
      case 1:
        UIApplication.shared.open(.github)
      default:
        break
      }
    default:
      break
    }
  }

  func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
    let section = indexPath.section
    let row = indexPath.row
    switch section {
    case 0:
      switch row {
      case 1:
        switch appDefaults.appVersion {
        case "Unknown":
          return nil
        default:
          return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { (_) in
            UIMenu(children: [
              UIAction(title: "Copy Version", image: .docOnClipboard) { (_) in
                UIPasteboard.general.string = appDefaults.appVersion
              }
            ])
          }
        }
      case 2:
        switch appDefaults.appBuild {
        case "Unknown":
          return nil
        default:
          return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { (_) in
            UIMenu(children: [
              UIAction(title: "Copy Build", image: .docOnClipboard) { (_) in
                UIPasteboard.general.string = appDefaults.appBuild
              }
            ])
          }
        }
      default:
        return nil
      }
    case 2:
      switch row {
      case 0:
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { (_) in
          UIMenu(children: [
            UIAction(title: "Copy Email", image: .docOnClipboard) { (_) in
              UIPasteboard.general.string = "feedback@tavitian.cloud"
            }
          ])
        }
      case 1:
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { (_) in
          UIMenu(children: [
            UIAction(title: "Copy Link", image: .docOnClipboard) { (_) in
              UIPasteboard.general.string = "https://github.com/themuzzleflare/Provenance"
            }
          ])
        }
      default:
        return nil
      }
    default:
      return nil
    }
  }
}
