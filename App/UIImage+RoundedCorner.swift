//
//  UIImage+RoundedCorner.swift
//
//  Created by Trevor Harmon on 09/20/09.
//  Swift port by Giacomo Boccardo on 03/18/15.
//
//  Free for personal or commercial use, with or without modification
//  No warranty is expressed or implied.
//

public extension UIImage {
    
    // Creates a copy of this image with rounded corners
    // If borderSize is non-zero, a transparent border of the given size will also be added
    // Original author: Björn Sållarp. Used with permission. See: http://blog.sallarp.com/iphone-uiimage-round-corners/
    public func roundedCornerImage(cornerRadius: Int, borderSize: Int) -> UIImage {
        // If the image does not have an alpha layer, add one
        let image = self.withAlpha()!
        
        // Build a context that's the same dimensions as the new size
        let colorSpace: CGColorSpace = cgImage!.colorSpace!
        let bitmapInfo = CGBitmapInfo(arrayLiteral: cgImage!.bitmapInfo)
        let context = CGContext.init(
            data: nil,
            width: Int(image.size.width),
            height: Int(image.size.height),
            bitsPerComponent: cgImage!.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        )!
        
        // Create a clipping path with rounded corners
        context.beginPath()
        self.addRoundedRectToPath(
            rect: CGRect(x: CGFloat(borderSize)
                , y: CGFloat(borderSize)
                , width: image.size.width - CGFloat(borderSize) * 2
                , height: image.size.height - CGFloat(borderSize) * 2),
            context: context,
            ovalWidth: CGFloat(cornerRadius),
            ovalHeight: CGFloat(cornerRadius)
        )
        context.closePath()
        context.clip()
        
        // Draw the image to the context; the clipping path will make anything outside the rounded rect transparent
        context.draw(cgImage!, in: CGRect(x:0, y:0, width: image.size.width, height: image.size.height))
        
        // Create a CGImage from the context
        let clippedImage = context.makeImage()!
        
        // Create a UIImage from the CGImage
        return UIImage(cgImage: clippedImage)
    }
    
    // Adds a rectangular path to the given context and rounds its corners by the given extents
    // Original author: Björn Sållarp. Used with permission. See: http://blog.sallarp.com/iphone-uiimage-round-corners/
    private func addRoundedRectToPath(rect: CGRect, context: CGContext, ovalWidth: CGFloat, ovalHeight: CGFloat) {
        if (ovalWidth == 0 || ovalHeight == 0) {
            context.addRect(rect)
            return
        }
        
        context.saveGState()
        context.translateBy(x: rect.minX, y: rect.minY)
        context.scaleBy(x: ovalWidth, y: ovalHeight)
        let fw = rect.width / ovalWidth
        let fh = rect.height / ovalHeight
        context.move(to: CGPoint(x: fw, y: fh/2))
        context.addArc(tangent1End: CGPoint(x: fw, y: fh), tangent2End: CGPoint(x: fw/2, y: fh), radius: 1)
        context.addArc(tangent1End: CGPoint(x: 0, y: fh), tangent2End: CGPoint(x: 0, y: fh/2), radius: 1)
        context.addArc(tangent1End: CGPoint(x: 0, y: 0), tangent2End: CGPoint(x: fw/2, y: 0), radius: 1)
        context.addArc(tangent1End: CGPoint(x: fw, y: 0), tangent2End: CGPoint(x: fw, y: fh/2), radius: 1)
        context.closePath();
        context.restoreGState()
    }
}
