//
//  QuotesViewController.swift
//  ScreenCapture
//
//  Created by kin on 12/27/16.
//  Copyright © 2016 Vuong, Thanh T. All rights reserved.
//

import Cocoa

class QuotesViewController: NSViewController {
    @IBOutlet weak var reminder: NSTextField!
    let quotes = ["1","2","3"]
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    var currentQuoteIndex: Int = 0 {
        didSet {
            updateQuote()
        }
    }
    func updateQuote() {
        reminder.stringValue = quotes[currentQuoteIndex] as String
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        currentQuoteIndex = 0
    }
}

