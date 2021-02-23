import UIKit
import MarqueeLabel

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
        
        tableView.register(UINib(nibName: "APIKeyCell", bundle: nil), forCellReuseIdentifier: "apiKeyCell")
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
        
        let apiKeyCell = tableView.dequeueReusableCell(withIdentifier: "apiKeyCell", for: indexPath) as! APIKeyCell
        let datePickerCell = tableView.dequeueReusableCell(withIdentifier: "datePickerCell", for: indexPath) as! DateStylePickerCell
        
        if UserDefaults.standard.string(forKey: "apiKey") != "" && UserDefaults.standard.string(forKey: "apiKey") != nil {
            apiKeyCell.leftImage.tintColor = .systemGreen
        } else {
            apiKeyCell.leftImage.tintColor = .secondaryLabel
        }
        
        apiKeyCell.rightDetail.speed = .rate(65)
        apiKeyCell.rightDetail.leadingBuffer = 20
        apiKeyCell.rightDetail.fadeLength = 20
        apiKeyCell.rightDetail.text = apiKeyDisplay
        
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
                field.autocapitalizationType = .none
                field.autocorrectionType = .no
                field.text = UserDefaults.standard.string(forKey: "apiKey") ?? nil
            })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
            
            let submitAction = UIAlertAction(title: "Save", style: .default) { [unowned ac] _ in
                let answer = ac.textFields![0]
                if (answer.text != "" && answer.text != nil) && answer.text != UserDefaults.standard.string(forKey: "apiKey") {
                    let url = URL(string: "https://api.up.com.au/api/v1/util/ping")!
                    var request = URLRequest(url: url)
                    request.httpMethod = "GET"
                    request.addValue("application/json", forHTTPHeaderField: "Accept")
                    request.addValue("Bearer \(answer.text!)", forHTTPHeaderField: "Authorization")
                    URLSession.shared.dataTask(with: request) { data, response, error in
                        if error == nil {
                            let statusCode = (response as! HTTPURLResponse).statusCode
                            if statusCode == 200 {
                                DispatchQueue.main.async {
                                    UserDefaults.standard.set(answer.text!, forKey: "apiKey")
                                    tableView.reloadData()
                                }
                            } else {
                                DispatchQueue.main.async {
                                    let ac = UIAlertController(title: "Failed", message: "The API Key could not be verified.", preferredStyle: .alert)
                                    let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel)
                                    ac.addAction(dismissAction)
                                    self.present(ac, animated: true)
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                let ac = UIAlertController(title: "Failed", message: error?.localizedDescription ?? "The API Key could not be verified.", preferredStyle: .alert)
                                let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel)
                                ac.addAction(dismissAction)
                                self.present(ac, animated: true)
                            }
                        }
                    }
                    .resume()
                } else {
                    let ac = UIAlertController(title: "Failed", message: "The provided API Key was either empty, or the same as the current one.", preferredStyle: .alert)
                    let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel)
                    ac.addAction(dismissAction)
                    self.present(ac, animated: true)
                }
            }
            
            ac.addAction(cancelAction)
            ac.addAction(submitAction)
            
            present(ac, animated: true)
        }
    }
}
