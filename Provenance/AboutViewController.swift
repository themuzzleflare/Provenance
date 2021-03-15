import UIKit
import Rswift
import TinyConstraints

class AboutViewController: UITableViewController {
    @IBOutlet var stackView: UIStackView!
    @IBOutlet var appNameValue: UILabel!
    @IBOutlet var versionValue: UILabel!
    @IBOutlet var buildValue: UILabel!
    @IBOutlet var contactCell: UITableViewCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.appNameValue.text = appName
        self.versionValue.text = appVersion
        self.buildValue.text = appBuild
        
        let settingsButton = UIBarButtonItem(image: R.image.gear(), style: .plain, target: self, action: #selector(openSettings))
        let diagnosticsButton = UIBarButtonItem(image: R.image.chevronLeftSlashChevronRight(), style: .plain, target: self, action: #selector(openDiagnostics))
        
        self.title = "About"
        self.navigationItem.title = "About"
        self.navigationItem.leftBarButtonItem = diagnosticsButton
        self.navigationItem.rightBarButtonItem = settingsButton
        
        self.navigationItem.largeTitleDisplayMode = .never
    }
    
    @objc private func openSettings() {
        let vc = NavigationController(rootViewController: SettingsVC(style: .insetGrouped))
        present(vc, animated: true)
    }
    
    @objc private func openDiagnostics() {
        let vc = NavigationController(rootViewController: DiagnosticTableVC(style: .insetGrouped))
        present(vc, animated: true)
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
            UIApplication.shared.open(URL(string: "mailto:feedback@tavitian.cloud?subject=Feedback%20for%20Provenance")!)
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if let footerView = view as? UITableViewHeaderFooterView {
            footerView.textLabel?.textColor = .lightGray
            footerView.textLabel?.font = R.font.circularStdBook(size: 12)
        }
    }
}
