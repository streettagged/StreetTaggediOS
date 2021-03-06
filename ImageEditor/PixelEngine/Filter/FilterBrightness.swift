//
//  Created by John O'Sullivan on 1/16/20.
//  Copyright © 2019 John O'Sullivan. All rights reserved.
//

import Foundation
import CoreImage

public struct FilterBrightness: Filtering, Equatable, Codable {
  
  public static let range: ParameterRange<Double, FilterContrast> = .init(min: -0.2, max: 0.2)
  
  public var value: Double = 0
  
  public init() {
    
  }
  
  public func apply(to image: CIImage, sourceImage: CIImage) -> CIImage {
    return
      image
        .applyingFilter(
          "CIColorControls",
          parameters: [
            "inputBrightness": value,
            ]
    )
  }
  
}
