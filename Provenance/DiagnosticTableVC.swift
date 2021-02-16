import UIKit

class DiagnosticTableVC: UITableViewController {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    let name = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String ?? Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Provenance"
    let copyright = Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String ?? "Copyright © 2021 Paul Tavitian"
    
    private var attributes: KeyValuePairs<String, String> {
        return ["Version": version, "Build": build]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeWorkflow))
        
        title = "Diagnostics"
        navigationItem.title = "Diagnostics"
        navigationItem.rightBarButtonItem = closeButton
        tableView.register(RightDetailTableViewCell.self, forCellReuseIdentifier: "diagnosticCell")
    }
    
    @objc private func closeWorkflow() {
        dismiss(animated: true)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return attributes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let attribute = attributes[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "diagnosticCell", for: indexPath) as! RightDetailTableViewCell
        
        cell.selectionStyle = .none
        cell.textLabel?.textColor = .secondaryLabel
        cell.textLabel?.font = UIFont(name: "CircularStd-Book", size: UIFont.labelFontSize)
        cell.textLabel?.text = attribute.key
        cell.detailTextLabel?.textColor = .label
        cell.detailTextLabel?.textAlignment = .right
        cell.detailTextLabel?.font = UIFont(name: "CircularStd-Book", size: UIFont.labelFontSize)
        cell.detailTextLabel?.text = attribute.value
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let attribute = attributes[indexPath.row]
        
        if attribute.value != "Unknown" {
            let copy = UIAction(title: "Copy", image: UIImage(systemName: "doc.on.clipboard")) { _ in
                UIPasteboard.general.string = attribute.value
            }
            
            return UIContextMenuConfiguration(identifier: nil,
                                              previewProvider: nil) { _ in
                UIMenu(title: "", children: [copy])
            }
        } else {
            return nil
        }
    }
}
