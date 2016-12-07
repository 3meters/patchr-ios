//
//  PHPhotoLibrary+PhotoAsset.swift
//  
//
//  kudos to ricardopereira
//  https://gist.github.com/ricardopereira
//

import Foundation
import Photos

public extension PHPhotoLibrary {
    
    typealias PhotoAsset = PHAsset
    typealias PhotoAlbum = PHAssetCollection
    
    static func saveImage(image: UIImage, albumName: String, completion: @escaping (PHAsset?)->()) {
        if let album = self.findAlbum(albumName: albumName) {
            saveImage(image: image, album: album, completion: completion)
            return
        }
        createAlbum(albumName: albumName) { album in
            if let album = album {
                self.saveImage(image: image, album: album, completion: completion)
            }
            else {
                assert(false, "Album is nil")
            }
        }
    }
    
    static func saveVideo(videoUrl: NSURL, albumName: String, completion: @escaping (PHAsset?)->()) {
        if let album = self.findAlbum(albumName: albumName) {
            saveVideo(videoUrl: videoUrl, album: album, completion: completion)
            return
        }
        createAlbum(albumName: albumName) { album in
            if let album = album {
                self.saveVideo(videoUrl: videoUrl, album: album, completion: completion)
            }
            else {
                assert(false, "Album is nil")
            }
        }
    }
    
    static private func saveImage(image: UIImage, album: PhotoAlbum, completion: @escaping (PHAsset?)->()) {
        
        var placeholder: PHObjectPlaceholder?
        
        PHPhotoLibrary.shared().performChanges({
            
            /* Request creating an asset from the image */
            let createAssetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            
            /* Request editing the album */
            guard let albumChangeRequest = PHAssetCollectionChangeRequest(for: album) else {
                assert(false, "Album change request failed")
                return
            }
            
            /* Get a placeholder for the new asset and add it to the album editing request */
            guard let photoPlaceholder = createAssetRequest.placeholderForCreatedAsset else {
                assert(false, "Placeholder is nil")
                return
            }
            
            placeholder = photoPlaceholder
            let enumeration: NSArray = [photoPlaceholder]
            albumChangeRequest.addAssets(enumeration)
            
        }, completionHandler: { success, error in
            
                guard let placeholder = placeholder else {
                    assert(false, "Placeholder is nil")
                    completion(nil)
                    return
                }
                
                if success {
                    completion(PHAsset.ah_fetchAssetWithLocalIdentifier(identifier: placeholder.localIdentifier, options: nil))
                }
                else {
                    print(error as Any)
                    completion(nil)
                }
        })
    }
     
    static private func saveVideo(videoUrl: NSURL, album: PhotoAlbum, completion: @escaping (PHAsset?)->()) {
    
        var placeholder: PHObjectPlaceholder?
        
        PHPhotoLibrary.shared().performChanges({
            
            // Request creating an asset from the image
            let createAssetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoUrl as URL)
            
            // Request editing the album
            guard let albumChangeRequest = PHAssetCollectionChangeRequest(for: album) else {
                assert(false, "Album change request failed")
                return
            }
            
            // Get a placeholder for the new asset and add it to the album editing request
            guard let videoPlaceholder = createAssetRequest!.placeholderForCreatedAsset else {
                assert(false, "Placeholder is nil")
                return
            }
            
            placeholder = videoPlaceholder
            let enumeration: NSArray = [videoPlaceholder]
            albumChangeRequest.addAssets(enumeration)
            
            }, completionHandler: { success, error in
                guard let placeholder = placeholder else {
                    assert(false, "Placeholder is nil")
                    completion(nil)
                    return
                }
                
                if success {
                    completion(PHAsset.ah_fetchAssetWithLocalIdentifier(identifier: placeholder.localIdentifier, options:nil))
                }
                else {
                    print(error as Any)
                    completion(nil)
                }
        })
    }

    static func findAlbum(albumName: String) -> PhotoAlbum? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let fetchResult = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if fetchResult.count == 0 {
            return nil
        }
        return fetchResult.firstObject! as PhotoAlbum
    }
    
    static func createAlbum(albumName: String, completion: @escaping (PhotoAlbum?)->()) {
        var albumPlaceholder: PHObjectPlaceholder?
        PHPhotoLibrary.shared().performChanges({
            
            // Request creating an album with parameter name
            let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
            
            // Get a placeholder for the new album
            albumPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
            }, completionHandler: { success, error in
                guard let placeholder = albumPlaceholder else {
                    assert(false, "Album placeholder is nil")
                    completion(nil)
                    return
                }
                
                let fetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [placeholder.localIdentifier], options: nil)
                if fetchResult.count == 0 {
                    assert(false, "FetchResult has no PHAssetCollection")
                    completion(nil)
                    return
                }
                
                if success {
                    completion(fetchResult.firstObject!)
                }
                else {
                    print(error as Any)
                    completion(nil)
                }
        })
    }
    
    static func loadThumbnailFromLocalIdentifier(localIdentifier: String, completion: @escaping (UIImage?)->()) {
        guard let asset = PHAsset.ah_fetchAssetWithLocalIdentifier(identifier: localIdentifier, options:nil) else {
            completion(nil)
            return
        }
        loadThumbnailFromAsset(asset: asset, completion: completion)
    }
    
    static func loadThumbnailFromAsset(asset: PhotoAsset, completion: @escaping (UIImage?)->()) {
        PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 100.0, height: 100.0), contentMode: .aspectFit, options: PHImageRequestOptions(), resultHandler: { result, info in
            completion(result)
        })
    }
}


