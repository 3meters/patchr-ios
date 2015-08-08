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

    var messageType:    MessageType = .Content
	var toString:       String?	// name of patch this message links to
    var patchId:        String?    // id of patch this message links to
    var shareId:        String?
    var shareSchema:    String = Schema.PHOTO
    var shareEntity:    Entity?
    
	@IBOutlet weak var userPhotoImage:   	AirImageView!
    @IBOutlet weak var userNameLabel:       UILabel!
	@IBOutlet weak var toName:              UILabel!
    @IBOutlet weak var shareHolder:         UIView!
    @IBOutlet weak var shareHolderHeight:   NSLayoutConstraint!
    
    @IBOutlet weak var descriptionCell:     UITableViewCell!
    @IBOutlet weak var photoCell:           UITableViewCell!
    @IBOutlet weak var shareCell:           UITableViewCell!

    /*--------------------------------------------------------------------------------------------
    * Lifecycle
    *--------------------------------------------------------------------------------------------*/
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.collection = "messages"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.descriptionField!.placeholder = "Message"
        self.photoView!.frame = CGRectMake(16, 0, self.photoHolder!.bounds.size.width - 32, self.photoHolder!.bounds.size.height)
        
        if self.messageType == .Share {
            
            self.progressStartLabel = "Inviting"
            self.progressFinishLabel = "Invites sent!"
            
            if self.shareSchema == Schema.ENTITY_PATCH {
                navigationItem.title = Utils.LocalizedString("Invite to patch")
            }
            else if self.shareSchema == Schema.ENTITY_MESSAGE {
                navigationItem.title = Utils.LocalizedString("Share message")
            }
            
            self.descriptionField!.placeholderColor = UIColor.clearColor()
            
            if let user = UserController.instance.currentUser {
                self.userPhotoImage.setImageWithPhoto(user.getPhotoManaged())
                self.userNameLabel.text = user.name
            }
            
            /* Navigation bar buttons */
            var doneButton   = UIBarButtonItem(title: "Send", style: UIBarButtonItemStyle.Plain, target: self, action: "doneAction:")
            self.navigationItem.rightBarButtonItems = [doneButton]
            
            /* Pull state from patch we are editing */
            bind()
        }
        else {
            if editMode {
                
                self.progressStartLabel = "Updating"
                self.progressFinishLabel = "Updated!"
                navigationItem.title = Utils.LocalizedString("Edit message")
                
                /* Navigation bar buttons */
                var deleteButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Trash, target: self, action: "deleteAction:")
                var doneButton   = UIBarButtonItem(title: "Save", style: UIBarButtonItemStyle.Plain, target: self, action: "doneAction:")
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
                
                self.progressStartLabel = "Posting"
                self.progressFinishLabel = "Posted!"
                self.descriptionField!.placeholderColor = UIColor.clearColor()
                
                if let toString = toString {
                    toName.text = toString
                }
                
                if let user = UserController.instance.currentUser {
                    self.userPhotoImage.setImageWithPhoto(user.getPhotoManaged())
                    self.userNameLabel.text = user.name
                }
                
                /* Navigation bar buttons */
                var doneButton   = UIBarButtonItem(title: "Post", style: UIBarButtonItemStyle.Plain, target: self, action: "doneAction:")
                self.navigationItem.rightBarButtonItems = [doneButton]
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        setScreenName("MessageEdit")
    }
    
    override func viewDidAppear(animated: Bool) {
        if photoChosen {
            photoChosen = false
            var rowFrame = self.tableView.rectForRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 0))
            var currentOffsetBottom = self.tableView.contentOffset.y + self.tableView.frame.size.height
            var currentRowBottom = rowFrame.origin.y + rowFrame.size.height
            var newOffset = self.tableView.contentOffset.y + (currentRowBottom - currentOffsetBottom)
            if newOffset > 0 {
                self.tableView.setContentOffset(CGPoint(x: 0, y: newOffset), animated: true)
            }
        }
        
        if !editMode && self.firstAppearance {
            self.descriptionField.becomeFirstResponder()
        }
    }
    
    /*--------------------------------------------------------------------------------------------
    * Events
    *--------------------------------------------------------------------------------------------*/

    @IBAction override func clearPhotoAction(sender: AnyObject) {
        super.clearPhotoAction(sender)
        
        self.tableView.reloadData() // Triggers row resizing
    }
    
    override func photoChosen(image: UIImage?, imageResult: ImageResult?) {
        super.photoChosen(image, imageResult: imageResult)
        /*
        * We need to make sure heightForRowAtIndexPath gets fired
        * to reset the cell height to accomodate the photo. viewDidAppear
        * has logic to make sure the photo is scrolled into view.
        */
        self.tableView.reloadData()
    }
    
    /*--------------------------------------------------------------------------------------------
    * Methods
    *--------------------------------------------------------------------------------------------*/
    
    override func bind() {
        super.bind()
        
        if let message = self.entity as? Message {
            /* User */
            self.userPhotoImage.setImageWithPhoto(message.creator.getPhotoManaged())
            self.userNameLabel.text = message.creator.name
        }
        
        /* Share */
        if self.messageType == .Share {
            
            var view: BaseView!
            if self.shareSchema == Schema.ENTITY_PATCH {
                view = NSBundle.mainBundle().loadNibNamed("PatchNormalView", owner: self, options: nil)[0] as! BaseView
                view.frame.size.width = self.shareHolder.bounds.size.width
                Patch.bindView(view, object: self.shareEntity!, tableView: self.tableView)
                self.shareHolder?.addSubview(view)
            }
            else if self.shareSchema == Schema.ENTITY_MESSAGE {
                view = NSBundle.mainBundle().loadNibNamed("MessageView", owner: self, options: nil)[0] as! BaseView
                view.frame.size.width = self.shareHolder.bounds.size.width
                Message.bindView(view, object: self.shareEntity!, tableView: self.tableView)
                view.frame.size.height = view.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height + 1
                self.shareHolder?.addSubview(view)
            }
            
            let views = Dictionary(dictionaryLiteral: ("view", view))
            let horizontalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[view]|", options: nil, metrics: nil, views: views)
            let verticalConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[view]|", options: nil, metrics: nil, views: views)
            self.shareHolder?.addConstraints(horizontalConstraints)
            self.shareHolder?.addConstraints(verticalConstraints)
        }
    }
    
    override func gather(parameters: NSMutableDictionary) -> NSMutableDictionary {
        
        var parameters = super.gather(parameters)
        
        if !editMode {
            parameters["links"] = [["type": "content", "_to": self.patchId!]]
        }
        return parameters
    }
    
    override func isValid() -> Bool {
        
        if ((self.description_ == nil || self.description_!.isEmpty) && self.photo == nil) {
            Alert("Add message or photo", message: nil, cancelButtonTitle: "OK")
            return false
        }
        
        return true
    }
    
    override func performBack(animated: Bool = true) {
        self.performSegueWithIdentifier("UnwindFromMessageEdit", sender: self)
    }
    
    /*--------------------------------------------------------------------------------------------
    * Properties
    *--------------------------------------------------------------------------------------------*/

}

extension MessageEditViewController: UITableViewDelegate{
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 {
            if indexPath.row == 1 { // Description
                var height: CGFloat = textViewHeightForRowAtIndexPath(indexPath)
                return height < 96 ? 96 : height
            }
            else if indexPath.row == 2 { // Photo
                if self.messageType == .Content {
                    /* Size so photo aspect ratio is 4:3 */
                    var height: CGFloat = ((UIScreen.mainScreen().bounds.size.width - 32) * 0.75) + 16
                    if !self.photoActive {
                        height = 64 // Leave enough room for set photo button
                    }
                    return height
                }
                else {
                    return 0
                }
            }
            else if indexPath.row == 3 {
                if self.messageType == .Share {
                    var height: CGFloat = 0
                    if self.shareSchema == Schema.ENTITY_PATCH {
                        height = 127
                    }
                    else if self.shareSchema == Schema.ENTITY_MESSAGE {
                        height = 400
                    }
                    else if self.shareSchema == Schema.PHOTO {
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

extension EntityEditViewController: UITextViewDelegate {
    
    func textViewDidEndEditing(textView: UITextView) {
        self.descriptionField.placeholderColor = UIColor.lightGrayColor()
    }
}


