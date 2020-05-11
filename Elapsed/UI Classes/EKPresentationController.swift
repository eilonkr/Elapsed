//
//  PresentationController.swift
//  Altro
//
//  Created by Eilon Krauthammer on 07/09/2019.
//  Copyright © 2019 Eilon Krauthammer. All rights reserved.
//

import UIKit

class EKPresentationController: UIViewController {
    internal static let widthMultiplier: CGFloat = 0.9
    
    static let minimumScale = CGAffineTransform(scaleX: 0.95, y: 0.95)
    private struct PresentationContext {
        var frameSize: CGSize
        var startCenter: CGPoint
        var endCenter: CGPoint
        var transform: CGAffineTransform
        var alpha: CGFloat
        
        internal init(in viewController: UIViewController, for vc: UIViewController, customSize: CGSize? = nil) {
            guard let view = viewController.view, let childView = vc.view else { fatalError() }
        
            frameSize = customSize ?? {
                let defaultHeight = view.frame.size.height * 0.85
                let autoHeight = childView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
                return .init(
                    width: view.frame.size.width * widthMultiplier,
                    height: min(defaultHeight, autoHeight)
                )
            }()
            
            let bar = viewController.navigationController?.navigationBar
            let barHeight = (bar?.frame.height ?? .zero) / 2

            startCenter = .init(
                x: view.relativeCenter.x,
                y: view.relativeCenter.y - barHeight
            )
            
            endCenter = .init(
                x: startCenter.x,
                y: startCenter.y
            )
            
            transform = minimumScale
            alpha = 0.0
        }
    }
    
    public var dismissHandler: (() -> Void)?
    
    public var scrollView: UIScrollView?
    
    public var customSize: CGSize?
    
    public var swipeDismissable: Bool = false
    
    internal var dismissRecognizer: UIPanGestureRecognizer?
    
    private var context: PresentationContext!
    
    private var animator: UIViewPropertyAnimator!
    private var startY: CGFloat!
    private var animationOngoing = false
    private var animationDuration: TimeInterval { 0.25 }
    private var modifyValue: CGFloat { 150.0 }
    
    public init(withViewController vc: UIViewController) {
        super.init(nibName: nil, bundle: nil)
        addChild(vc)
        view.addSubview(vc.view)
        vc.didMove(toParent: self)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        guard swipeDismissable else { return }

        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(presentationPan))
        recognizer.cancelsTouchesInView = false
        recognizer.delegate = self
        
        (scrollView ?? view).addGestureRecognizer(recognizer)
        
        self.dismissRecognizer = recognizer
    }
    
    private var didLayout = false
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        applyDesign()
        
        if !didLayout {
            delay(0.1) {
                self.didLayout = true
            }
            
            setupContent()
        }
    }
    
    func invalidateSize() {
        context = PresentationContext(in: parent!, for: self)
        UIView.animate(withDuration: 0.25) {
            self.view.frame.size = self.context.frameSize
            self.handleViewOnPresentation(false, context: self.context)
        }
    }
    
    private func setupContent() {
        guard let viewController = parent else { fatalError("Not inside a parent!") }
        
        context = PresentationContext(in: viewController, for: self, customSize: self.customSize)
        view.frame.size = context.frameSize
        handleViewOnPresentation(true, context: context)
        UIView.animate(withDuration: animationDuration, delay: 0, options: .curveEaseOut, animations: {
            self.handleViewOnPresentation(false, context: self.context)
        }) { _ in
            self.didMove(toParent: viewController)
        }
        
        guard viewController.view.currentCoverLayer == nil else { return }
        viewController.view.insertCoverLayer(behind: view) { [weak self] in self?.dismiss() }
    }
    
    private func handleViewOnPresentation(_ flag: Bool, context: PresentationContext) {
        view.transform = flag ? context.transform : .identity
        view.center = flag ? context.startCenter : context.endCenter
        view.alpha = flag ? context.alpha : 1.0
    }
    
    func present(in viewController: UIViewController) {
        viewController.addChild(self)
        viewController.view.addSubview(self.view)
    }
    
    func dismiss() {
        UIView.animate(withDuration: 0.25, animations: {
            self.handleViewOnPresentation(true, context: self.context)
        }) { _ in
            self.willMove(toParent: nil)
            self.removeFromParent()
            self.view.removeFromSuperview()
        }
    }
    
    private func applyDesign() {
        if let scrollView = scrollView {
            let contentView = view.subviews.first!
            contentView.clipsToBounds = true
            contentView.layer.roundCorners(of: .regular)
            scrollView.clipsToBounds = true
            scrollView.layer.roundCorners(of: .regular)
        }
    
        view.clipsToBounds = false
        view.layer.roundCorners(of: .regular)
        view.layer.applyShadow()
        view.layer.shadowRadius = 9.0
    }
    
    deinit {
        print("EKController gone.")
    }
}

extension EKPresentationController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer.view is UIScrollView && otherGestureRecognizer.view is UIScrollView
    }
    
    @objc func presentationPan(_ recognizer: UIPanGestureRecognizer) {
        let point = recognizer.location(in: view)
        
        if recognizer.state == .began {
            startY = point.y
            beginAnimation()
        } else if recognizer.state == .changed {
            // Make sure scrolling is upwards.
            let pointInView: CGPoint = .init(x: point.x, y: point.y + modifyValue)
            guard pointInView.y >= startY && animationOngoing else { cancelAnimation(); return }
            scrollView?.isScrollEnabled = false
            let fraction = ((pointInView.y - startY) / 100) * 0.5
            animator.fractionComplete = fraction
            if animator.fractionComplete == 1.0 {
                // Finish
            }
        } else {
            guard animationOngoing else { return }
            if animator.fractionComplete != 1.0 {
                animator.isReversed = true
                animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
                animationOngoing = false
                scrollView?.isScrollEnabled = true
                return
            } else {
                finishAnimation()
            }
        }
    }
    
    func beginAnimation() {
        guard scrollView?.contentOffset.y ?? -1 <= 0 else { return }
        setupPropertyAnimator()
        animationOngoing = true
    }
    
    func cancelAnimation() {
        guard animationOngoing else { return }
        scrollView?.isScrollEnabled = true
        animationOngoing = false
        animator.stopAnimation(true)
    }
    
    func finishAnimation() {
        weak var pr = parent
        dismissHandler?()
        animator.stopAnimation(true)
        animator.finishAnimation(at: .end)
        pr?.view.removeCoverLayer()
        self.willMove(toParent: nil)
        self.removeFromParent()
        self.view.removeFromSuperview()
    }
    
    func setupPropertyAnimator() {
        animator = UIViewPropertyAnimator(duration: 0.2, curve: .easeIn, animations: { [weak self] in
            guard let self = self else { return }
            self.view.frame.origin.y += self.modifyValue
            self.view.alpha = 0.0
            self.view.currentCoverLayer?.alpha = 0
        })
        animator.fractionComplete = 0
    }
}

