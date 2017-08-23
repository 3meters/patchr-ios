import UIKit

class DropdownButton: AirButtonBase {
    
    var dropdownImage = UIImageView()
    var badgeLabel = UILabel()
    
    /*--------------------------------------------------------------------------------------------
     * Lifecycle
     *--------------------------------------------------------------------------------------------*/
    
    init() {
        super.init(frame: CGRect.zero)
        initialize()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    func initialize() {
        self.badgeLabel.textColor = Colors.white
        self.badgeLabel.layer.backgroundColor = Theme.colorBackgroundBadge.cgColor
        self.badgeLabel.text = nil
        self.badgeLabel.font = UIFont(name: "HelveticaNeue", size: 14)
        self.badgeLabel.clipsToBounds = true
        self.badgeLabel.textAlignment = .center
        self.dropdownImage.image = UIImage(named: "imgArrowDownLight")
        self.dropdownImage.tintColor = Colors.white
        self.addSubview(self.dropdownImage)
        self.addSubview(self.badgeLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if self.badgeLabel.text != nil {
            self.badgeLabel.sizeToFit()
            self.dropdownImage.anchorBottomCenter(withBottomPadding: 2, width: 18, height: 14)
            self.badgeLabel.align(above: self.dropdownImage, matchingCenterWithBottomPadding: 0,
                                  width: max(22, self.badgeLabel.width()),
                                  height: 22)
            self.badgeLabel.layer.cornerRadius = self.badgeLabel.frame.size.height / 2
            self.badgeLabel.showShadow(offset: CGSize(width: 1, height: 2),
                                       radius: 2.0,
                                       rounded: true,
                                       cornerRadius: self.badgeLabel.layer.cornerRadius)
        }
        else {
            self.dropdownImage.anchorInCenter(withWidth: 18, height: 14)
        }
    }
}
