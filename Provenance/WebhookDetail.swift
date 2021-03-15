import UIKit
import Rswift

class WebhookDetail: TableViewController {
    var webhook: WebhooksResponse.WebhookResource!
    
    private var createdDate: String {
        switch UserDefaults.standard.string(forKey: "dateStyle") {
            case "Absolute", .none: return webhook.attributes.createdDate
            case "Relative": return webhook.attributes.createdDateRelative
            default: return webhook.attributes.createdDate
        }
    }
    
    private var attributes: KeyValuePairs<String, String> {
        return ["URL": webhook.attributes.url, "Description": webhook.attributes.description ?? "", "Secret Key": webhook.attributes.secretKey ?? "", "Creation Date": createdDate]
    }
    
    private var altAttributes: Array<(key: String, value: String)> {
        return attributes.filter {
            $0.value != ""
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Webhook Details"
        self.navigationItem.title = webhook.attributes.description ?? nil
        
        self.navigationItem.largeTitleDisplayMode = .never
        
        self.tableView.register(R.nib.attributeCell)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return altAttributes.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: R.reuseIdentifier.attributeCell, for: indexPath)!
        
        let attribute = altAttributes[indexPath.row]
        
        cell.leftLabel.text = attribute.key
        cell.rightDetail.text = attribute.value
        
        return cell
    }
}
