//
//  ImageResult.swift
//  
//
//  Created by Jay Massena on 6/13/15.
//
//

/*
* {
*   d: {
*       "__next": "https://api.datamarket.azure.com/Data.ashx/Bing/Search/v1/Image?Query='Grunge'&Market='en-US'&Adult='Strict'&ImageFilters='size:large'&$skip=50&$top=50";
*       "results": [
*           {
*               ContentType: "image/jpeg",
*               DisplayUrl: "www.graphicsfuel.com/2010/12/hi-res-grunge-texture-pack",
*               FileSize: 3402443,
*               Height: 1500,
*               ID: "58b831ed-e278-4deb-8b68-517bbe4e0857",
*               MediaUrl: "http://www.graphicsfuel.com/wp-content/uploads/2010/12/grunge-texture-03.jpg",
*               SourceUrl: "http://www.graphicsfuel.com/2010/12/hi-res-grunge-texture-pack/",
*               Thumbnail: {
*                   ContentType: "image/jpg",
*                   FileSize: 21950,
*                   Height: 225,
*                   MediaUrl: "http://ts1.mm.bing.net/th?id=JN.ChpizRfLOh6WcLYotRoJRA&pid=15.1",
*                   Width: 300,
*                   "__metadata": {
*                       type = "Bing.Thumbnail",
*                   }
*               },
*               Title: "High resolution grunge texture pack",
*               Width: 2000,
*               "__metadata": {
*                   type: ImageResult,
*                   uri: "https://api.datamarket.azure.com/Data.ashx/Bing/Search/v1/Image?Query='Grunge'&Market='en-US'&Adult='Strict'&ImageFilters='size:large'&$skip=0&$top=1";
*               }
*           }
*       ]
*   }
* }
*/

import Foundation

class ImageResult: NSObject {
    
    var title: String?
    var mediaUrl: String?
    var sourceUrl: String?
    var displayUrl: String?
    var width: Int?
    var height: Int?
    var fileSize: Int?
    var contentType: String?
    var thumbnail: Thumbnail?
    
    static func setPropertiesFromDictionary(dictionary: NSDictionary, onObject imageResult: ImageResult) -> ImageResult {
        
        imageResult.title = dictionary["Title"] as? String
        imageResult.mediaUrl = dictionary["MediaUrl"] as? String
        imageResult.sourceUrl = dictionary["SourceUrl"] as? String
        imageResult.displayUrl = dictionary["DisplayUrl"] as? String
        imageResult.width = (dictionary["Width"] as! String).toInt()
        imageResult.height = (dictionary["Height"] as! String).toInt()
        imageResult.fileSize = (dictionary["FileSize"] as! String).toInt()
        imageResult.contentType = dictionary["ContentType"] as? String
        
        if let thumbnailDict = dictionary["Thumbnail"] as? NSDictionary {
            imageResult.thumbnail = Thumbnail.setPropertiesFromDictionary(thumbnailDict, onObject: Thumbnail())
        }
        
        return imageResult
    }
}

class Thumbnail {
    
    var mediaUrl: String?
    var width: Int?
    var height: Int?
    var fileSize: Int?
    var contentType: String?
    
    static func setPropertiesFromDictionary(dictionary: NSDictionary, onObject thumbnail: Thumbnail) -> Thumbnail {
        
        thumbnail.mediaUrl = dictionary["MediaUrl"] as? String
        thumbnail.width = (dictionary["Width"] as! String).toInt()
        thumbnail.height = (dictionary["Height"] as! String).toInt()
        thumbnail.fileSize = (dictionary["FileSize"] as! String).toInt()
        thumbnail.contentType = dictionary["ContentType"] as? String
        
        return thumbnail
    }
}
