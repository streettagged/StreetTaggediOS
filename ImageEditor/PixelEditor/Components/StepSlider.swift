//
//  Created by John O'Sullivan on 1/16/20.
//  Copyright © 2019 John O'Sullivan. All rights reserved.
//
import Foundation

import TransitionPatch

public final class StepSlider : UIControl {
  
  public enum Mode {
    case plus
    case plusAndMinus
    case minus
  }
  
  public var mode: Mode = .plusAndMinus {
    didSet {
      setupValues()
    }
  }

  private var minStep: Int = -100

  private var maxStep: Int = 100

  public override var intrinsicContentSize: CGSize {
    return internalSlider.intrinsicContentSize
  }

  private let feedbacker = UIImpactFeedbackGenerator(style: .light)
  private let feedbackGenerator = UISelectionFeedbackGenerator()

  private let offset: Double = 0.05

  public private(set) var step: Int = 0 {
    didSet {
      if oldValue != step {
        if step == 0, internalSlider.isTracking {
          feedbackGenerator.selectionChanged()
          feedbackGenerator.prepare()
        }
      }
      updateStepLabel()

      sendActions(for: .valueChanged)
    }
  }

  private let internalSlider = _StepSlider(frame: .zero)

  public override init(frame: CGRect) {
    super.init(frame: .zero)
    setup()
    feedbackGenerator.prepare()
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setup() {

    internalSlider.addTarget(self, action: #selector(__didChangeValue), for: .valueChanged)

    addSubview(internalSlider)
    internalSlider.frame = bounds
    internalSlider.autoresizingMask = [.flexibleWidth, .flexibleHeight]

    setupValues()
  }

  private func setupValues() {
    
    switch mode {
    case .plus:
      maxStep = 100
      minStep = 0
    case .plusAndMinus:
      maxStep = 100
      minStep = -100
    case .minus:
      maxStep = 0
      minStep = -100
    }
    
    internalSlider.dotLocation = mode

    if minStep < 0 {
      internalSlider.minimumValue = -1
    } else {
      internalSlider.minimumValue = 0
    }

    if maxStep > 0 {
      internalSlider.maximumValue = 1
    } else {
      internalSlider.maximumValue = 0
    }

    step = 0
  }

  public func set(value: Double, min: Double, max: Double) {

    guard !internalSlider.isTracking else { return }

    if value == 0 {
      internalSlider.value = 0
    } else {
      if value > 0 {
        internalSlider.value = Float(
          ValuePatch(CGFloat(value))
            .progress(start: 0, end: CGFloat(max))
            .transition(start: CGFloat(offset), end: CGFloat(internalSlider.maximumValue))
            .value
        )
      } else {
        internalSlider.value = Float(
          ValuePatch(CGFloat(value))
            .progress(start: 0, end: CGFloat(min))
            .transition(start: CGFloat(-offset), end: CGFloat(internalSlider.minimumValue))
            .value
        )
      }
    }

    __didChangeValue()

  }

  public func transition(min: Double, max: Double) -> Double {

    if step == 0 {
      return 0
    } else {
      if step > 0 {
        return
          Double(
            ValuePatch(CGFloat(step))
              .progress(start: CGFloat(0), end: CGFloat(maxStep))
              .transition(start: 0, end: CGFloat(max))
              .value
        )
        
      } else {
        return
          Double(
            ValuePatch(CGFloat(step))
              .progress(start: CGFloat(0), end: CGFloat(minStep))
              .transition(start: 0, end: CGFloat(min))
              .value
        )
      }
    }
  }

  @objc
  private func __didChangeValue() {

    let value = internalSlider.value

    if case -offset ... offset = Double(value) {
      if self.step != 0 {
        self.step = 0
      }
      // To fix thumb
      internalSlider.value = 0
      return
    }

    let step: Int

    if value > 0 {

      step = Int(
        ValuePatch(CGFloat(value))
          .progress(start: CGFloat(offset), end: CGFloat(internalSlider.maximumValue))
          .transition(start: 0, end: CGFloat(maxStep))
          .value
          .rounded()
      )

    } else {

      step = Int(
        ValuePatch(CGFloat(value))
          .progress(start: CGFloat(-offset), end: CGFloat(internalSlider.minimumValue))
          .transition(start: 0, end: CGFloat(minStep))
          .value
          .rounded()
      )

    }

    self.step = Int(step)
  }

  private func updateStepLabel() {
    if step == 0 {
      internalSlider.stepLabel.text = ""
    } else {
      internalSlider.stepLabel.text = "\(step)"
    }
    internalSlider.stepLabel.sizeToFit()
    internalSlider.updateStepLabel()
  }
}

extension StepSlider {

  public func set<T>(value: Double, in range: ParameterRange<Double, T>) {

    set(value: value, min: range.min, max: range.max)
  }

  public func transition<T>(in range: ParameterRange<Double, T>) -> Double {
    return transition(min: range.min, max: range.max)
  }
}

private final class _StepSlider: UISlider {

  let stepLabel: UILabel = .init()

  private var _trackImageView: UIImageView?

  var dotLocation: StepSlider.Mode = .plus {
    didSet {
      setNeedsDisplay()
    }
  }

  override init(frame: CGRect) {

    super.init(frame: frame)
    self.setup()
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }

  override func draw(_ rect: CGRect) {

    guard let context = UIGraphicsGetCurrentContext() else {
      return
    }

    let scale = contentScaleFactor

    guard
      let layer = CGLayer(context, size: CGSize(width: bounds.size.width * scale, height: bounds.size.height * scale), auxiliaryInfo: nil),
      let layerContext = layer.context
      else {
        return
    }

    UIGraphicsPushContext(layerContext)

    layerContext.scaleBy(x: scale, y: scale)

    UIColor(white: 0, alpha: 1).setStroke()
    UIColor(white: 0, alpha: 1).setFill()

    line: do {
      let path = UIBezierPath()
      path.move(to: CGPoint.init(x: 10, y: bounds.midY))
      path.addLine(to: CGPoint.init(x: bounds.maxX - 10, y: bounds.midY))
      path.lineWidth = 1
      path.stroke()
    }

    dot: do {

      switch dotLocation {
      case .plus:
        let path = UIBezierPath(ovalIn: .init(origin: .init(x: 10 - 3, y: bounds.midY - 3), size: .init(width: 6, height: 6)))
        path.fill()
      case .plusAndMinus:
        let path = UIBezierPath(ovalIn: .init(origin: .init(x: bounds.midX - 3, y: bounds.midY - 3), size: .init(width: 6, height: 6)))
        path.fill()
      case .minus:
        let path = UIBezierPath(ovalIn: .init(origin: .init(x: bounds.maxX - 10 - 3, y: bounds.midY - 3), size: .init(width: 6, height: 6)))
        path.fill()
      }

    }

    UIGraphicsPopContext()

    context.setAlpha(0.2)
    context.draw(layer, in: bounds)
  }

  private func setup() {

    minimumTrackTintColor = UIColor.clear
    maximumTrackTintColor = UIColor.clear
    setThumbImage(UIImage(named: "slider_thumb", in: bundle, compatibleWith: nil), for: [])
    tintColor = Style.default.black

    let label = stepLabel
    label.backgroundColor = UIColor.clear
    label.font = UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
    label.textColor = UIColor.black
    label.textAlignment = .center

    self.addSubview(label)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    updateStepLabel()
  }

  func updateStepLabel() {

    findTrackViewIfNeeded()

    guard let trackImageView = _trackImageView else {
      return
    }

    let center = CGPoint(x: trackImageView.frame.midX, y: -16)
    self.stepLabel.center = center
  }

  private func findTrackViewIfNeeded() {

    guard _trackImageView == nil else {
      return
    }

    for imageView in self.subviews where imageView is UIImageView {

      if imageView.bounds.width == imageView.bounds.height {
        _trackImageView = imageView as? UIImageView
      }
    }
  }
}
