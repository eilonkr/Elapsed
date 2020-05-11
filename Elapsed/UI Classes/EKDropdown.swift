//
//  EKDropdown.swift
//  Elapsed
//
//  Created by Eilon Krauthammer on 22/09/2019.
//  Copyright © 2019 Eilon Krauthammer. All rights reserved.
//

import UIKit

protocol DropdownDelegate: AnyObject {
    func dropdown(_ dropdown: EKDropdown, didSelect option: String)
}

class EKDropdown: UIView {
    
    private let reuseIdentifier = "Cell"
    
    private var tableView: SizingTableView!
    
    public var options: [String] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    public weak var delegate: DropdownDelegate?
    
    public var totalHeight: CGFloat {
        return min(200.0, systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height)
    }
        
    private var didLayout = false
    
    // MARK: - Startup & View Cycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    init(frame: CGRect, options: [String], delegate: DropdownDelegate) {
        super.init(frame: frame)
        self.delegate = delegate
        commonInit(options: options)
    }

    private func commonInit(options: [String] = []) {
        setupView()
        setupTableView()
        self.options = options
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if !didLayout {
            didLayout = true
            self.frame.size.height = totalHeight
            delay(0.5) {
                self.backgroundColor = UIColor(white: 1.0, alpha: 0.8)
            }
        }
    }
    
    private func setupView() {
        backgroundColor = nil
        clipsToBounds = true
        layer.cornerRadius = 10.0
    }
    
    private func setupTableView() {
        tableView = SizingTableView(frame: bounds, style: .plain)
        tableView.backgroundColor = nil //UIColor.init(white: 1.0, alpha: 0.8)
        addSubview(tableView)
        tableView.fix(in: self)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(DropdownCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.estimatedRowHeight = 30.0
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
    }
    
    public func dismiss() {
        UIView.animate(withDuration: 0.15, animations: {
            self.alpha = 0.0
        }) { _ in
            self.removeFromSuperview()
        }
    }
}

// MARK: - Protocol

extension EKDropdown: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier) as? DropdownCell else { fatalError() }
        
        let option = options[indexPath.row]
        cell.option = option
        
        let delayFactor: Double = 0.07
        cell.appearFactor = Double(indexPath.row) * delayFactor
        cell.alpha = 0.0
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.dropdown(self, didSelect: options[indexPath.row])
    }
}

// MARK: - TableViewCell Class

class DropdownCell: UITableViewCell {
    
    private var label: UILabel!
    
    public var option: String! {
        didSet {
            label.text = option
        }
    }
    
    public var appearFactor: Double!
    
    private var didLayout = false
    private var didAppear = false
    
    private lazy var separator: UIView = {
        let sep = DashedSeparator(frame: CGRect(x: 0, y: bounds.maxY - 1, width: bounds.width, height: 1.0))
        sep.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        return sep
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonSetup()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if !didAppear { alpha = 0 }
        if !didLayout {
            didLayout = true
            addSubview(separator)
            delay(0.05) {
                self.appear()
            }
        }
    }
    
    private func commonSetup() {
        backgroundColor = nil
        contentView.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
        
        self.label = UILabel(frame: bounds)
        self.label.textColor = AppColors.blue
        self.label.textAlignment = .center
        self.label.font = kDefaultFont?.withSize(16.0)
        self.label.numberOfLines = 0
        
        self.label.fix(in: self, padding: .even(12.0))
    }
    
    private func appear() {
        // TODO: Implement
        transform = transform.translatedBy(x: 0, y: 20).scaledBy(x: 0.9, y: 0.9)
        delay(appearFactor) {
            UIView.animate(withDuration: 0.3, animations: {
                self.transform = .identity
                self.alpha = 1.0
            })
        }
        
        didAppear = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}




