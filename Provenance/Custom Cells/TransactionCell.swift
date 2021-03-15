import UIKit

class TransactionCell: UITableViewCell {
    @IBOutlet var leftLabel: UILabel!
    @IBOutlet var leftSubtitle: UILabel!
    @IBOutlet var rightLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
