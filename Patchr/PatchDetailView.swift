//
//  UserDetailView.swift
//  Patchr
//
//  Created by Jay Massena on 10/24/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class PatchDetailView: BaseDetailView {

    var contextAction: ContextAction = .SharePatch
    var photoRect: CGRect!
    var infoVisible = false

    var contentGroup = UIView()

    var bannerGroup = UIView()
    var photo = AirImageView(frame: CGRect.zero)

    var titleGroup = UIView()
    var name = AirLabelDisplay()
    var settings = AirLabelDisplay()
    var visibility = AirLabelDisplay()
    var lockImage = AirImageView(frame: CGRect.zero)
    var mutedImage = AirImageView(frame: CGRect.zero)

    var buttonGroup = AirRuleView()
    var membersButton = AirLinkButton()
    var photosButton = AirLinkButton()
    var contextButton: UIView = AirFeaturedButton()

    var infoGroup = AirRuleView()

    var infoTitleGroup = UIView()
    var infoName = AirLabelDisplay()
    var infoType = AirLabelDisplay()
    var infoSettings = AirLabelDisplay()
    var infoVisibility = AirLabelDisplay()
    var infoLockImage = AirImageView(frame: CGRect.zero)
    var infoDescription = TTTAttributedLabel(frame: CGRect.zero)

    var infoButtonGroup = UIView()
    var infoOwnerLabel = AirLabelDisplay()
    var infoOwner = AirLabelDisplay()
    var gradient = CAGradientLayer()

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/

    init() {
        super.init(frame: CGRect.zero)
        initialize()
    }

    override init(frame: CGRect) {
        /* Called when instantiated from code */
        super.init(frame: frame)
        initialize()
    }

    init(contextView: UIView!) {
        super.init(frame: CGRect.zero)
        self.contextButton = contextView
        initialize()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("This view should never be loaded from storyboard")
    }

    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/

    override func layoutSubviews() {
        /*
         * Scrolling does not cause this to be called.
         */
        super.layoutSubviews()

        self.infoGroup.isHidden = true
        self.bannerGroup.isHidden = false
        let viewWidth = self.bounds.size.width
        let viewHeight = viewWidth * 0.625

        self.contentGroup.anchorTopCenterFillingWidth(withLeftAndRightPadding: 0, topPadding: 0, height: viewHeight) // 16:10
        self.bannerGroup.fillSuperview()

        self.titleGroup.anchorBottomLeft(withLeftPadding: 68, bottomPadding: 16, width: viewWidth - 68, height: 72)

        self.name.bounds.size.width = self.titleGroup.width()
        self.name.sizeToFit()
        self.name.anchorBottomLeft(withLeftPadding: 0, bottomPadding: 0, width: self.name.width(), height: self.name.height())
        self.lockImage.align(toTheRightOf: self.name, matchingCenterWithLeftPadding: 4, width: !self.lockImage.isHidden ? 16 : 0, height: !self.lockImage.isHidden ? 16 : 0)
        self.mutedImage.align(toTheRightOf: self.lockImage, matchingCenterWithLeftPadding: 4, width: !self.mutedImage.isHidden ? 20 : 0, height: !self.mutedImage.isHidden ? 20 : 0)

        let gradientHeight = self.bannerGroup.width() * 0.35
        self.gradient.frame = CGRect(x:0, y:self.bannerGroup.height() - gradientHeight, width:self.bannerGroup.width(), height:gradientHeight)

        self.photosButton.anchorTopLeft(withLeftPadding: 0, topPadding: 0, width: (viewWidth / 2) - 1, height: 44)
        self.membersButton.anchorTopRight(withRightPadding: 0, topPadding: 0, width: viewWidth / 2, height: 44)

        /* Context Group */
        if self.contextButton is UIButton {
            self.buttonGroup.alignUnder(self.bannerGroup, centeredFillingWidthWithLeftAndRightPadding: 0, topPadding: 0, height: !self.contextButton.isHidden ? 100 : 44)
            self.contextButton.anchorBottomCenter(withBottomPadding: 6, width: viewWidth - 12, height: !self.contextButton.isHidden ? 44 : 0)
        }
        else if self.contextButton is UserInviteView {
            self.contextButton.resizeToFitSubviews()
            self.buttonGroup.alignUnder(self.bannerGroup, centeredFillingWidthWithLeftAndRightPadding: 0, topPadding: 0, height: self.contextButton.height() + 32 + 48)
            self.contextButton.anchorBottomCenter(withBottomPadding: 16, width: viewWidth - 32, height: self.contextButton.height())
        }

        /* Info Group */

        self.infoGroup.fillSuperview()

        self.infoName.bounds.size.width = viewWidth - 32
        self.infoName.sizeToFit()
        self.infoName.anchorTopLeft(withLeftPadding: 0, topPadding: 0, width: self.infoName.width(), height: self.infoName.height())

        self.infoType.sizeToFit()
        self.infoSettings.sizeToFit()

        self.infoType.alignUnder(self.infoName, withLeftPadding: 0, topPadding: 0, width: self.infoType.width(), height: self.infoType.height())
        self.infoSettings.alignUnder(self.infoType, withLeftPadding: 0, topPadding: 0, width: self.infoSettings.width(), height: self.infoSettings.height())

        self.infoLockImage.align(toTheRightOf: self.infoType, matchingCenterWithLeftPadding: 4, width: 16, height: 16)
        self.infoVisibility.sizeToFit()
        self.infoVisibility.align(toTheRightOf: self.infoLockImage, matchingCenterWithLeftPadding: 4, width: self.infoVisibility.width(), height: self.infoVisibility.height())

        self.infoTitleGroup.anchorTopCenterFillingWidth(withLeftAndRightPadding: 16, topPadding: 16, height: self.infoGroup.height() - 48)

        self.infoDescription.bounds.size.width = viewWidth - 32
        self.infoDescription.sizeToFit()
        self.infoDescription.alignUnder(self.infoSettings, matchingLeftAndFillingWidthWithRightPadding: 16, topPadding: 8, height: self.infoDescription.height())

        self.infoButtonGroup.anchorBottomCenterFillingWidth(withLeftAndRightPadding: 0, bottomPadding: 0, height: 48)
        self.infoOwnerLabel.sizeToFit()
        self.infoOwner.sizeToFit()
        self.infoOwnerLabel.anchorCenterLeftFillingHeight(withTopPadding: 0, bottomPadding: 0, leftPadding: 16, width: self.infoOwnerLabel.width())
        self.infoOwner.align(toTheRightOf: self.infoOwnerLabel, matchingCenterWithLeftPadding: 4, width: self.infoOwner.width(), height: self.infoOwner.height())
    }

    func watchDidChange(sender: NSNotification) {
        if self.entity?.countWatchingValue == 0 {
            if self.membersButton.alpha != 0 {
                self.membersButton.fadeOut()
            }
        }
        else {
            let watchersTitle = "\(self.entity?.countWatching ?? 0) MEMBERS"
            self.membersButton.setTitle(watchersTitle, for: UIControlState.normal)
            if self.membersButton.alpha == 0 {
                self.membersButton.fadeIn()
            }
        }
    }

    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/

    func initialize() {

        self.titleGroup.addSubview(self.name)
        self.titleGroup.addSubview(self.settings)
        self.titleGroup.addSubview(self.visibility)
        self.titleGroup.addSubview(self.lockImage)
        self.titleGroup.addSubview(self.mutedImage)

        self.bannerGroup.addSubview(self.photo)
        self.bannerGroup.addSubview(self.titleGroup)

        self.infoTitleGroup.addSubview(self.infoName)
        self.infoTitleGroup.addSubview(self.infoType)
        self.infoTitleGroup.addSubview(self.infoSettings)
        self.infoTitleGroup.addSubview(self.infoVisibility)
        self.infoTitleGroup.addSubview(self.infoLockImage)
        self.infoTitleGroup.addSubview(self.infoDescription)

        self.infoButtonGroup.addSubview(self.infoOwnerLabel)
        self.infoButtonGroup.addSubview(self.infoOwner)

        self.infoGroup.addSubview(self.infoTitleGroup)
        self.infoGroup.addSubview(self.infoButtonGroup)

        self.contentGroup.addSubview(self.bannerGroup)
        self.contentGroup.addSubview(self.infoGroup)

        self.buttonGroup.addSubview(self.photosButton)
        self.buttonGroup.addSubview(self.membersButton)
        self.buttonGroup.addSubview(self.contextButton)

        self.addSubview(contentGroup)
        self.addSubview(buttonGroup)

        self.clipsToBounds = false
        self.backgroundColor = Theme.colorBackgroundForm

        self.photo.parallaxIntensity = -40
        self.photo.sizeCategory = SizeCategory.standard
        self.photo.clipsToBounds = true
        self.photo.contentMode = UIViewContentMode.scaleAspectFill
        self.photo.backgroundColor = Theme.colorBackgroundImage

        let bannerTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(PatchDetailView.flipToInfo(sender:)))
        self.bannerGroup.addGestureRecognizer(bannerTapGestureRecognizer)
        let infoTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(PatchDetailView.flipToBanner(sender:)))
        self.infoGroup.addGestureRecognizer(infoTapGestureRecognizer)

        /* Apply gradient to banner */
        let topColor: UIColor = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.0))        // Top
        let stop2Color: UIColor = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.33))    // Middle
        let bottomColor: UIColor = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.66))        // Bottom
        self.gradient.colors = [topColor.cgColor, stop2Color.cgColor, bottomColor.cgColor]
        self.gradient.locations = [0.0, 0.5, 1.0]

        /* Travels from top to bottom */
        self.gradient.startPoint = CGPoint(x: 0.5, y: 0.0)    // (0,0) upper left corner, (1,1) lower right corner
        self.gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
        self.bannerGroup.layer.insertSublayer(self.gradient, at: 1)

        self.name.font = UIFont(name: "HelveticaNeue-Light", size: 28)!
        self.name.textColor = Colors.white
        self.name.numberOfLines = 2

        self.settings.font = Theme.fontTextDisplay
        self.settings.textColor = Colors.white

        self.infoName.font = UIFont(name: "HelveticaNeue-Light", size: 28)!
        self.infoName.textColor = Theme.colorTextTitle
        self.infoName.numberOfLines = 2

        self.infoType.font = Theme.fontTextDisplay
        self.infoType.textColor = Theme.colorTextSecondary

        self.infoSettings.font = Theme.fontTextDisplay
        self.infoSettings.textColor = Colors.accentOnLight

        self.infoVisibility.font = Theme.fontTextDisplay
        self.infoVisibility.textColor = Theme.colorTextSecondary
        self.infoVisibility.text = "Private".uppercased()

        self.infoDescription.numberOfLines = SCREEN_320 ? 3 : SCREEN_375 ? 5 : 6
        self.infoDescription.verticalAlignment = .top
        self.infoDescription.font = Theme.fontTextDisplay
        self.infoDescription.isUserInteractionEnabled = true
        self.infoDescription.attributedTruncationToken = NSAttributedString(string: "...more",
                                                                            attributes: [NSForegroundColorAttributeName: Colors.brandOnLight, NSLinkAttributeName: NSURL(string: "http://more.com")!, NSFontAttributeName: Theme.fontTextDisplay])
        self.infoDescription.delegate = self

        self.infoOwnerLabel.text = "Patch owned by"
        self.infoOwnerLabel.font = Theme.fontTextDisplay
        self.infoOwner.font = Theme.fontTextDisplay
        self.infoOwner.textColor = Theme.colorTextTitle

        self.lockImage.image = Utils.imageLock
        self.lockImage.tintColor = Colors.white

        self.mutedImage.image = Utils.imageMuted
        self.mutedImage.tintColor = Colors.white

        self.infoLockImage.image = Utils.imageLock
        self.infoLockImage.tintColor = Colors.accentOnLight

        self.photosButton.setTitle("Gallery", for: .normal)
        self.photosButton.setImage(UIImage(named: "imgGallery2Light"), for: .normal)
        self.photosButton.imageView!.contentMode = UIViewContentMode.scaleAspectFit
        self.photosButton.imageView?.tintColor = Colors.brandColorDark
        self.photosButton.imageEdgeInsets = UIEdgeInsetsMake(10, 4, 10, 24)
        self.photosButton.contentHorizontalAlignment = .center
        self.photosButton.backgroundColor = Colors.gray95pcntColor

        self.membersButton.contentHorizontalAlignment = .center
        self.membersButton.backgroundColor = Colors.gray95pcntColor

        self.contextButton.isHidden = true

        self.bannerGroup.clipsToBounds = true
    }

    func bindToEntity(entity: Entity!) {

        if let entity = entity as? Patch {
            self.entity = entity

            /* Name, type and photo */

            self.name.text = entity.name
            self.settings.text = entity.lockedValue ? "Only owners can post messages" : nil

            if entity.photo != nil {
                self.photo.setImageWithPhoto(photo: entity.photo, animate: false)
            }
            else {
                let seed = Utils.numberFromName(fullname: self.name.text!)
                self.photo.backgroundColor = Utils.randomColor(seed: seed)
            }

            /* Indicators */

            self.lockImage.isHidden = (entity.visibility == "public")
            self.visibility.isHidden = (entity.visibility == "public")
            self.mutedImage.isHidden = !entity.userWatchMutedValue

            /* Members button */

            if entity.countWatchingValue == 0 {
                if self.membersButton.alpha != 0 {
                    self.membersButton.fadeOut()
                }
            }
            else {
                let watchersTitle = "\(entity.countWatching ?? 0) \(entity.countWatchingValue == 1 ? "Member" : "Members")"
                self.membersButton.setTitle(watchersTitle, for: UIControlState.normal)
                if self.membersButton.alpha == 0 {
                    self.membersButton.fadeIn()
                }
            }

            /* Info view */
            self.infoName.text = entity.name

            if entity.type != nil {
                self.infoType.text = entity.type.uppercased() + " PATCH"
            }

            /* Info indicators */
            self.infoLockImage.isHidden = (entity.visibility == "public")
            self.infoVisibility.isHidden = (entity.visibility == "public")
            self.infoSettings.text = entity.lockedValue ? "Only owners can post messages" : nil

            self.infoDescription.text = entity.description_
            self.infoOwner.text = entity.creator?.name ?? "Deleted"
        }

        self.setNeedsLayout()    // Needed because binding can change element layout
        self.layoutIfNeeded()
        self.sizeToFit()
    }

    func flipToInfo(sender: AnyObject) {
        UIView.transition(from: self.bannerGroup, to: self.infoGroup, duration: 0.4, options: [.transitionFlipFromBottom, .showHideTransitionViews, .curveEaseOut], completion: nil);
    }

    func flipToBanner(sender: AnyObject) {
        UIView.transition(from: self.infoGroup, to: self.bannerGroup, duration: 0.4, options: [.transitionFlipFromTop, .showHideTransitionViews, .curveEaseOut], completion: nil);
    }
}

extension PatchDetailView: TTTAttributedLabelDelegate {
    func attributedLabel(_ label: TTTAttributedLabel!, didSelectLinkWith url: URL!) {
        let controller = TextZoomController()
        controller.inputMessage = self.entity?.description_
        controller.modalPresentationStyle = .overFullScreen
        controller.modalTransitionStyle = .crossDissolve
        let hostController = UIViewController.topMostViewController()!
        hostController.present(controller, animated: true, completion: nil)
    }
}

