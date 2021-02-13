import UIKit

class AttributeCell: UITableViewCell {
    @IBOutlet var leftLabel: UILabel!
    @IBOutlet var rightDetail: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
