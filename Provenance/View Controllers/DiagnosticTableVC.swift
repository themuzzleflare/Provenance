import UIKit
import Rswift

class DiagnosticTableVC: TableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setProperties()
        setupNavigation()
        setupTableView()
    }
}

extension DiagnosticTableVC {
    private var attributes: KeyValuePairs<String, String> {
        return ["Version": appVersion, "Build": appBuild]
    }
    
    @objc private func closeWorkflow() {
        dismiss(animated: true)
    }
    
    private func setProperties() {
        title = "Diagnostics"
    }
    
    private func setupNavigation() {
        navigationItem.title = "Diagnostics"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeWorkflow))
    }
    
    private func setupTableView() {
        tableView.register(AttributeCell.self, forCellReuseIdentifier: AttributeCell.reuseIdentifier)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return attributes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let attribute = attributes[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: AttributeCell.reuseIdentifier, for: indexPath) as! AttributeCell
        
        cell.leftLabel.text = attribute.key
        cell.rightLabel.text = attribute.value
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let attribute = attributes[indexPath.row]
        
        if attribute.value != "Unknown" {
            let copy = UIAction(title: "Copy", image: R.image.docOnClipboard()) { _ in
                UIPasteboard.general.string = attribute.value
            }
            
            return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
                UIMenu(children: [copy])
            }
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}
