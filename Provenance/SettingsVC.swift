import UIKit

class SettingsVC: UITableViewController {
    private var apiKeyDisplay: String {
        switch UserDefaults.standard.string(forKey: "apiKey") {
            case nil, "": return "None"
            default: return UserDefaults.standard.string(forKey: "apiKey")!
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let closeButton = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(closeWorkflow))
        
        title = "Settings"
        navigationItem.title = "Settings"
        navigationItem.rightBarButtonItem = closeButton
        
        tableView.register(RightDetailTableViewCell.self, forCellReuseIdentifier: "apiKeyCell")
        tableView.register(UINib(nibName: "DateStylePickerCell", bundle: nil), forCellReuseIdentifier: "datePickerCell")
    }
    
    @objc private func closeWorkflow() {
        dismiss(animated: true)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        
        let apiKeyCell = tableView.dequeueReusableCell(withIdentifier: "apiKeyCell", for: indexPath) as! RightDetailTableViewCell
        let datePickerCell = tableView.dequeueReusableCell(withIdentifier: "datePickerCell", for: indexPath) as! DateStylePickerCell
        
        apiKeyCell.accessoryType = .disclosureIndicator
        apiKeyCell.textLabel?.textColor = .secondaryLabel
        apiKeyCell.textLabel?.font = UIFont(name: "CircularStd-Book", size: UIFont.labelFontSize)
        apiKeyCell.textLabel?.text = "API Key"
        apiKeyCell.detailTextLabel?.textColor = .label
        apiKeyCell.detailTextLabel?.textAlignment = .right
        apiKeyCell.detailTextLabel?.font = UIFont(name: "CircularStd-Book", size: UIFont.labelFontSize)
        apiKeyCell.detailTextLabel?.lineBreakMode = .byTruncatingMiddle
        apiKeyCell.detailTextLabel?.text = apiKeyDisplay
        
        if UserDefaults.standard.string(forKey: "dateStyle") == "Absolute" || UserDefaults.standard.string(forKey: "dateStyle") == nil {
            datePickerCell.datePicker.selectedSegmentIndex = 0
        } else {
            datePickerCell.datePicker.selectedSegmentIndex = 1
        }
        datePickerCell.datePicker.addTarget(self, action: #selector(switchDateStyle), for:.valueChanged)
        
        
        if section == 0 {
            return apiKeyCell
        } else {
            return datePickerCell
        }
    }
    
    @objc private func switchDateStyle(segment: UISegmentedControl) {
        if segment.selectedSegmentIndex == 0 {
            UserDefaults.standard.setValue("Absolute", forKey: "dateStyle")
        } else {
            UserDefaults.standard.setValue("Relative", forKey: "dateStyle")
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let section = indexPath.section
        
        if section == 0 {
            tableView.deselectRow(at: indexPath, animated: true)
            
            let ac = UIAlertController(title: "New API Key", message: "Enter a new API Key.", preferredStyle: .alert)
            ac.addTextField(configurationHandler: { field in
                field.text = UserDefaults.standard.string(forKey: "apiKey") ?? nil
            })
            
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
}
