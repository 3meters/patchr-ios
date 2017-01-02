import UIKit

class UnreadBackView: UIView {

    var backImage = UIImageView()
    var badge = UILabel()
    var buttonScrim = AirScrimButton()
    
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
    
    func initialize() {
        self.badge.backgroundColor = Theme.colorBackgroundBadge
        self.badge.textColor = Colors.white
        self.badge.layer.borderColor = Colors.white.withAlphaComponent(1.0).cgColor
        self.badge.layer.borderWidth = 0.5
        self.badge.text = nil
        self.badge.font = UIFont(name: "HelveticaNeue", size: 14)
        self.badge.clipsToBounds = true
        self.badge.textAlignment = .center
        self.backImage.image = UIImage(named: "imgArrowDownLight")
        self.backImage.tintColor = Colors.white
        self.buttonScrim.setBackgroundImage(Utils.imageFromColor(color: Colors.clear), for: .highlighted)
        self.addSubview(self.backImage)
        self.addSubview(self.badge)
        self.addSubview(self.buttonScrim)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if self.badge.text != nil {
            self.badge.sizeToFit()
            self.backImage.anchorBottomCenter(withBottomPadding: 2, width: 18, height: 14)
            self.badge.align(above: self.backImage, matchingCenterWithBottomPadding: -2,
                             width: max(22, self.badge.width()),
                             height: 22)
            self.badge.layer.cornerRadius = self.badge.frame.size.height / 2
        }
        else {
            self.backImage.anchorInCenter(withWidth: 18, height: 14)
        }
        self.buttonScrim.fillSuperview()
    }
}
