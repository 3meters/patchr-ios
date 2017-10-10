//
//  PhotoTableViewCell.swift
//  Patchr
//
//  Created by Jay Massena on 8/3/15.
//  Copyright (c) 2015 3meters. All rights reserved.
//

import UIKit

class PopupTableView: UIView {
    
    var rule = UIView(frame: .zero)
    var searchBar = UISearchBar(frame: .zero)

    lazy var titleLabel: AirLabelDisplay = {
        let label = AirLabelDisplay(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = Theme.colorTextTitle
        label.textAlignment = .center
        return label
    }()
    
    lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()

        self.rule.translatesAutoresizingMaskIntoConstraints = false
        self.rule.backgroundColor = Theme.colorRule
        
        self.searchBar.translatesAutoresizingMaskIntoConstraints = false
        self.searchBar.autocapitalizationType = .none
        self.searchBar.backgroundColor = Colors.clear
        self.searchBar.placeholder = "Search"
        self.searchBar.searchBarStyle = .prominent

        self.addSubview(self.titleLabel)
        self.addSubview(self.rule)
        self.addSubview(self.searchBar)
        self.addSubview(self.tableView)
        
        /* Setup constraints */
        self.heightAnchor.constraint(equalToConstant: 400).isActive = true
        
        var constraints = [NSLayoutConstraint]()
        let views: [String: UIView] = ["titleLabel": self.titleLabel, "rule": self.rule, "searchBar": self.searchBar, "tableView": self.tableView]
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|[tableView]|", options: [], metrics: nil, views: views)
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|[titleLabel(50)][rule(1)][searchBar(50)][tableView]|", options: [], metrics: nil, views: views)
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|[titleLabel]|", options: [], metrics: nil, views: views)
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|[rule]|", options: [], metrics: nil, views: views)
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|[searchBar]|", options: [], metrics: nil, views: views)
        NSLayoutConstraint.activate(constraints)
    }
}
