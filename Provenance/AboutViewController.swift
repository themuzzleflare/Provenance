import UIKit
import Rswift

class AboutViewController: TableViewController {
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
        
        appNameValue.text = appName
        versionValue.text = appVersion
        buildValue.text = appBuild
    }
    
    private func setupNavigation() {
        navigationItem.title = "About"
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: R.image.chevronLeftSlashChevronRight(), style: .plain, target: self, action: #selector(openDiagnostics))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: R.image.gear(), style: .plain, target: self, action: #selector(openSettings))
        navigationItem.largeTitleDisplayMode = .never
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
