//
//  PostMessageViewController.swift
//  Patchr
//
//  Created by Brent on 2015-03-09.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import Foundation

enum MessageType: Int {
    case Content
    case Share
}

class MessageEditViewController: EntityEditViewController {

    var inputMessageType: MessageType = .Content
	var inputToString: String?     // name of patch this message links to
    var inputPatchId:  String?     // id of patch this message links to
    var inputShareId:     String?
    var inputShareSchema: String = Schema.PHOTO
    var inputShareEntity: Entity?

    private var shareDescription: String!

    private let searchItems: NSMutableArray = NSMutableArray()
    private var searchInProgress = false
    private var searchTimer: NSTimer?
    private var searchEditing = false
    private var searchText: String = ""
    private var searchTableView: UITableView!

    private let toPickerPadding: CGFloat = 32

    private var suggestions: NSMutableArray = NSMutableArray()
    
	@IBOutlet weak var userPhotoImage:   	AirImageView!
    @IBOutlet weak var userNameLabel:       UILabel!
    @IBOutlet weak var toPicker:            MBContactPicker!
	@IBOutlet weak var facebookButton:		UIButton!
	
    @IBOutlet weak var descriptionCell:     UITableViewCell!
    @IBOutlet weak var photoCell:           UITableViewCell!
    @IBOutlet weak var shareCell:           UITableViewCell!

    /*--------------------------------------------------------------------------------------------
    * Lifecycle¬
    *--------------------------------------------------------------------------------------------*/
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.collection = "messages"
		self.schema = Schema.ENTITY_MESSAGE
    }
	
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.descriptionField!.placeholder = "Message"
        self.photoView!.frame = CGRectMake(16, 0, self.photoHolder!.bounds.size.width - 32, self.photoHolder!.bounds.size.height)
		
        self.toPicker.prompt = nil
        self.toPicker.showPrompt = false
		self.toPicker.bounds.size.height = 32
        self.toPicker.cellHeight = 32
		
		let tap = UITapGestureRecognizer(target: self, action: "focusToPicker:");
		tap.delegate = self
		tap.cancelsTouchesInView = false
		self.toPicker.addGestureRecognizer(tap)
		
        MBContactPicker.appearance().font = UIFont(name:"HelveticaNeue-Light", size: 18)
        MBContactCollectionViewEntryCell.appearance().font = UIFont(name:"HelveticaNeue-Light", size: 18)
        MBContactCollectionViewContactCell.appearance().font = UIFont(name:"HelveticaNeue-Light", size: 18)
		MBContactCollectionViewContactCell.appearance().tintColor = Colors.brandColorDark
		MBContactCollectionViewEntryCell.appearance().tintColor = Colors.brandColorDark
		MBContactCollectionViewPromptCell.appearance().tintColor = Colors.brandColorDark

        self.toPicker.dynamicBinding = true
        
        self.toPicker.delegate = self
        self.toPicker.datasource = self
        
        if self.inputMessageType == .Share {
            
            self.toPicker.borderWidth = 1
            self.toPicker.borderColor = Colors.windowColor
            self.toPicker.cornerRadius = 4
            
            self.progressStartLabel = "Inviting"
            self.progressFinishLabel = "Invites sent!"
            self.cancelledLabel = "Invites cancelled"
			
			self.photoHolder?.hidden = true
            
            if self.inputShareSchema == Schema.ENTITY_PATCH {
                self.navigationItem.title = Utils.LocalizedString("Invite to patch")
                self.shareDescription = "You\'re invited to the \'\(self.inputShareEntity!.name!)\' patch!"
            }
            else if self.inputShareSchema == Schema.ENTITY_MESSAGE {
                self.navigationItem.title = Utils.LocalizedString("Share message")
                if let message = self.inputShareEntity as? Message {
                    if message.patch != nil {
                        self.shareDescription = "Check out \(message.creator.name!)\'s message to the \'\(message.patch.name)\' patch!"
                    }
                    else {
                        self.shareDescription = "Check out \(message.creator.name!)\'s message to a patch!"
                    }
                }
            }
            
            self.descriptionField!.placeholderColor = UIColor.clearColor()
            
            if let user = UserController.instance.currentUser {
                self.userPhotoImage.setImageWithPhoto(user.getPhotoManaged())
                self.userNameLabel.text = user.name
            }
            
            /* Navigation bar buttons */
            let doneButton   = UIBarButtonItem(title: "Send", style: UIBarButtonItemStyle.Plain, target: self, action: "doneAction:")
            self.navigationItem.rightBarButtonItems = [doneButton]
            
            /* Pull state from patch we are editing */
            bind()
        }
        else {
            
            self.toPicker.enabled = false
            self.toPicker.collectionView.allowsSelection = false
            self.toPicker.maxVisibleRows = 1
            self.shareCell.hidden = true

            if self.editMode {
                
                self.progressStartLabel = "Updating"
                self.progressFinishLabel = "Updated!"
                self.cancelledLabel = "Update cancelled"
                navigationItem.title = Utils.LocalizedString("Edit message")
                
                /* Navigation bar buttons */
                let deleteButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Trash, target: self, action: "deleteAction:")
                let doneButton   = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Save, target: self, action: "doneAction:")
                self.navigationItem.rightBarButtonItems = [doneButton, spacer, deleteButton]
                
                /* Box the description to make edit mode more obvious */
                self.descriptionField!.borderWidth = 0.5
                self.descriptionField!.borderColor = Colors.windowColor
                self.descriptionField!.cornerRadius = 4
                self.descriptionField!.textContainer.lineFragmentPadding = 0
                self.descriptionField!.textContainerInset = UIEdgeInsetsMake(8, 8, 8, 8)
                
                /* Pull state from patch we are editing */
                bind()
            }
            else {
                
                self.progressStartLabel = "Sending"
                self.progressFinishLabel = "Sent!"
                self.cancelledLabel = "Send cancelled"
                self.descriptionField!.placeholderColor = UIColor.clearColor()
                
                if let user = UserController.instance.currentUser {
                    self.userPhotoImage.setImageWithPhoto(user.getPhotoManaged())
                    self.userNameLabel.text = user.name
                }
                
                /* Navigation bar buttons */
                let doneButton = UIBarButtonItem(title: "Send", style: UIBarButtonItemStyle.Plain, target: self, action: "doneAction:")
                self.navigationItem.rightBarButtonItems = [doneButton]
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setScreenName("MessageEdit")
    }
    
    override func viewDidAppear(animated: Bool) {
        if self.photoView!.photoChosen {
            self.photoView!.photoChosen = false
            let rowFrame = self.tableView.rectForRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 0))
            let currentOffsetBottom = self.tableView.contentOffset.y + self.tableView.frame.size.height
            let currentRowBottom = rowFrame.origin.y + rowFrame.size.height
            let newOffset = self.tableView.contentOffset.y + (currentRowBottom - currentOffsetBottom)
            if newOffset > 0 {
                self.tableView.setContentOffset(CGPoint(x: 0, y: newOffset), animated: true)
            }
        }
        if self.inputMessageType == .Share {
            self.toPicker.becomeFirstResponder()
        }
        else if !editMode && self.firstAppearance {
            self.descriptionField.becomeFirstResponder()
        }
    }
	
	override func viewWillDisappear(animated: Bool) {
		super.viewWillDisappear(animated)
	}
	
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/
	
	func focusToPicker(sender: AnyObject?) {
		self.toPicker.becomeFirstResponder()
	}
	
    func searchTextChanged(sender: AnyObject?) {
        Log.d("searchTextChanged called")
    }
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    override func bind() {
        super.bind()
        
        if let message = self.inputEntity as? Message {
            /* User */
            self.userPhotoImage.setImageWithPhoto(message.creator.getPhotoManaged())
            self.userNameLabel.text = message.creator.name
        }
        
        /* Share */
        if self.inputMessageType == .Share {
            
            /* Set the default description */
            self.descriptionField.text = self.shareDescription
			
			/* Share entity */
			
            var shareView: BaseView!
            if self.inputShareSchema == Schema.ENTITY_PATCH {
				
				shareView = PatchView()
				let shareView = shareView as! PatchView
				
				shareView.borderColor = Colors.gray80pcntColor
				shareView.borderWidth = 1
				shareView.cornerRadius = 6
				shareView.shadow.backgroundColor = UIColor.clearColor()
				
				shareView.bindToEntity(self.inputShareEntity!, location: nil)
				
				self.shareCell.contentView.addSubview(shareView)
				self.shareCell.contentView.frame.size.height = 128
				shareView.fillSuperviewWithLeftPadding(12, rightPadding: 12, topPadding: 0, bottomPadding: 0)
            }
            else if self.inputShareSchema == Schema.ENTITY_MESSAGE {
				
				let holderView = UIView()
				holderView.clipsToBounds = true
				holderView.borderColor = Colors.gray80pcntColor
				holderView.borderWidth = 1
				holderView.cornerRadius = 6
				
				var cellType: CellType = .TextAndPhoto
				if self.inputShareEntity!.photo == nil {
					cellType = .Text
				}
				else if self.inputShareEntity!.description_ == nil {
					cellType = .Photo
				}
				
				shareView = MessageView(cellType: cellType)
				let shareView = shareView as! MessageView
				
				shareView.bindToEntity(self.inputShareEntity!)
				
				holderView.addSubview(shareView)
				self.shareCell.contentView.addSubview(holderView)
				
				/* Need correct width before layout and sizing */
				holderView.fillSuperviewWithLeftPadding(12, rightPadding: 12, topPadding: 0, bottomPadding: 0)
				shareView.fillSuperviewWithLeftPadding(12, rightPadding: 12, topPadding: 12, bottomPadding: 12)
				
				shareView.setNeedsLayout()
				shareView.layoutIfNeeded()
				shareView.sizeToFit()
				
				/* Row height not set until reloadData called below */
				self.shareCell.contentView.frame.size.height = shareView.bounds.size.height + 24
				holderView.fillSuperviewWithLeftPadding(12, rightPadding: 12, topPadding: 0, bottomPadding: 0)
            }
        }
    }
    
    func suggest() {
        
        if self.searchInProgress {
            return
        }
        
        self.searchInProgress = true
        let searchString = self.searchText
        
        Log.d("Suggest call: \(searchString)")
        
        let endpoint: String = "https://api.aircandi.com/v1/suggest"
        let request = NSMutableURLRequest(URL: NSURL(string: endpoint)!)
        let session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
        
        let body = [
            "users": true,
            "input": searchString.lowercaseString,
            "limit":10 ] as [String:AnyObject]
        
        do {
            request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(body, options: [])
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            let task = session.dataTaskWithRequest(request, completionHandler: {
                data, response, error -> Void in
                
                self.searchInProgress = false
                self.searchItems.removeAllObjects()
                self.suggestions.removeAllObjects()
                
                if error == nil {
                    let json:JSON = JSON(data: data!)
                    let results = json["data"]
                    for (index: _, subJson) in results {
                        let patch: AnyObject = subJson.object
                        self.searchItems.addObject(patch)
                        
                        let model = SuggestionModel()
                        model.contactTitle = subJson["name"].string
                        model.contactImage = UIImage(named: "imgDefaultUser")
                        model.entityId = (subJson["_id"] != nil) ? subJson["_id"].string : subJson["id_"].string
                        
                        if subJson["photo"] != nil {
                            
                            let prefix = subJson["photo"]["prefix"].string
                            let source = subJson["photo"]["source"].string
                            let photoUrl = PhotoUtils.url(prefix!, source: source!, category: SizeCategory.profile)
                            model.contactImageUrl = photoUrl
                            model.contactImage = UIImage(named: "imgDefaultUser")
                        }
                        self.suggestions.addObject(model)
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), {
                        self.toPicker.showSuggestions(self.suggestions as [AnyObject])
                    })
                }
            })
            
            task.resume()
        }
        catch let error as NSError {
            print("json error: \(error.localizedDescription)")
        }
    }
    
    override func gather(parameters: NSMutableDictionary) -> NSMutableDictionary {
        
        let parameters = super.gather(parameters)
        
        if self.inputMessageType == .Share {
            let links = NSMutableArray()
            links.addObject(["type": "share", "_to": self.inputShareEntity!.id_])
            for contact in self.toPicker.contactsSelected {
                links.addObject(["type": "share", "_to": contact.entityId])
            }
            parameters["links"] = links
            parameters["type"] = "share"
        }
        else {
            if !editMode {
                parameters["links"] = [["type": "content", "_to": self.inputPatchId!]]
            }
        }
        return parameters
    }
    
    override func isDirty() -> Bool {
        if self.inputMessageType == .Share {
            return (descriptionField != nil && self.shareDescription != self.descriptionField.text)
        }
        else {
            return super.isDirty()
        }
    }
    
    override func isValid() -> Bool {
        
        /* Share */
        if self.inputMessageType == .Share {
            if self.toPicker.contactsSelected.count == 0 {
                Alert("Please add recipient(s)", message: nil, cancelButtonTitle: "OK")
                return false
            }
            
            if self.descriptionField.text == nil || self.descriptionField.text!.isEmpty {
                Alert("Add message", message: nil, cancelButtonTitle: "OK")
                return false
            }
        }
        else {
            if ((self.descriptionField.text == nil || self.descriptionField.text!.isEmpty)
				&& self.photoView!.imageButton.imageForState(.Normal) == nil) {
                Alert("Add message or photo", message: nil, cancelButtonTitle: "OK")
                return false
            }
        }
        
        return true
    }
    
    func showSearchTableView(visible: Bool) {
        self.searchTableView.hidden = !visible
    }
}

extension MessageEditViewController {
    /*
     * UITableViewDelegate
     */
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 {
            
            if indexPath.row == 0 {         // User
                return 64
            }
            else if indexPath.row == 1 {    // Description
                let height: CGFloat = textViewHeightForRowAtIndexPath(indexPath)
                return height < 96 ? 96 : height
            }
            else if indexPath.row == 2 {    // Photo
                if self.inputMessageType == .Content {
                    /* Size so photo aspect ratio is 4:3 */
                    var height: CGFloat = ((UIScreen.mainScreen().bounds.size.width - 32) * 0.75) + 16
                    if !self.photoView!.photoActive {
                        height = 64 // Leave enough room for set photo button
                    }
                    return height
                }
                else {
                    return 0
                }
            }
            else if indexPath.row == 3 {
                if self.inputMessageType == .Share {
                    var height: CGFloat = 0
                    if self.inputShareSchema == Schema.ENTITY_PATCH {
                        height = 400
                    }
                    else if self.inputShareSchema == Schema.ENTITY_MESSAGE {
                        height = 400
                    }
                    else if self.inputShareSchema == Schema.PHOTO {
                        height = ((UIScreen.mainScreen().bounds.size.width - 32) * 0.75) + 16
                    }
                    return height
                }
                else {
                    return 0
                }
            }
        }
        return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
    }
    
    private func textViewHeightForRowAtIndexPath(indexPath: NSIndexPath) -> CGFloat {
        let textViewWidth: CGFloat = descriptionField!.frame.size.width
        let size: CGSize = descriptionField.sizeThatFits(CGSizeMake(textViewWidth, CGFloat(FLT_MAX)))
        return size.height + 16;
    }
}

extension MessageEditViewController: MBContactPickerDataSource {
    
    func contactModelsForContactPicker(contactPickerView: MBContactPicker!) -> [AnyObject]! {
        Log.d("contact data requested")
        return self.suggestions as [AnyObject]
    }
    
    func selectedContactModelsForContactPicker(contactPickerView: MBContactPicker!) -> [AnyObject]! {
        if self.inputMessageType != .Share {
            if self.inputToString != nil {
                let model = SuggestionModel()
                model.contactTitle = self.inputToString! + " Patch"
                model.entityId = self.inputPatchId
                return [model]
            }
            else if let message = self.inputEntity as? Message where message.patch != nil {
                let model = SuggestionModel()
                model.contactTitle = message.patch.name + " Patch"
                model.entityId = message.patch.id_
                return [model]
            }
        }
        return []
    }
}

extension MessageEditViewController: MBContactPickerDelegate {
    
    func contactCollectionView(contactCollectionView: MBContactCollectionView!, didSelectContact model: MBContactPickerModelProtocol!) {
        resizeHeader(self.toPicker.currentContentHeight + self.toPickerPadding)
    }
    
    func contactCollectionView(contactCollectionView: MBContactCollectionView!, didAddContact model: MBContactPickerModelProtocol!) {
        resizeHeader(self.toPicker.currentContentHeight + self.toPickerPadding)
        self.toPicker.becomeFirstResponder()
    }
    
    func contactCollectionView(contactCollectionView: MBContactCollectionView!, didRemoveContact model: MBContactPickerModelProtocol!) {
        resizeHeader(self.toPicker.currentContentHeight + self.toPickerPadding)
    }
    
    func didShowFilteredContactsForContactPicker(contactPicker: MBContactPicker!) {
        /* Can be called after the view controller has been stopped */
        if (self.isViewLoaded() && self.view.window != nil) {
            let pickerRectInWindow = self.view.convertRect(self.toPicker.frame, fromView: nil)
            let newHeight = self.view.window!.bounds.size.height - pickerRectInWindow.origin.y - self.toPicker.keyboardHeight
            resizeHeader(newHeight + self.toPickerPadding)
        }
    }
    
    func didHideFilteredContactsForContactPicker(contactPicker: MBContactPicker!) {
        resizeHeader(self.toPicker.currentContentHeight + self.toPickerPadding)
    }
    
    func contactPicker(contactPicker: MBContactPicker!, didUpdateContentHeightTo newHeight: CGFloat) {
        resizeHeader(self.toPicker.currentContentHeight + self.toPickerPadding)
    }
    
    func contactPicker(contactPicker: MBContactPicker!, entryTextDidChange text: String!) {
        let text = text.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        Log.d("contactPicker: entry text did change: \(text)")
        self.searchEditing = (text.length > 0)
        
        if text.length >= 2 {
            self.searchText = text
            /* To limit network activity, reload half a second after last key press. */
            if let timer = self.searchTimer {
                timer.invalidate()
            }
            self.searchTimer = NSTimer(timeInterval:0.2, target:self, selector:Selector("suggest"), userInfo:nil, repeats:false)
            NSRunLoop.currentRunLoop().addTimer(self.searchTimer!, forMode: "NSDefaultRunLoopMode")
        }
        else {
            self.toPicker.hideSearchTableView()
        }
    }
    
    func resizeHeader(height: CGFloat) {
        
        let newRect = CGRectMake(0, 0, self.view.bounds.size.width, height)
        let headerView = self.tableView.tableHeaderView
        
        UIView.animateWithDuration(
            NSTimeInterval(0),
            delay: 0,
            options: UIViewAnimationOptions.TransitionCrossDissolve,
            animations: {
                headerView!.frame = newRect
                self.tableView.tableHeaderView = headerView
            },
            completion: nil)
    }
}

class SuggestionModel: MBContactModel {
    var entityId: String?
}


