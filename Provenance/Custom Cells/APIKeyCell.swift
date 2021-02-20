import UIKit
import MarqueeLabel

class APIKeyCell: UITableViewCell {
    @IBOutlet var leftImage: UIImageView!
    @IBOutlet var leftLabel: UILabel!
    @IBOutlet var rightDetail: MarqueeLabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
