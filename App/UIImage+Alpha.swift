//
//  UIImage+Alpha.swift
//
//  Created by Trevor Harmon on 09/20/09.
//  Swift port by Giacomo Boccardo on 03/18/15.
//
//  Free for personal or commercial use, with or without modification
//  No warranty is expressed or implied.
//

public extension UIImage {
    
    public func hasAlpha() -> Bool {
        let alpha: CGImageAlphaInfo = self.cgImage!.alphaInfo
        return
            alpha == CGImageAlphaInfo.first ||
            alpha == CGImageAlphaInfo.last ||
            alpha == CGImageAlphaInfo.premultipliedFirst ||
            alpha == CGImageAlphaInfo.premultipliedLast
    }
    
    public func imageWithAlpha() -> UIImage {
        if self.hasAlpha() {
            return self
        }
        
        let imageRef: CGImage = self.cgImage!
        let width  = cgImage!.width
        let height = cgImage!.height

        // The bitsPerComponent and bitmapInfo values are hard-coded to prevent an "unsupported parameter combination" error
        let offscreenContext: CGContext = CGBitmapContextCreate(
            nil,
            width,
            height,
            8,
            0,
            cgImage!.colorSpace!,
            CGBitmapInfo.ByteOrderDefault | CGBitmapInfo(rawValue: CGImageAlphaInfo.PremultipliedFirst.rawValue)
        )
        
        // Draw the image into the context and retrieve the new image, which will now have an alpha layer
        self.draw(in: CGRect.init(x: 0, y: 0, width: width, height: height))
        CGContextDrawImage(offscreenContext, CGRect.init(x: 0, y: 0, width: width, height: height), imageRef)
        let imageRefWithAlpha:CGImageRef = CGBitmapContextCreateImage(offscreenContext)
        
        return UIImage(CGImage: imageRefWithAlpha)
    }
    
    public func transparentBorderImage(borderSize: Int) -> UIImage {
        let image = self.imageWithAlpha()
        
        let newRect = CGRect(x:
            0, 0,
            image.size.width + CGFloat(borderSize) * 2,
            image.size.height + CGFloat(borderSize) * 2
        )
        
        // Build a context that's the same dimensions as the new size
        let bitmap: CGContextRef = CGBitmapContextCreate(
            nil,
            Int(newRect.size.width), Int(newRect.size.height),
            CGImageGetBitsPerComponent(self.CGImage),
            0,
            CGImageGetColorSpace(self.CGImage),
            CGImageGetBitmapInfo(self.CGImage)
        )
        
        // Draw the image in the center of the context, leaving a gap around the edges
        let imageLocation = CGRect(x:CGFloat(borderSize), CGFloat(borderSize), image.size.width, image.size.height)
        CGContextDrawImage(bitmap, imageLocation, self.CGImage)
        let borderImageRef: CGImageRef = CGBitmapContextCreateImage(bitmap)
        
        // Create a mask to make the border transparent, and combine it with the image
        let maskImageRef: CGImageRef = self.newBorderMask(borderSize, size: newRect.size)
        let transparentBorderImageRef: CGImageRef = CGImageCreateWithMask(borderImageRef, maskImageRef)
        return UIImage(CGImage:transparentBorderImageRef)
    }
    
    private func newBorderMask(borderSize: Int, size: CGSize) -> CGImageRef {
        let colorSpace: CGColorSpaceRef = CGColorSpaceCreateDeviceGray()
        
        // Build a context that's the same dimensions as the new size
        let maskContext: CGContextRef = CGBitmapContextCreate(
            nil,
            Int(size.width), Int(size.height),
            8, // 8-bit grayscale
            0,
            colorSpace,
            CGBitmapInfo.ByteOrderDefault | CGBitmapInfo(rawValue: CGImageAlphaInfo.None.rawValue)
        )
        
        // Start with a mask that's entirely transparent
        CGContextSetFillColorWithColor(maskContext, UIColor.blackColor().CGColor)
        CGContextFillRect(maskContext, CGRect(x:0, 0, size.width, size.height))
        
        // Make the inner part (within the border) opaque
        CGContextSetFillColorWithColor(maskContext, UIColor.whiteColor().CGColor)
        CGContextFillRect(maskContext, CGRect(x:
            CGFloat(borderSize),
            CGFloat(borderSize),
            size.width - CGFloat(borderSize) * 2,
            size.height - CGFloat(borderSize) * 2)
        )
        
        // Get an image of the context
        return CGBitmapContextCreateImage(maskContext)
    }
}
