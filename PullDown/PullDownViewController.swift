//
//  PullDownViewController.swift
//  PullDown
//
//  Created by Kush Taneja on 17/06/17.
//  Copyright © 2017 Kush Taneja. All rights reserved.
//

import UIKit

enum PullDownState : Int {
    /// The PullDownViewController is shown at its minimum height.
    case collapsed
    /// The PullDownViewController is currently being dragged, or
    /// within a state change animation.
    case dragging
    /// The PullDownViewController is currently resting somewhere
    /// between the collapsed and expanded positions.
    case intermediate
    /// The PullDownViewController is shown at its maximum height.
    case expanded
}

protocol PullDownDelegate: class {
    func pullDownViewController(didChangeTo state: PullDownState)
}

class PullDownViewController: UIViewController {

    @IBOutlet var handleView: HandleView!
    var height: CGFloat!
    var minimumHeight: CGFloat!

    lazy var dimmingView: UIView = {
        UIView(frame: CGRect.zero)
    }()
    var dimmingColor: UIColor!

    var cornerRadius: CGFloat!

    var animator: UIDynamicAnimator!
    var container: UICollisionBehavior!
    var snap: UISnapBehavior!
    var dynamicItem: UIDynamicItemBehavior!
    var gravity: UIGravityBehavior!

    var panGestureRecognizer: UIPanGestureRecognizer!
    var panArea: UIView!

    weak var delegate: PullDownDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?, height: CGFloat, minimumHeight: CGFloat, dimmingAlpha: CGFloat, cornerRadius: CGFloat) {
        self.height = height
        self.minimumHeight = minimumHeight
        self.cornerRadius = cornerRadius
        self.dimmingColor = UIColor.black.withAlphaComponent(dimmingAlpha)
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    func setup() {

        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(pan:)))
        panGestureRecognizer.cancelsTouchesInView = false
        panArea = UIView(frame: CGRect(x: 0, y: self.view.frame.height - minimumHeight, width: self.view.frame.width, height: minimumHeight))
        self.view.addSubview(panArea)
        panArea.addGestureRecognizer(panGestureRecognizer)

        animator = UIDynamicAnimator(referenceView: self.view.superview!)
        dynamicItem = UIDynamicItemBehavior(items: [self.view])
        dynamicItem.allowsRotation = false
        dynamicItem.elasticity = 0

        gravity = UIGravityBehavior(items: [self.view])
        gravity.gravityDirection = CGVector(dx: 0, dy: -1)

        container = UICollisionBehavior(items: [self.view])

        configureContainer()

        animator.addBehavior(gravity)
        animator.addBehavior(dynamicItem)
        animator.addBehavior(container)

        
        let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))

        visualEffectView.frame = CGRect(x: 0, y: 0, width: self.view.bounds.width, height: height)
        visualEffectView.layer.cornerRadius = self.view.layer.cornerRadius
        if visualEffectView.subviews.count >= 2 {
            let filterView = visualEffectView.subviews[1]
//            filterView.backgroundColor = UIColor(red: 83/255, green: 24/255, blue: 79/255, alpha: 0.3)
////                .black.withAlphaComponent(0.2)

        }
        visualEffectView.layer.masksToBounds = true
        visualEffectView.clipsToBounds = true
        self.view.insertSubview(visualEffectView, at: 0)


        if let superView = self.view.superview {
            dimmingView.frame = superView.frame
            superView.insertSubview(dimmingView, belowSubview: self.view)
            dimmingView.layer.backgroundColor = dimmingColor.cgColor
        }
        snapToBottom()
        delegate?.pullDownViewController(didChangeTo: .expanded)
        handleView.setState(
            HandleView.HandleViewState(
                for: .expanded), animated: true)
      let snapTapGesture = UITapGestureRecognizer(target: self, action: #selector(self.didTapHandleView))
      panArea.addGestureRecognizer(snapTapGesture)
    }

  func didTapHandleView() {

    if handleView.state == HandleView.HandleViewState(for: .collapsed) {
      snapToBottom()
      delegate?.pullDownViewController(didChangeTo: .expanded)
      handleView.setState(
        HandleView.HandleViewState(
          for: .expanded), animated: true)
    }
    else {
      snapToTop()
      delegate?.pullDownViewController(didChangeTo: .collapsed)
      handleView.setState(HandleView.HandleViewState(for: .collapsed), animated: true)
    }
  }
    func configureContainer() {
        let boundaryWidth = UIScreen.main.bounds.size.width
        container.addBoundary(withIdentifier: "upper" as NSCopying, from: CGPoint.init(x: 0, y: -height + minimumHeight), to: CGPoint(x: boundaryWidth, y: -height + minimumHeight))

        container.addBoundary(withIdentifier: "lower" as NSCopying, from: CGPoint.init(x: 0, y: height), to: CGPoint(x: boundaryWidth, y: height))

    }

    func handlePan (pan: UIPanGestureRecognizer) {
        let velocity = pan.velocity(in: self.view.superview).y

        var movement = self.view.frame
        movement.origin.x = 0
        movement.origin.y = movement.origin.y + (velocity * 0.05)

        if pan.state == .ended {
            panGestureEnded()
        }
        else if pan.state == .began {

            self.setDimmingViewHidden(hidden: false, finished: false)
            snapToBottom()
            delegate?.pullDownViewController(didChangeTo: .intermediate)
            handleView.setState(HandleView.HandleViewState(for: .intermediate), animated: true)

        }
        else {
            self.setDimmingViewHidden(hidden: false, finished: false)
            delegate?.pullDownViewController(didChangeTo: .dragging)
            handleView.setState(HandleView.HandleViewState(for: .dragging), animated: true)

            if let snap = snap {
                animator.removeBehavior(snap)
            }

            snap = UISnapBehavior(item: self.view, snapTo: CGPoint(x: movement.midX, y: movement.midY))
            animator.addBehavior(snap)
        }
        
    }

    func panGestureEnded() {

        if let snap = snap {
            animator.removeBehavior(snap)
        }

        let velocity = dynamicItem.linearVelocity(for: self.view)

        if fabsf(Float(velocity.y)) > 250 {
            if velocity.y < 0 {
                setDimmingViewHidden(hidden: true, finished: false)
                snapToTop()
                delegate?.pullDownViewController(didChangeTo: .collapsed)
                handleView.setState(HandleView.HandleViewState(for: .collapsed), animated: true)
            }
            else {
                setDimmingViewHidden(hidden: false, finished: false)
                snapToBottom()
                delegate?.pullDownViewController(didChangeTo: .expanded)
                handleView.setState(HandleView.HandleViewState(for: .expanded), animated: true)
            }
        }
        else {
                if self.view.frame.maxY > self.height / 2 {
                    setDimmingViewHidden(hidden: false, finished: false)
                    snapToBottom()
                    delegate?.pullDownViewController(didChangeTo: .expanded)
                    handleView.setState(HandleView.HandleViewState(for: .expanded), animated: true)
                }
                else {
                    setDimmingViewHidden(hidden: true, finished: false)
                    snapToTop()
                    delegate?.pullDownViewController(didChangeTo: .collapsed)
                    handleView.setState(HandleView.HandleViewState(for: .collapsed), animated: true)
                }
        }

    }

    func snapToBottom() {
        gravity.gravityDirection = CGVector(dx: 0, dy: 2.5)
    }

    func snapToTop() {
        gravity.gravityDirection = CGVector(dx: 0, dy: -2.5)
    }

    func setDimmingViewHidden(hidden: Bool, finished: Bool) {

        UIView.animate(withDuration: 0.25, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
            self.dimmingView.alpha = hidden ? 0.0 : 1.0
        }, completion: { _ in
            if finished {
                self.dimmingView.removeFromSuperview()
            }
        })

    }
}

extension PullDownViewController: UIGestureRecognizerDelegate {


}
