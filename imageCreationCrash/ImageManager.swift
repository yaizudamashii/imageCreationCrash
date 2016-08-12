//
//  ImageManager.swift
//  imageCreationCrash
//
//  Created by Yuki Konda on 8/12/16.
//  Copyright © 2016 Yuki Konda. All rights reserved.
//

import UIKit

class ImageManager: NSObject {
    static let sharedInstance = ImageManager()

    func scaleImage(image: UIImage, maxDimension: CGFloat) -> UIImage {
        
        var scaledSize = CGSize(width: maxDimension, height: maxDimension)
        var scaleFactor: CGFloat
        
        if image.size.width > image.size.height {
            scaleFactor = image.size.height / image.size.width
            scaledSize.width = maxDimension
            scaledSize.height = scaledSize.width * scaleFactor
        } else {
            scaleFactor = image.size.width / image.size.height
            scaledSize.height = maxDimension
            scaledSize.width = scaledSize.height * scaleFactor
        }
        
        UIGraphicsBeginImageContext(scaledSize)
        image.drawInRect(CGRectMake(0, 0, scaledSize.width, scaledSize.height))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
    
    func croppedImage(screenShotImage : UIImage) -> UIImage {
        let contextImage: UIImage = UIImage(CGImage: screenShotImage.CGImage!)
        
        let contextSize: CGSize = contextImage.size
        
        let posX: CGFloat = contextSize.width * 0.30
        let posY: CGFloat = contextSize.height * 0.06
        let cgwidth: CGFloat = contextSize.width * 0.35
        let cgheight: CGFloat = contextSize.height * 0.05
        
        let rect: CGRect = CGRectMake(posX, posY, cgwidth, cgheight)
        
        // Create bitmap image from context using the rect
        let imageRef: CGImageRef = CGImageCreateWithImageInRect(contextImage.CGImage, rect)!
        
        // Create a new image based on the imageRef and rotate back to the original orientation
        var image: UIImage = UIImage(CGImage: imageRef, scale: screenShotImage.scale, orientation: screenShotImage.imageOrientation)
        image = self.scaleImage(image, maxDimension: 640.0)
        return image
    }
    
    func preprocessImage(image: UIImage) -> UIImage? {
        
        var data = self.intensityValuesFromImage(image)
        
        0.stride(to: data.width * data.height * 4, by: 4).forEach {
            let count = $0
            let r = Double(data.pixelValues![count + 0])
            let g = Double(data.pixelValues![count + 1])
            let b = Double(data.pixelValues![count + 2])
            let a = Double(data.pixelValues![count + 3])
            
            let gray = 0.2989 * r + 0.5870 * g + 0.1140 * b
            
            data.pixelValues![count + 0] = UInt8(gray)
            data.pixelValues![count + 1] = UInt8(gray)
            data.pixelValues![count + 2] = UInt8(gray)
            data.pixelValues![count + 3] = UInt8(a)
            
        }
        
        if let pixelValues = data.pixelValues {
            let img = self.imageFromRGBA32Bitmap(pixelValues, width: data.width, height: data.height)
            return img
        }
        return nil
    }
    
    func intensityValuesFromImage(image: UIImage?) -> (pixelValues: [UInt8]?, width: Int, height: Int) {
        var width = 0
        var height = 0
        var pixelValues: [UInt8]?
        if (image != nil) {
            let imageRef = image!.CGImage
            width = CGImageGetWidth(imageRef)
            height = CGImageGetHeight(imageRef)
            
            let bytesPerPixel = 4
            let bytesPerRow = bytesPerPixel * width
            let bitsPerComponent = 8
            let totalBytes = width * height * bytesPerPixel
            
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            pixelValues = [UInt8](count: totalBytes, repeatedValue: 0)
            
            let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.ByteOrder32Big.rawValue | CGImageAlphaInfo.PremultipliedLast.rawValue)
            let contextRef = CGBitmapContextCreate(&pixelValues!, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo.rawValue)
            CGContextDrawImage(contextRef, CGRectMake(0.0, 0.0, CGFloat(width), CGFloat(height)), imageRef)
        }
        
        return (pixelValues, width, height)
    }
    
    func imageFromRGBA32Bitmap(pixels:[UInt8], width:Int, height:Int)-> UIImage? {
        let bitsPerComponent: Int = 8
        let bitsPerPixel: Int = 32
        let bpp = 4
        
        assert(pixels.count == Int(width * height) * bpp)
        
        var data = pixels // Copy to mutable []
        let cfData = NSData(bytes: &data, length: data.count * sizeof([UInt8]))
        let providerRef = CGDataProviderCreateWithCFData(cfData)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.ByteOrder32Big.rawValue | CGImageAlphaInfo.PremultipliedLast.rawValue)
        let cgim = CGImageCreate(
            width,
            height,
            bitsPerComponent,
            bitsPerPixel,
            width * bpp,
            rgbColorSpace,
            bitmapInfo,
            providerRef,
            nil,
            true,
            CGColorRenderingIntent.RenderingIntentDefault
        )
        if (cgim != nil) {
            return UIImage(CGImage: cgim!)
        }
        return nil
    }
    
    func grayscaleImage(image : UIImage, completionHandler: ((recognizedText : String?, processedImage : UIImage?) -> Void)?) {
        let croppedImage : UIImage = ImageManager.sharedInstance.croppedImage(image)
        let contrastedImage: UIImage? = self.preprocessImage(croppedImage)
        completionHandler?(recognizedText: nil, processedImage: contrastedImage)
    }
}
