import UIKit
import Rswift

class AboutViewController: TableViewController {
    @IBOutlet var appImage: UIImageView!
    @IBOutlet var appNameValue: UILabel!
    @IBOutlet var versionValue: UILabel!
    @IBOutlet var buildValue: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(self, selector: #selector(applicationDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)
        
        setProperties()
        setupNavigation()
        configureTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        for cell in tableView.visibleCells {
            if cell.isSelected {
                tableView.deselectRow(at: tableView.indexPath(for: cell)!, animated: true)
                if tableView.indexPath(for: cell)?.section == 2 {
                    tableView.cellForRow(at: tableView.indexPath(for: cell)!)?.imageView?.tintColor = R.color.accentColor()
                }
            }
        }
    }
}

extension AboutViewController {
    @objc private func applicationDidBecomeActive(notification: NSNotification) {
        for cell in tableView.visibleCells {
            if cell.isSelected {
                tableView.deselectRow(at: tableView.indexPath(for: cell)!, animated: true)
                if tableView.indexPath(for: cell)?.section == 2 {
                    tableView.cellForRow(at: tableView.indexPath(for: cell)!)?.imageView?.tintColor = R.color.accentColor()
                }
            }
        }
    }

    @objc private func openSettings() {
        present(NavigationController(rootViewController: SettingsVC(style: .grouped)), animated: true)
    }
    
    @objc private func openDiagnostics() {
        present(NavigationController(rootViewController: DiagnosticTableVC(style: .grouped)), animated: true)
    }
    
    private func setProperties() {
        title = "About"
        
        appImage.image = upAnimation
        appImage.clipsToBounds = true
        appImage.layer.cornerRadius = 20
        
        appNameValue.text = appName
        versionValue.text = appVersion
        buildValue.text = appBuild
    }
    
    private func setupNavigation() {
        navigationItem.title = "About"
        navigationItem.backBarButtonItem = UIBarButtonItem(image: R.image.infoCircle(), style: .plain, target: self, action: nil)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: R.image.chevronLeftSlashChevronRight(), style: .plain, target: self, action: #selector(openDiagnostics))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: R.image.gear(), style: .plain, target: self, action: #selector(openSettings))
    }

    private func configureTableView() {
        clearsSelectionOnViewWillAppear = false
    }
}

extension AboutViewController {
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let section = indexPath.section
        let row = indexPath.row

        if section == 0 {
            if row == 1 {
                if appVersion != "Unknown" {
                    return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                        UIMenu(children: [
                            UIAction(title: "Copy Version", image: R.image.docOnClipboard()) { _ in
                                UIPasteboard.general.string = appVersion
                            }
                        ])
                    }
                } else {
                    return nil
                }
            } else if row == 2 {
                if appBuild != "Unknown" {
                    return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                        UIMenu(children: [
                            UIAction(title: "Copy Build", image: R.image.docOnClipboard()) { _ in
                                UIPasteboard.general.string = appBuild
                            }
                        ])
                    }
                } else {
                    return nil
                }
            } else {
                return nil
            }
        } else if section == 2 {
            if row == 0 {
                return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                    UIMenu(children: [
                        UIAction(title: "Copy Email", image: R.image.docOnClipboard()) { _ in
                            UIPasteboard.general.string = "feedback@tavitian.cloud"
                        }
                    ])
                }
            } else {
                return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                    UIMenu(children: [
                        UIAction(title: "Copy Link", image: R.image.docOnClipboard()) { _ in
                            UIPasteboard.general.string = "https://github.com/themuzzleflare/Provenance"
                        }
                    ])
                }
            }
        } else {
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 2 {
            return appCopyright
        } else {
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if indexPath.section == 2 {
            tableView.cellForRow(at: indexPath)?.imageView?.tintColor = .label
        }
    }

    override func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        if indexPath.section == 2 {
            tableView.cellForRow(at: indexPath)?.imageView?.tintColor = R.color.accentColor()
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        let row = indexPath.row

        if section == 1 {
            if row == 0 {
                navigationController?.pushViewController(WidgetsVC(), animated: true)
            } else {
                navigationController?.pushViewController(StickersVC(collectionViewLayout: gridLayout()), animated: true)
            }
        } else if section == 2 {
            tableView.cellForRow(at: indexPath)?.imageView?.tintColor = .label

            if row == 0 {
                UIApplication.shared.open(URL(string: "mailto:feedback@tavitian.cloud?subject=Feedback%20for%20Provenance")!)
            } else {
                UIApplication.shared.open(URL(string: "https://github.com/themuzzleflare/Provenance")!)
            }
        }
    }

    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if let footerView = view as? UITableViewHeaderFooterView {
            footerView.textLabel?.font = R.font.circularStdBook(size: UIFont.smallSystemFontSize)
            footerView.textLabel?.textAlignment = .center
        }
    }
}
