//
//  UIImage+Extension.swift
//  Cyber-coffe
//
//  Created by Леонід Квіт on 27.04.2024.
//

import Foundation
import UIKit

extension UIImage {
    
    var base64: String {
        let jpegData = self.jpegData(compressionQuality: 1.0)
        let base64EncodedString = (jpegData! as NSData).base64EncodedString()
        return base64EncodedString
    }
    
    func processPixels(_ color: UIColor) -> UIImage? {
        guard let inputCGImage = self.cgImage else {
            print("unable to get cgImage")
            return nil
        }
        let colorSpace       = CGColorSpaceCreateDeviceRGB()
        let width            = inputCGImage.width
        let height           = inputCGImage.height
        let bytesPerPixel    = 4
        let bitsPerComponent = 8
        let bytesPerRow      = bytesPerPixel * width
        let bitmapInfo       = RGBA32.bitmapInfo
        
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo) else {
            print("unable to create context")
            return nil
        }
        context.draw(inputCGImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        guard let buffer = context.data else {
            print("unable to get context data")
            return nil
        }
        
        let pixelBuffer = buffer.bindMemory(to: RGBA32.self, capacity: width * height)
        
        for row in 0 ..< Int(height) {
            for column in 0 ..< Int(width) {
                let offset = row * width + column
                if (pixelBuffer[offset].redComponent > 50 && pixelBuffer[offset].greenComponent > 50 && pixelBuffer[offset].blueComponent > 50) || (pixelBuffer[offset].alphaComponent < 240 && pixelBuffer[offset].alphaComponent > 0) {
                    pixelBuffer[offset] = color.rgba32 ?? .black
                }
            }
        }
        
        let outputCGImage = context.makeImage()!
        let outputImage = UIImage(cgImage: outputCGImage, scale: self.scale, orientation: self.imageOrientation)
        
        return outputImage
    }
    
    func tint(color: UIColor, _ blendMode: CGBlendMode = .normal) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        color.setFill()
        
        let context = UIGraphicsGetCurrentContext()
        context?.translateBy(x: 0, y: self.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        context?.setBlendMode(blendMode)
        
        let rect = CGRect(origin: .zero, size: CGSize(width: self.size.width, height: self.size.height))
        context?.clip(to: rect, mask: self.cgImage!)
        context?.fill(rect)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    func alpha(_ value: CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: CGPoint.zero, blendMode: .normal, alpha: value)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    static func fromGradient(colors: [UIColor], locations: [CGFloat], horizontal: Bool, size: CGSize) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let cgColors = colors.map {$0.cgColor} as CFArray
        let grad = CGGradient(colorsSpace: colorSpace, colors: cgColors, locations: locations)
        
        let startPoint = CGPoint(x: 0, y: 0)
        let endPoint = horizontal ? CGPoint(x: size.width, y: 0) : CGPoint(x: 0, y: size.height)
        
        context?.drawLinearGradient(grad!, start: startPoint, end: endPoint, options: .drawsAfterEndLocation)
        
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
    
    func blendWithGradientAndRect(blendMode: CGBlendMode, colors: [UIColor], locations: [CGFloat], horizontal: Bool = false, alpha: CGFloat = 1.0, rect: CGRect) -> UIImage {
        
        let imageColor = UIImage.fromGradient(colors: colors, locations: locations, horizontal: horizontal, size: size)
        let rectImage = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        
        UIGraphicsBeginImageContextWithOptions(self.size, true, 0)
        let context = UIGraphicsGetCurrentContext()
        
        // fill the background with white so that translucent colors get lighter
        context!.setFillColor(UIColor.white.cgColor)
        context!.fill(rectImage)
        
        self.draw(in: rectImage, blendMode: .normal, alpha: 1)
        imageColor.draw(in: rect, blendMode: blendMode, alpha: alpha)
        
        // grab the finished image and return it
        let result = UIGraphicsGetImageFromCurrentImageContext()
        
        //self.backgroundImageView.image = result
        UIGraphicsEndImageContext()
        return result!
        
    }
    
    // <-->
    func applyOverlayWithColor(color: UIColor, blendMode: CGBlendMode) -> UIImage? {
        
        // Create a new CGContext
        UIGraphicsBeginImageContextWithOptions(self.size, false, UIScreen.main.scale)
        let bounds = CGRect(origin: CGPoint.zero, size: self.size)
        let context = UIGraphicsGetCurrentContext()
        
        // Draw image into context, then fill using the proper color and blend mode
        draw(in: bounds, blendMode: .normal, alpha: 1.0)
        context!.setBlendMode(blendMode)
        context!.setFillColor(color.cgColor)
        context!.fill(bounds)
        
        // Return the resulting image
        let overlayImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext();
        
        return overlayImage
    }
    func applyOverlayWithColor(color: UIColor, blendMode: CGBlendMode, alpha: CGFloat) -> UIImage? {
        return applyOverlayWithColor(color: color.withAlphaComponent(alpha), blendMode: blendMode)
    }
    // <-->
    
    func resizeImage(_ dimension: CGFloat, opaque: Bool, contentMode: UIView.ContentMode = .scaleAspectFit) -> UIImage {
        var width: CGFloat
        var height: CGFloat
        var newImage: UIImage
        
        let size = self.size
        let aspectRatio =  size.width / size.height
        
        switch contentMode {
            case .scaleAspectFit:
                if aspectRatio > 1 {                            // Landscape image
                    width = dimension
                    height = dimension / aspectRatio
                } else {                                        // Portrait image
                    height = dimension
                    width = dimension * aspectRatio
            }
            
            default:
                fatalError("UIImage.resizeToFit(): FATAL: Unimplemented ContentMode")
        }
        
        if #available(iOS 10.0, *) {
            let renderFormat = UIGraphicsImageRendererFormat.default()
            renderFormat.opaque = opaque
            let renderer = UIGraphicsImageRenderer(size: CGSize(width: width, height: height), format: renderFormat)
            newImage = renderer.image {
                (context) in
                self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
            }
        } else {
            UIGraphicsBeginImageContextWithOptions(CGSize(width: width, height: height), opaque, 0)
            self.draw(in: CGRect(x: 0, y: 0, width: width, height: height))
            newImage = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
        }
        
        return newImage
    }
    
    func replaceColor(color: UIColor, withColor: UIColor, tolerance: CGFloat) -> UIImage {
        
        // This function expects to get source color(color which is supposed to be replaced)
        // and target color in RGBA color space, hence we expect to get 4 color components: r, g, b, a
        assert(color.cgColor.numberOfComponents == 4 && withColor.cgColor.numberOfComponents == 4,
               "Must be RGBA colorspace")
        
        // Allocate bitmap in memory with the same width and size as source image
        let imageRef = cgImage!
        let width = imageRef.width
        let height = imageRef.height
        
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width;
        let bitsPerComponent = 8
        let bitmapByteCount = bytesPerRow * height
        
        let rawData = UnsafeMutablePointer<UInt8>.allocate(capacity: bitmapByteCount)
        
        let context = CGContext(data: rawData, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: CGColorSpace(name: CGColorSpace.genericRGBLinear)!,
                                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue)
        
        
        let rc = CGRect(x: 0, y: 0, width: width, height: height)
        
        // Draw source image on created context
        context!.draw(imageRef, in: rc)
        
        
        // Get color components from replacement color
        let withColorComponents = withColor.cgColor.components
        let r2 = UInt8(withColorComponents![0] * 255)
        let g2 = UInt8(withColorComponents![1] * 255)
        let b2 = UInt8(withColorComponents![2] * 255)
        let a2 = UInt8(withColorComponents![3] * 255)
        
        // Prepare to iterate over image pixels
        var byteIndex = 0
        
        while byteIndex < bitmapByteCount {
            
            // Get color of current pixel
            let red = CGFloat(rawData[byteIndex + 0]) / 255
            let green = CGFloat(rawData[byteIndex + 1]) / 255
            let blue = CGFloat(rawData[byteIndex + 2]) / 255
            let alpha = CGFloat(rawData[byteIndex + 3]) / 255
            
            let currentColor = UIColor(red: red, green: green, blue: blue, alpha: alpha);
            
            // Compare two colors using given tolerance value
            if compareColor(color: color, withColor: currentColor , withTolerance: tolerance) {
                
                // If the're 'similar', then replace pixel color with given target color
                rawData[byteIndex + 0] = r2
                rawData[byteIndex + 1] = g2
                rawData[byteIndex + 2] = b2
                rawData[byteIndex + 3] = a2
            }
            
            byteIndex = byteIndex + 4;
        }
        
        // Retrieve image from memory context
        let imgref = context!.makeImage()
        let result = UIImage(cgImage: imgref!)
        
        // Clean up a bit
        rawData.deallocate()
        
        return result
    }
}

func compareColor(color: UIColor, withColor: UIColor, withTolerance: CGFloat) -> Bool {
    
    var r1: CGFloat = 0.0, g1: CGFloat = 0.0, b1: CGFloat = 0.0, a1: CGFloat = 0.0;
    var r2: CGFloat = 0.0, g2: CGFloat = 0.0, b2: CGFloat = 0.0, a2: CGFloat = 0.0;
    
    color.getRed(&r1, green: &g1, blue: &b1, alpha: &a1);
    withColor.getRed(&r2, green: &g2, blue: &b2, alpha: &a2);
    
    return abs(r1 - r2) <= withTolerance &&
        abs(g1 - g2) <= withTolerance &&
        abs(b1 - b2) <= withTolerance &&
        abs(a1 - a2) <= withTolerance;
}
