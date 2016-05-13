//
//  UserDetailView.swift
//  Patchr
//
//  Created by Jay Massena on 10/24/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class PatchDetailView: BaseDetailView {
	
	var contextAction		: ContextAction = .SharePatch
	var photoRect			: CGRect!
	var infoVisible			= false
	
	var contentGroup		= UIView()
	
	var bannerGroup			= UIView()
	var photo				= AirImageView(frame: CGRectZero)
	
	var titleGroup			= UIView()
	var name				= AirLabelDisplay()
	var type				= AirLabelDisplay()
	var visibility			= AirLabelDisplay()
	var lockImage			= AirImageView(frame: CGRectZero)
	
	var buttonGroup			= UIView()
	var mapButton			= AirToolButton()
	var watchersButton		= AirLinkButton()
	var photosButton		= AirLinkButton()
	var soundButton			= AirMuteButton()
	var moreButton			= AirToolButton()
	
	var contextGroup		= AirRuleView()
	var contextView			: UIView = AirFeaturedButton()
	
	var infoGroup			= AirRuleView()
	
	var infoTitleGroup		= UIView()
	var infoName			= AirLabelDisplay()
	var infoType			= AirLabelDisplay()
	var infoVisibility		= AirLabelDisplay()
	var infoLockImage		= AirImageView(frame: CGRectZero)
	var infoDescription		= TTTAttributedLabel(frame: CGRectZero)
	
	var infoButtonGroup		= UIView()
	var infoOwnerLabel		= AirLabelDisplay()
	var infoOwner			= AirLabelDisplay()
	var infoMoreButton		= AirToolButton()
	var gradient			= CAGradientLayer()
	
	/*--------------------------------------------------------------------------------------------
	* Lifecycle
	*--------------------------------------------------------------------------------------------*/
	
	init() {
		super.init(frame: CGRectZero)
		initialize()
	}
	
	override init(frame: CGRect) {
		/* Called when instantiated from code */
		super.init(frame: frame)
		initialize()
	}
	
	init(contextView: UIView!) {
		super.init(frame: CGRectZero)
		self.contextView = contextView
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
		
		self.infoGroup.hidden = true
		self.bannerGroup.hidden = false
		let viewWidth = self.bounds.size.width
		let viewHeight = viewWidth * 0.625
		
		self.contentGroup.anchorTopCenterFillingWidthWithLeftAndRightPadding(0, topPadding: 0, height: viewHeight) // 16:10
		self.bannerGroup.fillSuperview()
		
		self.buttonGroup.anchorBottomCenterFillingWidthWithLeftAndRightPadding(0, bottomPadding: 0, height: 48)
		self.mapButton.anchorCenterLeftWithLeftPadding(0, width: self.mapButton.width(), height: self.mapButton.height())
		self.moreButton.anchorCenterRightWithRightPadding(0, width: self.moreButton.width(), height: self.moreButton.height())
		self.soundButton.alignToTheLeftOf(self.moreButton, matchingCenterWithRightPadding: 0, width: self.soundButton.width(), height: self.soundButton.height())
		
		self.titleGroup.alignAbove(self.buttonGroup, withLeftPadding: 68, bottomPadding: 0, width: viewWidth - 68, height: 72)
		self.name.bounds.size.width = self.titleGroup.width()
		self.name.sizeToFit()
		self.name.anchorBottomLeftWithLeftPadding(0, bottomPadding: 0, width: self.name.width(), height: self.name.height())
		self.type.sizeToFit()
		self.type.alignAbove(self.name, withLeftPadding: 0, bottomPadding: 0, width: self.type.width(), height: self.type.height())
		self.lockImage.alignToTheRightOf(self.type, matchingCenterWithLeftPadding: 4, width: 16, height: 16)
		
		let gradientHeight = self.bannerGroup.width() * 0.35
		self.gradient.frame = CGRectMake(0, self.bannerGroup.height() - gradientHeight, self.bannerGroup.width(), gradientHeight)
		
		self.photosButton.anchorTopLeftWithLeftPadding(0, topPadding: 0, width: (viewWidth / 2) - 1, height: 48)
		self.watchersButton.anchorTopRightWithRightPadding(0, topPadding: 0, width: viewWidth / 2, height: 48)

		/* Context Group */
		if self.contextView is UIButton {
			self.contextGroup.alignUnder(self.bannerGroup, centeredFillingWidthWithLeftAndRightPadding: 0, topPadding: 0, height: 96)
			self.contextView.anchorBottomCenterWithBottomPadding(0, width: viewWidth, height: 48)
		}
		else if self.contextView is UserInviteView {
			self.contextView.resizeToFitSubviews()
			self.contextGroup.alignUnder(self.bannerGroup, centeredFillingWidthWithLeftAndRightPadding: 0, topPadding: 0, height: self.contextView.height() + 32 + 48)
			self.contextView.anchorBottomCenterWithBottomPadding(16, width: viewWidth - 32, height: self.contextView.height() + 32)
		}
		
		/* Info Group */
		
		self.infoGroup.fillSuperview()
		
		self.infoName.bounds.size.width = viewWidth - 32
		self.infoName.sizeToFit()
		self.infoName.anchorTopLeftWithLeftPadding(0, topPadding: 0, width: self.infoName.width(), height: self.infoName.height())
		
		self.infoType.sizeToFit()
		self.infoType.alignUnder(self.infoName, withLeftPadding: 0, topPadding: 0, width: self.infoType.width(), height: self.infoType.height())
		self.infoLockImage.alignToTheRightOf(self.infoType, matchingCenterWithLeftPadding: 4, width: 16, height: 16)
		self.infoVisibility.sizeToFit()
		self.infoVisibility.alignToTheRightOf(self.infoLockImage, matchingCenterWithLeftPadding: 4, width: self.infoVisibility.width(), height: self.infoVisibility.height())
		
		self.infoTitleGroup.anchorTopCenterFillingWidthWithLeftAndRightPadding(16, topPadding: 16, height: self.infoGroup.height() - 48)
		
		self.infoDescription.bounds.size.width = viewWidth - 32
		self.infoDescription.sizeToFit()
		self.infoDescription.alignUnder(self.infoType, matchingLeftAndFillingWidthWithRightPadding: 16, topPadding: 8, height: self.infoDescription.height())
		
		self.infoButtonGroup.anchorBottomCenterFillingWidthWithLeftAndRightPadding(0, bottomPadding: 0, height: 48)
		self.infoOwnerLabel.sizeToFit()
		self.infoOwner.sizeToFit()
		self.infoOwnerLabel.anchorCenterLeftFillingHeightWithTopPadding(0, bottomPadding: 0, leftPadding: 16, width: self.infoOwnerLabel.width())
		self.infoOwner.alignToTheRightOf(self.infoOwnerLabel, matchingCenterWithLeftPadding: 4, width: self.infoOwner.width(), height: self.infoOwner.height())
		self.infoMoreButton.anchorCenterRightFillingHeightWithTopPadding(0, bottomPadding: 0, rightPadding: 0, width: self.infoMoreButton.width())
	}
	
	func watchDidChange(sender: NSNotification) {
		if self.entity?.countWatchingValue == 0 {
			if self.watchersButton.alpha != 0 {
				self.watchersButton.fadeOut()
			}
		}
		else {
			let watchersTitle = "\(self.entity?.countWatching ?? 0) MEMBERS"
			self.watchersButton.setTitle(watchersTitle, forState: UIControlState.Normal)
			if self.watchersButton.alpha == 0 {
				self.watchersButton.fadeIn()
			}
		}
		if (self.entity?.userWatchStatusValue == .Member) {
			self.soundButton.fadeIn(alpha: 1.0)
		}
		else {
			self.soundButton.fadeOut(alpha: 0.0)
		}
	}
	
	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/
	
	func initialize() {
		
		self.titleGroup.addSubview(self.name)
		self.titleGroup.addSubview(self.type)
		self.titleGroup.addSubview(self.visibility)
		self.titleGroup.addSubview(self.lockImage)
		
		self.buttonGroup.addSubview(self.mapButton)
		self.buttonGroup.addSubview(self.soundButton)
		self.buttonGroup.addSubview(self.moreButton)
		
		self.bannerGroup.addSubview(self.photo)
		self.bannerGroup.addSubview(self.titleGroup)
		self.bannerGroup.addSubview(self.buttonGroup)
		
		self.infoTitleGroup.addSubview(self.infoName)
		self.infoTitleGroup.addSubview(self.infoType)
		self.infoTitleGroup.addSubview(self.infoVisibility)
		self.infoTitleGroup.addSubview(self.infoLockImage)
		self.infoTitleGroup.addSubview(self.infoDescription)
		
		self.infoButtonGroup.addSubview(self.infoOwnerLabel)
		self.infoButtonGroup.addSubview(self.infoOwner)
		self.infoButtonGroup.addSubview(self.infoMoreButton)
		
		self.infoGroup.addSubview(self.infoTitleGroup)
		self.infoGroup.addSubview(self.infoButtonGroup)
		
		self.contentGroup.addSubview(self.bannerGroup)
		self.contentGroup.addSubview(self.infoGroup)
		
		self.contextGroup.addSubview(self.photosButton)
		self.contextGroup.addSubview(self.watchersButton)
		self.contextGroup.addSubview(self.contextView)
		
		self.addSubview(contentGroup)
		self.addSubview(contextGroup)
		
		self.clipsToBounds = false
		self.backgroundColor = Theme.colorBackgroundForm
		
		self.photo.parallaxIntensity = -40
		self.photo.sizeCategory = SizeCategory.standard
		self.photo.clipsToBounds = true
		self.photo.contentMode = UIViewContentMode.ScaleAspectFill
		self.photo.backgroundColor = Theme.colorBackgroundImage
		
		let bannerTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(PatchDetailView.flipToInfo(_:)))
		self.bannerGroup.addGestureRecognizer(bannerTapGestureRecognizer)
		let infoTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(PatchDetailView.flipToBanner(_:)))
		self.infoGroup.addGestureRecognizer(infoTapGestureRecognizer)
		
		/* Apply gradient to banner */
		let topColor:   UIColor = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.0))		// Top
		let stop2Color:   UIColor = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.33))	// Middle
		let bottomColor: UIColor = UIColor(red: CGFloat(0), green: CGFloat(0), blue: CGFloat(0), alpha: CGFloat(0.66))		// Bottom
		self.gradient.colors = [topColor.CGColor, stop2Color.CGColor, bottomColor.CGColor]
		self.gradient.locations = [0.0, 0.5, 1.0]
		
		/* Travels from top to bottom */
		self.gradient.startPoint = CGPoint(x: 0.5, y: 0.0)	// (0,0) upper left corner, (1,1) lower right corner
		self.gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
		self.bannerGroup.layer.insertSublayer(self.gradient, atIndex: 1)
		
		self.name.font = UIFont(name: "HelveticaNeue-Light", size: 28)!
		self.name.textColor = Colors.white
		self.name.numberOfLines = 2
		
		self.type.font = Theme.fontTextDisplay
		self.type.textColor = Colors.white
		
		self.infoName.font = UIFont(name: "HelveticaNeue-Light", size: 28)!
		self.infoName.textColor = Theme.colorTextTitle
		self.infoName.numberOfLines = 2
		
		self.infoType.font = Theme.fontTextDisplay
		self.infoType.textColor = Theme.colorTextSecondary
		
		self.infoVisibility.font = Theme.fontTextDisplay
		self.infoVisibility.textColor = Theme.colorTextSecondary
		self.infoVisibility.text = "Private".uppercaseString
		
		self.infoDescription.numberOfLines = SCREEN_320 ? 3 : SCREEN_375 ? 5 : 6
		self.infoDescription.verticalAlignment = .Top
		self.infoDescription.font = Theme.fontTextDisplay
		self.infoDescription.userInteractionEnabled = true
		self.infoDescription.attributedTruncationToken = NSAttributedString(string: "...more",
			attributes: [NSForegroundColorAttributeName: Colors.brandOnLight, NSLinkAttributeName: NSURL(string: "http://more.com")!, NSFontAttributeName: Theme.fontTextDisplay])
		self.infoDescription.delegate = self
		
		self.infoOwnerLabel.text = "Patch owned by"
		self.infoOwnerLabel.font = Theme.fontTextDisplay
		self.infoOwner.font = Theme.fontTextDisplay
		self.infoOwner.textColor = Theme.colorTextTitle
		
		self.lockImage.image = Utils.imageLock
		self.lockImage.tintColor = Colors.white
		
		self.infoLockImage.image = Utils.imageLock
		self.infoLockImage.tintColor = Colors.accentOnLight
		
		self.mapButton.setImage(UIImage(named: "imgMapLight")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate), forState: .Normal)
		self.mapButton.bounds.size = CGSizeMake(48, 48)
		self.mapButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
		
		self.moreButton.setImage(UIImage(named: "imgOverflowLight")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate), forState: .Normal)
		self.moreButton.bounds.size = CGSizeMake(48, 48)
		self.moreButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
		
		self.infoMoreButton.setImage(UIImage(named: "imgOverflowLight")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate), forState: .Normal)
		self.infoMoreButton.bounds.size = CGSizeMake(48, 48)
		self.infoMoreButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
		
		self.photosButton.setTitle("PHOTOS", forState: .Normal)
		self.photosButton.contentHorizontalAlignment = .Center
		self.photosButton.backgroundColor = Colors.gray95pcntColor
		
		self.watchersButton.contentHorizontalAlignment = .Center
		self.watchersButton.backgroundColor = Colors.gray95pcntColor
		
		self.soundButton.setProgressStyle(UIActivityIndicatorViewStyle.White)
		self.soundButton.imageOn = UIImage(named: "imgSoundOn2Light")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
		self.soundButton.imageOff = UIImage(named: "imgSoundOff2Light")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
		self.soundButton.messageOn = "Notifications active"
		self.soundButton.messageOff = "Notifications muted"
		self.soundButton.bounds.size = CGSizeMake(48, 48)
		self.soundButton.imageEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
		self.soundButton.alpha = 0.0
		
		self.contextView.layer.cornerRadius = 0

		self.bannerGroup.clipsToBounds = true
	}
	
	func bindToEntity(entity: Entity!) {
		
		if let entity = entity as? Patch {
			
			self.entity = entity
			
			/* Name, type and photo */
			
			self.name.text = entity.name
			self.type.text = entity.type == nil ? "PATCH" : entity.type.uppercaseString + " PATCH"
			
			if entity.photo != nil {
				self.photo.setImageWithPhoto(entity.photo, animate: false)
			}
			else {
				let seed = Utils.numberFromName(self.name.text!)
				self.photo.backgroundColor = Utils.randomColor(seed)
			}
			
			/* Privacy */
			
			self.lockImage.hidden = (entity.visibility == "public")
			self.infoLockImage.hidden = (entity.visibility == "public")
			self.visibility.hidden = (entity.visibility == "public")
			self.infoVisibility.hidden = (entity.visibility == "public")
			
			/* Map button */
			self.mapButton.hidden = (entity.location == nil)
			
			/* Watching button */
			
			if entity.countWatchingValue == 0 {
				if self.watchersButton.alpha != 0 {
					self.watchersButton.fadeOut()
				}
			}
			else {
				let watchersTitle = "\(entity.countWatching ?? 0) \(entity.countWatchingValue == 1 ? "MEMBER": "MEMBERS")"
				self.watchersButton.setTitle(watchersTitle, forState: UIControlState.Normal)
				if self.watchersButton.alpha == 0 {
					self.watchersButton.fadeIn()
				}
			}
			
			/* Mute button */
			
			self.soundButton.bindEntity(entity)
			if (entity.userWatchStatusValue == .Member) {
				self.soundButton.fadeIn(alpha: 1.0)
			}
			else {
				self.soundButton.fadeOut(alpha: 0.0)
			}
			
			/* Info view */
			self.infoName.text = entity.name
			if entity.type != nil {
				self.infoType.text = entity.type.uppercaseString + " PATCH"
			}
			self.infoDescription.text = entity.description_
			self.infoOwner.text = entity.creator?.name ?? "Deleted"
		}
		
		self.setNeedsLayout()	// Needed because binding can change element layout
		self.layoutIfNeeded()
		self.sizeToFit()
	}
	
	func flipToInfo(sender: AnyObject) {
		UIView.transitionFromView(self.bannerGroup, toView: self.infoGroup, duration: 0.4, options: [.TransitionFlipFromBottom, .ShowHideTransitionViews, .CurveEaseOut], completion: nil);
	}
	
	func flipToBanner(sender: AnyObject) {
		UIView.transitionFromView(self.infoGroup, toView: self.bannerGroup, duration: 0.4, options: [.TransitionFlipFromTop, .ShowHideTransitionViews, .CurveEaseOut], completion: nil);
	}
}

extension PatchDetailView: TTTAttributedLabelDelegate {
	
	func attributedLabel(label: TTTAttributedLabel!, didSelectLinkWithURL url: NSURL!) {
		let controller = TextZoomController()
		controller.inputMessage = self.entity?.description_
		controller.modalPresentationStyle = .OverFullScreen
		controller.modalTransitionStyle	= .CrossDissolve
		let hostController = UIViewController.topMostViewController()!
		hostController.presentViewController(controller, animated: true, completion: nil)
	}
}

