//
//  TimerController.swift
//  Elapsed
//
//  Created by Eilon Krauthammer on 18/09/2019.
//  Copyright © 2019 Eilon Krauthammer. All rights reserved.
//

import UIKit
import CoreData

class TimerController: UIViewController, TimerDelegate {
    
    @IBOutlet weak var timerView: TimerView!
    @IBOutlet weak var completionControlStack: UIStackView!
    @IBOutlet weak var inputBox: EKInputBox!
    
    @IBOutlet weak var discardButton: EKHighlightButton!
    @IBOutlet weak var saveButton: EKHighlightButton!
    
    public var onFinish: (() -> Void)?
    
    private var timeInterval: TimeInterval!
    
    public var activityTitle: String = "" {
        willSet {
            delay(0.05) {
                self.inputBox.input = newValue
            }
        }
    }
    
    public var startDateRepresentation: TimeInterval = Date().timeIntervalSince1970
    public var allActivities: [Activity] = []
    
    private lazy var timerContext = TimerContext.shared ?? TimerContext(activityTitle: activityTitle)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.layer.applyGradient(ofColors: [AppColors.background1, AppColors.background2])

        timerView.delegate = self
        timerView.isInRun = true
        timerView.startTimer(paused: timerContext.isActive && !timerContext.isRunning)
        if DefaultsService.shouldAutoResumeOnAppStart {
            // * Resume
            timerView.pause()
        }
        
        inputBox.delegate = self
    
        completionControlStack.alpha = 0
        completionControlStack.transform = .init(translationX: 0, y: 16)
        delay(0.5) {
            UIView.animate(withDuration: 0.3) {
                self.completionControlStack.alpha = 1.0
                self.completionControlStack.transform = .identity
            }
        }
        
        saveButton.alpha = 0.0
        
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: Notification.Name("didBecomeActive"), object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    func timerViewDidStart(_ timerView: TimerView) {
        if timerContext.isActive {
            activityTitle = timerContext.activityTitle ?? ""
            if timerContext.isRunning {
                timerContext.setTimerRunning(true)
            } 
        } else {
            timerContext.setTimerBegin()
        }
    }
    
    func timerViewDidPause(atInterval: TimeInterval) {
        timerContext.setTimerRunning(false)
        timerContext.setPause()
    }
    
    func timerViewDidResume(atInterval: TimeInterval) {
        timerContext.setTimerRunning(true)
        timerContext.setResume()
    }
    
    func timerView(_ timerView: TimerView, didFinishWithInterval interval: TimeInterval) {
        timerContext.setTimerEnd()
        
        UIView.animate(withDuration: 0.3, animations: {
            self.saveButton.isHidden = false
        }) { _ in
            UIView.animate(withDuration: 0.3) {
                self.saveButton.alpha = 1.0
            }
        }
    }
    
    private func save(title: String, interval: TimeInterval) {
        let activity = Activity(title: title, creationDate: startDateRepresentation, repeats: [.new(interval)])
        do {
            try PersistenceManager.shared.saveActivity(activity)
        } catch let error {
            print(error.localizedDescription)
        }
        
        onFinish?()
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func saveTapped(_ sender: Any) {
        let title = inputBox.input
        guard !title.isEmpty else {
            UIView.animate(withDuration: 0.3, animations: {
                self.inputBox.transform = .evenScale(1.1)
                self.inputBox.highlightView.alpha = 1.0
            }) { _ in
                UIView.animate(withDuration: 0.3) {
                    self.inputBox.transform = .identity
                    self.inputBox.highlightView.alpha = 0
                }
            }
            return
        }
        
        save(title: title, interval: timerView.timeInterval)
    }
    
    @IBAction func discardTapped(_ sender: Any) {
        self.timerContext.setTimerEnd()        
        dismiss(animated: true)
    }
    
    @IBAction func menuTapped(_ sender: Any) {
        MenuController().present(in: self)
    }
    
    @objc private func didBecomeActive() {
        timerView.timeInterval = timerContext.elapsed ?? 0
        timerView.resumeSpinAnimation()
    }
    
}

extension TimerController: InputBoxDelegate {
    func textDidChange(_ text: String) {
        timerContext.activityTitle = text
    }
}






