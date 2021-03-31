import UIKit
import Rswift

class AboutViewController: TableViewController {
    @IBOutlet var appImage: UIImageView!
    @IBOutlet var appNameValue: UILabel!
    @IBOutlet var versionValue: UILabel!
    @IBOutlet var buildValue: UILabel!
    
    @objc private func openSettings() {
        let vc = NavigationController(rootViewController: SettingsVC(style: .insetGrouped))
        
        present(vc, animated: true)
    }
    @objc private func openDiagnostics() {
        let vc = NavigationController(rootViewController: DiagnosticTableVC(style: .insetGrouped))
        
        present(vc, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setProperties()
        setupNavigation()
    }
    
    private func setProperties() {
        title = "About"
        
        appImage.image = upAnimation
        appNameValue.text = appName
        versionValue.text = appVersion
        buildValue.text = appBuild
    }
    
    private func setupNavigation() {
        navigationItem.title = "About"
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: R.image.chevronLeftSlashChevronRight(), style: .plain, target: self, action: #selector(openDiagnostics))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: R.image.gear(), style: .plain, target: self, action: #selector(openSettings))
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let row = indexPath.row
        
        if indexPath.section == 0 {
            if row == 1 {
                if appVersion != "Unknown" {
                    let copyVersion = UIAction(title: "Copy", image: R.image.docOnClipboard()) { _ in
                        UIPasteboard.general.string = appVersion
                    }
                    
                    return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                        UIMenu(children: [copyVersion])
                    }
                } else {
                    return nil
                }
            } else if row == 2 {
                if appBuild != "Unknown" {
                    let copyBuild = UIAction(title: "Copy", image: R.image.docOnClipboard()) { _ in
                        UIPasteboard.general.string = appBuild
                    }
                    
                    return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                        UIMenu(children: [copyBuild])
                    }
                } else {
                    return nil
                }
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 1 {
            return appCopyright
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            self.tableView.deselectRow(at: indexPath, animated: true)
            
            if indexPath.row == 0 {
                UIApplication.shared.open(URL(string: "mailto:feedback@tavitian.cloud?subject=Feedback%20for%20Provenance")!)
            } else {
                UIApplication.shared.open(URL(string: "https://github.com/themuzzleflare/Provenance")!)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if let footerView = view as? UITableViewHeaderFooterView {
            footerView.textLabel?.textColor = .lightGray
            footerView.textLabel?.font = R.font.circularStdBook(size: 12)
        }
    }
}
