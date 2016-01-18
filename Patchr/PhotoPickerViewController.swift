//
//  MessageDetailViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-23.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AirPhotoBrowser

class PhotoPickerViewController: UICollectionViewController, UITableViewDelegate, UITableViewDataSource {
    
    var imageResults: [ImageResult] = [ImageResult]()
    var searchBarActive: Bool = false
    var searchBarBoundsY: CGFloat?
	var threshold = 0
	var processing = false
    
    var searchBar				: UISearchBar!
    var pickerDelegate			: PhotoBrowseControllerDelegate?
	var activity				: UIActivityIndicatorView?
	var footerView				: UIView!
	var loadMoreMessage			: String = "LOAD MORE"
	var autocompleteList		= AirTableView()
	var autocompleteData		: NSMutableArray = NSMutableArray()
	var searches				: NSMutableArray = NSMutableArray()
	
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
    private var maxSize = 500
	private var virtualSize = 49
    private let maxImageSize: Int = 500000
    private let maxDimen: Int = Int(IMAGE_DIMENSION_MAX)
    
	/*--------------------------------------------------------------------------------------------
	 * Lifecycle
	 *--------------------------------------------------------------------------------------------*/

	override func viewDidLoad() {
		super.viewDidLoad()
        
        self.collectionView!.registerNib(UINib(nibName: "ThumbnailCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: reuseIdentifier)
		self.collectionView?.backgroundColor = Theme.colorBackgroundForm
		self.collectionView?.accessibilityIdentifier = "photo_collection"
		if let layout = self.collectionViewLayout as? UICollectionViewFlowLayout {
			layout.minimumLineSpacing = 4
			layout.minimumInteritemSpacing = 4
		}
		self.queue.name = "Image loading queue"
		
		/* Simple activity indicator */
		self.activity = addActivityIndicatorTo(self.view)
		
		/* Auto complete table view */
		self.autocompleteList.delegate = self
		self.autocompleteList.dataSource = self
		self.autocompleteList.scrollEnabled = true
		self.autocompleteList.hidden = true
		self.autocompleteList.rowHeight = 40
		self.autocompleteList.separatorInset = UIEdgeInsetsZero

		self.view.addSubview(self.autocompleteList)
		
		/* Past searches */
		loadSearches()
		
		/* Navigation bar buttons */
		let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Cancel, target: self, action: "cancelAction:")
		cancelButton.accessibilityIdentifier = "nav_cancel_button"
		self.navigationItem.leftBarButtonItems = [cancelButton]
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
			self.searchBar!.accessibilityIdentifier = "search_field"
        }
        
		/* Scroll inset */
		self.sectionInsets = UIEdgeInsets(top: self.searchBar!.frame.size.height + 4, left: 4, bottom: 4, right: 4)
		
        if !self.searchBar!.isDescendantOfView(self.view) {
            self.view.addSubview(self.searchBar!)
        }
		
		/* Calculate thumbnail width */
		availableWidth = UIScreen.mainScreen().bounds.size.width - (sectionInsets!.left + sectionInsets!.right)
		let requestedColumnWidth: CGFloat = 100
		let numColumns: CGFloat = floor(CGFloat(availableWidth!) / CGFloat(requestedColumnWidth))
		let spaceLeftOver = availableWidth! - (numColumns * requestedColumnWidth) - ((numColumns - 1) * 4)
		self.thumbnailWidth = requestedColumnWidth + (spaceLeftOver / numColumns)

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
    
    func cancelAction(sender: AnyObject){
        self.pickerDelegate!.photoBrowseControllerDidCancel!()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/

    private func loadData(paging: Bool = false) {
		
		guard !self.processing else {
			return
		}
		
		guard self.searchBar!.text != nil && !self.searchBar!.text!.isEmpty else {
			return
		}
        
        var offset = 0
		self.processing = true
		
		self.activity?.startAnimating()
		
        if !paging {
            self.imageResults.removeAll()
			self.virtualSize = self.pageSize
			let topOffset = CGPointMake(0, -(self.collectionView?.contentInset.top ?? 0))
			self.collectionView?.setContentOffset(topOffset, animated: true)
        }
        else {
            offset = Int(ceil(Float(self.imageResults.count) / Float(self.pageSize)) * Float(self.pageSize))
        }
		
		DataController.instance.backgroundOperationQueue.addOperationWithBlock {
			
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
								
								Utils.updateSearches(self.searchBar!.text!)
								self.loadSearches()
								
								let resultsCopy = results.mutableCopy() as! NSMutableArray
								let more: Bool = (resultsCopy.count > self.pageSize)
								if more {
									resultsCopy.removeLastObject()
								}
								
								let beginCount = self.imageResults.count
								
								for imageResultDict in resultsCopy {
									
									let imageResult = ImageResult.setPropertiesFromDictionary(imageResultDict as! NSDictionary, onObject: ImageResult())
									var usable = (imageResult.thumbnail != nil && imageResult.thumbnail!.mediaUrl != nil);
									
									if (usable) {
										/* Make sure we don't already have it */
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
								
								if self.imageResults.count == beginCount {
									self.virtualSize = self.imageResults.count
									self.threshold = 1000
								}
								else {
									self.threshold = self.imageResults.count - 20
									self.virtualSize = self.imageResults.count + 49
								}
						}
						
						self.collectionView?.reloadData()
					}
					self.processing = false
				}
			}
		}
    }
	
	func loadSearches() {
		self.searches.removeAllObjects()
		if let searches = NSUserDefaults.standardUserDefaults().arrayForKey(PatchrUserDefaultKey("recent.searches")) as? [String] {
			for search in searches {
				self.searches.addObject(search)
			}
		}
	}
	
    func imageForIndexPath(indexPath: NSIndexPath) -> ImageResult? {
		if indexPath.row > self.imageResults.count - 1 {
			return nil
		}
        return imageResults[indexPath.row]
    }
	
	func filterSearchesWithSubstring(substring: String) {
		self.autocompleteData.removeAllObjects()
		for search in self.searches {
			let substringRange = search.rangeOfString(substring)
			if substringRange.location == 0 {
				self.autocompleteData.addObject(search)
			}
		}

		self.autocompleteList.hidden = (self.autocompleteData.count == 0)
		self.autocompleteList.alignUnder(self.searchBar, centeredFillingWidthWithLeftAndRightPadding: 0, topPadding: 0, height: CGFloat(self.autocompleteData.count * 40))
		self.autocompleteList.reloadData()
	}
}

extension PhotoPickerViewController: UISearchBarDelegate {
	
	func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
		filterSearchesWithSubstring(searchText)
	}
    
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
	* UITableViewDelegate
	*/
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		
		var cell = tableView.dequeueReusableCellWithIdentifier(CELL_IDENTIFIER)
		
		if cell == nil {
			cell = UITableViewCell(style: .Default, reuseIdentifier: CELL_IDENTIFIER)
		}
		
		if let search = self.autocompleteData[indexPath.row] as? String {
			cell?.textLabel?.text = search
			cell?.textLabel?.font = Theme.fontComment
		}
		return cell!
	}
	
	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.autocompleteData.count
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		
		if let search = self.autocompleteData[indexPath.row] as? String {
			self.searchBar!.text = search
			self.autocompleteList.hidden = true
			self.loadData(false)
			searchBar.resignFirstResponder()
		}
	}
}

extension PhotoPickerViewController {
    /*
     * UICollectionViewDelegate
     */
	override func scrollViewWillBeginDecelerating(scrollView: UIScrollView) {
		
		if !self.processing {
			if let indexPaths = self.collectionView?.indexPathsForVisibleItems() {
				for indexPath in indexPaths {
					if indexPath.row > self.threshold {
						loadData(true)
						return
					}
				}
			}
		}
	}
	
	override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
		
		if !self.processing {
			if let indexPaths = self.collectionView?.indexPathsForVisibleItems() {
				for indexPath in indexPaths {
					if indexPath.row > self.threshold {
						loadData(true)
						return
					}
				}
			}
		}
	}
	
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
        return self.virtualSize
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(self.reuseIdentifier, forIndexPath: indexPath) 
        cell.backgroundColor = Theme.colorBackgroundImage
		
		if let imageResult = self.imageForIndexPath(indexPath) {
			if let thumbCell = cell as? ThumbnailCollectionViewCell {
				if let imageView = thumbCell.thumbnail {
					thumbCell.imageResult = imageResult
					imageView.setImageWithThumbnail(imageResult.thumbnail!, animate: false)
				}
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