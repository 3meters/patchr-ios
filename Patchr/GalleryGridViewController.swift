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
	
    var largePhotoIndexPath : IndexPath? {
		
        didSet {
            var indexPaths = [NSIndexPath]()
            if largePhotoIndexPath != nil {
                indexPaths.append(largePhotoIndexPath! as NSIndexPath)
            }
            if oldValue != nil {
                indexPaths.append(oldValue! as NSIndexPath)
            }
            
            collectionView?.performBatchUpdates({
                self.collectionView?.reloadItems(at: indexPaths as [IndexPath])
                return }) { completed in
                if self.largePhotoIndexPath != nil {
                    self.collectionView?.scrollToItem(
                        at: self.largePhotoIndexPath!,
                        at: .centeredVertically,
                        animated: true)
                }
            }
        }
    }
    
    fileprivate let reuseIdentifier = "ThumbnailCell"
    fileprivate var sectionInsets	: UIEdgeInsets?
    fileprivate var thumbnailWidth	: CGFloat?
    fileprivate var availableWidth	: CGFloat?
    fileprivate let pageSize		= 49
	fileprivate var virtualSize		= 49
	fileprivate var maxSize			= 500
    fileprivate let maxImageSize	: Int = 500000
    fileprivate let maxDimen		: Int = Int(IMAGE_DIMENSION_MAX)
    
	/*--------------------------------------------------------------------------------------------
	 * Lifecycle
	 *--------------------------------------------------------------------------------------------*/

	override func viewDidLoad() {
		super.viewDidLoad()
		initialize()
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
        
        Reporting.screen("GalleryGrid")
		
		/* Scroll inset */
		self.sectionInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
		
		/* Calculate thumbnail width */
		self.availableWidth = UIScreen.main.bounds.size.width - (self.sectionInsets!.left + self.sectionInsets!.right)
		let requestedColumnWidth: CGFloat = 200
		let numColumns: CGFloat = floor(CGFloat(availableWidth!) / CGFloat(requestedColumnWidth))
		let spaceLeftOver = availableWidth! - (numColumns * requestedColumnWidth) - ((numColumns - 1) * 4)
		self.thumbnailWidth = requestedColumnWidth + (spaceLeftOver / numColumns)
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
	}

	/*--------------------------------------------------------------------------------------------
	 * Events
	 *--------------------------------------------------------------------------------------------*/
    
    func cancelAction(sender: AnyObject){
        self.dismiss(animated: true, completion: nil)
    }
    
	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/
	
	func initialize() {
		
		self.collectionView?.backgroundColor = Theme.colorBackgroundForm
		
		self.collectionView!.register(GalleryViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
		
		if let layout = self.collectionViewLayout as? UICollectionViewFlowLayout {
			layout.minimumLineSpacing = 4
			layout.minimumInteritemSpacing = 4
		}
		
		/* Create sorted array for data binding */
		self.displayPhotosArray = Array(self.displayPhotos.values).sorted(by: { $0.createdDateValue! > $1.createdDateValue! })
		
		/* Simple activity indicator */
		self.activity = addActivityIndicatorTo(view: self.view)
		
		/* Navigation bar buttons */
		let cancelButton = UIBarButtonItem(title: "Close", style: .plain, target: self, action: #selector(PhotoPickerViewController.cancelAction(sender:)))
		self.navigationItem.rightBarButtonItems = [cancelButton]
	}
	
	func loadPhotos() {
		
		guard !self.processing else {
			return
		}
		
		self.processing = true
		
		DataController.instance.backgroundOperationQueue.addOperation {
			
			DataController.proxibase.fetchPhotosForPatch(patchId: self.entityId!, limit: self.pageSize, skip: self.virtualSize) {
				response, error in
				
				if ServerError(error) == nil {
					let dataWrapper = ServiceData()
					if let dictionary = response as? [String:AnyObject] {
						ServiceData.setPropertiesFrom(dictionary, onObject: dataWrapper)
						if let maps = dataWrapper.data as? [[String: AnyObject]] {
							for map in maps {
								let displayPhoto = DisplayPhoto.fromMap(map: map)
								self.displayPhotos[displayPhoto.entityId!] = displayPhoto
							}
						}
						self.morePhotos = dataWrapper.moreValue
						self.virtualSize += self.pageSize
					}
				}
				
				OperationQueue.main.addOperation {
					
					if let error = ServerError(error) {
						self.handleError(error)
					}
					else {
						if self.displayPhotos.count > 0 {
							/* Stub */
						}
						else {
							UIShared.Toast(message: "No photos yet", controller: self, addToWindow: false)
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
	
	func photoBrowser(_ photoBrowser: IDMPhotoBrowser!, captionViewForPhotoAt index: UInt) -> IDMCaptionView! {
		let captionView = CaptionView(displayPhoto: self.displayPhotosArray![Int(index)])
		captionView?.alpha = 0
		return captionView
	}
	
	func photoBrowser(_ photoBrowser: IDMPhotoBrowser!, didShowPhotoAt index: UInt) {
		
		let index = Int(index)
		
		if let browser = photoBrowser as? GalleryBrowser {
			let displayPhoto = self.displayPhotosArray![index]
			browser.likeButton.bind(displayPhoto: displayPhoto)
		}
	}
}

extension GalleryGridViewController { /* UICollectionViewDelegate, UICollectionViewDataSource */
	
	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) -> Void {
		
		/*
		* Create browser (must be done each time photo browser is displayed. Photo
		* browser objects cannot be re-used)
		*/
		let cell = collectionView.cellForItem(at: indexPath) as! GalleryViewCell
        let browser = GalleryBrowser(photos: self.displayPhotosArray! as [Any], animatedFrom: cell)
		
		browser?.setInitialPageIndex(UInt(indexPath.row))
		browser?.useWhiteBackgroundColor = true
		browser?.usePopAnimation = true
		browser?.scaleImage = cell.displayImageView.image  // Used because final image might have different aspect ratio than initially
		browser?.disableVerticalSwipe = false
		browser?.autoHideInterface = false
		browser?.delegate = self
		
		self.navigationController!.present(browser!, animated:true, completion:nil)
	}
	
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.displayPhotosArray.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		
		var cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.reuseIdentifier, for: indexPath) as? GalleryViewCell
		
		if cell == nil {
			cell = GalleryViewCell()
		}
		
		cell!.displayImageView.image = nil
        cell!.backgroundColor = Theme.colorBackgroundImage
		
		if let displayPhoto = self.imageForIndexPath(indexPath: indexPath as NSIndexPath) {
			cell!.displayPhoto = displayPhoto
			cell!.displayImageView.setImageWithUrl(url: (displayPhoto.photoURL as NSURL) as URL, animate: false)
		}
		
        return cell!
    }
}

extension GalleryGridViewController : NHBalancedFlowLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView!,
                        layout collectionViewLayout: NHBalancedFlowLayout!,
                        preferredSizeForItemAt indexPath: IndexPath!) -> CGSize {
		
		let displayPhoto = self.displayPhotosArray[indexPath.item]
        return displayPhoto.size ?? CGSize(width:500, height:500)
	}
}

extension GalleryGridViewController : UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath) -> CGSize {
            
            if indexPath == self.largePhotoIndexPath {
                return CGSize(width: self.availableWidth! - 100, height: self.availableWidth! - 100)
            }
            
            return CGSize(width: self.thumbnailWidth!, height: self.thumbnailWidth!)
    }
    
    func collectionView(_ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int) -> UIEdgeInsets {
            return self.sectionInsets!
    }
}
