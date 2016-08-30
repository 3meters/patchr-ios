//
//  ImageResult.swift
//  
//
//  Created by Jay Massena on 6/13/15.
//
//
import Foundation

class ImageResult: NSObject {
    
    var name: String?
    var contentUrl: String?
    var contentSize: Int?
    var encodingFormat: String?
    var width: Int?
    var height: Int?
    var thumbnailUrl: String?
    var thumbnailWidth: Int?
    var thumbnailHeight: Int?

    static func setPropertiesFromDictionary(dictionary: NSDictionary, onObject imageResult: ImageResult) -> ImageResult {
        
        let json:JSON = JSON(dictionary)

        imageResult.name = json["name"].string
        imageResult.contentUrl = json["contentUrl"].string
        imageResult.contentSize = Int((json["contentSize"].string?.numbersOnly)!)
        imageResult.encodingFormat = json["encodingFormat"].string
        imageResult.width = json["width"].int
        imageResult.height = json["height"].int
        
        imageResult.thumbnailUrl = json["thumbnailUrl"].string
        imageResult.thumbnailWidth = json["thumbnail"]["width"].int
        imageResult.thumbnailHeight = json["thumbnail"]["height"].int
        
        return imageResult
    }
}