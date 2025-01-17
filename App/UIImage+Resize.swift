//
//  UIImage+Resize.swift
//
//  Created by Trevor Harmon on 08/05/09.
//  Swift port by Giacomo Boccardo on 03/18/15.
//
//  Free for personal or commercial use, with or without modification
//  No warranty is expressed or implied.
//

public extension UIImage {
    
    // Returns a copy of this image that is cropped to the given bounds.
    // The bounds will be adjusted using CGRectIntegral.
    // This method ignores the image's imageOrientation setting.
    public func croppedImage(bounds: CGRect) -> UIImage {
        let imageRef: CGImageRef = CGImageCreateWithImageInRect(self.CGImage, bounds)
        return UIImage(CGImage: imageRef)
    }
    
    public func thumbnailImage(thumbnailSize: Int, transparentBorder borderSize:Int, cornerRadius:Int, interpolationQuality quality:CGInterpolationQuality) -> UIImage {
        let resizedImage = self.resizedImageWithContentMode(.ScaleAspectFill, bounds: CGSize(width:CGFloat(thumbnailSize), CGFloat(thumbnailSize)), interpolationQuality: quality)
 
        // Crop out any part of the image that's larger than the thumbnail size
        // The cropped rect must be centered on the resized image
        // Round the origin points so that the size isn't altered when CGRectIntegral is later invoked
        let cropRect = CGRect(x:
            round((resizedImage.size.width - CGFloat(thumbnailSize))/2),
            round((resizedImage.size.height - CGFloat(thumbnailSize))/2),
            CGFloat(thumbnailSize),
            CGFloat(thumbnailSize)
        )
        
        let croppedImage = resizedImage.croppedImage(cropRect)
        let transparentBorderImage = borderSize != 0 ? croppedImage.transparentBorderImage(borderSize) : croppedImage
        
        return transparentBorderImage.roundedCornerImage(cornerSize: cornerRadius, borderSize: borderSize)
    }
    
    // Returns a rescaled copy of the image, taking into account its orientation
    // The image will be scaled disproportionately if necessary to fit the bounds specified by the parameter
    public func resizedImage(newSize: CGSize, interpolationQuality quality: CGInterpolationQuality) -> UIImage {
        var drawTransposed: Bool
        
        switch(self.imageOrientation) {
            case .Left, .LeftMirrored, .Right, .RightMirrored:
                drawTransposed = true
            default:
                drawTransposed = false
        }
        
        return self.resizedImage(
            newSize,
            transform: self.transformForOrientation(newSize),
            drawTransposed: drawTransposed,
            interpolationQuality: quality
        )
    }
    
    public func cropToSquare() -> UIImage {
        // Create a copy of the image without the imageOrientation property so it is in its native orientation (landscape)
        let contextImage: UIImage = UIImage(CGImage: self.CGImage)!
        
        // Get the size of the contextImage
        let contextSize: CGSize = contextImage.size
        
        let posX: CGFloat
        let posY: CGFloat
        let width: CGFloat
        let height: CGFloat
        
        // Check to see which length is the longest and create the offset based on that length, then set the width and height of our rect
        if contextSize.width > contextSize.height {
            posX = ((contextSize.width - contextSize.height) / 2)
            posY = 0
            width = contextSize.height
            height = contextSize.height
        } else {
            posX = 0
            posY = ((contextSize.height - contextSize.width) / 2)
            width = contextSize.width
            height = contextSize.width
        }
        
        let rect: CGRect = CGRect(x:posX, posY, width, height)
        
        // Create bitmap image from context using the rect
        let imageRef: CGImageRef = CGImageCreateWithImageInRect(contextImage.CGImage, rect)
        
        // Create a new image based on the imageRef and rotate back to the original orientation
        let image: UIImage = UIImage(CGImage: imageRef, scale: self.scale, orientation: self.imageOrientation)
        
        return image
    }
    
    public func resizedImageWithContentMode(contentMode: UIViewContentMode, bounds: CGSize, interpolationQuality quality: CGInterpolationQuality) -> UIImage {
        let horizontalRatio = bounds.width / self.size.width
        let verticalRatio = bounds.height / self.size.height
        var ratio: CGFloat = 1

        switch(contentMode) {
            case .ScaleAspectFill:
                ratio = max(horizontalRatio, verticalRatio)
            case .ScaleAspectFit:
                ratio = min(horizontalRatio, verticalRatio)
            default:
                fatalError("Unsupported content mode \(contentMode)")
        }

        let newSize: CGSize = CGSize(width:self.size.width * ratio, self.size.height * ratio)
        return self.resizedImage(newSize, interpolationQuality: quality)
    }
    
    private func normalizeBitmapInfo(bI: CGBitmapInfo) -> CGBitmapInfo {
        var alphaInfo: CGBitmapInfo = bI & CGBitmapInfo.AlphaInfoMask
        
        if alphaInfo == CGBitmapInfo(rawValue: CGImageAlphaInfo.Last.rawValue) {
            alphaInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedLast.rawValue)
        }

        if alphaInfo == CGBitmapInfo(rawValue: CGImageAlphaInfo.First.rawValue) {
            alphaInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedFirst.rawValue)
        }

        var newBI: CGBitmapInfo = bI & ~CGBitmapInfo.AlphaInfoMask;

        newBI |= alphaInfo;

        return newBI
    }
    
    private func resizedImage(newSize: CGSize, transform: CGAffineTransform, drawTransposed transpose: Bool, interpolationQuality quality: CGInterpolationQuality) -> UIImage {
        let newRect = CGRectIntegral(CGRect(x:0, 0, newSize.width, newSize.height))
        let transposedRect = CGRect(x:0, 0, newRect.size.height, newRect.size.width)
        let imageRef: CGImageRef = self.CGImage

        // Build a context that's the same dimensions as the new size
        let bitmap: CGContextRef = CGBitmapContextCreate(
            nil,
            Int(newRect.size.width),
            Int(newRect.size.height),
            CGImageGetBitsPerComponent(imageRef),
            0,
            CGImageGetColorSpace(imageRef),
            normalizeBitmapInfo(CGImageGetBitmapInfo(imageRef))
        )

        // Rotate and/or flip the image if required by its orientation
        CGContextConcatCTM(bitmap, transform)

        // Set the quality level to use when rescaling
        CGContextSetInterpolationQuality(bitmap, quality)

        // Draw into the context; this scales the image
        CGContextDrawImage(bitmap, transpose ? transposedRect: newRect, imageRef)

        // Get the resized image from the context and a UIImage
        let newImageRef: CGImageRef = CGBitmapContextCreateImage(bitmap)
        return UIImage(CGImage: newImageRef)
    }
    
    private func transformForOrientation(newSize: CGSize) -> CGAffineTransform {
        var transform: CGAffineTransform = CGAffineTransformIdentity
        
        switch (self.imageOrientation) {
            case .Down, .DownMirrored:
                // EXIF = 3 / 4
                transform = CGAffineTransformTranslate(transform, newSize.width, newSize.height)
                transform = CGAffineTransformRotate(transform, CGFloat(M_PI))
            case .Left, .LeftMirrored:
                // EXIF = 6 / 5
                transform = CGAffineTransformTranslate(transform, newSize.width, 0)
                transform = CGAffineTransformRotate(transform, CGFloat(M_PI_2))
            case .Right, .RightMirrored:
                // EXIF = 8 / 7
                transform = CGAffineTransformTranslate(transform, 0, newSize.height)
                transform = CGAffineTransformRotate(transform, -CGFloat(M_PI_2))
            default:
                break
        }
        
        switch(self.imageOrientation) {
            case .UpMirrored, .DownMirrored:
                // EXIF = 2 / 4
                transform = CGAffineTransformTranslate(transform, newSize.width, 0)
                transform = CGAffineTransformScale(transform, -1, 1)
            case .LeftMirrored, .RightMirrored:
                // EXIF = 5 / 7
                transform = CGAffineTransformTranslate(transform, newSize.height, 0)
                transform = CGAffineTransformScale(transform, -1, 1)
            default:
                break
        }
        
        return transform
    }
}
