import UIKit
import Rswift

class AboutViewController: TableViewController {
    @IBOutlet var appImage: UIImageView!
    @IBOutlet var appNameValue: UILabel!
    @IBOutlet var versionValue: UILabel!
    @IBOutlet var buildValue: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setProperties()
        setupNavigation()
    }
}

extension AboutViewController {
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
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: R.image.chevronLeftSlashChevronRight(), style: .plain, target: self, action: #selector(openDiagnostics))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: R.image.gear(), style: .plain, target: self, action: #selector(openSettings))
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let section = indexPath.section
        let row = indexPath.row
        
        if section == 0 {
            if row == 1 {
                if appVersion != "Unknown" {
                    let copyVersion = UIAction(title: "Copy Version", image: R.image.docOnClipboard()) { _ in
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
                    let copyBuild = UIAction(title: "Copy Build", image: R.image.docOnClipboard()) { _ in
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
        } else if section == 1 {
            if row == 1 {
                let copyGithub = UIAction(title: "Copy Link", image: R.image.docOnClipboard()) { _ in
                    UIPasteboard.general.string = "https://github.com/themuzzleflare/Provenance"
                }
                
                return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                    UIMenu(children: [copyGithub])
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
            tableView.deselectRow(at: indexPath, animated: true)
            
            if indexPath.row == 0 {
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
