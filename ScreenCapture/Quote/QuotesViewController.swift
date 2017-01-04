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
    @IBOutlet weak var licenseidTextField: NSTextField!
    var quotes = ["1","2","3"]
    override func viewDidLoad() {
        super.viewDidLoad()
        let applicationSupportDirectory = "\(NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.ApplicationSupportDirectory, NSSearchPathDomainMask.UserDomainMask, true).first!)/ScreenCapture"
        let filemanager:NSFileManager = NSFileManager()
        if filemanager.fileExistsAtPath("\(applicationSupportDirectory)/LicenseID.txt") {
            quotes[0] = try! NSString(contentsOfFile: "\(applicationSupportDirectory)/LicenseID.txt", encoding: NSUTF8StringEncoding) as String
            print("File exists")
        }
        // Do view setup here.
    }
    var currentQuoteIndex: Int = 0 {
        didSet {
            updateQuote()
        }
    }
    func updateQuote() {
        licenseidTextField.stringValue = quotes[currentQuoteIndex] as String
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        currentQuoteIndex = 0
    }
}

