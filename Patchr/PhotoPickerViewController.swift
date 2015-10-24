//
//  MessageDetailViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-23.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class PhotoPickerViewController: UICollectionViewController {
    
    var imageResults: [ImageResult] = [ImageResult]()
    var searchBarActive: Bool = false
    var searchBarBoundsY: CGFloat?
    
    var searchBar: UISearchBar?
    var pickerDelegate: PhotoBrowseControllerDelegate?
	var activity: UIActivityIndicatorView?
	var footerView:      UIView!
	var loadMoreMessage: String = "LOAD MORE"
	
	var queue = NSOperationQueue()
	
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
                return }) {
                completed in
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
    private var sectionInsets: UIEdgeInsets?
    private var thumbnailWidth: CGFloat?
    private var availableWidth: CGFloat?
    private let pageSize = 49
    private let maxSize = 500
    private let maxImageSize: Int = 500000
    private let maxDimen: Int = Int(IMAGE_DIMENSION_MAX)
    
	/*--------------------------------------------------------------------------------------------
	 * Lifecycle
	 *--------------------------------------------------------------------------------------------*/

	override func viewDidLoad() {
		super.viewDidLoad()
        
        self.collectionView!.registerNib(UINib(nibName: "ThumbnailCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: reuseIdentifier)
		self.queue.name = "Image loading queue"
		
		/* Simple activity indicator */
		self.activity = addActivityIndicatorTo(self.view)
		
		/* Scroll inset */
		self.sectionInsets = UIEdgeInsets(top: self.searchBar!.frame.size.height + 4, left: 4, bottom: 4, right: 4)
		
		/* Calculate thumbnail width */
		availableWidth = UIScreen.mainScreen().bounds.size.width - (sectionInsets!.left + sectionInsets!.right)
		let requestedColumnWidth: CGFloat = 100
		let numColumns: CGFloat = floor(CGFloat(availableWidth!) / CGFloat(requestedColumnWidth))
		let spaceLeftOver = availableWidth! - (numColumns * requestedColumnWidth) - ((numColumns - 1) * 4)
		self.thumbnailWidth = requestedColumnWidth + (spaceLeftOver / numColumns)
		
		/* Footer spinner */
		self.footerView = UIView(frame: CGRectMake(0, 0, self.thumbnailWidth!, self.thumbnailWidth!))
		
		let button = UIButton(type: UIButtonType.RoundedRect)
		button.tag = 1
		button.frame = CGRectMake(0, 0, self.collectionView!.bounds.size.width, 48)
		button.backgroundColor = UIColor.whiteColor()
		button.addTarget(self, action: Selector("loadMore:"), forControlEvents: UIControlEvents.TouchUpInside)
		button.setTitle(self.loadMoreMessage, forState: .Normal)
		footerView.addSubview(button)
		
		let spinner: UIActivityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .White)
		spinner.tag = 2
		spinner.frame = CGRectMake(0, 0, self.collectionView!.bounds.size.width, 48)
		spinner.color = Colors.brandColorDark
		spinner.hidden = true
		footerView.addSubview(spinner)
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
        
        setScreenName("PhotoPicker")
		
        if self.searchBar == nil {
            self.searchBarBoundsY = self.navigationController!.navigationBar.frame.size.height + UIApplication.sharedApplication().statusBarFrame.size.height
            self.searchBar = UISearchBar(frame: CGRectMake(0, self.searchBarBoundsY!, UIScreen.mainScreen().bounds.size.width, 44))
            self.searchBar!.searchBarStyle = UISearchBarStyle.Prominent
            self.searchBar!.delegate = self
            self.searchBar!.placeholder = "Search for photos"
        }
        
        if !self.searchBar!.isDescendantOfView(self.view) {
            self.view.addSubview(self.searchBar!)
        }
	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
	}

	override func viewDidAppear(animated: Bool) {
		super.viewDidAppear(animated)
        self.searchBar?.becomeFirstResponder()
	}

	/*--------------------------------------------------------------------------------------------
	 * Events
	 *--------------------------------------------------------------------------------------------*/
    
    @IBAction func cancelAction(sender: AnyObject){
        self.pickerDelegate!.photoBrowseControllerDidCancel!()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/

    private func loadData(paging: Bool = false) {
        
        var offset = 0
		
		self.activity?.startAnimating()
		
        if !paging {
            self.imageResults.removeAll()
        }
        else {
            offset = Int(ceil(Float(self.imageResults.count) / Float(self.pageSize)) * Float(self.pageSize))
        }
		
		self.queue.addOperationWithBlock {
			DataController.proxibase.loadSearchImages(self.searchBar!.text!, limit: Int64(self.pageSize), offset: Int64(offset)) {
				response, error in
				
				NSOperationQueue.mainQueue().addOperationWithBlock {
					self.activity?.stopAnimating()
					if let error = ServerError(error) {
						self.handleError(error)
					}
					else {
						if let
							dictionary = response as? NSDictionary,
							data = dictionary["d"] as? NSDictionary,
							results = data["results"] as? NSMutableArray {
								
								let resultsCopy = results.mutableCopy() as! NSMutableArray
								let more: Bool = (resultsCopy.count > self.pageSize)
								if more {
									resultsCopy.removeLastObject()
								}
								
								for imageResultDict in resultsCopy {
									let imageResult = ImageResult.setPropertiesFromDictionary(imageResultDict as! NSDictionary, onObject: ImageResult())
									
									var usable = false;
									usable = (imageResult.thumbnail != nil && imageResult.thumbnail!.mediaUrl != nil);
									
									if (usable) {
										for tempImageResult in self.imageResults {
											if tempImageResult.thumbnail!.mediaUrl == imageResult.thumbnail!.mediaUrl {
												usable = false
												break
											}
										}
									}
									
									if (usable) {
										self.imageResults.append(imageResult)
									}
								}
							
						}
						
						self.collectionView?.reloadData()
					}
				}
			}
		}
    }
	
    func imageForIndexPath(indexPath: NSIndexPath) -> ImageResult {
        return imageResults[indexPath.row]
    }
}

extension PhotoPickerViewController: UISearchBarDelegate {
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        self.searchBar!.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        self.searchBar!.setShowsCancelButton(false, animated: false)
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        self.searchBar!.resignFirstResponder()
        self.searchBar!.text = nil
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        self.loadData(false)
        searchBar.resignFirstResponder()
    }
}

extension PhotoPickerViewController {
    /*
     * UICollectionViewDelegate
     */
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) -> Void {
        
        if let cell = collectionView.cellForItemAtIndexPath(indexPath) as? ThumbnailCollectionViewCell {
            
            let photo = IDMPhoto(image:cell.thumbnail.image)
            let photos = Array([photo])
            let browser = AirPhotoPreview(photos:photos as [AnyObject], animatedFromView: cell.thumbnail)
            
            browser.usePopAnimation = true
            browser.scaleImage = cell.thumbnail.image  // Used because final image might have different aspect ratio than initially
            browser.useWhiteBackgroundColor = true
            browser.disableVerticalSwipe = false
            browser.forceHideStatusBar = true
            
            browser.browseDelegate = self.pickerDelegate  // Pass delegate through
            browser.imageResult = self.imageForIndexPath(indexPath)
            
            presentViewController(browser, animated:true, completion:nil)
        }
    }
}

extension PhotoPickerViewController {
    /*
     * UICollectionViewDataSource
     */
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageResults.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(self.reuseIdentifier, forIndexPath: indexPath) 
        cell.backgroundColor = Colors.windowColor
        cell.layer.shouldRasterize = true
        cell.layer.rasterizationScale = UIScreen.mainScreen().scale
		
		let imageResult = self.imageForIndexPath(indexPath)
		if let thumbCell = cell as? ThumbnailCollectionViewCell {
			if let imageView = thumbCell.thumbnail {
				thumbCell.imageResult = imageResult
				imageView.setImageWithThumbnail(imageResult.thumbnail!, animate: false)
			}
		}
		
        return cell
    }
}

extension PhotoPickerViewController : UICollectionViewDelegateFlowLayout {
    
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
            
            return sectionInsets!
    }
}