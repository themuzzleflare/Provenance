import Cocoa

class TransactionDetailVC: NSViewController {
    var transaction: TransactionResource!
    var accounts: [AccountResource]!
    var categories: [CategoryResource]!
    
    @IBOutlet var statusImage: NSImageView!
    @IBOutlet var statusValue: NSTextField!
    
    @IBOutlet var accountValue: NSTextField!
    
    @IBOutlet var messageValue: NSTextField!
    
    @IBOutlet var rawTextValue: NSTextField!
    
    @IBOutlet var amountLabel: NSTextField!
    @IBOutlet var amountValue: NSTextField!
    
    @IBOutlet var descriptionValue: NSTextField!
    
    @IBOutlet var creationDateValue: NSTextField!
    @IBOutlet var settlementDateValue: NSTextField!
    
    @IBOutlet var pCategoryValue: NSTextField!
    
    @IBOutlet var categoryValue: NSTextField!
    
    private var statusString: String {
        switch transaction?.attributes.isSettled {
            case true: return "Settled"
            case false: return "Held"
            default: return ""
        }
    }
    
    private var statusIcon: NSImage {
        let settledIconImage = NSImage(systemSymbolName: "checkmark.circle", accessibilityDescription: "Settled")
        let heldIconImage = NSImage(systemSymbolName: "clock", accessibilityDescription: "Held")
        
        switch transaction!.attributes.isSettled {
            case true: return settledIconImage!
            case false: return heldIconImage!
        }
    }
    
    private var statusColor: NSColor {
        switch transaction!.attributes.isSettled {
            case true: return .systemGreen
            case false: return .systemYellow
        }
    }
    
    private var categoryFilter: [CategoryResource]? {
        categories?.filter { category in
            transaction?.relationships.category.data?.id == category.id
        }
    }
    
    private var parentCategoryFilter: [CategoryResource]? {
        categories?.filter { pcategory in
            transaction?.relationships.parentCategory.data?.id == pcategory.id
        }
    }
    
    private var accountFilter: [AccountResource]? {
        accounts?.filter { account in
            transaction?.relationships.account.data.id == account.id
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        statusImage.image = statusIcon
        statusImage.contentTintColor = statusColor
        statusValue.stringValue = statusString
        
        accountValue.stringValue = accountFilter?.first?.attributes.displayName ?? ""
        
        messageValue.stringValue = transaction?.attributes.message ?? ""
        
        rawTextValue.stringValue = transaction?.attributes.rawText ?? ""
        
        amountLabel.stringValue = transaction?.attributes.amount.transType ?? "Amount"
        amountValue.stringValue = "\(transaction?.attributes.amount.valueSymbol ?? "")\(transaction?.attributes.amount.valueString ?? "") \(transaction?.attributes.amount.currencyCode ?? "")"
        
        descriptionValue.stringValue = transaction?.attributes.description ?? ""
        
        creationDateValue.stringValue = transaction?.attributes.createdDate ?? ""
        settlementDateValue.stringValue = transaction?.attributes.settledDate ?? ""
        
        pCategoryValue.stringValue = parentCategoryFilter?.first?.attributes.name ?? ""
        
        categoryValue.stringValue = categoryFilter?.first?.attributes.name ?? ""
    }
}
