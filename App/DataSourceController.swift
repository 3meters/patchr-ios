//
//  DataSourceController.swift
//  Patchr
//
//  Created by Jay Massena on 7/22/17.
//  Copyright © 2017 3meters. All rights reserved.
//

import Foundation
import FirebaseDatabaseUI
import FirebaseAuth

class DataSourceController: NSObject, FUICollectionDelegate {
    
    weak var delegate: FUICollectionDelegate?
    var scrollView: UIScrollView!
    var name: String!
    
    var populate: ((UIScrollView, IndexPath, Any) -> UIView)!
    var matcher: ((String, Any) -> Bool)?
    
    var snapshots: FUIArray! // Contains snapshots
    private var dataScreened = [Any]() // Does NOT stay synchronized beyond initial pass
    private var dataFiltered = [Any]() // Pulls from active array
    
    var filterActive = false
    var mapperActive = false
    var startEmpty = false
    
    var items: [Any] {
        get {
            if self.startEmpty {
                return self.dataFiltered
            }
            else if self.mapperActive {
                return self.filterActive ? self.dataFiltered : self.dataScreened
            }
            else {
                return self.filterActive ? self.dataFiltered : self.snapshots.items
            }
        }
    }
    
    init(name: String) {
        self.name = name
        super.init()
    }
    
    func bind(to scrollView: UIScrollView, query: FUIDataObservable, populateCell: @escaping (UIScrollView, IndexPath, Any) -> UIView) {
        self.scrollView = scrollView
        self.populate = populateCell
        if let tableView = scrollView as? UITableView {
            tableView.dataSource = self
        }
        else if let collectionView = scrollView as? UICollectionView {
            collectionView.dataSource = self
        }
        self.snapshots = FUIArray(query: query)
        self.snapshots.delegate = self // So we get called when there are changes to the synchronized array
        self.snapshots.observeQuery() // Start synching
    }
    
    func unbind() {
        if let tableView = scrollView as? UITableView {
            tableView.dataSource = nil
        }
        else if let collectionView = scrollView as? UICollectionView {
            collectionView.dataSource = nil
        }
        self.snapshots?.invalidate()
    }
    
    func snapshot(at index: Int) -> DataSnapshot {
        let item = self.items.at(index)
        return item as! DataSnapshot
    }
    
    func filter(searchText text: String?) {
        guard self.matcher != nil else {
            fatalError("Filtering requires filterMatcher")
        }
        self.dataFiltered.removeAll()
        
        if text == nil {
            let items = (self.dataScreened.count > 0) ? self.dataScreened : self.snapshots.items
            for item in items {
                self.dataFiltered.append(item)
            }
        }
        else {
            let items = (self.dataScreened.count > 0) ? self.dataScreened : self.snapshots.items
            for item in items {
                if self.matcher!(text!, item) {
                    self.dataFiltered.append(item)
                }
            }
        }
        
        DispatchQueue.main.async {
            if let tableView = self.scrollView as? UITableView {
                tableView.reloadData()
            }
            else if let collectionView = self.scrollView as? UICollectionView {
                collectionView.reloadData()
            }
        }
        return
    }
    
    func arrayDidBeginUpdates(_ collection: FUICollection) {
        self.delegate?.arrayDidBeginUpdates?(collection)
    }
    
    func arrayDidEndUpdates(_ collection: FUICollection) {
        self.delegate?.arrayDidEndUpdates?(collection)
    }
    
    func array(_ array: FUICollection, didAdd object: Any, at index: UInt) {
        if self.mapperActive || self.startEmpty { return }
        do {
            self.delegate?.array?(array, didAdd: object, at: index)
            let indexPath = IndexPath(row: Int(index), section: 0)
            try ObjC.catchException {
                if let tableView = self.scrollView as? UITableView {
                    tableView.insertRows(at: [indexPath], with: .none)
                }
                else if let collectionView = self.scrollView as? UICollectionView {
                    collectionView.insertItems(at: [indexPath])
                }
            }
        }
        catch {
            Log.w("Caught exception: arrayDidAdd: \(error.localizedDescription)")
            return
        }
    }
    
    func array(_ array: FUICollection, didMove object: Any, from fromIndex: UInt, to toIndex: UInt) {
        if self.mapperActive || self.startEmpty { return }
        do {
            self.delegate?.array?(array, didMove: object, from: fromIndex, to: toIndex)
            try ObjC.catchException {
                if let tableView = self.scrollView as? UITableView {
                    tableView.moveRow(at: IndexPath(row: Int(fromIndex), section: 0), to: IndexPath(row: Int(toIndex), section: 0))
                }
                else if let collectionView = self.scrollView as? UICollectionView {
                    collectionView.moveItem(at: IndexPath(row: Int(fromIndex), section: 0), to: IndexPath(row: Int(toIndex), section: 0))
                }
            }
        }
        catch {
            Log.w("Caught exception: arrayDidMove: \(error.localizedDescription)")
            return
        }
    }
    
    func array(_ array: FUICollection, didRemove object: Any, at index: UInt) {
        if self.mapperActive || self.startEmpty { return }
        do {
            self.delegate?.array?(array, didRemove: object, at: index)
            try ObjC.catchException {
                if let tableView = self.scrollView as? UITableView {
                    tableView.deleteRows(at: [IndexPath(row: Int(index), section: 0)], with: .none)
                }
                else if let collectionView = self.scrollView as? UICollectionView {
                    collectionView.deleteItems(at: [IndexPath(row: Int(index), section: 0)])
                }
            }
        }
        catch {
            Log.w("Caught exception: arrayDidRemove: \(error.localizedDescription)")
            return
        }
    }
    
    func array(_ array: FUICollection, didChange object: Any, at index: UInt) {
        if self.mapperActive || self.startEmpty { return }
        do {
            try ObjC.catchException {
                if self.delegate != nil && self.delegate!.responds(to: #selector(self.array(_:didChange:at:))) {
                    self.delegate?.array?(array, didChange: object, at: index)
                }
                else {
                    if let tableView = self.scrollView as? UITableView {
                        tableView.reloadRows(at: [IndexPath(row: Int(index), section: 0)], with: .none)
                    }
                    else if let collectionView = self.scrollView as? UICollectionView {
                        collectionView.reloadItems(at: [IndexPath(row: Int(index), section: 0)])
                    }
                }
            }
        }
        catch {
            Log.w("Caught exception: arrayDidChange: \(error.localizedDescription)")
            return
        }
    }
    
    func array(_ array: FUICollection, queryCancelledWithError error: Error) {
        self.delegate?.array?(array, queryCancelledWithError: error)
    }
}

extension DataSourceController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let data = self.items.at(indexPath.row)
        let cell = self.populate(tableView, indexPath, data!)
        return cell as! UITableViewCell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = self.items.count
        return count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}

extension DataSourceController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let data = self.items.at(indexPath.row)
        let cell = self.populate(collectionView, indexPath, data!)
        return cell as! UICollectionViewCell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = self.items.count
        return count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
}
