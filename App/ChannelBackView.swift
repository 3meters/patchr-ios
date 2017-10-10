import UIKit

class ChannelBackView: UIControl {
    
    var backImage = UIImageView()
    var badge = UILabel()
    var label = UILabel()
    var buttonScrim = AirScrimButton(frame: .zero, hitInsets: UIEdgeInsets(top: -8, left: -8, bottom: -8, right: -8))
    var badgeIsHidden = true {
        didSet {
            self.badge.isHidden = badgeIsHidden
            self.setNeedsDisplay()
            self.setNeedsLayout()
        }
    }
    
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
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("This view should never be loaded from storyboard")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if self.badgeIsHidden {
            self.badge.isHidden = true
            self.badge.sizeToFit()
            self.label.sizeToFit()
            self.backImage.anchorCenterLeft(withLeftPadding: 0, width: 14, height: 18)
            self.label.align(toTheRightOf: self.backImage, matchingCenterWithLeftPadding: 4, width: self.label.width(), height: 22)
        }
        else {
            self.badge.isHidden = false
            self.badge.sizeToFit()
            self.label.sizeToFit()
            self.backImage.anchorCenterLeft(withLeftPadding: 0, width: 14, height: 18)
            self.badge.align(toTheRightOf: self.backImage
                , matchingCenterWithLeftPadding: 2
                , width: max(22, self.badge.width())
                , height: 22)
            self.badge.layer.cornerRadius = self.badge.frame.size.height / 2
            self.badge.showShadow(offset: CGSize(width: 2, height: 4)
                , radius: 4.0
                , rounded: true
                , cornerRadius: self.badge.layer.cornerRadius)
            self.label.align(toTheRightOf: self.badge, matchingCenterWithLeftPadding: 4, width: self.label.width(), height: 22)
        }
        self.buttonScrim.fillSuperview(withLeftPadding: -8, rightPadding: -8, topPadding: -8, bottomPadding: -8)
    }
    
    func initialize() {
        self.backImage.image = UIImage(named: "imgArrowLeftLight")
        self.backImage.tintColor = Colors.white
        
        self.badge.textColor = Colors.white
        self.badge.layer.backgroundColor = Theme.colorBackgroundBadge.cgColor
        self.badge.text = (UserController.instance.unreads! > 0) ? "\(String(describing: UserController.instance.unreads))" : nil
        self.badge.font = UIFont(name: "HelveticaNeue", size: 14)
        self.badge.clipsToBounds = true
        self.badge.textAlignment = .center
        
        self.label.textColor = Colors.white
        self.label.text = nil
        self.label.font = UIFont(name: "HelveticaNeue-Light", size: 18)
        self.label.textAlignment = .left
        
        self.buttonScrim.setBackgroundImage(ImageUtils.imageFromColor(color: Colors.clear), for: .highlighted)
        
        self.addSubview(self.backImage)
        self.addSubview(self.badge)
        self.addSubview(self.label)
        self.insertSubview(self.buttonScrim, at: 3)
    }
    
}
