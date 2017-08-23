//
//  PHAsset+identifier.swift
//  
//
//  kudos tos666
//  https://forums.developer.apple.com/people/tos666
//

import Foundation
import Photos

public extension PHAsset {
    
    public class func ah_fetchAssetWithLocalIdentifier(identifier: String, options: PHFetchOptions?) -> PHAsset? {
        /* Try to find the asset by identifier. */
        let asset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: options)
        if asset.count > 0 {
            return asset.firstObject
        }
        
        /* Try to find the asset using search */
        var result : PHAsset?
        let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumMyPhotoStream, options: options)
        let fetchOptions = PHFetchOptions()
        
        fetchOptions.predicate = NSPredicate(format: "localIdentifier ==[cd] %@", identifier)
        
        userAlbums.enumerateObjects({
            (objectCollection : Any, _ : Int, stopCollectionEnumeration : UnsafeMutablePointer<ObjCBool>) in
            
            guard let collection = objectCollection as? PHAssetCollection else { return }
            
            let assetsFetchResult = PHAsset.fetchAssets(in: collection, options: fetchOptions)
            
            assetsFetchResult.enumerateObjects({
                (objectAsset : AnyObject, _ : Int, stopAssetEnumeration: UnsafeMutablePointer<ObjCBool>) in
                
                guard let asset = objectAsset as? PHAsset else { return }
                result = asset
                stopAssetEnumeration.initialize(to: true)
                stopCollectionEnumeration.initialize(to: true)
            })
        })
        return result
    }
}
