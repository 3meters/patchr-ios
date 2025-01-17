//
//  Created by Rob MacEachern on 2015-02-23.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit
import AMScrollingNavbar
import IDMPhotoBrowser

public enum ImageType {
    case photo
    case animatedGif
}

class PhotoSearchController: UICollectionViewController, UITableViewDelegate, UITableViewDataSource {
    
    var inputImageType = ImageType.photo
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
	var autocompleteList = AirTableView()
	var autocompleteData = [String]()
	var searches = [String]()
	
	var queue = OperationQueue()
	
    fileprivate var sectionInsets: UIEdgeInsets?
    fileprivate var cellWidth: CGFloat?
    fileprivate var cellHeight: CGFloat?
    fileprivate var availableWidth: CGFloat?
    
    fileprivate let pageSize = 150      // Maximum allowed by Bing. We pull max to keep request count down.
    fileprivate var maxSize = 100
	fileprivate var virtualSize = 60
    fileprivate var virtualChunk = 60
    fileprivate let maxImageSize = 500000
    fileprivate let maxDimen = Int(Config.imageDimensionMax)
    
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.searchBar?.becomeFirstResponder()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let navigationController = navigationController as? ScrollingNavigationController {
            navigationController.showNavbar(animated: true)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.searchBar.anchorTopCenter(withTopPadding: 0, width: self.view.width(), height: 44)
        self.collectionView?.alignUnder(self.searchBar, matchingLeftAndRightFillingHeightWithTopPadding: 0, bottomPadding: 0)
    }
    
	/*--------------------------------------------------------------------------------------------
	 * Events
	 *--------------------------------------------------------------------------------------------*/
    
    @objc func cancelAction(sender: AnyObject){
        self.pickerDelegate!.photoBrowseControllerDidCancel!()
        self.dismiss(animated: true, completion: nil)
    }
    
	/*--------------------------------------------------------------------------------------------
	* Methods
	*--------------------------------------------------------------------------------------------*/
    
    func initialize() {

        self.navigationItem.title = "search".localized()
        self.queue.name = "Image loading queue"
        if #available(iOS 11.0, *) {
            self.collectionView!.contentInsetAdjustmentBehavior = .never
        }
        else {
            self.automaticallyAdjustsScrollViewInsets = false
        }

        self.searchBar = UISearchBar(frame: CGRect(x:0, y:0, width: UIScreen.main.bounds.size.width, height:44))
        self.searchBar!.autocapitalizationType = .none
        self.searchBar!.delegate = self
        self.searchBar!.placeholder = "photo_search_bar_placeholder".localized()
        self.searchBar.setValue("cancel".localized(), forKey: "_cancelButtonText")
        self.searchBar!.searchBarStyle = .prominent

        /* Scroll inset */
        self.sectionInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        
        /* Calculate thumbnail width */
        self.availableWidth = UIScreen.main.bounds.size.width - (sectionInsets!.left + sectionInsets!.right)
        let requestedColumnWidth: CGFloat = (UIDevice.current.userInterfaceIdiom == .phone) ? 100 : 150
        let numColumns: CGFloat = floor(CGFloat(self.availableWidth!) / CGFloat(requestedColumnWidth))
        let spaceLeftOver = self.availableWidth! - (numColumns * requestedColumnWidth) - ((numColumns - 1) * 4)
        self.cellWidth = requestedColumnWidth + (spaceLeftOver / numColumns)
        self.cellHeight = self.cellWidth
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: self.cellWidth!, height: self.cellHeight!)
        layout.sectionInset = self.sectionInsets!
        layout.minimumInteritemSpacing = 4
        layout.minimumLineSpacing = 4

        self.collectionView?.backgroundColor = Theme.colorBackgroundForm
        self.collectionView!.collectionViewLayout = layout
        self.collectionView!.register(UINib(nibName: "ThumbnailCell", bundle: nil), forCellWithReuseIdentifier: "cell")
        
        /* Auto complete table view */
        self.autocompleteList.delegate = self
        self.autocompleteList.dataSource = self
        self.autocompleteList.isScrollEnabled = true
        self.autocompleteList.isHidden = true
        self.autocompleteList.rowHeight = 40
        self.autocompleteList.separatorInset = UIEdgeInsets.zero
        
        /* Simple activity indicator */
        self.activity = addActivityIndicatorTo(view: self.view)
        
        self.view.addSubview(self.searchBar!)
        self.view.addSubview(self.autocompleteList)
        
        /* Past searches */
        loadSearches()
        
        /* Navigation bar buttons */
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(PhotoSearchController.cancelAction(sender:)))
        self.navigationItem.leftBarButtonItems = [cancelButton]
    }

    fileprivate func loadData(paging: Bool = false) {
		
		guard !self.processing else {
			return
		}
		
		guard let searchText = self.searchBar!.text, !searchText.isEmpty else {
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
			
			BingController.instance.loadSearchImages(query: searchText
                , type: self.inputImageType
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
                        
                        guard totalEstimatedMatches != nil else {
                            /* Triggers ui handling of empty, etc. */
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Events.DidFetchQuery), object: self, userInfo: userInfo)
                            self.processing = false
                            self.collectionView?.reloadData()
                            return
                        }
                        
                        let more = (self.pageSize + self.offset + offsetAddCount! < totalEstimatedMatches!)
                        
                        if let data = json["value"].arrayObject {
                            
                            Utils.updateSearchHistory(search: searchText)
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
                                self.virtualSize = self.imageResults.count + self.virtualChunk
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
    
    override func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        if let navigationController = navigationController as? ScrollingNavigationController {
            navigationController.showNavbar(animated: true)
        }
        return true
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
        Reporting.track("submit_photo_search")
        self.loadData(paging: false)
        self.autocompleteList.isHidden = true
    }
}

extension PhotoSearchController { // UITableViewDelegate
    
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
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

extension PhotoSearchController { // UICollectionViewDelegate
    
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
        
        if let cell = collectionView.cellForItem(at: indexPath) as? ThumbnailCell {
            if self.inputImageType == .photo {
                
                if cell.imageView.image != nil { // Ignore touches on placeholder images
                    let photo = DisplayPhoto(image: cell.imageView.image!)!
                    let browser = PhotoBrowser(photos: [photo] as [Any], animatedFrom: cell.imageView)!
                    
                    browser.mode = .preview
                    browser.usePopAnimation = true
                    browser.scaleImage = cell.imageView.image  // Used because final image might have different aspect ratio than initially
                    browser.useWhiteBackgroundColor = true
                    browser.disableVerticalSwipe = false
                    browser.browseDelegate = self.pickerDelegate  // Pass delegate through
                    browser.imageResult = self.imageForIndexPath(indexPath: indexPath as NSIndexPath)
                    Reporting.track("preview_search_photo")
                    present(browser, animated:true, completion:nil)
                }
            }
            else if self.inputImageType == .animatedGif {
                if let imageResult = self.imageForIndexPath(indexPath: indexPath as NSIndexPath) {
                    
                    let photo = DisplayPhoto(url: URL(string:imageResult.contentUrl!))!
                    let browser = PhotoBrowser(photos: [photo] as [Any])
                    
                    browser?.mode = .preview
                    browser?.useWhiteBackgroundColor = true
                    browser?.disableVerticalSwipe = false
                    browser?.browseDelegate = self.pickerDelegate  // Pass delegate through
                    browser?.imageResult = self.imageForIndexPath(indexPath: indexPath as NSIndexPath)
                    
                    present(browser!, animated:true, completion:nil)
                }
            }
        }
    }
}

extension PhotoSearchController { // UICollectionViewDataSource
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.virtualSize
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        cell.backgroundColor = Theme.colorBackgroundImage
		
		if let imageResult = self.imageForIndexPath(indexPath: indexPath as NSIndexPath) {
			if let thumbCell = cell as? ThumbnailCell {
				if let imageView = thumbCell.imageView {
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
        return CGSize(width: self.cellWidth!, height: self.cellHeight!)
    }
    
    func collectionView(_ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int) -> UIEdgeInsets {
        return sectionInsets!
    }
}
