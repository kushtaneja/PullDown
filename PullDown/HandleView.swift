//
//  HandleView.swift
//  PullDown
//
//  Created by Kush Taneja on 17/06/17.
//  Copyright © 2017 Kush Taneja. All rights reserved.
//

import UIKit

/**
 *   Enum describing the state of a HandleView.
 */

enum HandleViewState : Int {
    /// Arrow points upwards
    case up = -1
    /// A flat handle without an arrow in any direction
    case neutral = 0
    /// Arrow points downwards
    case down = 1
}

@IBDesignable
class HandleView: UIView {

    @IBInspectable var arrowSize: CGSize = CGSize.zero {
        didSet {
            setNeedsLayout()
            invalidateIntrinsicContentSize()
        }
    }
    /// The stroke width of the arrow. Default matches the notification center style.
    @IBInspectable var strokeWidth: CGFloat = 6.0 {
        didSet {
            shapeLayer().lineWidth = strokeWidth
            invalidateIntrinsicContentSize()
        }
    }
        /// The stroke color of the arrow. Default is lightGrayColor.
    @IBInspectable var strokeColor: UIColor? {
        didSet {
            shapeLayer().strokeColor = strokeColor?.cgColor
        }
    }

    /// The current state of the handle view.
    private(set) var state = HandleViewState(rawValue: 1)
    override class var layerClass: AnyClass {
        return CAShapeLayer.self
    }
    override var intrinsicContentSize: CGSize {
        return CGSize(width: CGFloat(arrowSize.width + strokeWidth), height: CGFloat(arrowSize.height + strokeWidth))
    }

    var boundsUsedForCurrentPath = CGRect.zero

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupDefaultsValues()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupDefaultsValues()
    }

    func setupDefaultsValues() {
        backgroundColor = UIColor.clear
        boundsUsedForCurrentPath = CGRect.zero
        shapeLayer().lineCap = kCALineCapRound
        shapeLayer().lineJoin = kCALineJoinRound
        shapeLayer().fillColor = UIColor.clear.cgColor
        strokeWidth = 6.0
        strokeColor = UIColor.lightGray
        arrowSize = CGSize(width: CGFloat(30.0), height: CGFloat(10.0))
        setState(.neutral, animated: false)
    }

    func setState(_ state: HandleViewState, animated: Bool) {
        if let oldState = self.state, oldState == state {
                return
        }

        self.state = state
        let newPath: UIBezierPath? = path(forBounds: bounds, state: state)
        let keyPath: String = "path"
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.fromValue = shapeLayer().path
        shapeLayer().path = newPath?.cgPath
        animation.toValue = shapeLayer().path
        animation.duration = animated ? 0.35 : 0.0
        shapeLayer().add(animation, forKey: keyPath)
    }

    func shapeLayer() -> CAShapeLayer {
        return layer as! CAShapeLayer
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if !boundsUsedForCurrentPath.equalTo(bounds) {
            boundsUsedForCurrentPath = bounds
            shapeLayer().path = path(forBounds: bounds, state: state!).cgPath
        }
    }


    func path(forBounds bounds: CGRect, state: HandleViewState) -> UIBezierPath {
        let arrowHeight: CGFloat = arrowSize.height
        let arrowSpan = CGSize(width: CGFloat(arrowSize.width / 2.0), height: CGFloat(arrowHeight / 2.0))
        var offsetMultiplier: CGFloat = 0
        switch state {
        case .up:
            offsetMultiplier = 1
        case .down:
            offsetMultiplier = -1
        case .neutral:
            offsetMultiplier = 0
        }

        let centerY: CGFloat = bounds.midY + offsetMultiplier * arrowHeight / 2.0
        let centerX: CGFloat = bounds.midX
        let wingsY: CGFloat = centerY - offsetMultiplier * arrowHeight
        let center = CGPoint(x: centerX, y: centerY)
        let centerRight = CGPoint(x: CGFloat(centerX + arrowSpan.width), y: wingsY)
        let centerLeft = CGPoint(x: CGFloat(centerX - arrowSpan.width), y: wingsY)

        let bezierPath = UIBezierPath()
        bezierPath.move(to: centerLeft)
        bezierPath.addLine(to: center)
        bezierPath.addLine(to: centerRight)
        return bezierPath 
        
    }

    class func HandleViewState(for state: PullDownState) -> HandleViewState {
        switch state {
        case .dragging, .intermediate:
            return .neutral
        case .expanded:
            return .down
        case .collapsed:
            return .up
        }
        
    }

}
