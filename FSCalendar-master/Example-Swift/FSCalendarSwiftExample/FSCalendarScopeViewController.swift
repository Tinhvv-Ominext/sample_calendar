//
//  FSCalendarScopeViewController.swift
//  FSCalendarSwiftExample
//
//  Created by dingwenchao on 30/12/2016.
//  Copyright © 2016 wenchao. All rights reserved.
//

import UIKit

extension UIView {
    
    enum Direction: Int {
        case topToBottom = 0
        case bottomToTop
        case leftToRight
        case rightToLeft
    }
    
    func applyGradient(colors: [Any]?, locations: [NSNumber]? = [0.0, 1.0], direction: Direction = .topToBottom) {
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = self.bounds
        gradientLayer.colors = colors
        gradientLayer.locations = locations
        
        switch direction {
        case .topToBottom:
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
            
        case .bottomToTop:
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.0)
            
        case .leftToRight:
            gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
            gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
            
        case .rightToLeft:
            gradientLayer.startPoint = CGPoint(x: 1.0, y: 0.5)
            gradientLayer.endPoint = CGPoint(x: 0.0, y: 0.5)
        }
        
        gradientLayer.cornerRadius = layer.cornerRadius
        
        self.layer.insertSublayer(gradientLayer, at: 0)
        
        for view in subviews {
            bringSubview(toFront: view)
        }
    }
}

class FSCalendarScopeExampleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, FSCalendarDataSource, FSCalendarDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var titleView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var calendar: FSCalendar!
    @IBOutlet weak var calendarView: UIView!
    @IBOutlet weak var animationSwitch: UISwitch!
    @IBOutlet weak var swipeView: UIView!
    @IBOutlet weak var monthLabel: UILabel!
    
    @IBOutlet weak var calendarHeightConstraint: NSLayoutConstraint!
    
    private var appliedGradient = false
    
    fileprivate lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()
    fileprivate lazy var scopeGesture: UIPanGestureRecognizer = {
        [unowned self] in
        let panGesture = UIPanGestureRecognizer(target: self.calendar, action: #selector(self.calendar.handleScopeGesture(_:)))
        panGesture.delegate = self
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 2
        return panGesture
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if UIDevice.current.model.hasPrefix("iPad") {
            self.calendarHeightConstraint.constant = 400
        }
        view.backgroundColor = .groupTableViewBackground
        tableView.panGestureRecognizer.require(toFail: scopeGesture)
        self.view.addGestureRecognizer(self.scopeGesture)
        self.calendar.scope = .week
        calendar.headerHeight = 0
        calendar.placeholderType = .none
        calendar.firstWeekday = 2
        calendar.appearance.weekdayTextColor = .white
        calendar.appearance.titleDefaultColor = .white
        calendar.appearance.selectionColor = .white
        calendar.appearance.titleSelectionColor = .orange
        calendar.appearance.todaySelectionColor = .white
        calendar.appearance.todayColor = .clear
        // For UITest
        self.calendar.accessibilityIdentifier = "calendar"
        titleView.backgroundColor = .red
        
        navigationController?.isNavigationBarHidden = true
        
        self.calendar.select(Date())
        monthLabel.text = dateFormatter.string(from: calendar.currentPage)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !appliedGradient {
            calendarView.applyGradient(colors: [UIColor.orange.cgColor, UIColor.yellow.cgColor],
            locations: [0.7, 1.0],
            direction: .leftToRight)
            
            titleView.applyGradient(colors: [UIColor.orange.cgColor, UIColor.yellow.cgColor],
            locations: [0.7, 1.0],
            direction: .leftToRight)
            
            calendarView.layer.cornerRadius = 10
            calendarView.clipsToBounds = true
            
            appliedGradient = true
        }
    }
    
    deinit {
        print("\(#function)")
    }
    
    
    @IBAction func todayTapped(_ sender: Any) {
        self.calendar.select(Date())
    }
    
    // MARK:- UIGestureRecognizerDelegate
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let shouldBegin = self.tableView.contentOffset.y <= -self.tableView.contentInset.top
        if shouldBegin {
            let velocity = self.scopeGesture.velocity(in: self.view)
            switch self.calendar.scope {
            case .month:
                return velocity.y < 0
            case .week:
                return velocity.y > 0
            }
        }
        return shouldBegin
    }
    
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        self.calendarHeightConstraint.constant = bounds.height + 10
        self.view.layoutIfNeeded()
    }
    
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        print("did select date \(self.dateFormatter.string(from: date))")
        let selectedDates = calendar.selectedDates.map({self.dateFormatter.string(from: $0)})
        print("selected dates is \(selectedDates)")
        if monthPosition == .next || monthPosition == .previous {
            calendar.setCurrentPage(date, animated: true)
        }
    }

    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        monthLabel.text = dateFormatter.string(from: calendar.currentPage)
    }
    
    // MARK:- UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return [2,20][section]
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let identifier = ["cell_month", "cell_week"][indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier)!
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
            return cell
        }
    }
    
    
    // MARK:- UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            let scope: FSCalendarScope = (indexPath.row == 0) ? .month : .week
            self.calendar.setScope(scope, animated: self.animationSwitch.isOn)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 10
    }
    
    // MARK:- Target actions
    
    @IBAction func toggleClicked(sender: AnyObject) {
        if self.calendar.scope == .month {
            self.calendar.setScope(.week, animated: self.animationSwitch.isOn)
        } else {
            self.calendar.setScope(.month, animated: self.animationSwitch.isOn)
        }
    }
    
}
