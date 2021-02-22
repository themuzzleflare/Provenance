import UIKit
import NotificationBannerSwift

class SettingsVC: UITableViewController {
    var appearingBanner: NotificationBanner?
    
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
    
    override func viewDidAppear(_ animated: Bool) {
        if let banner = appearingBanner {
            banner.show()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.appearingBanner = nil
            }
        }
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
                                    let banner = NotificationBanner(title: "Success", subtitle: "The API Key was verified and set.", leftView: nil, rightView: nil, style: .success, colors: nil)
                                    banner.duration = 2
                                    banner.show()
                                    UserDefaults.standard.set(answer.text!, forKey: "apiKey")
                                    tableView.reloadData()
                                }
                            } else {
                                DispatchQueue.main.async {
                                    let banner = NotificationBanner(title: "Failed", subtitle: "The API Key could not be verified.", leftView: nil, rightView: nil, style: .danger, colors: nil)
                                    banner.duration = 2
                                    banner.show()
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                let banner = NotificationBanner(title: "Failed", subtitle: error?.localizedDescription ?? "The API Key could not be verified.", leftView: nil, rightView: nil, style: .danger, colors: nil)
                                banner.duration = 2
                                banner.show()
                            }
                        }
                    }
                    .resume()
                } else {
                    let banner = NotificationBanner(title: "Failed", subtitle: "The provided API Key was either empty, or the same as the current one.", leftView: nil, rightView: nil, style: .danger, colors: nil)
                    banner.duration = 2
                    banner.show()
                }
            }
            
            ac.addAction(cancelAction)
            ac.addAction(submitAction)
            
            present(ac, animated: true)
        }
    }
}
