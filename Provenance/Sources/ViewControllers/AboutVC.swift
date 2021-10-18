import AsyncDisplayKit

final class AboutVC: ASViewController {
  // MARK: - Properties
  
  private let tableNode = ASTableNode(style: .grouped)
  
  // MARK: - Life Cycle
  
  override init() {
    super.init(node: tableNode)
  }
  
  deinit {
    print("deinit")
  }
  
  required init?(coder: NSCoder) {
    fatalError("Not implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    configureSelf()
    configureNavigation()
    configureTableNode()
  }
}

// MARK: - Configuration

private extension AboutVC {
  private func configureSelf() {
    title = "About"
  }
  
  private func configureNavigation() {
    navigationItem.title = "About"
    navigationItem.largeTitleDisplayMode = .never
    navigationItem.backBarButtonItem = .infoCircle
    navigationItem.leftBarButtonItem = .openDiagnostics(self, action: #selector(openDiagnostics))
    navigationItem.rightBarButtonItem = .openSettings(self, action: #selector(openSettings))
  }
  
  private func configureTableNode() {
    tableNode.dataSource = self
    tableNode.delegate = self
    tableNode.view.showsVerticalScrollIndicator = false
  }
}

// MARK: - Actions

private extension AboutVC {
  @objc private func openSettings() {
    let viewController = NavigationController(rootViewController: .settings)
    present(viewController, animated: true)
  }
  
  @objc private func openDiagnostics() {
    let viewController = NavigationController(rootViewController: .diagnostics)
    present(viewController, animated: true)
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
          return .aboutTop
        case 1:
          return RightDetailCellNode(text: "Version", detailText: ProvenanceApp.userDefaults.appVersion)
        case 2:
          return RightDetailCellNode(text: "Build", detailText: ProvenanceApp.userDefaults.appBuild)
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
        navigationController?.pushViewController(.widgets, animated: true)
      case 1:
        navigationController?.pushViewController(.stickers, animated: true)
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
        return ProvenanceApp.userDefaults.appVersion == "Unknown" ? nil : UIContextMenuConfiguration(elements: [
          .copyGeneric(title: "Version", string: ProvenanceApp.userDefaults.appVersion)
        ])
      case 2:
        return ProvenanceApp.userDefaults.appBuild == "Unknown" ? nil : UIContextMenuConfiguration(elements: [
          .copyGeneric(title: "Build", string: ProvenanceApp.userDefaults.appBuild)
        ])
      default:
        return nil
      }
    case 2:
      switch row {
      case 0:
        return UIContextMenuConfiguration(elements: [
          .copyGeneric(title: "Email", string: "feedback@tavitian.cloud")
        ])
      case 1:
        return UIContextMenuConfiguration(elements: [
          .copyGeneric(title: "Link", string: "https://github.com/themuzzleflare/Provenance")
        ])
      default:
        return nil
      }
    default:
      return nil
    }
  }
}
