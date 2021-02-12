import UIKit

class SettingsVC: UITableViewController {
    private var apiKeyDisplay: String {
        switch UserDefaults.standard.string(forKey: "apiKey") {
            case nil, "": return "None"
            default: return UserDefaults.standard.string(forKey: "apiKey")!
        }
    }
    
    private var attributes: KeyValuePairs<String, String> {
        return ["API Key": apiKeyDisplay]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeWorkflow))
        
        navigationItem.title = "Settings"
        navigationItem.setRightBarButton(closeButton, animated: true)
        tableView.register(RightDetailTableViewCell.self, forCellReuseIdentifier: "settingCell")
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
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingCell", for: indexPath) as! RightDetailTableViewCell
        
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.textColor = .secondaryLabel
        cell.textLabel?.text = attribute.key
        cell.detailTextLabel?.textColor = .label
        cell.detailTextLabel?.textAlignment = .right
        cell.detailTextLabel?.text = attribute.value
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let attribute = attributes[indexPath.row]
        
        let ac = UIAlertController(title: "New \(attribute.key)", message: "Enter a new \(attribute.key).", preferredStyle: .alert)
        ac.addTextField()
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        let submitAction = UIAlertAction(title: "Save", style: .default) { [unowned ac] _ in
            let answer = ac.textFields![0]
            if answer.text != "" && answer.text != UserDefaults.standard.string(forKey: "apiKey") {
                UserDefaults.standard.set(answer.text!, forKey: "apiKey")
                tableView.reloadData()
            }
        }
        
        ac.addAction(cancelAction)
        ac.addAction(submitAction)
        
        present(ac, animated: true)
    }
}
