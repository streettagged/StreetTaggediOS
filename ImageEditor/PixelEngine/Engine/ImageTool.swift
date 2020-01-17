//
//  Created by John O'Sullivan on 1/16/20.
//  Copyright © 2019 John O'Sullivan. All rights reserved.
//

import UIKit
import CoreImage
import AVFoundation

public enum ImageTool {

  private static let ciContext = CIContext(options: [
    .useSoftwareRenderer : false,
    .highQualityDownsample: true,
    .workingColorSpace : CGColorSpaceCreateDeviceRGB()
    ]
  )

  public static func resize(to pixelSize: CGSize, from image: CIImage) -> CIImage? {

    var targetSize = pixelSize
    targetSize.height.round(.down)
    targetSize.width.round(.down)

    let scaleX = targetSize.width / image.extent.width
    let scaleY = targetSize.height / image.extent.height

    if false, #available(iOS 12, *) {

      // This code does not work well.
      // In UIImageView, display 1px white line.

      let resized = image
        .transformed(by: .init(scaleX: scaleX, y: scaleY))

      // TODO: round extent

      let result = resized
        .transformed(by: .init(
          translationX: -(resized.extent.minX - resized.extent.minX.rounded(.down)),
          y: -(resized.extent.minY - resized.extent.minY.rounded(.down))
          )
        )
        .insertingIntermediate()

      return result

    } else {

      return
        autoreleasepool { () -> CIImage? in

          let originalExtent = image.extent

          let format: UIGraphicsImageRendererFormat
          if #available(iOS 11.0, *) {
            format = UIGraphicsImageRendererFormat.preferred()
          } else {
            format = UIGraphicsImageRendererFormat.default()
          }
          format.scale = 1
          format.opaque = true
          if #available(iOS 12.0, *) {
            format.preferredRange = .automatic
          } else {
            format.prefersExtendedRange = false
          }
                    
          let uiImage = UIGraphicsImageRenderer.init(size: targetSize, format: format)
            .image { c in
              
              autoreleasepool {
                let rect = CGRect(origin: .zero, size: targetSize)
                if let cgImage = image.cgImage {
                  c.cgContext.translateBy(x: 0, y: targetSize.height)
                  c.cgContext.scaleBy(x: 1, y: -1)
                  c.cgContext.draw(cgImage, in: rect)

                } else {
                  
                  if #available(iOS 13, *) {
                    c.cgContext.translateBy(x: 0, y: targetSize.height)
                    c.cgContext.scaleBy(x: 1, y: -1)
                    let context = CIContext(cgContext: c.cgContext, options: [:])
                    context.draw(image, in: rect, from: image.extent)
                  } else {
                    UIImage(ciImage: image).draw(in: rect)
                  }
                  
                }
              }
            }
                            
          let resizedImage: CIImage
          
          if #available(iOS 12, *) {
            resizedImage = CIImage(image: uiImage)!
              .insertingIntermediate(cache: true)
          } else {
            resizedImage = uiImage
              .pngData()
              .flatMap {
                CIImage(data: $0, options: [.colorSpace : image.colorSpace ?? CGColorSpaceCreateDeviceRGB()])
              }!
          }
          
          let r = resizedImage.transformed(by: .init(
            translationX: (originalExtent.origin.x * scaleX).rounded(.down),
            y: (originalExtent.origin.y * scaleY).rounded(.down)
            )
          )

          return r
      }

    }
  }

}
