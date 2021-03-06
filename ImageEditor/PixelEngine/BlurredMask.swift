//
//  Created by John O'Sullivan on 1/16/20.
//  Copyright © 2019 John O'Sullivan. All rights reserved.
//

import Foundation
import UIKit

public struct BlurredMask : GraphicsDrawing {

  public var paths: [DrawnPathInRect]

  public init(paths: [DrawnPathInRect]) {
    self.paths = paths
  }

  public func draw(in context: CGContext, canvasSize: CGSize) {

    guard !paths.isEmpty else {
      return
    }

    let mainContext = context
    let size = canvasSize

    guard
      let cglayer = CGLayer(mainContext, size: size, auxiliaryInfo: nil),
      let layerContext = cglayer.context else {
        assert(false, "Failed to create CGLayer")
        return
    }

    let ciContext = CIContext(cgContext: layerContext, options: [:])
    let ciImage = BlurredMask.blur(image: CIImage(image: UIGraphicsGetImageFromCurrentImageContext()!)!)!

    UIGraphicsPushContext(layerContext)

    paths.forEach { path in
      layerContext.saveGState()

      let scale = Geometry.diagonalRatio(to: canvasSize, from: path.inRect.size)

      layerContext.scaleBy(x: scale, y: scale)
      path.draw(in: layerContext, canvasSize: canvasSize)

      layerContext.restoreGState()
    }

    layerContext.saveGState()

    layerContext.setBlendMode(.sourceIn)
    layerContext.translateBy(x: 0, y: canvasSize.height)
    layerContext.scaleBy(x: 1, y: -1)

    ciContext.draw(ciImage, in: ciImage.extent, from: ciImage.extent)

    layerContext.restoreGState()

    UIGraphicsPopContext()

    UIGraphicsPushContext(mainContext)

    mainContext.draw(cglayer, at: .zero)

    UIGraphicsPopContext()
  }

  public static func blur(image: CIImage) -> CIImage? {

    func radius(_ imageExtent: CGRect) -> Double {

      let v = Double(sqrt(pow(imageExtent.width, 2) + pow(imageExtent.height, 2)))
      return v / 20 // ?
    }

    // let min: Double = 0
    let max: Double = 100
    let value: Double = 40

    let _radius = radius(image.extent) * value / max

    let outputImage = image
      .clamped(to: image.extent)
      .applyingFilter(
        "CIGaussianBlur",
        parameters: [
          "inputRadius" : _radius
        ])
      .cropped(to: image.extent)

    return outputImage
  }
}
