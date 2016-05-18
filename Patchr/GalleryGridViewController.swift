//
//  MessageDetailViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-23.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import IDMPhotoBrowser
import NHBalancedFlowLayout

class GalleryGridViewController: UICollectionViewController {
	
	var entityId				: String?
	var displayPhotos			= [String: DisplayPhoto]()
	var displayPhotosArray		: [DisplayPhoto]!
	var threshold				= 0
	var processing				= false
	var activity				: UIActivityIndicatorView?
	var footerView				: UIView!
	var loadMoreMessage			: String = "LOAD MORE"
	var morePhotos				= false
	
    var largePhotoIndexPath : NSIndexPath? {
		
        didSet {
            var indexPaths = [NSIndexPath]()
            if largePhotoIndexPath != nil {
                indexPaths.append(largePhotoIndexPath!)
            }
            if oldValue != nil {
                indexPaths.append(oldValue!)
            }
            
            collectionView?.performBatchUpdates({
                self.collectionView?.reloadItemsAtIndexPaths(indexPaths)
                return }) { completed in
                if self.largePhotoIndexPath != nil {
                    self.collectionView?.scrollToItemAtIndexPath(
                        self.largePhotoIndexPath!,
                        atScrollPosition: .CenteredVertically,
                        animated: true)
                }
            }
        }
    }
    
    private let reuseIdentifier = "ThumbnailCell"
    private var sectionInsets	: UIEdgeInsets?
    private var thumbnailWidth	: CGFloat?
    private var availableWidth	: CGFloat?
    private let pageSize		= 49
	private var virtualSize		= 49
	private var maxSize			= 500
    private let maxImageSize	: Int = 500000
    private let maxDimen		: Int = Int(IMAGE_DIMENSION_MAX)
    
	/*--------------------------------------------------------------------------------------------
	 * Lifecycle
	 *--------------------------------------------------------------------------------------------*/

	override func viewDidLoad() {
		super.viewDidLoad()
		initialize()
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
        
        Reporting.screen("GalleryGrid")
		
		/* Scroll inset */
		self.sectionInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
		
		/* Calculate thumbnail width */
		self.availableWidth = UIScreen.mainScreen().bounds.size.width - (self.sectionInsets!.left + self.sectionInsets!.right)
		let requestedColumnWidth: CGFloat = 200
		let numColumns: CGFloat = floor(CGFloat(availableWidth!) / CGFloat(requestedColumnWidth))
		let spaceLeftOver = availableWidth! - (numColumns * requestedColumnWidth) - ((numColumns - 1) * 4)
		self.thumbnailWidth = requestedColumnWidth + (spaceLeftOver / numColumns)
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
	}

	/*--------------------------------------------------------------------------------------------
	 * Events
	 *--------------------------------------------------------------------------------------------*/
    
    func cancelAction(sender: AnyObject){
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/
	
	func initialize() {
		
		self.collectionView!.accessibilityIdentifier = Collection.Gallery
		self.collectionView?.backgroundColor = Theme.colorBackgroundForm
		
		self.collectionView!.registerClass(GalleryViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
		
		if let layout = self.collectionViewLayout as? UICollectionViewFlowLayout {
			layout.minimumLineSpacing = 4
			layout.minimumInteritemSpacing = 4
		}
		
		/* Create sorted array for data binding */
		self.displayPhotosArray = Array(self.displayPhotos.values).sort({ $0.createdDateValue > $1.createdDateValue })
		
		/* Simple activity indicator */
		self.activity = addActivityIndicatorTo(self.view)
		self.activity?.accessibilityIdentifier = "activity_view"
		
		/* Navigation bar buttons */
		let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: #selector(PhotoPickerViewController.cancelAction(_:)))
		cancelButton.accessibilityIdentifier = "nav_cancel_button"
		self.navigationItem.leftBarButtonItems = [cancelButton]
	}
	
	func loadPhotos() {
		
		guard !self.processing else {
			return
		}
		
		self.processing = true
		
		DataController.instance.backgroundOperationQueue.addOperationWithBlock {
			
			DataController.proxibase.fetchPhotosForPatch(self.entityId!, limit: self.pageSize, skip: self.virtualSize) {
				response, error in
				
				if ServerError(error) == nil {
					let dataWrapper = ServiceData()
					if let dictionary = response as? [String:AnyObject] {
						ServiceData.setPropertiesFromDictionary(dictionary, onObject: dataWrapper)
						if let maps = dataWrapper.data as? [[String: AnyObject]] {
							for map in maps {
								let displayPhoto = DisplayPhoto.fromMap(map)
								self.displayPhotos[displayPhoto.entityId!] = displayPhoto
							}
						}
						self.morePhotos = dataWrapper.moreValue
						self.virtualSize += self.pageSize
					}
				}
				
				NSOperationQueue.mainQueue().addOperationWithBlock {
					
					if let error = ServerError(error) {
						self.handleError(error)
					}
					else {
						if self.displayPhotos.count > 0 {
							/* Stub */
						}
						else {
							UIShared.Toast("No photos yet", controller: self, addToWindow: false)
						}
					}
					self.processing = false
				}
			}
		}
	}
	
    func imageForIndexPath(indexPath: NSIndexPath) -> DisplayPhoto? {
		if indexPath.row > self.displayPhotosArray!.count - 1 {
			return nil
		}
        return self.displayPhotosArray![indexPath.row]
    }
}

extension GalleryGridViewController: IDMPhotoBrowserDelegate {
	
	func photoBrowser(photoBrowser: IDMPhotoBrowser!, captionViewForPhotoAtIndex index: UInt) -> IDMCaptionView! {
		let captionView = CaptionView(displayPhoto: self.displayPhotosArray![Int(index)])
		captionView.alpha = 0
		return captionView
	}
	
	func photoBrowser(photoBrowser: IDMPhotoBrowser!, didShowPhotoAtIndex index: UInt) {
		
		let index = Int(index)
		
		if let browser = photoBrowser as? GalleryBrowser {
			let displayPhoto = self.displayPhotosArray![index]
			browser.likeButton.bind(displayPhoto)
		}
	}
}

extension GalleryGridViewController { /* UICollectionViewDelegate, UICollectionViewDataSource */
	
	override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) -> Void {
		
		/*
		* Create browser (must be done each time photo browser is displayed. Photo
		* browser objects cannot be re-used)
		*/
		let cell = collectionView.cellForItemAtIndexPath(indexPath) as! GalleryViewCell
		let browser = GalleryBrowser(photos: self.displayPhotosArray!, animatedFromView: cell)
		
		browser.setInitialPageIndex(UInt(indexPath.row))
		browser.useWhiteBackgroundColor = true
		browser.usePopAnimation = true
		browser.scaleImage = cell.displayImageView.image  // Used because final image might have different aspect ratio than initially
		browser.disableVerticalSwipe = false
		browser.autoHideInterface = false
		browser.delegate = self
		
		self.navigationController!.presentViewController(browser, animated:true, completion:nil)
	}
	
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.displayPhotosArray.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		
		var cell = collectionView.dequeueReusableCellWithReuseIdentifier(self.reuseIdentifier, forIndexPath: indexPath) as? GalleryViewCell
		
		if cell == nil {
			cell = GalleryViewCell()
		}
		
		cell!.displayImageView.image = nil
        cell!.backgroundColor = Theme.colorBackgroundImage
		
		if let displayPhoto = self.imageForIndexPath(indexPath) {
			cell!.displayPhoto = displayPhoto
			cell!.displayImageView.setImageWithUrl(displayPhoto.photoURL, animate: false)
		}
		
        return cell!
    }
}

extension GalleryGridViewController : NHBalancedFlowLayoutDelegate {
	func collectionView(collectionView: UICollectionView!,
	                    layout collectionViewLayout: NHBalancedFlowLayout!,
	                           preferredSizeForItemAtIndexPath indexPath: NSIndexPath!) -> CGSize {
		
		let displayPhoto = self.displayPhotosArray[indexPath.item]
		return displayPhoto.size ?? CGSizeMake(500, 500)
	}
}

extension GalleryGridViewController : UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
            
            if indexPath == self.largePhotoIndexPath {
                return CGSize(width: self.availableWidth! - 100, height: self.availableWidth! - 100)
            }
            
            return CGSize(width: self.thumbnailWidth!, height: self.thumbnailWidth!)
    }
    
    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAtIndex section: Int) -> UIEdgeInsets {
            return self.sectionInsets!
    }
}