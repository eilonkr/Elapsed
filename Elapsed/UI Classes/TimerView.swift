//
//  StartView.swift
//  Elapsed
//
//  Created by Eilon Krauthammer on 17/09/2019.
//  Copyright © 2019 Eilon Krauthammer. All rights reserved.
//

import UIKit
import Hero

@objc protocol TimerDelegate: AnyObject {
    @objc optional func timerViewDidStart(_ timerView: TimerView)
    @objc optional func timerViewDidPause(atInterval: TimeInterval)
    @objc optional func timerViewDidResume(atInterval: TimeInterval)
    @objc optional func timerView(_ timerView: TimerView, didFinishWithInterval interval: TimeInterval)
}

class TimerView: UIView {
    
    private let longPressDuration: TimeInterval = 2.0

    public weak var delegate: TimerDelegate?
    
    private var animator: UIViewPropertyAnimator!
    
    private var didLayout = false
    
    public var highlightLayer: UIView?
    public var stoppingLayer: UIView?
    
    lazy var mainLabel: UILabel = subviews.first {$0.tag == 1}! as! UILabel
    lazy var infoLabel: UILabel? = subviews.first {$0.tag == 2} as? UILabel
    
    //private lazy var mainLabelYConstraint = mainLabel.findConstraint(layoutAttribute: .centerY)
    
    public var isInRun: Bool = false
    private var mainTimer = Timer()
    public var timeInterval: TimeInterval = TimerContext.shared?.elapsed ?? 0 {
        didSet {
            mainLabel.text = timeInterval.timerString(chopped: shouldDisplayFullFormat, decimalPlaces: shouldDisplayMiliseconds)
        }
    }
    private lazy var timerBlock: (Timer) -> () = { [weak self] _ in self?.timeInterval += 0.1 }
    
    private var spinLayer: CAShapeLayer!
    
    private var shouldDisplayFullFormat: Bool { !DefaultsService.shouldShowFullFormat }
    private var shouldDisplayMiliseconds: Bool { DefaultsService.shouldDisplayMiliseconds }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        startPulsateAnimation()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupDesign()
        if !didLayout {
            didLayout = true
            guard mainTimer.isValid else { return }
            infoLabel?.text = "tap to pause, long press to stop"
            delay(2.5) {
                UIView.animate(withDuration: 0.15) {
                    self.infoLabel?.alpha = 0.0
                }
            }
        }
    }
    
    private func setupDesign() {
        let c1 = UIColor(red: 16/255, green: 22/255, blue: 75/255, alpha: 0.2)
        let c2 = UIColor(red: 255/255, green: 90/255, blue: 161/255, alpha: 1.00)
        layer.roundCorners(of: .oval)
        layer.applyShadow()
        layer.shadowRadius = 10.0
        
        if let grad = layer.sublayers?.first(where: {$0 is CAGradientLayer }) {
            grad.frame = bounds
            grad.roundCorners(of: .oval)
        } else {
            layer.applyGradient(ofColors: [c1,c2])
        }
    }
    
    private func startPulsateAnimation() {
        layer.addAnimation(keyPath: "transform.scale", from: 1.0, to: 1.08, duration: 2.0, timingFunction: .easeInOut)
    }
    
    private func stopPulsate() {
        layer.removeAnimation(forKey: "transform.scale")
    }
    
    private func startCountingAnimation() {
        guard DefaultsService.shouldRunSpinAnimation else { return }
        
        if spinLayer == nil {
            let animationPath = UIBezierPath(ovalIn: layer.bounds)
            spinLayer = CAShapeLayer()
            spinLayer.strokeColor = UIColor.systemRed.cgColor
            spinLayer.frame = layer.bounds
            spinLayer.fillColor = nil
            spinLayer.strokeStart = 0.0
            spinLayer.strokeEnd = 0.25
            spinLayer.lineWidth = 3.0
            spinLayer.lineCap = .round
            spinLayer.path = animationPath.cgPath
        } else {
            spinLayer.isHidden = false
        }
    
        spinLayer.addAnimation(keyPath: "transform.rotation", from: 0.0, to: Float.pi*2, reverses: false)
        spinLayer.addAnimation(keyPath: "lineWidth", from: 2.0, to: 4.0)
        //shapeLayer.addAnimation(keyPath: "strokeColor", from: UIColor.white.cgColor, to: UIColor.systemRed.cgColor)
        spinLayer.addAnimation(keyPath: "opacity", from: 0.8, to: 1.0)
        layer.addSublayer(spinLayer)
    }
    
    public func resumeSpinAnimation() {
        spinLayer?.addAnimation(keyPath: "transform.rotation", from: 0.0, to: Float.pi*2, reverses: false)
    }
    
    private func stopCountingAnimation() {
        spinLayer?.removeAllAnimations()
        spinLayer?.isHidden = true
    }
    
    private func startAnimation(state: AnimationContext.State) {
        AnimationContext(state: state, stage: .start).commit(on: self, completion: nil)
    }
    
    private func endAnimation(state: AnimationContext.State, startTimer: Bool = false) {
        AnimationContext(state: state, stage: .end).commit(on: self) { [unowned self] in
            guard startTimer else { return }
            self.toTimerView()
        }
    }
    
    private func toTimerView() {
        delegate?.timerViewDidStart?(self)
        self.layoutIfNeeded()
        
        UIView.animate(withDuration: 0.25) {
            self.mainLabel.alpha = 1.0
        }
    }
    
    public func startTimer(paused: Bool) {
        if !paused {
            mainTimer = .scheduledTimer(withTimeInterval: 0.1, repeats: true, block: timerBlock)
            mainTimer.fire()
            stopPulsate()
            delay(0.1) {
                self.startCountingAnimation()
            }
        } else {
            mainLabel.text = timeInterval.timerString(chopped: shouldDisplayFullFormat, decimalPlaces: shouldDisplayMiliseconds)
            infoLabel?.text = "paused"
        }
        
        delegate?.timerViewDidStart?(self)
        
        // Add gesture recognizers
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressed))
        longPressGesture.minimumPressDuration = longPressDuration
        addGestureRecognizer(longPressGesture)
        
    }
    
    internal func pause() {
        guard isInRun else { return }
        infoLabel?.text = mainTimer.isValid ? "paused" : "resumed"
        if mainTimer.isValid {
            // Pause
            mainTimer.invalidate()
            stopCountingAnimation()
            delegate?.timerViewDidPause?(atInterval: self.timeInterval)
        } else {
            // Resume
            delegate?.timerViewDidResume?(atInterval: self.timeInterval)
            mainTimer = .scheduledTimer(withTimeInterval: 0.1, repeats: true, block: timerBlock)
            stopPulsate()
            startCountingAnimation()
        }
        
        layAction(pause: !mainTimer.isValid)
    }
    
    private func layAction(pause: Bool) {
        UIView.animate(withDuration: 0.25, animations: {
            self.infoLabel?.alpha = 1.0
        }) { _ in
            if !pause {
                delay(1.0, block: {
                    guard self.mainTimer.isValid else { return }
                    UIView.animate(withDuration: 0.25, animations: {
                        self.infoLabel?.alpha = 0.0
                    })
                })
            }
        }
    }
    
    @objc private func longPressed(_ gr: UILongPressGestureRecognizer) {
        // Stop timer => Transition
        guard isInRun else { return }
        mainTimer.invalidate()
        
        delegate?.timerView?(self, didFinishWithInterval: self.timeInterval)
        
        stopCountingAnimation()
        startPulsateAnimation()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Make sure we're on the second stage
        guard !isInRun else {
            startAnimation(state: .pause)
            startAnimation(state: .stop)
            return
        }
        startAnimation(state: .fire)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard !isInRun else {
            // Pause
            endAnimation(state: .pause)
            endAnimation(state: .stop)
            pause()
            return
        }
        guard let touch = touches.first else { return }
        endAnimation(state: .fire, startTimer: bounds.contains(touch.location(in: self)))
    }
}

fileprivate extension CALayer {
    func addAnimation<T>(keyPath: String, from: T, to: T, duration: CFTimeInterval = 1.0, reverses: Bool = true, timingFunction: CAMediaTimingFunction = .linear) {
        let anim = CABasicAnimation(keyPath: keyPath)
        anim.fromValue = from
        anim.toValue = to
        anim.autoreverses = reverses
        anim.duration = duration
        anim.timingFunction = timingFunction
        anim.repeatCount = .infinity
        add(anim, forKey: keyPath)
    }
}
