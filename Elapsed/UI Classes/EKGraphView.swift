//
//  EKGraphView.swift
//  Elapsed
//
//  Created by Eilon Krauthammer on 23/09/2019.
//  Copyright © 2019 Eilon Krauthammer. All rights reserved.
//

import UIKit

protocol ChartDelegate: AnyObject {
    func chartSelected(withRepeat _repeat: Repeat)
}

fileprivate extension Array where Element == Repeat {
    var average: TimeInterval? {
        return map {$0.time}.reduce(0, +) / Double(count)
    }
    
    var shortest: TimeInterval? {
        return map {$0.time}.min()
    }
    
    var longest: TimeInterval? {
        return map {$0.time}.max()
    }
}

class EKGraphView: UIView {
    enum TimePeriod: String, CaseIterable {
        case week = "Last week"
        case month = "Last month"
        case year = "Last year"
        case allTime = "All time"
        
        static var allValues: [String] {
            allCases.map {$0.rawValue}
        }
        
        init(_ intValue: Int) {
            switch intValue {
                case 0: self = .week
                case 1: self = .month
                case 2: self = .year
                default: self = .allTime
            }
        }
        
        public func repeats(fromActivity activity: Activity) -> [Repeat] {
            let granularity: Calendar.Component? = {
                switch self {
                    case .week:  return .weekOfYear
                    case .month: return .month
                    case .year:  return .year
                    default: return nil
                }
            }()

            
            if let granularity = granularity {
                return activity.repeats.filter {
                    Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: granularity)
                }.sorted { $0.date > $1.date }
            } else {
                return activity.dateSortedRepeats
            }
        }
    }
        
    private let cellId = "chart"
    
    private var timePeriodControl: UISegmentedControl!
    private lazy var display: EKGraphDisplayView = {
        let display = EKGraphDisplayView(
        frame: CGRect(x: 0, y: timePeriodControl.frame.maxY + padding, width: bounds.width, height: 30),
        repeat: repeatSource.first)
        return display
    }()
    
    private lazy var info: EKGraphInfoView = {
        let view = EKGraphInfoView(
            frame: CGRect(x: padding, y: chartSafeArea.min, width: 0, height: bounds.height - chartSafeArea.min - 20),
            repeats: repeatSource
        )
        view.frame.size.width = view.totalWidth
        return view
    }()
    
    public var activity: Activity!
    
    private var repeatSource = [Repeat]() {
        didSet {
            guard
                oldValue.count > 0,
                oldValue != repeatSource,
                repeatSource.count > 0
            else { return }
            
            let toRemove = oldValue.filter { !repeatSource.contains($0) }.map { oldValue.firstIndex(of: $0)
            }
            let toAdd = repeatSource.filter { !oldValue.contains($0) }.map { repeatSource.firstIndex(of: $0)
            }
            
            toRemove.forEach { self.deleteChart(at: $0) }
            toAdd.forEach {
                self.addChart(at: $0)
                
            }
            
            info.repeats = repeatSource
            chartCollectionView.reloadData()
        }
    }
    
    private var padding: CGFloat { 8.0 }
    private var chartSafeArea: (min: CGFloat, max: CGFloat) {
        return (display.frame.maxY + padding, bounds.height)
    }
    
    private var chartCollectionView: UICollectionView!
        
    private var chosenIndex: Int = 0 {
        didSet {
            guard chosenIndex != oldValue else { return }
            guard let chosenCell = chartCollectionView.cellForItem(at: IndexPath(item: oldValue, section: 0)) as? ChartCell else { print("Not found"); return }
            chosenCell.isChosen = false
        }
    }
    
    private var initFromIB = false
    private var didLayout = false

    init(frame: CGRect, activity: Activity) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initFromIB = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if !didLayout {
            didLayout = true
            if initFromIB {
                commonInit()
            }
        }
    }
    
    private func commonInit() {
        backgroundColor = UIColor.black.withAlphaComponent(0.05)
        
        repeatSource = TimePeriod(0).repeats(fromActivity: activity)
        
        let aspectRatio: CGFloat = 1/12
        let width = bounds.width*0.9
        timePeriodControl = UISegmentedControl(items: TimePeriod.allValues)
        timePeriodControl.frame = CGRect(x: (bounds.width-width)/2, y: padding, width: width, height: width*aspectRatio)
        timePeriodControl.selectedSegmentIndex = 0
        timePeriodControl.addTarget(self, action: #selector(timePeriodChanged), for: .valueChanged)
        
        addSubview(timePeriodControl)
        addSubview(display)
        addSubview(info)
                
        setupGraph()
    }
    
    private func setupGraph() {
        let minX = info.frame.maxX + padding
        let containingHeight = chartSafeArea.max - chartSafeArea.min
        let containingWidth = bounds.width - minX
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 12.0
        layout.sectionInset = .init(top: 0, left: 0, bottom: 0, right: 12.0)
        
        chartCollectionView = UICollectionView(frame: CGRect(x: minX, y: chartSafeArea.min, width: containingWidth, height: containingHeight), collectionViewLayout: layout)
        chartCollectionView.delegate = self
        chartCollectionView.dataSource = self
        chartCollectionView.backgroundColor = nil
        chartCollectionView.showsHorizontalScrollIndicator = false
        
        chartCollectionView.register(ChartCell.self, forCellWithReuseIdentifier: cellId)
        addSubview(chartCollectionView)
    }
    
    @objc private func timePeriodChanged(_ sender: UISegmentedControl) {
        self.repeatSource =
            TimePeriod(sender.selectedSegmentIndex).repeats(fromActivity: activity)
    }
}

// MARK: - Graph Collection Data Source
extension EKGraphView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return repeatSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChartCell
        cell.delegate = self
        
        cell._repeat = repeatSource[indexPath.item]
        cell.chartBoundary = (repeatSource.shortest, repeatSource.longest)
        cell.reset()
        cell.isChosen = indexPath.item == self.chosenIndex
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? ChartCell else { return }
        cell.delegate?.chartSelected(withRepeat: cell._repeat)
        cell.isChosen = true
        self.chosenIndex = indexPath.item
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: 30.0, height: collectionView.bounds.height)
    }
    
}

// MARK: - Actions
extension EKGraphView {
    public func selectChart(at index: Int) {
        guard let chart = chartCollectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? ChartCell else { return }
        chart.chartTapped()
        self.chartCollectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .right, animated: true)
        chart.isChosen = true
        self.chosenIndex = index
    }
    
    public func refresh(_ repeats: [Repeat]) {
        self.repeatSource = repeats
    }
    
    private func deleteChart(at index: Int?) {
        guard let idx = index else { return }
        let indexPath = IndexPath(item: idx, section: 0)
        
        chartCollectionView.performBatchUpdates({
            self.chartCollectionView.deleteItems(at: [indexPath])
        }, completion: { _ in
            self.chartCollectionView.reloadData()
        })
    }
    
    private func addChart(at index: Int?) {
        chartCollectionView.performBatchUpdates({
            self.chartCollectionView.insertItems(at: [IndexPath(item: 0, section: 0)])
        }, completion: { _ in
            
            self.chartCollectionView.reloadData()
        })
    }
}


// MARK: - Delegates
extension EKGraphView: ChartDelegate {
    func chartSelected(withRepeat _repeat: Repeat) {
        self.display.refresh(withRepeat: _repeat)
    }
}

// MARK: - Chart View
class ChartCell: UICollectionViewCell {
    public var _repeat: Repeat!
    public weak var delegate: ChartDelegate?
    public var chartBoundary: (floor: TimeInterval?, ceil: TimeInterval?)!
    
    public var isChosen: Bool = false {
        didSet {
            guard bar != nil else { return }
            UIView.animate(withDuration: 0.15) {
                self.bar.backgroundColor = self.isChosen ? AppColors.green : .systemGray3
            }
        }
    }
    
    private var padding: CGFloat { 4.0 }
    private var labelHeight: CGFloat { 20.0 }

    private var bar: UIView!
    private lazy var dateLabel: UILabel! = createLabel(ofText: "", atY: bounds.height - labelHeight)
    
    private var didLayout = false
    override func layoutSubviews() {
        if !didLayout {
            didLayout = true
            commonInit(_repeat)
        }
    }
    
    private func commonInit(_ _repeat: Repeat) {
        self._repeat = _repeat
        setupDesign()
        
        let component = Calendar.current.component(.weekday, from: _repeat.date)
        dateLabel.text = Calendar.current.shortWeekdaySymbols[component-1].lowercased()
    }
    
    private func setupDesign() {
        guard
            let floor = chartBoundary.floor, let ceil = chartBoundary.ceil else { return }
        let representation = _repeat.chartRepresentation(floor: CGFloat(floor), ceil: CGFloat(ceil))
        let height = chartHeight(with: representation)
        
        bar = UIView(frame: CGRect(x: 0, y: bounds.height - height - labelHeight, width: bounds.width, height: height))
        bar.layer.cornerRadius = bar.frame.width / 5
        bar.backgroundColor = isChosen ? AppColors.green : .systemGray3
        
        dateLabel.frame = CGRect(x: 0, y: bounds.height - labelHeight, width: bounds.width, height: labelHeight)
        
        addSubview(bar)
        addSubview(dateLabel)
    }
    
    func animateBarUpdate() {
        guard let bar = bar else { return }
        guard
            let floor = chartBoundary.floor, let ceil = chartBoundary.ceil else { return }
        let representation = _repeat.chartRepresentation(floor: CGFloat(floor), ceil: CGFloat(ceil))
        let height = chartHeight(with: representation)
        
        let frame = CGRect(x: 0, y: bounds.height - height - labelHeight, width: bounds.width, height: height)
        UIView.animate(withDuration: 0.3) {
            bar.frame = frame
        }
    }
    
    public func reset() {
//        guard didLayout else { return }
//        didLayout = false
//        layoutSubviews()
        animateBarUpdate()
    }
    
    private func chartHeight(with representation: CGFloat) -> CGFloat {
        let paddedSafeArea = bounds.height - 12.0
        let height = paddedSafeArea * representation
        let modifier: CGFloat = 0.87
        return (height * (modifier)) + 12
    }
    
    private func createLabel(ofText text: String, atY y: CGFloat) -> UILabel {
        let label = UILabel(frame: CGRect(x: 0, y: y, width: bounds.width, height: labelHeight))
        label.font = kDefaultFont
        label.textColor = .secondaryLabel
        label.text = text
        label.textAlignment = .center
        
        let fittingWidth = label.sizeThatFits(.init(width: CGFloat.greatestFiniteMagnitude, height: labelHeight)).width
        label.frame.size.width = fittingWidth
        label.frame.origin.x = (bounds.width - fittingWidth) / 2

        return label
    }
    
    public func collapse(completion: (() -> Void)?) {
        UIView.animate(withDuration: 0.15, animations: {
            self.alpha = 0.0
        }) { _ in completion?() }
    }
    
    @objc fileprivate func chartTapped() {
        self.delegate?.chartSelected(withRepeat: _repeat)
    }
}

// MARK: - Display View
class EKGraphDisplayView: UIView {
    private var _repeat: Repeat? {
        didSet {
            guard let rep = _repeat else {
                timeLabel.text = ""
                dateLabel.text = ""
                return
            }
            timeLabel.text = rep.formatted
            dateLabel.text = rep.date.shortFormat() + ","
        }
    }
    
    private let timeLabel: UILabel = UILabel.defaultLabel(text: "", font: kDefaultFont!.withSize(17.0), color: AppColors.green)
    private let dateLabel: UILabel = UILabel.defaultLabel(text: "", font: kDefaultFont!.withSize(17.0), color: AppColors.green)
    
    init(frame: CGRect, repeat _repeat: Repeat?) {
        super.init(frame: frame)
        commonInit(_repeat)
    }
    
    private func commonInit(_ _repeat: Repeat?) {
        // Add both labels and attach constraints.
        
        [dateLabel, timeLabel].forEach {
            $0.numberOfLines = 1
            //$0.backgroundColor = .systemYellow
        }
        let labelStackView = UIStackView(arrangedSubviews: [dateLabel, timeLabel])
        labelStackView.axis = .horizontal
        labelStackView.distribution = .fill
        labelStackView.spacing = 12.0
        
        let sep = UIView()
        sep.heightAnchor.constraint(equalToConstant: 1.0).isActive = true
        sep.backgroundColor = .separator
        
        let stackView = UIStackView(arrangedSubviews: [labelStackView, sep])
        stackView.axis = .vertical
        stackView.spacing = 4.0
        stackView.alignment = .leading
        
        stackView.fix(in: self, padding: .init(top: 0, left: 16.0, bottom: 0, right: 16.0))
        
        
        self._repeat = _repeat
    }
    
    public func refresh(withRepeat _repeat: Repeat) {
        self._repeat = _repeat
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

// MARK: - Info View
class EKGraphInfoView: UIView {
    
    private var maxLabel: UILabel!
    private var medianLabel: UILabel!
    private var minLabel: UILabel!
    
    public var totalWidth: CGFloat {
        let maxString = stackView.arrangedSubviews.compactMap {($0 as! UILabel).text}.max(by: {$1.count > $0.count})
        let width = maxString!.size(withAttributes: [NSAttributedString.Key.font: kDefaultFont!]).width
        return width + 4.0
    }
    
    public var repeats: [Repeat]! {
        didSet {
            longest = repeats.longest?.timerString()
            shortest = repeats.shortest?.timerString()
            median = ((repeats.longest! + repeats.shortest!) / 2).timerString()
        }
    }
    
    private var longest: String?  = "" { willSet { maxLabel.text = newValue ?? "" } }
    private var median: String?   = "" { willSet { medianLabel.text = newValue ?? "" } }
    private var shortest: String? = "" { willSet { minLabel.text = newValue ?? "" } }
    
    private var stackView: UIStackView!
    
    init(frame: CGRect, repeats: [Repeat]) {
        super.init(frame: frame)
        commonInit(repeats)
    }
    
    private func commonInit(_ repeats: [Repeat]) {
        maxLabel = UILabel.defaultLabel(text: longest ?? "", color: .tertiaryLabel)
        medianLabel = UILabel.defaultLabel(text: median ?? "", color: .tertiaryLabel)
        minLabel = UILabel.defaultLabel(text: shortest ?? "", color: .tertiaryLabel)
        
        stackView = UIStackView(arrangedSubviews: [
            maxLabel,
            medianLabel,
            minLabel
        ])
        
        self.repeats = repeats
        
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .equalSpacing
        stackView.fix(in: self)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
}








