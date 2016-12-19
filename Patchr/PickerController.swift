//
//  PagingController.swift
//  Patchr
//
//  Created by Jay Massena on 12/18/16.
//  Copyright © 2016 3meters. All rights reserved.
//

import Foundation

class PickerController: UIPageViewController {
    
    lazy var pages = [UIViewController]()
    
    var segmentedController = UISegmentedControl()
    var pageControl: UIPageControl?
    var rule = UIView()
    var scrollView: UIScrollView?
    var startPage = 1
    var showPageControl = true
    var pagesCount: Int {
        return pages.count
    }
    
    fileprivate(set) var currentIndex = 0
    
    public convenience init(_ pages: [UIViewController], options: [String : AnyObject]? = nil) {
        self.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: options)
        for page in pages {
            addPage(page)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.view.fillSuperview()
        self.segmentedController.anchorTopCenter(withTopPadding: 12, width: 200, height: 28)
        self.rule.alignUnder(self.segmentedController, centeredFillingWidthWithLeftAndRightPadding: 0, topPadding: 12, height: 1)
        self.scrollView?.alignUnder(self.segmentedController, centeredFillingWidthWithLeftAndRightPadding: 0, topPadding: 12, height: self.view.height() - 52)
    }
    
    func initialize() {
        
        for subview in view.subviews {
            if subview is UIScrollView {
                self.scrollView = subview as? UIScrollView
            }
        }

        self.dataSource = self
        self.view.backgroundColor = Colors.gray95pcntColor
        self.rule.backgroundColor = Theme.colorSeparator
        
        UIPageControl.appearance().pageIndicatorTintColor = Colors.gray85pcntColor
        UIPageControl.appearance().currentPageIndicatorTintColor = Colors.accentColor

        self.segmentedController.insertSegment(withTitle: "Groups", at: 0, animated: true)
        self.segmentedController.insertSegment(withTitle: "Channels", at: 1, animated: true)
        self.view.addSubview(self.segmentedController)
        self.view.addSubview(self.rule)
        goTo(self.startPage)
    }
    
    func addPage(_ page: UIViewController) {
        pages.append(page)
        if pages.count == 1 {
            setViewControllers([page], direction: .forward, animated: true) { [unowned self] finished in
                self.segmentedController.selectedSegmentIndex = self.currentIndex
            }
        }
    }
    
    func pageIndex(_ page: UIViewController) -> Int? {
        return self.pages.index(of: page)
    }
    
    func goTo(_ index: Int) {
        if index >= 0 && index < self.pages.count {
            let direction: UIPageViewControllerNavigationDirection = (index > self.currentIndex) ? .forward : .reverse
            let page = self.pages[index]
            self.currentIndex = index
            setViewControllers([page], direction: direction, animated: true) { [unowned self] finished in
                self.segmentedController.selectedSegmentIndex = index
            }
        }
    }
    
    func moveForward() {
        goTo(currentIndex + 1)
    }
    
    func moveBack() {
        goTo(currentIndex - 1)
    }
    
    func nextIndex(_ x: Int?) -> Int? {
        return ((x)! + 1)
    }
    
    func prevIndex(_ x: Int?) -> Int? {
        return ((x)! - 1)
    }
}

extension PickerController: UIPageViewControllerDataSource {
    
    open func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        let index = prevIndex(pageIndex(viewController))
        return pages.at(index)
    }
    
    open func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let index: Int? = nextIndex(pageIndex(viewController))
        return pages.at(index)
    }
    
    open func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return showPageControl ? pages.count : 0
    }
    
    open func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        return showPageControl ? currentIndex : 0
    }
}
