//
//  MessageDetailViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-23.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AMScrollingNavbar
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
    var inputTitle: String?
	var morePhotos = false
	
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
        if let navigationController = navigationController as? ScrollingNavigationController {
            navigationController.followScrollView(self.collectionView!, delay: 50.0)
        }
	}
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let navigationController = navigationController as? ScrollingNavigationController {
            navigationController.showNavbar(animated: true)
        }
    }
    
    /*--------------------------------------------------------------------------------------------
	 * Events
	 *--------------------------------------------------------------------------------------------*/
    
    @objc func closeAction(sender: AnyObject) {
        self.close(animated: true)
    }
    
	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/
	
	func initialize() {
		
		self.collectionView!.backgroundColor = Theme.colorBackgroundForm
		self.collectionView!.register(GalleryViewCell.self, forCellWithReuseIdentifier: "cell")
        
		if let layout = self.collectionViewLayout as? UICollectionViewFlowLayout {
			layout.minimumLineSpacing = 4
			layout.minimumInteritemSpacing = 4
		}
        
		/* Create sorted array for data binding */
		self.displayPhotosSorted = Array(self.displayPhotos.values).sorted(by: {
            $0.createdDateValue! > $1.createdDateValue!
        })
        
        /* Start prefetching photos to the disk cache if on wifi network */
        let urls = self.displayPhotosSorted.map { $0.photoURL! }
        if  ReachabilityManager.instance.isReachableViaWiFi() {
            SDWebImagePrefetcher.shared().prefetchURLs(urls)    // method starts by clearing any ongoing prefetch
            SDWebImagePrefetcher.shared().delegate = self
        }
		
		/* Simple activity indicator */
		self.activity = addActivityIndicatorTo(view: self.view)
		
		/* Navigation bar buttons */
        if self.inputTitle != nil {
            self.navigationItem.title = self.inputTitle!
        }
        let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(closeAction(sender:)))
		self.navigationItem.leftBarButtonItems = [closeButton]
	}
	
    func imageForIndexPath(indexPath: NSIndexPath) -> DisplayPhoto? {
		if indexPath.row > self.displayPhotosSorted!.count - 1 {
			return nil
		}
        return self.displayPhotosSorted![indexPath.row]
    }
    
    override func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        if let navigationController = navigationController as? ScrollingNavigationController {
            navigationController.showNavbar(animated: true)
        }
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return false
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
        Reporting.track("view_photo_from_gallery")
        self.navigationController!.present(photoBrowser!, animated: true, completion: nil)
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.displayPhotosSorted.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? GalleryViewCell
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
    func collectionView(_ collectionView: UICollectionView!
        , layout collectionViewLayout: NHBalancedFlowLayout!
        , preferredSizeForItemAt indexPath: IndexPath!) -> CGSize {
        let displayPhoto = self.displayPhotosSorted[indexPath.item]
        return displayPhoto.size ?? CGSize(width:300, height:300)
    }
}

extension GalleryGridViewController : UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView
        , layout collectionViewLayout: UICollectionViewLayout
        , sizeForItemAt indexPath: IndexPath) -> CGSize {
        let flowLayout = collectionViewLayout as! NHBalancedFlowLayout
        let availableWidth = collectionView.width() - (flowLayout.sectionInset.left + flowLayout.sectionInset.right)
        let preferredColumnWidth: CGFloat = 200
        let numColumns: CGFloat = floor(CGFloat(availableWidth) / CGFloat(preferredColumnWidth))
        let spaceLeftOver = availableWidth - (numColumns * preferredColumnWidth) - ((numColumns - 1) * flowLayout.minimumInteritemSpacing)
        let cellSize = preferredColumnWidth + (spaceLeftOver / numColumns)
        return CGSize(width: cellSize, height: cellSize)
    }
    
    func collectionView(_ collectionView: UICollectionView
        , layout collectionViewLayout: UICollectionViewLayout
        , insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(4, 4, 4, 4)
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
            browser.reactionToolbar.alwaysShowAddButton = true
            browser.reactionToolbar.bind(message: displayPhoto.message!)
		}
	}
}
