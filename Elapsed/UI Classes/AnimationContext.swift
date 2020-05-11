//
//  AnimationContext.swift
//  Elapsed
//
//  Created by Eilon Krauthammer on 19/09/2019.
//  Copyright © 2019 Eilon Krauthammer. All rights reserved.
//

import UIKit

struct AnimationContext {
    enum Stage { case start, end }
    enum State {
        case fire, pause, stop
        var color: UIColor {
            get {
                switch self {
                    case .fire:  return UIColor.red.withAlphaComponent(0.2)
                    case .pause: return UIColor.yellow.withAlphaComponent(0.2)
                    case .stop:  return UIColor.blue.withAlphaComponent(0.2)
                }
            }
        }
    }
    
    let state: State
    let stage: Stage
    let duration: TimeInterval
    
    init(state: State, stage: Stage, duration: TimeInterval = 0.3) {
        self.state = state
        self.stage = stage
        self.duration = duration
    }
    
    func commit(on timerView: TimerView, completion: (() -> Void)?) {
        if state == .stop {
            if stage == .start {
                let container = UIView(frame: timerView.bounds)
                container.clipsToBounds = true
                container.layer.cornerRadius = timerView.layer.cornerRadius
                let stopLayer = UIView(frame: timerView.bounds)
                stopLayer.frame.origin.y = timerView.bounds.maxY
                stopLayer.backgroundColor = state.color
                container.addSubview(stopLayer)
                timerView.addSubview(container)
                timerView.stoppingLayer = container
                
                UIView.animate(withDuration: 2.0, animations: {
                    stopLayer.frame.origin.y = 0
                }) { _ in
                    
                }
            } else {
                guard let stopLayer = timerView.stoppingLayer, stopLayer.isDescendant(of: timerView) else { fatalError() }
                UIView.animate(withDuration: 0.3, animations: {
                    stopLayer.alpha = 0.0
                }) { _ in
                    stopLayer.removeFromSuperview()
                }
            }
        } else {
            if stage == .start {
                let layer = UIView(frame: timerView.bounds)
                layer.layer.cornerRadius = timerView.layer.cornerRadius
                layer.backgroundColor = state.color
                timerView.addSubview(layer)
                
                layer.transform = .evenScale(0.5)
                layer.alpha = 0.0
                
                UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: .curveEaseInOut, animations: {
                    layer.transform = .identity
                    layer.alpha = 0.8
                    timerView.mainLabel.transform = .evenScale(1.2)
                }, completion: { _ in
                    completion?()
                })
                timerView.highlightLayer = layer
            } else {
                guard let layer = timerView.highlightLayer, layer.isDescendant(of: timerView) else { fatalError() }
                UIView.animate(withDuration: 0.3, animations: {
                    layer.alpha = 0.0
                    timerView.mainLabel.transform = .identity
                }) { _ in
                    layer.removeFromSuperview()
                    completion?()
                }
            }
        }
    }
}




