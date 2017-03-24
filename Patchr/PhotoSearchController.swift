//
//  MessageDetailViewController.swift
//  Patchr
//
//  Created by Rob MacEachern on 2015-02-23.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import IDMPhotoBrowser

class PhotoSearchController: UICollectionViewController, UITableViewDelegate, UITableViewDataSource {
    
    var imageResults = [ImageResult]()
    var searchBarActive = false
    var searchBarBoundsY: CGFloat?
	var threshold = 0
	var processing = false
    var offset = 0
    var more = false
    
    var searchBar : UISearchBar!
    var pickerDelegate : PhotoBrowseControllerDelegate?
	var activity : UIActivityIndicatorView?
	var footerView : UIView!
	var loadMoreMessage = "LOAD MORE"
	var autocompleteList = AirTableView()
	var autocompleteData = [String]()
	var searches = [String]()
	
	var queue = OperationQueue()
	
    var largePhotoIndexPath : IndexPath? {
        didSet {
            var indexPaths = [IndexPath]()
            if largePhotoIndexPath != nil {
                indexPaths.append(largePhotoIndexPath!)
            }
            if oldValue != nil {
                indexPaths.append(oldValue!)
            }
            
            collectionView?.performBatchUpdates({
                self.collectionView?.reloadItems(at: indexPaths)
                return }) {
                completed in
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
    fileprivate let pageSize = 150      // Maximum allowed by Bing. We pull max to keep request count down.
    fileprivate var maxSize = 100
	fileprivate var virtualSize = 30
    fileprivate let maxImageSize = 500000
    fileprivate let maxDimen = Int(Config.imageDimensionMax)
    
	/*--------------------------------------------------------------------------------------------
	 * Lifecycle
	 *--------------------------------------------------------------------------------------------*/

	override func viewDidLoad() {
		super.viewDidLoad()
		
        self.collectionView!.register(UINib(nibName: "ThumbnailCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: reuseIdentifier)
		self.collectionView?.backgroundColor = Theme.colorBackgroundForm
		if let layout = self.collectionViewLayout as? UICollectionViewFlowLayout {
			layout.minimumLineSpacing = 4
			layout.minimumInteritemSpacing = 4
		}
		self.queue.name = "Image loading queue"
		
		/* Simple activity indicator */
		self.activity = addActivityIndicatorTo(view: self.view)
		
		/* Auto complete table view */
		self.autocompleteList.delegate = self
		self.autocompleteList.dataSource = self
		self.autocompleteList.isScrollEnabled = true
		self.autocompleteList.isHidden = true
		self.autocompleteList.rowHeight = 40
		self.autocompleteList.separatorInset = UIEdgeInsets.zero

		self.view.addSubview(self.autocompleteList)
		
		/* Past searches */
		loadSearches()
		
		/* Navigation bar buttons */
		let cancelButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(PhotoSearchController.cancelAction(sender:)))
		self.navigationItem.rightBarButtonItems = [cancelButton]
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
        
        Reporting.screen("PhotoPicker")
		
        if self.searchBar == nil {
			let navHeight = self.navigationController?.navigationBar.height() ?? 0
			let statusHeight = UIApplication.shared.statusBarFrame.size.height

            self.searchBarBoundsY = navHeight + statusHeight
            self.searchBar = UISearchBar(frame: CGRect(x:0, y:self.searchBarBoundsY!, width:UIScreen.main.bounds.size.width, height:44))
            self.searchBar!.autocapitalizationType = .none
            self.searchBar!.delegate = self
            self.searchBar!.placeholder = "Search for photos"
            self.searchBar!.searchBarStyle = .prominent
        }
        
		/* Scroll inset */
		self.sectionInsets = UIEdgeInsets(top: self.searchBar!.frame.size.height + 4, left: 4, bottom: 4, right: 4)
		
        if !self.searchBar!.isDescendant(of: self.view) {
            self.view.addSubview(self.searchBar!)
        }
		
		/* Calculate thumbnail width */
		availableWidth = UIScreen.main.bounds.size.width - (sectionInsets!.left + sectionInsets!.right)
		let requestedColumnWidth: CGFloat = 100
		let numColumns: CGFloat = floor(CGFloat(availableWidth!) / CGFloat(requestedColumnWidth))
		let spaceLeftOver = availableWidth! - (numColumns * requestedColumnWidth) - ((numColumns - 1) * 4)
		self.thumbnailWidth = requestedColumnWidth + (spaceLeftOver / numColumns)

	}

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
        self.searchBar?.becomeFirstResponder()
	}

	/*--------------------------------------------------------------------------------------------
	 * Events
	 *--------------------------------------------------------------------------------------------*/
    
    func cancelAction(sender: AnyObject){
        self.pickerDelegate!.photoBrowseControllerDidCancel!()
        self.dismiss(animated: true, completion: nil)
    }
    
	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/

    fileprivate func loadData(paging: Bool = false) {
		
		guard !self.processing else {
			return
		}
		
		guard self.searchBar!.text != nil && !self.searchBar!.text!.isEmpty else {
			return
		}
        
		self.processing = true
		self.activity?.startAnimating()
		
        if !paging {
            self.imageResults.removeAll()
			self.virtualSize = self.pageSize
            let topOffset = CGPoint(x:0, y:-(self.collectionView?.contentInset.top ?? 0))
			self.collectionView?.setContentOffset(topOffset, animated: true)
        }
		
		BingController.instance.backgroundOperationQueue.addOperation {
			
			BingController.instance.loadSearchImages(query: self.searchBar!.text!
                , count: Int64(self.pageSize)
                , offset: Int64(self.offset)) { response, error in
                
				OperationQueue.main.addOperation {
					
					self.activity?.stopAnimating()
					var userInfo: [AnyHashable: Any] = ["error": (error != nil)]
                    
                    if error == nil {
                        
                        let json = JSON(response!)
                        var imagesFiltered: [ImageResult] = [ImageResult]()
                        let offsetAddCount = json["nextOffsetAddCount"].int
                        let totalEstimatedMatches = json["totalEstimatedMatches"].int
                        let more = (self.pageSize + self.offset + offsetAddCount! < totalEstimatedMatches!)
                        
                        if let data = json["value"].arrayObject {
                            
                            Utils.updateSearchHistory(search: self.searchBar!.text!)
                            self.loadSearches()
                            
                            let beginCount = self.imageResults.count
                            
                            Log.d("Images returned: \(data.count)")
                            
                            for imageResultDict in data {
                                let imageResult = ImageResult.setPropertiesFromDictionary(dictionary: imageResultDict as! NSDictionary, onObject: ImageResult())
                                var usable = (imageResult.contentSize! <= self.maxImageSize)
                                
                                if usable {
                                    usable = imageResult.height! <= self.maxDimen && imageResult.width! <= self.maxDimen
                                }
                                
                                if usable {
                                    usable = imageResult.thumbnailUrl != nil
                                }
                                
                                if (usable) {
                                    imagesFiltered.append(imageResult)
                                }
                            }
                            self.imageResults.append(contentsOf: imagesFiltered)
                            
                            if self.imageResults.count == beginCount {
                                self.virtualSize = self.imageResults.count
                                self.threshold = 1000
                            }
                            else {
                                self.threshold = self.imageResults.count - 20
                                self.virtualSize = self.imageResults.count + 30
                            }

                            userInfo["count"] = self.imageResults.count
                        }
                        else {
                            userInfo["count"] = 0
                        }
                        
                        if more && self.imageResults.count < self.maxSize {
                            self.offset += (self.pageSize + offsetAddCount!)
                            if (self.imageResults.count < 60) {
                                self.processing = false
                                self.loadData(paging: true)
                            }
                        }
                        else {
                            /* Disables scroll triggered fetches */
                            self.threshold = 1000
                            self.virtualSize = self.imageResults.count
                            Log.d("No more search images available")
                        }
						
						self.collectionView?.reloadData()
					}
                    
                    /* Triggers ui handling of empty, etc. */
					NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.DidFetchQuery), object: self, userInfo: userInfo)
					self.processing = false
				}
			}
		}
    }
	
	func loadSearches() {
		self.searches.removeAll()
		if let searches = UserDefaults.standard.array(forKey: PerUserKey(key: Prefs.searchHistory)) as? [String] {
			for search in searches {
				self.searches.append(search)
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
        self.autocompleteData = self.searches.filter { search in
            return search.lowercased().contains(substring.lowercased())
        }
		self.autocompleteList.isHidden = (self.autocompleteData.count == 0)
		self.autocompleteList.alignUnder(self.searchBar, centeredFillingWidthWithLeftAndRightPadding: 0, topPadding: 0, height: CGFloat(self.autocompleteData.count * 40))
		self.autocompleteList.reloadData()
	}
}

extension PhotoSearchController: UISearchBarDelegate {
	
	func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
		filterSearchesWithSubstring(substring: searchText)
	}
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        self.searchBar!.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.searchBar!.setShowsCancelButton(false, animated: false)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.searchBar!.resignFirstResponder()
        self.searchBar!.text = nil
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.offset = 0
        searchBar.resignFirstResponder()
        self.loadData(paging: false)
        self.autocompleteList.isHidden = true
    }
}

extension PhotoSearchController {
	/*
	* UITableViewDelegate
	*/
	@objc(tableView:cellForRowAtIndexPath:) func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
		
		if cell == nil {
			cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
		}
		
		let search = self.autocompleteData[indexPath.row]
        cell?.textLabel?.text = search
        cell?.textLabel?.font = Theme.fontComment
		return cell!
	}
    
    @objc(numberOfSectionsInTableView:) func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
    
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.autocompleteData.count
	}
	
	@objc(tableView:didSelectRowAtIndexPath:) func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		
		let search = self.autocompleteData[indexPath.row]
        self.searchBar!.text = search
        self.offset = 0
        self.autocompleteList.isHidden = true
        self.loadData(paging: false)
        searchBar.resignFirstResponder()
	}
}

extension PhotoSearchController {
    /*
     * UICollectionViewDelegate
     */
	override func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
		
		if !self.processing {
			if let indexPaths = self.collectionView?.indexPathsForVisibleItems {
				for indexPath in indexPaths {
					if indexPath.row > self.threshold {
						loadData(paging: true)
						return
					}
				}
			}
		}
	}
	
	override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		
		if !self.processing {
			if let indexPaths = self.collectionView?.indexPathsForVisibleItems {
				for indexPath in indexPaths {
					if indexPath.row > self.threshold {
						loadData(paging: true)
						return
					}
				}
			}
		}
	}
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        if let cell = collectionView.cellForItem(at: indexPath) as? ThumbnailCollectionViewCell {
            let photo = IDMPhoto(image: cell.thumbnail.image!)!
            let photos = Array([photo])
            let browser = PhotoBrowser(photos: photos as [AnyObject], animatedFrom: cell.thumbnail)
            
            browser?.mode = .preview
            browser?.usePopAnimation = true
            browser?.scaleImage = cell.thumbnail.image  // Used because final image might have different aspect ratio than initially
            browser?.useWhiteBackgroundColor = true
            browser?.disableVerticalSwipe = false
            
            browser?.browseDelegate = self.pickerDelegate  // Pass delegate through
            browser?.imageResult = self.imageForIndexPath(indexPath: indexPath as NSIndexPath)
            
            present(browser!, animated:true, completion:nil)
        }
    }
}

extension PhotoSearchController {
    /*
     * UICollectionViewDataSource
     */
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.virtualSize
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.reuseIdentifier, for: indexPath) 
        cell.backgroundColor = Theme.colorBackgroundImage
		
		if let imageResult = self.imageForIndexPath(indexPath: indexPath as NSIndexPath) {
			if let thumbCell = cell as? ThumbnailCollectionViewCell {
				if let imageView = thumbCell.thumbnail {
					thumbCell.imageResult = imageResult
                    imageView.enableProgress = false
					imageView.setImageWithUrl(url: URL(string: imageResult.thumbnailUrl!)!, animate: false)
				}
			}			
		}
		
        return cell
    }
}

extension PhotoSearchController: UICollectionViewDelegateFlowLayout {
    
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
            
            return sectionInsets!
    }
}
