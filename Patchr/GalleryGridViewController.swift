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
import SDWebImage

class GalleryGridViewController: UICollectionViewController {
	
	var displayPhotos = [String: DisplayPhoto]()
	var displayPhotosSorted: [DisplayPhoto]!
	var threshold = 0
	var processing = false
	var activity: UIActivityIndicatorView?
	var footerView: UIView!
	var loadMoreMessage: String = "LOAD MORE"
	var morePhotos = false
	
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
    fileprivate var sectionInsets: UIEdgeInsets?
    fileprivate var thumbnailWidth: CGFloat?
    fileprivate var availableWidth: CGFloat?
    fileprivate let pageSize = 49
	fileprivate var virtualSize	= 49
	fileprivate var maxSize = 500
    fileprivate let maxImageSize: Int = 500000
    fileprivate let maxDimen: Int = Int(Config.imageDimensionMax)
    
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
    
    deinit {
        SDWebImagePrefetcher.shared().cancelPrefetching()
        Log.v("Grid prefetch cancelled if active")
    }

	/*--------------------------------------------------------------------------------------------
	 * Events
	 *--------------------------------------------------------------------------------------------*/
    
    func closeAction(sender: AnyObject) {
        self.close(animated: true)
    }
    
	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/
	
	func initialize() {
		
		self.collectionView!.backgroundColor = Theme.colorBackgroundForm
		self.collectionView!.register(GalleryViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        
		if let layout = self.collectionViewLayout as? UICollectionViewFlowLayout {
			layout.minimumLineSpacing = 4
			layout.minimumInteritemSpacing = 4
		}
        
		/* Create sorted array for data binding */
		self.displayPhotosSorted = Array(self.displayPhotos.values).sorted(by: { $0.createdDateValue! > $1.createdDateValue! })
        
        /* Start prefetching photos to the disk cache if on wifi network */
        let urls = self.displayPhotosSorted.map { $0.photoURL! }
        if  ReachabilityManager.instance.isReachableViaWiFi() {
            SDWebImagePrefetcher.shared().prefetchURLs(urls)
            SDWebImagePrefetcher.shared().delegate = self
        }
		
		/* Simple activity indicator */
		self.activity = addActivityIndicatorTo(view: self.view)
		
		/* Navigation bar buttons */
        let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeAction(sender:)))
		self.navigationItem.rightBarButtonItems = [closeButton]
	}
	
    func imageForIndexPath(indexPath: NSIndexPath) -> DisplayPhoto? {
		if indexPath.row > self.displayPhotosSorted!.count - 1 {
			return nil
		}
        return self.displayPhotosSorted![indexPath.row]
    }
}

extension GalleryGridViewController: SDWebImagePrefetcherDelegate {
    func imagePrefetcher(_ imagePrefetcher: SDWebImagePrefetcher, didFinishWithTotalCount totalCount: UInt, skippedCount: UInt) {
        Log.v("Grid prefetch complete: total: \(totalCount), skipped: \(skippedCount)")
    }
}

extension GalleryGridViewController: IDMPhotoBrowserDelegate {
	
	func photoBrowser(_ photoBrowser: IDMPhotoBrowser!, captionViewForPhotoAt index: UInt) -> IDMCaptionView! {
		let captionView = CaptionView(displayPhoto: self.displayPhotosSorted![Int(index)])
		captionView?.alpha = 0
		return captionView
	}
	
	func photoBrowser(_ photoBrowser: IDMPhotoBrowser!, didShowPhotoAt index: UInt) {
		let index = Int(index)		
		if let browser = photoBrowser as? PhotoBrowser {
			let displayPhoto = self.displayPhotosSorted![index]
			browser.likeButton?.bind(displayPhoto: displayPhoto)
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
        
        let photoBrowser = PhotoBrowser(photos: self.displayPhotosSorted! as [Any], animatedFrom: cell)
        photoBrowser!.mode = .gallery
        photoBrowser!.useWhiteBackgroundColor = true
        photoBrowser!.usePopAnimation = true
        photoBrowser!.disableVerticalSwipe = false
        photoBrowser!.autoHideInterface = false
        photoBrowser!.delegate = self
        
		photoBrowser!.setInitialPageIndex(UInt(indexPath.row))
		photoBrowser!.scaleImage = cell.displayImageView.image  // Used because final image might have different aspect ratio than initially
		self.navigationController!.present(photoBrowser!, animated: true, completion: nil)
	}
	
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.displayPhotosSorted.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		
		var cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.reuseIdentifier, for: indexPath) as? GalleryViewCell
		
		if cell == nil {
			cell = GalleryViewCell()
		}
		
        cell!.backgroundColor = Theme.colorBackgroundImage
		
		if let displayPhoto = self.imageForIndexPath(indexPath: indexPath as NSIndexPath) {
            if !cell!.displayImageView.associated(withUrl: displayPhoto.photoURL!) {
                cell!.displayImageView.image = nil
                cell!.displayPhoto = displayPhoto
                cell!.displayImageView.setImageWithUrl(url: displayPhoto.photoURL!, animate: true)
            }
		}
		
        return cell!
    }
}

extension GalleryGridViewController : NHBalancedFlowLayoutDelegate {
    func collectionView(_ collectionView: UICollectionView!,
                        layout collectionViewLayout: NHBalancedFlowLayout!,
                        preferredSizeForItemAt indexPath: IndexPath!) -> CGSize {
		
		let displayPhoto = self.displayPhotosSorted[indexPath.item]
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
