//
//  AppDelegate.swift
//  ScreenCapture
//
//  Created by Vuong, Thanh T on 26/10/16.
//  Copyright © 2016 Vuong, Thanh T. All rights reserved.
//

import Cocoa
import Foundation
import AppKit
import ServiceManagement


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-2)
    let twoSeconds = 2
    let thirtySeconds = 30
    var countdown_waitforinput = 0
    var countdown_waittosenddata = 0
    var timer_waitforinput: NSTimer? = NSTimer()
    var timer_waittosenddata: NSTimer? = NSTimer()
    var priorInput = [Dictionary<String, String>]()
    var switchtype = String("")
    var licenseid = String("")
    var waitforresponse = Bool(false)
    var LOG_CONDITION = Bool(true)
    var publicIPAddress = String("")
    // Popup menu
    let popover = NSPopover()
    let notification = QuotesViewController()
    var eventMonitor: EventMonitor?
    
    let screen = ScreenShot()
    var applicationSupportDirectory = String("")
    var applicationLogDirectory = String("")
    
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        //Launcher Application setting
        let launcherAppIdentifier = "VK.LauncherApplication"
        //set launcher to login items for auto turn on upon start up
        var ret = SMLoginItemSetEnabled(launcherAppIdentifier, false)
        //print(ret)
        var startedAtLogin = false
        for app in NSWorkspace.sharedWorkspace().runningApplications{
            if app.bundleIdentifier == launcherAppIdentifier{
                startedAtLogin = true
            }
        }
        
        if startedAtLogin{
            NSDistributedNotificationCenter.defaultCenter().postNotificationName("killme", object: NSBundle.mainBundle().bundleIdentifier!)
        }
        
        // popup menu params
        popover.contentViewController = notification
        eventMonitor = EventMonitor(mask:[.LeftMouseDownMask,.RightMouseDownMask]) { [unowned self] event in
            if self.popover.shown {
                self.closePopover(event)
            }
        }
        eventMonitor?.start()
        //print(NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.ApplicationSupportDirectory, NSSearchPathDomainMask.UserDomainMask, true).first!)
        
        // Get public IP Address
        if(self.publicIPAddress == "")
        {self.doGetIpPublic()}
        
        // Check LicenseID.txt exist, Otherwise create a new file and generate a new license ID
        applicationSupportDirectory = "\(NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.ApplicationSupportDirectory, NSSearchPathDomainMask.UserDomainMask, true).first!)/ScreenCapture"
        applicationLogDirectory = applicationSupportDirectory.stringByReplacingOccurrencesOfString("Application Support", withString: "Logs")
        // Check Support Folder exists
        checkSupportFolderExistence()
        
        // periodically run doAutoSendData function
        self.countdown_waittosenddata = self.thirtySeconds
        self.timer_waittosenddata = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "doAutoSendData", userInfo: nil, repeats: true)
        
        // User input event
        var inputEventMonitor: AnyObject!
        inputEventMonitor = NSEvent.addGlobalMonitorForEventsMatchingMask((NSEventMask:[.KeyDownMask,.LeftMouseUpMask,.RightMouseUpMask,.OtherMouseUpMask,.ScrollWheelMask]), handler: {(event: NSEvent) -> Void in
//////////// MAIN LOGGING EVENT BASED ON USER INPUT ///////////////////////////////////////////
            if self.LOG_CONDITION {
                self.countdown_waitforinput = self.twoSeconds
                self.timer_waitforinput?.invalidate()
                self.switchtype = self.screen.windowSwitchType()
                
                if self.switchtype == "OnTheSameWindow"
                {
                    switch event.type.rawValue {
                    case 10:
                        self.priorInput.append(["type":"KeyDown","time":"\(NSDate().timeIntervalSince1970)","detail":""])
                    case 2:
                        self.priorInput.append(["type":"MouseLClick","time":"\(NSDate().timeIntervalSince1970)","detail":"\(event)"])
                    case 4:
                        self.priorInput.append(["type":"MouseRClick","time":"\(NSDate().timeIntervalSince1970)","detail":"\(event)"])
                    case 22:
                        self.priorInput.append(["type":"ScrollWheel","time":"\(NSDate().timeIntervalSince1970)","detail":"\(event)"])
                    default:
                        self.priorInput.append(["type":"","time":"\(NSDate().timeIntervalSince1970)","detail":"\(event)"])
                    }
                    
                    self.timer_waitforinput = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "doWaitForInput", userInfo: nil, repeats: true)
                }
                else
                {
                    self.priorInput.removeAll()
                    let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
                    dispatch_async(dispatch_get_global_queue(priority, 0)) {
                        self.screenShot()
                    }
                }
            }
///////////////////////////////////////////////////////////////////////////
        })
        
        // Create Pause/Resume button
        if let button = statusItem.button {
            button.image = NSImage(named: "ResumeButtonImage")
            button.toolTip = "The logger is RUNNING"
            // pause click event
            // Stop logging activity
            button.action = Selector("pauseOrResumeLog:")
            }
    }
    
    func checkSupportFolderExistence()
    {
        let filemanager:NSFileManager = NSFileManager()
        
        // Check ScreenCapture Folder exists in Application Support Folder, Otherwise create a Folder for us
        if !filemanager.fileExistsAtPath("\(applicationSupportDirectory)"){
            do {
                try filemanager.createDirectoryAtPath("\(applicationSupportDirectory)", withIntermediateDirectories: true, attributes: nil)
                print("Support Folder created")
            }
            catch {
                // Exception
            }
        }
        if !filemanager.fileExistsAtPath("\(applicationLogDirectory)"){
            do {
                try filemanager.createDirectoryAtPath("\(applicationLogDirectory)", withIntermediateDirectories: true, attributes: nil)
                print("Log Folder created")
            }
            catch {
                // Exception
            }
        }
        if !filemanager.fileExistsAtPath("\(applicationSupportDirectory)/temp"){
            do {
                try filemanager.createDirectoryAtPath("\(applicationSupportDirectory)/temp", withIntermediateDirectories: true, attributes: nil)
                print("Temp Folder created")
            }
            catch {
                // Exception
            }
        }
        if !filemanager.fileExistsAtPath("\(applicationSupportDirectory)/extra"){
            do {
                try filemanager.createDirectoryAtPath("\(applicationSupportDirectory)/extra", withIntermediateDirectories: true, attributes: nil)
                print("Extra Folder created")
            }
            catch {
                // Exception
            }
        }
        
        // Check License File exists
        if filemanager.fileExistsAtPath("\(applicationSupportDirectory)/LicenseID.txt") {
            licenseid = try! NSString(contentsOfFile: "\(applicationSupportDirectory)/LicenseID.txt", encoding: NSUTF8StringEncoding) as String
            print("File exists")
        } else {
            print("File not found")
            licenseid = NSUUID().UUIDString
            // Register LicenseID on system if not yet registered
            self.HTTPGet("https://reknowdesktopsurveillance.hiit.fi/createlicenseid.php?licenseid=\(licenseid)", requestInterval: 2) {
                (data: String, error: String?) -> Void in
                if error != nil {
                    print(error)
                } else {
                    do {
                        try self.licenseid.writeToFile("\(self.applicationSupportDirectory)/LicenseID.txt", atomically: true, encoding: NSUTF8StringEncoding)
                    }
                    catch {/* error handling here */}
                }
            }
        }
    }
    
    func doWaitForInput() {
        if countdown_waitforinput == 0 {
            timer_waitforinput?.invalidate()
            countdown_waitforinput = twoSeconds
            let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
            dispatch_async(dispatch_get_global_queue(priority, 0)) {
                self.screenShot()
            }
        }
        else{
            print("time eslapsed for further INPUT \(countdown_waitforinput)")
        }
        countdown_waitforinput--
    }
    
    func doAutoSendData() {
        let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
        if self.countdown_waittosenddata == 0 {
            self.countdown_waittosenddata--
            
            // Get public IP Address
            if(self.publicIPAddress == "")
            {self.doGetIpPublic()}
            
            //Iterate through log folder
            
            // Check Support Folder exists
            checkSupportFolderExistence()
                
            // loop through files not uploaded yet 5 files at a time
            let filemanager:NSFileManager = NSFileManager()
            let files = filemanager.enumeratorAtPath("\(applicationSupportDirectory)/temp/")
            var index = 0
                
            dispatch_async(dispatch_get_global_queue(priority, 0)) {
                // CHECK LICENSE ID VALID TO PROCEED
                //print("this is id \(licenseid)")
                //let requestURL = "https://reknowdesktopsurveillance.hiit.fi/checklicenseid.php?licenseid=\(self.licenseid)"
                
                let requestURL = NSURL(string: "https://reknowdesktopsurveillance.hiit.fi/checklicenseid.php?licenseid=\(self.licenseid)")!
                do
                {
                    let data = try String(contentsOfURL: requestURL, encoding: NSUTF8StringEncoding)
                    //print(data)
                    if (self.convertStringToDictionary(data)!["hits"]!["total"] as! Int) == 1 {
                        while let file = files?.nextObject() {
                            if index < 10 && file.hasSuffix("jpeg") {
                                var counter = 0
                                let filename = file.stringByReplacingOccurrencesOfString(".jpeg", withString: "")
                                // sending data to backend
                                //print("file: \(filename)")
                                self.sendDataToServer(filename)
                                while self.waitforresponse {
                                    print("SLEEP!!!!! \(counter)")
                                    sleep(1)
                                    counter++
                                }
                            }
                            index++
                        }
                        //print("correct ID")
                        self.countdown_waittosenddata = self.thirtySeconds
                    }
                    else
                    {
                        //print("wrong ID")
                        self.countdown_waittosenddata = self.thirtySeconds
                    }
                    
                }
                catch let error as NSError {
                    //print("--------------------------------\(error)")
                    self.countdown_waittosenddata = self.thirtySeconds
                    if self.LOG_CONDITION{
                        if let button = self.statusItem.button {
                            if(button.image != NSImage(named: "WarningButtonImage"))
                            {
                                button.image = NSImage(named: "WarningButtonImage")
                                button.toolTip = "Server Unreachable"
                            }
                        }
                    }
                }
            }
        }
        else{
            if self.countdown_waittosenddata > 0{
                print("time eslapsed for send data \(self.countdown_waittosenddata)")
                self.countdown_waittosenddata--
            }
        }
    }
    


    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    
    func screenShot(){
        print(self.switchtype)
        // Take screenshot active window
        let screenshotName = "\(NSDate().timeIntervalSince1970)"
        self.screen.screenShot("\(applicationSupportDirectory)/temp/\(screenshotName).jpeg")
        // Recordd all computer logs
        let logDataContent = ["url":"\(self.screen.getURL())",
            "appname":"\(self.screen.getAppName())",
            "title":"\(self.screen.getTitle())",
            "filename":"\(screenshotName)",
            "ipaddress":self.publicIPAddress,
            "switchtype":"\(self.switchtype)",
            "priorinput":self.priorInput]
            //"licenseid":"\(self.licenseid)"]
        
        do {
            // ENSURE screenshot file co-exist with log file
            let filemanager:NSFileManager = NSFileManager()
            if filemanager.fileExistsAtPath("\(applicationSupportDirectory)/temp/\(screenshotName).jpeg") {
                let json = try NSJSONSerialization.dataWithJSONObject(logDataContent, options: .PrettyPrinted)
                try (NSString(data: json, encoding: NSUTF8StringEncoding)! as String).writeToFile("\(applicationSupportDirectory)/extra/\(screenshotName).txt", atomically: true, encoding: NSUTF8StringEncoding)
            }
        }
        catch {/* error handling here */}
        
        priorInput.removeAll()
    }
    
    func sendDataToServer(fname: String) {
        self.waitforresponse = true
        print("Waiting to send Data for FILE: \(fname)")
        // Check co-existence of log file and screenshot
        let filemanager:NSFileManager = NSFileManager()
        if !filemanager.fileExistsAtPath("\(applicationSupportDirectory)/temp/\(fname).jpeg") || !filemanager.fileExistsAtPath("\(applicationSupportDirectory)/extra/\(fname).txt"){
            self.waitforresponse = false
            return
        }
        
        
        // data to be sent
        var logDataAsText = try? String(contentsOfFile: "\(applicationSupportDirectory)/extra/\(fname).txt", encoding: NSUTF8StringEncoding)
        // Create URL request
        let OCRAPIurl = NSURL(string: "https://reknowdesktopsurveillance.hiit.fi/upload.php")!
        let request = NSMutableURLRequest(URL: OCRAPIurl)
        request.HTTPMethod = "POST"
        let boundary = generateBoundaryString()
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let session = NSURLSession.sharedSession()
        // Image file and parameters
        let image = NSImage(contentsOfFile: "\(applicationSupportDirectory)/temp/\(fname).jpeg")
        var imageData = image!.TIFFRepresentation
        let imageRep = NSBitmapImageRep(data: imageData!)
        let compressionFactor = Int(0.1)
        let imageProps = [ NSImageCompressionFactor : compressionFactor ]
        imageData = imageRep!.representationUsingType(NSBitmapImageFileType.NSJPEGFileType, properties: imageProps)
        
        var logDataAsDict = self.convertStringToDictionary(logDataAsText!)
        logDataAsDict!["licenseid"] = licenseid
        do{
            let logDataAsJSON = try NSJSONSerialization.dataWithJSONObject(logDataAsDict!, options: .PrettyPrinted)
            logDataAsText = (NSString(data: logDataAsJSON, encoding: NSUTF8StringEncoding)! as String)
        }
        catch{}
        
        print(logDataAsText! as String)
        let parametersDictionary = [
            "extra": logDataAsText! as String,
            "username": self.licenseid
        ]
        
        let data = self.createBodyWithBoundary(boundary, parameters: parametersDictionary, imageData: imageData!, filename: "\(applicationSupportDirectory)/temp/\(fname).jpeg")
        request.HTTPBody = data
        // Start data session
        let task = session.dataTaskWithRequest(request) {
            (
            let data, let response, let error) in
            
            guard let _:NSData = data, let _:NSURLResponse = response  where error == nil else {
                print("Server Unreachable")
                self.waitforresponse = false;
                // SET ICON WARNING
                if self.LOG_CONDITION{
                    if let button = self.statusItem.button {
                        if(button.image != NSImage(named: "WarningButtonImage"))
                        {
                            button.image = NSImage(named: "WarningButtonImage")
                            button.toolTip = "Server Unreachable"
                        }
                    }
                }
                
                return
            }
            
            let dataString = NSString(data: data!, encoding: NSUTF8StringEncoding)
            // delete temporay files after file uploaded successfully
            if dataString as! String == "file uploaded"{
                let fileManager = NSFileManager.defaultManager()
                do {
                    try fileManager.removeItemAtPath("\(self.applicationSupportDirectory)/extra/\(fname).txt")
                    try fileManager.removeItemAtPath("\(self.applicationSupportDirectory)/temp/\(fname).jpeg")
                    self.waitforresponse = false;
                    if self.LOG_CONDITION{
                        if let button = self.statusItem.button {
                            button.image = NSImage(named: "ResumeButtonImage")
                            button.toolTip = "The logger is RUNNING"
                        }
                    }
                }
                catch let error as NSError {
                    print("Ooops! Something went wrong: \(error)")
                    self.waitforresponse = false;
                }
            }
            else {
                print("Ooops! Something went wrong)")
                self.waitforresponse = false;
            }
            
        }
        
        task.resume()
    }
    
    // change image button to pause or resume
    func pauseOrResumeLog(sender: AnyObject){
        //print("pause clicked")
        self.countdown_waitforinput = self.twoSeconds
        self.countdown_waittosenddata = self.thirtySeconds
        self.timer_waitforinput?.invalidate()
        self.timer_waittosenddata?.invalidate()
        self.LOG_CONDITION = (self.LOG_CONDITION) ? false : true
        if let button = statusItem.button {
            button.image = (self.LOG_CONDITION) ? NSImage(named: "ResumeButtonImage") : NSImage(named: "PauseButtonImage")
            button.toolTip = (self.LOG_CONDITION) ? "The logger is RUNNING" : "The logger is STOPPED"
            if self.LOG_CONDITION{
                self.timer_waittosenddata = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "doAutoSendData", userInfo: nil, repeats: true)
                // toggle popup status
                if popover.shown {
                    closePopover(sender)
                }
                
            }
            else
            {
                // toggle popup status
                if !popover.shown {
                    showPopover(sender)
                }
                //popover.showRelativeToRect(button.bounds, ofView: button, preferredEdge: NSRectEdge.MinY)
            }
        }
        
    }
    
    func generateBoundaryString() -> String
    {
        return "Boundary-\(NSUUID().UUIDString)"
    }
    
    func doGetIpPublic() -> Void{
        //let ipifyurl = NSURL(string: "https://api.ipify.org/")!
        let ipifyurl = "https://api.ipify.org/"
        var ipAddress = ""
        self.HTTPGet(ipifyurl, requestInterval: 2) {
            (data: String, error: String?) -> Void in
            if error != nil {
                ipAddress = error! as String
                print("aaa \(error)")
            } else {
                ipAddress = data as String
                self.publicIPAddress = ipAddress
            }
        }
        
        /*do
        {
            ipAddress = try String(contentsOfURL: ipifyurl, encoding: NSUTF8StringEncoding)
        }
        catch {}*/
    }
    
    func HTTPsendRequest(request: NSMutableURLRequest,callback: (String, String?) -> Void) {
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request,completionHandler :
            {
                data, response, error in
                if error != nil {
                    callback("", (error!.localizedDescription) as String)
                } else {
                    callback(NSString(data: data!, encoding: NSUTF8StringEncoding) as! String,nil)
                }
        })
        
        task.resume() //Tasks are called with .resume()
        
    }
    
    func HTTPGet(url: String, requestInterval: Double, callback: (String, String?) -> Void) {
        let request = NSMutableURLRequest(URL: NSURL(string: url)!) //To get the URL of the receiver , var URL: NSURL? is used
        request.timeoutInterval = requestInterval
        HTTPsendRequest(request, callback: callback)
    }
    
    func convertStringToDictionary(text: String) -> [String:AnyObject]? {
        if let data = text.dataUsingEncoding(NSUTF8StringEncoding) {
            do {
                return try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String:AnyObject]
            } catch let error as NSError {
                print(error)
            }
        }
        return nil
    }
    
    func writeLog(text: String) -> Void{
        do {
            try text.writeToFile("\(self.applicationLogDirectory)/\(NSDate().timeIntervalSince1970).log", atomically: true, encoding: NSUTF8StringEncoding)
        }
        catch {/* error handling here */}
    }
    
    func createBodyWithBoundary(boundary: String, parameters: [NSObject : AnyObject], imageData: NSData, filename: String) -> NSData {
        let body = NSMutableData()
        //if (data) {
        body.appendData("--\(boundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        body.appendData("Content-Disposition: form-data; name=\"image\"; filename=\"\(filename)\"\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        body.appendData("Content-Type: image/jpeg\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        body.appendData(imageData)
        body.appendData("\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        //}
        for key: AnyObject in parameters.keys {
            body.appendData("--\(boundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            body.appendData("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
            body.appendData("\(parameters[key as! NSObject]!)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        }
        body.appendData("--\(boundary)--\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
        return body
    }
    
    func showPopover(sender: AnyObject?) {
        if let button = statusItem.button {
            popover.showRelativeToRect(button.bounds, ofView: button, preferredEdge: NSRectEdge.MinY)
        }
        eventMonitor?.start()
    }
    
    func closePopover(sender: AnyObject?) {
        popover.performClose(sender)
        eventMonitor?.stop()
    }
    
    func macSerialNumber() -> String {
        
        // Get the platform expert
        let platformExpert: io_service_t = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"));
        
        // Get the serial number as a CFString ( actually as Unmanaged<AnyObject>! )
        let serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert, kIOPlatformSerialNumberKey, kCFAllocatorDefault, 0);
        
        // Release the platform expert (we're responsible)
        IOObjectRelease(platformExpert);
        
        // Take the unretained value of the unmanaged-any-object
        // (so we're not responsible for releasing it)
        // and pass it back as a String or, if it fails, an empty string
        return (serialNumberAsCFString.takeUnretainedValue() as? String) ?? ""
    }


}

