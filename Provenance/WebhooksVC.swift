import UIKit

class WebhooksVC: ViewController, UITableViewDelegate {
    let fetchingView: UIActivityIndicatorView = UIActivityIndicatorView(style: .medium)
    let tableViewController: UITableViewController = UITableViewController(style: .grouped)
    
    let circularStdBook = UIFont(name: "CircularStd-Book", size: UIFont.labelFontSize)!
    let circularStdBold = UIFont(name: "CircularStd-Bold", size: UIFont.labelFontSize)!
    
    var refreshControl: UIRefreshControl = UIRefreshControl()
    
    var webhooks: [WebhooksResponse.WebhookResource] = []
    var webhooksErrorResponse: [ErrorObject] = []
    var webhooksError: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        super.addChild(tableViewController)
        
        self.view.backgroundColor = .systemBackground
        
        self.title = "Webhooks"
        self.navigationItem.title = "Loading"
        
        #if targetEnvironment(macCatalyst)
        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshWebhooks)), animated: true)
        #endif
        
        self.tableViewController.clearsSelectionOnViewWillAppear = true
        self.tableViewController.refreshControl = refreshControl
        self.refreshControl.addTarget(self, action: #selector(refreshWebhooks), for: .valueChanged)
        
        self.setupFetchingView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.prefersLargeTitles = true
        self.tableViewController.tableView.reloadData()
        self.listWebhooks()
    }
    
    @objc private func refreshWebhooks() {
        #if targetEnvironment(macCatalyst)
        let loadingView = UIActivityIndicatorView(style: .medium)
        loadingView.startAnimating()
        navigationItem.setRightBarButton(UIBarButtonItem(customView: loadingView), animated: true)
        #endif
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.listWebhooks()
        }
    }
    
    func setupFetchingView() {
        view.addSubview(fetchingView)
        
        fetchingView.translatesAutoresizingMaskIntoConstraints = false
        fetchingView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        fetchingView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        fetchingView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        fetchingView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        fetchingView.hidesWhenStopped = true
        
        fetchingView.startAnimating()
    }
    
    func setupTableView() {
        view.addSubview(tableViewController.tableView)
        
        tableViewController.tableView.translatesAutoresizingMaskIntoConstraints = false
        tableViewController.tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableViewController.tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableViewController.tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableViewController.tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        tableViewController.tableView.dataSource = self
        tableViewController.tableView.delegate = self
        
        tableViewController.tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: "webhookCell")
        tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "noWebhooksCell")
        tableViewController.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "errorStringCell")
        tableViewController.tableView.register(SubtitleTableViewCell.self, forCellReuseIdentifier: "errorObjectCell")
    }
    
    private func listWebhooks() {
        var url = URL(string: "https://api.up.com.au/api/v1/webhooks")!
        let urlParams = ["page[size]":"100"]
        url = url.appendingQueryParameters(urlParams)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(UserDefaults.standard.string(forKey: "apiKey") ?? "")", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if error == nil {
                if let decodedResponse = try? JSONDecoder().decode(WebhooksResponse.self, from: data!) {
                    DispatchQueue.main.async {
                        print("Webhooks JSON Decoding Succeeded!")
                        self.webhooks = decodedResponse.data
                        self.webhooksError = ""
                        self.webhooksErrorResponse = []
                        self.navigationItem.title = "Webhooks"
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshWebhooks)), animated: true)
                        #endif
                        self.fetchingView.stopAnimating()
                        self.fetchingView.removeFromSuperview()
                        self.setupTableView()
                        self.tableViewController.tableView.reloadData()
                        self.refreshControl.endRefreshing()
                    }
                } else if let decodedResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data!) {
                    DispatchQueue.main.async {
                        print("Webhooks Error JSON Decoding Succeeded!")
                        self.webhooksErrorResponse = decodedResponse.errors
                        self.webhooksError = ""
                        self.webhooks = []
                        self.navigationItem.title = "Errors"
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshWebhooks)), animated: true)
                        #endif
                        self.fetchingView.stopAnimating()
                        self.fetchingView.removeFromSuperview()
                        self.setupTableView()
                        self.tableViewController.tableView.reloadData()
                        self.refreshControl.endRefreshing()
                    }
                } else {
                    DispatchQueue.main.async {
                        print("Webhooks JSON Decoding Failed!")
                        self.webhooksError = "JSON Decoding Failed!"
                        self.webhooksErrorResponse = []
                        self.webhooks = []
                        self.navigationItem.title = "Error"
                        #if targetEnvironment(macCatalyst)
                        self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshWebhooks)), animated: true)
                        #endif
                        self.fetchingView.stopAnimating()
                        self.fetchingView.removeFromSuperview()
                        self.setupTableView()
                        self.tableViewController.tableView.reloadData()
                        self.refreshControl.endRefreshing()
                    }
                }
            } else {
                DispatchQueue.main.async {
                    print(error?.localizedDescription ?? "Unknown Error!")
                    self.webhooksError = error?.localizedDescription ?? "Unknown Error!"
                    self.webhooksErrorResponse = []
                    self.webhooks = []
                    self.navigationItem.title = "Error"
                    #if targetEnvironment(macCatalyst)
                    self.navigationItem.setRightBarButton(UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(self.refreshWebhooks)), animated: true)
                    #endif
                    self.fetchingView.stopAnimating()
                    self.fetchingView.removeFromSuperview()
                    self.setupTableView()
                    self.tableViewController.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                }
            }
        }
        .resume()
    }
}

extension WebhooksVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.webhooks.isEmpty && self.webhooksError.isEmpty && self.webhooksErrorResponse.isEmpty {
            return 1
        } else {
            if !self.webhooksError.isEmpty {
                return 1
            } else if !self.webhooksErrorResponse.isEmpty {
                return webhooksErrorResponse.count
            } else {
                return webhooks.count
            }
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let webhookCell = tableView.dequeueReusableCell(withIdentifier: "webhookCell", for: indexPath) as! SubtitleTableViewCell
        
        let noWebhooksCell = tableView.dequeueReusableCell(withIdentifier: "noWebhooksCell", for: indexPath)
        
        let errorStringCell = tableView.dequeueReusableCell(withIdentifier: "errorStringCell", for: indexPath)
        
        let errorObjectCell = tableView.dequeueReusableCell(withIdentifier: "errorObjectCell", for: indexPath) as! SubtitleTableViewCell
        
        if self.webhooks.isEmpty && self.webhooksError.isEmpty && self.webhooksErrorResponse.isEmpty && !self.refreshControl.isRefreshing {
            tableView.separatorStyle = .none
            noWebhooksCell.selectionStyle = .none
            noWebhooksCell.textLabel?.font = UIFontMetrics.default.scaledFont(for: circularStdBook)
            noWebhooksCell.textLabel?.textAlignment = .center
            noWebhooksCell.textLabel?.text = "No Webhooks"
            noWebhooksCell.backgroundColor = tableView.backgroundColor
            return noWebhooksCell
        } else {
            tableView.separatorStyle = .singleLine
            if !self.webhooksError.isEmpty {
                errorStringCell.selectionStyle = .none
                errorStringCell.textLabel?.numberOfLines = 0
                errorStringCell.textLabel?.font = UIFontMetrics.default.scaledFont(for: circularStdBook)
                errorStringCell.textLabel?.text = webhooksError
                return errorStringCell
            } else if !self.webhooksErrorResponse.isEmpty {
                let error = webhooksErrorResponse[indexPath.row]
                errorObjectCell.selectionStyle = .none
                errorObjectCell.textLabel?.textColor = .red
                errorObjectCell.textLabel?.font = UIFontMetrics.default.scaledFont(for: circularStdBold)
                errorObjectCell.textLabel?.text = error.title
                errorObjectCell.detailTextLabel?.numberOfLines = 0
                errorObjectCell.detailTextLabel?.font = UIFont(name: "CircularStd-Book", size: UIFont.smallSystemFontSize)
                errorObjectCell.detailTextLabel?.text = error.detail
                return errorObjectCell
            } else {
                let webhook = webhooks[indexPath.row]
                webhookCell.accessoryType = .disclosureIndicator
                webhookCell.textLabel?.font = UIFontMetrics.default.scaledFont(for: circularStdBold)
                webhookCell.textLabel?.textColor = .label
                webhookCell.textLabel?.text = webhook.attributes.url
                webhookCell.detailTextLabel?.textColor = .secondaryLabel
                webhookCell.detailTextLabel?.font = UIFont(name: "CircularStd-Book", size: UIFont.smallSystemFontSize)
                webhookCell.detailTextLabel?.text = webhook.attributes.description ?? ""
                return webhookCell
            }
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if self.webhooksErrorResponse.isEmpty && self.webhooksError.isEmpty && !self.webhooks.isEmpty {
            let vc = WebhookDetail(style: .grouped)
            vc.webhook = webhooks[indexPath.row]
            navigationController?.pushViewController(vc, animated: true)
        }
    }
}
