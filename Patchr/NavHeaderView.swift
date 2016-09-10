//
//  UserDetailView.swift
//  Patchr
//
//  Created by Jay Massena on 10/24/15.
//  Copyright © 2015 3meters. All rights reserved.
//

import UIKit

class NavHeaderView: BaseDetailView {

	var name           = AirLabelTitle()
	var photo          = UserPhotoView()
    var switchButton   = UIButton()
	var userGroup      = UIView()
    var gradient       = CAGradientLayer()
    var searchBar      = UISearchBar()
	
	init() {
		super.init(frame: CGRectZero)
		initialize()
	}
	
	override init(frame: CGRect) {
		/* Called when instantiated from code */
		super.init(frame: frame)
		initialize()
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("This view should never be loaded from storyboard")
	}
	
	func initialize() {
		
		self.clipsToBounds = true
		self.backgroundColor = Theme.colorBackgroundForm
        
        /* Apply gradient to banner */
        let startColor = Colors.brandColor
        let endColor = Colors.accentColor
        
        self.gradient.colors = [startColor.CGColor, endColor.CGColor]
        self.gradient.locations = [0.0, 1.0]
        
        /* Travels from left to right */
        self.gradient.startPoint = CGPoint(x: 0.0, y: 0.5)    // (0,0) upper left corner, (1,1) lower right corner
        self.gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
        self.userGroup.layer.addSublayer(self.gradient)
		
		/* Name */
		self.name.lineBreakMode = .ByTruncatingMiddle
		self.name.font = Theme.fontTextBold
        self.name.textColor = Colors.white
        
        self.switchButton.setImage(UIImage(named: "imgSwitchLight"), forState: .Normal)
        self.switchButton.imageEdgeInsets = UIEdgeInsetsMake(4, 4, 4, 4)
        self.switchButton.imageView?.tintColor = Colors.white
        
        self.photo.borderWidth = 1
        self.photo.borderColor = Theme.colorScrimLighten
		
		self.userGroup.addSubview(self.photo)
		self.userGroup.addSubview(self.name)
        self.userGroup.addSubview(self.switchButton)
		self.addSubview(self.userGroup)
        self.addSubview(self.searchBar)
	}
	
	override func layoutSubviews() {
		super.layoutSubviews()
        
        self.gradient.frame = CGRectMake(0, 0, self.bounds.size.width + 10, self.bounds.size.height + 10)
		
		self.userGroup.anchorTopCenterFillingWidthWithLeftAndRightPadding(0, topPadding: 0, height: 64)
		self.photo.anchorCenterLeftWithLeftPadding(16, width: 48, height: 48)
		self.name.alignToTheRightOf(self.photo, matchingCenterWithLeftPadding: 12, width: 200, height: 24)
        self.switchButton.anchorCenterRightWithRightPadding(8, width: 36, height: 36)
        self.searchBar.alignUnder(self.userGroup, matchingLeftAndRightWithTopPadding: 0, height: 48)
	}
	
	func bindToEntity(entity: Entity!) {
		self.name.text?.removeAll(keepCapacity: false)
		self.name.text = entity.name
		self.photo.bindToEntity(entity)
	}
}
