import UIKit

class SettledOnlyCell: UITableViewCell {
    @IBOutlet var checkmarkCircle: UIImageView!
    @IBOutlet var leftLabel: UILabel!
    @IBOutlet var rightSwitch: UISwitch!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
