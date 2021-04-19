import UIKit
import Rswift

class AboutVC: TableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
}

extension AboutVC {
    @objc private func openSettings() {
        present(NavigationController(rootViewController: SettingsVC(style: .grouped)), animated: true)
    }
    
    @objc private func openDiagnostics() {
        present(NavigationController(rootViewController: DiagnosticTableVC(style: .grouped)), animated: true)
    }
    
    private func configure() {
        title = "About"

        navigationItem.title = "About"
        navigationItem.backBarButtonItem = UIBarButtonItem(image: R.image.infoCircle(), style: .plain, target: self, action: nil)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: R.image.chevronLeftSlashChevronRight(), style: .plain, target: self, action: #selector(openDiagnostics))
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: R.image.gear(), style: .plain, target: self, action: #selector(openSettings))
        
        tableView.register(AboutTopTableViewCell.self, forCellReuseIdentifier: AboutTopTableViewCell.reuseIdentifier)
        tableView.register(AttributeTableViewCell.self, forCellReuseIdentifier: AttributeTableViewCell.reuseIdentifier)
        tableView.register(BasicTableViewCell.self, forCellReuseIdentifier: "basicCell")
    }
}

extension AboutVC {
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        let row = indexPath.row
        
        let topCell = tableView.dequeueReusableCell(withIdentifier: AboutTopTableViewCell.reuseIdentifier, for: indexPath) as! AboutTopTableViewCell
        let sectionOneAttributeCell = tableView.dequeueReusableCell(withIdentifier: AttributeTableViewCell.reuseIdentifier, for: indexPath) as! AttributeTableViewCell
        let basicCell = tableView.dequeueReusableCell(withIdentifier: "basicCell", for: indexPath) as! BasicTableViewCell
        
        basicCell.selectionStyle = .default
        basicCell.separatorInset = .zero
        basicCell.selectedBackgroundView = selectedBackgroundCellView
        basicCell.imageView?.tintColor = .label
        basicCell.textLabel?.textColor = .label
        basicCell.textLabel?.font = R.font.circularStdBook(size: UIFont.labelFontSize)
        
        if section == 0 {
            if row == 0 {
                return topCell
            } else if row == 1 {
                sectionOneAttributeCell.leftLabel.text = "Version"
                sectionOneAttributeCell.rightLabel.text = appVersion
                return sectionOneAttributeCell
            } else {
                sectionOneAttributeCell.leftLabel.text = "Build"
                sectionOneAttributeCell.rightLabel.text = appBuild
                return sectionOneAttributeCell
            }
        } else if section == 1 {
            basicCell.accessoryType = .disclosureIndicator
            basicCell.imageView?.image = nil
            
            if row == 0 {
                basicCell.textLabel?.text = "Widgets"
                return basicCell
            } else {
                basicCell.textLabel?.text = "Stickers"
                return basicCell
            }
        } else {
            basicCell.accessoryType = .none
            
            if row == 0 {
                basicCell.imageView?.image = R.image.envelope()
                basicCell.textLabel?.text = "Contact Developer"
                return basicCell
            } else {
                basicCell.imageView?.image = R.image.linkCircle()
                basicCell.textLabel?.text = "GitHub"
                return basicCell
            }
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
            tableView.deselectRow(at: indexPath, animated: true)
            
            if row == 0 {
                UIApplication.shared.open(URL(string: "mailto:feedback@tavitian.cloud?subject=Feedback%20for%20Provenance")!)
            } else {
                UIApplication.shared.open(URL(string: "https://github.com/themuzzleflare/Provenance")!)
            }
        }
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

    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        if let footerView = view as? UITableViewHeaderFooterView {
            footerView.textLabel?.font = R.font.circularStdBook(size: UIFont.smallSystemFontSize)
            footerView.textLabel?.textAlignment = .center
        }
    }
}
