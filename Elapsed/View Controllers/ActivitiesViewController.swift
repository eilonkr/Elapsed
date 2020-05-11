//
//  ActivitiesViewController.swift
//  Elapsed
//
//  Created by Eilon Krauthammer on 17/09/2019.
//  Copyright © 2019 Eilon Krauthammer. All rights reserved.
//

import UIKit

class ActivitiesViewController: UIViewController {
    
    // MARK: - Outlets

    @IBOutlet private weak var collectionView: AwareCollectionView!
    @IBOutlet private weak var inputBox: EKInputBox!
    
    // MARK: - Constants
    
    private let cellIdentifier = "ActivityCell"
    
    private let calendar = Calendar.current
    private let day: TimeInterval = 24*60*60
    
    // MARK: - Properties & Computed properties
    
    private var allActivities: [Activity] { PersistenceManager.shared.allActivities }
    private var isSearching: Bool = false
    private var searchFilterActivities = [Activity]() {
        didSet {
            collectionView.noResults(searchFilterActivities.isEmpty)
        }
    }
    private var activitySource: [Activity] {
        return isSearching ? searchFilterActivities : allActivities
    }
    
    private var todayActivities: [Activity] {
        return activitySource.filter {
            calendar.isDateInToday($0.lastRepeat?.date ?? Date() - day)
        }
    }
    
    private var thisWeekActivities: [Activity] {
        return activitySource.filter {
            calendar.isDate($0.lastRepeat?.date ?? Date() - day*7, equalTo: Date(), toGranularity: .weekOfYear)
        }.filter {
            todayActivities.contains($0) == false
        }
    }
    
    private var olderActivities: [Activity] {
        return activitySource.filter {
            !todayActivities.contains($0) && !thisWeekActivities.contains($0)
        }
    }
    
    // MARK: - View Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.layer.applyGradient(ofColors: [AppColors.background1, AppColors.background2])
        hideKeyboardWhenTappedAround()
        setupCollectionView()
        inputBox.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    private func setupCollectionView() {
        //collectionView.clipsToBounds = false
        collectionView.register(UINib(nibName: String(describing: CollectionHeaderView.self), bundle: nil), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "Header")
        
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.estimatedItemSize = .init(width: view.frame.width*0.85, height: 100)
            layout.minimumLineSpacing = 24.0
            collectionView.collectionViewLayout = layout
        }
    }
    
    private func presentDetailController(for activity: Activity) {
        if let detail = storyboard?.instantiateViewController(withIdentifier: "ActivityDetail") as? ActivityDetailController {
            detail.activity = activity
            detail.dismissHandler = { [weak self] in
                self?.viewWillAppear(true)
            }
            present(detail, animated: true, completion: nil)
        } else { fatalError() }
    }
    
    @IBAction func menuTapped(_ sender: Any) {
        MenuController().present(in: self)
    }
    
}

// MARK: - CollectionView Protocol methods
extension ActivitiesViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    enum Section: Int, CaseIterable {
        case today, thisWeek, older
        init(date: Date) {
            switch date {
                case _ where Calendar.current.isDateInToday(date):
                    self = .today
                case _ where Calendar.current.isDate(date, equalTo: Date(), toGranularity: .weekOfYear):
                    self = .thisWeek
                default: self = .older
            }
        }
        
        var title: String {
            switch self {
                case .today:    return "TODAY"
                case .thisWeek: return "THIS WEEK"
                case .older:    return "OLDER"
            }
        }
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        var count = Section.allCases.count
        [todayActivities, thisWeekActivities, olderActivities]
            .forEach { if $0.isEmpty {count -= 1} }
        return count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
            case Section.today.rawValue:
                return {
                    todayActivities.isEmpty ? (thisWeekActivities.isEmpty ? olderActivities.count : thisWeekActivities.count) : todayActivities.count
                }()
            case Section.thisWeek.rawValue:
                return {
                    thisWeekActivities.isEmpty ? olderActivities.count : thisWeekActivities.count
                }()
            case Section.older.rawValue: return olderActivities.count
            default: return 0
        }
    }
    
    private func absoluteRow(for indexPath: IndexPath) -> Int {
        var skip = 0
        for i in 0 ... indexPath.section where i != indexPath.section {
            skip += collectionView.numberOfItems(inSection: i)
        }
        return indexPath.row + skip
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? ActivityCell else { fatalError() }
        
        let activity = activitySource[absoluteRow(for: indexPath)]
        cell.configure(with: activity)
        
        let delayFactor: Double = 0.07
        cell.appearFactor = Double(indexPath.row) * delayFactor
        
        cell.onStart = { [weak self] activity in
            self?.start(activity)
        }
        
        cell.onShowMore = { [weak self] activity in
            self?.presentDetailController(for: activity)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let headerIdentifier = UICollectionView.elementKindSectionHeader
        if kind == headerIdentifier {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: headerIdentifier, withReuseIdentifier: "Header", for: indexPath) as! CollectionHeaderView
            
            let activity = activitySource[absoluteRow(for: indexPath)]
            header.titleLabel.text = Section(date: activity.lastRepeat?.date ?? Date()).title
            
            return header
        }
        
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        UIView.animate(withDuration: 0.2) {
            cell?.transform = .evenScale(0.97)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        UIView.animate(withDuration: 0.2) {
            cell?.transform = .identity
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let activity = activitySource[absoluteRow(for: indexPath)]
        presentDetailController(for: activity)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return .init(width: collectionView.frame.width, height: 20.0)
    }
    
}

// MARK: - Context Menu Implementation
extension ActivitiesViewController {
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let activity = activitySource[absoluteRow(for: indexPath)]
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { element in
            let start = UIAction(title: "Start", image: UIImage(systemName: "play.fill")) { _ in
                self.start(activity)
            }
            let delete = self.deleteConfirmationSubmenu(forActivity: activity, indexPath: indexPath)
            let showDetail = UIAction(title: "Show more", image: UIImage(systemName: "info.circle.fill")) { _ in
                self.presentDetailController(for: activity)
            }
            
            return UIMenu(title: activity.title, children: [start, showDetail, delete])
        }
    }
    
    private func deleteConfirmationSubmenu(forActivity activity: Activity, indexPath: IndexPath) -> UIMenu {
        let deleteCancel = UIAction(title: "Cancel", image: UIImage(systemName: "xmark")) { _ in }
        let deleteConfirm = UIAction(title: "Confirm", image: UIImage(systemName: "checkmark"), attributes: .destructive) { _ in
            self.delete(activity, atIndexPath: indexPath)
        }
        
        return UIMenu(title: "Delete", image: UIImage(systemName: "trash"), children: [deleteCancel, deleteConfirm])
    }
    
    private func start(_ activity: Activity) {
        if let timerController = storyboard?.instantiateViewController(withIdentifier: "Timer") as? TimerController {
            timerController.activityTitle = activity.title
            timerController.modalPresentationStyle = .custom
            timerController.hero.modalAnimationType = .uncover(direction: .down)
            present(timerController, animated: true, completion: nil)
        }
    }
    
    private func delete(_ activity: Activity, atIndexPath indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) else { return }
        UIView.animate(withDuration: 0.2, animations: {
            cell.transform = cell.transform.translatedBy(x: self.view.frame.width, y: 0)
        }) { _ in
            activity.delete()
            self.collectionView.reloadData()
        }
    }
}

// MARK: - Other protocol implementations
extension ActivitiesViewController: InputBoxDelegate {
    func textDidChange(_ text: String) {
        isSearching = !text.isEmpty
        searchFilterActivities = allActivities.filter { $0.title.contains(text) }
        collectionView.reloadData()
    }
}




