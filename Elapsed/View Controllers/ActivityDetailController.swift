//
//  ActivityDetailController.swift
//  Elapsed
//
//  Created by Eilon Krauthammer on 22/09/2019.
//  Copyright © 2019 Eilon Krauthammer. All rights reserved.
//

import UIKit

class ActivityDetailController: UIViewController, UIAdaptivePresentationControllerDelegate {

    private let MAX_REPEAT_COUNTMIN = 5
    private let MAX_REPEAT_COUNTMAX = 10
    
    // MARK: - Outlets
        
    @IBOutlet weak var titleLabel: UITextView!
    @IBOutlet weak var averageLabel: UILabel!
    @IBOutlet weak var lastLabel: UILabel!
    @IBOutlet weak var shortestLabel: UILabel!
    @IBOutlet weak var longestLabel: UILabel!
    @IBOutlet weak var repeatsLabel: UILabel!
    @IBOutlet weak var showModifyButton: UIButton!
    @IBOutlet weak var showAllButton: UIButton!
    
    
    @IBOutlet weak var repeatsTableView: UITableView!
    
    @IBOutlet weak var graphView: EKGraphView!
    
    public var activity: Activity!
    
    public var dismissHandler: (() -> Void)?
    
    private var shouldRemoveCell: Bool = false
    
    private var years: [Int] {
        let dates = activity.repeats.map { $0.date }
        let years = dates.map { Calendar.current.component(.year, from: $0) }
        return years.unique()
    }
    
    private var shouldShowAllRepeats = false {
        didSet {
            repeatsTableView.reloadSections(IndexSet(0..<repeatsTableView.numberOfSections),
                                            with: .automatic)
            showAllButton.isHidden = !shouldShowAllRepeats
            
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: .curveEaseInOut, animations: {
                self.view.layoutIfNeeded()
            }, completion: nil)
            
            let moreTitle = "SHOW MORE"
            let lessTitle = "SHOW LESS"
            showModifyButton.setTitle(shouldShowAllRepeats ? lessTitle : moreTitle, for: .normal)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()
        setupTableView()
        configure()
    }
    
    private var didLayout = false
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !didLayout {
            didLayout = true
            titleLabel.layer.cornerRadius = 10.0
            delay(0.5) {
                UIView.animate(withDuration: 0.6, animations: {
                    self.titleLabel.backgroundColor = AppColors.oppositeBackground.withAlphaComponent(0.1)
                }) { _ in
                    UIView.animate(withDuration: 0.6) {
                        self.titleLabel.backgroundColor = .clear
                    }
                }
            }
        }
    }
    
    private func configure() {
        view.backgroundColor = AppColors.secondaryBackground
        graphView.activity = activity
        titleLabel.delegate = self
        //ftitleLabel.isSelectable = true
        presentationController?.delegate = self
        
        if activity.repeats.count <= MAX_REPEAT_COUNTMIN {
            showModifyButton.isHidden = true
        } else {
            showModifyButton.addTarget(self, action: #selector(modifyRepeatsView), for: .touchUpInside)
        }
        showAllButton.addTarget(self, action: #selector(showAll), for: .touchUpInside)
        
        self.titleLabel.text = activity.title
        averageLabel.text = activity.average?.timerString()
        lastLabel.text = activity.lastRepeat?.time.timerString()
        shortestLabel.text = activity.shortest?.timerString()
        longestLabel.text = activity.longest?.timerString()
        repeatsLabel.text = "repeats (\(activity.repeats.count))"
    }
    
    private func setupTableView() {
        repeatsTableView.estimatedRowHeight = 50.0
        repeatsTableView.rowHeight = UITableView.automaticDimension
    }

    @objc private func modifyRepeatsView() {
        self.shouldShowAllRepeats.toggle()
    }
    
    @objc private func showAll() {
//        let detail = RepeatsDetailController(activity: self.activity)
//        present(detail, animated: true, completion: nil)
    }
    
    @IBAction func startTapped(_ sender: Any) {
    }
    
    @IBAction func newEntryTapped(_ sender: Any) {
        ActivityEntryView(delegate: self).appear(in: view)
    }
    
    @IBAction func deleteTapped(_ sender: Any) {
        self.activity.delete()
        self.dismiss(animated: true)
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        self.dismissHandler?()
    }
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.dismissHandler?()
    }
    
}

extension ActivityDetailController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return min(activity.repeats.count,
                        shouldShowAllRepeats ? activity.repeats.count : MAX_REPEAT_COUNTMIN)
        //return shouldRemoveCell ? count - 1 : count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") as? RepeatCell else { fatalError() }
        cell.configure(with: activity.dateSortedRepeats[indexPath.row])
        
        self.shouldRemoveCell = false
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        graphView.selectChart(at: indexPath.row)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            activity.removeRepeat(activity.dateSortedRepeats[indexPath.row])
            try? PersistenceManager.shared.saveActivity(activity, shouldRemove: true)
            
            self.shouldRemoveCell = true
            tableView.deleteRows(at: [indexPath], with: .automatic)
            guard !activity.repeats.isEmpty else {
                dismiss(animated: true, completion: nil)
                return
            }
            
            graphView.refresh(activity.dateSortedRepeats)
            self.configure()
            
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
            
            delay(0.3) {
                tableView.reloadData()
            }
        }
    }
}

// MARK: - Delegation
extension ActivityDetailController: UITextViewDelegate, EntryDelegate {

    func textViewDidBeginEditing(_ textView: UITextView) {
        textView.selectAll(nil)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        guard
            let newTitle = textView.text,
            !(Activity.exists(newTitle))
        else {
            wrongInput()
            return
        }
        
        try? self.activity.rename(to: newTitle)
    }
    
    func finished(time: TimeInterval) {
        let newRepeat = Repeat.new(time)
        self.activity.repeats.append(newRepeat)
        try? PersistenceManager.shared.saveActivity(self.activity, handler: { err in
            guard err == nil else {
                self.activity.repeats.removeLast()
                return
            }
            self.handleNewRepeat()
        })
    }
    
    private func handleNewRepeat() {
        defer {
            self.graphView.refresh(activity.dateSortedRepeats)
            configure()
        }
        
        guard repeatsTableView.numberOfRows(inSection: 0) < MAX_REPEAT_COUNTMIN else {
            self.repeatsTableView.reloadData()
            return
        }
        
        repeatsTableView.insertRows(at: [IndexPath(row: activity.repeats.count-1, section: 0)], with: .automatic)
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func wrongInput() {
        
    }
    
}














