//
//  DetailViewController.swift
//  HazeLight
//
//  Created by Jon Shier on 6/20/15.
//  Copyright © 2015 Jon Shier. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var detailDescriptionLabel: UILabel!

    var detailItem: Any? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

    func configureView() {
        // Update the user interface for the detail item.
        if let detail = self.detailItem,
           let label = self.detailDescriptionLabel {
                label.text = (detail as AnyObject).description
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
    }
}

