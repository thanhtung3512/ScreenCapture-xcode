//
//  ScreenShot.swift
//  ScreenCapture
//
//  Created by kin on 12/27/16.
//  Copyright © 2016 Vuong, Thanh T. All rights reserved.
//

import Cocoa

class ScreenShot: NSObject {
    var wnumber = Int()
    var wtitle = String("")
    var appname = String("")
    //var url = String("")
    
    override init(){
        
    }
    
    deinit{
        print("Release object \(wnumber)")
    }
    
    func screenShot(fname: String) -> Void{
        // Capture active window screen by window number
        var cgImage = CGWindowListCreateImage(CGRectNull, CGWindowListOption.OptionIncludingWindow, CGWindowID(wnumber), CGWindowImageOption.BoundsIgnoreFraming)
        let cropRect = CGRectMake(0, 0, CGFloat(CGImageGetWidth(cgImage)), CGFloat(CGImageGetHeight(cgImage)) - 0)
        cgImage = CGImageCreateWithImageInRect(cgImage, cropRect)
        if cgImage == nil {
            //print("null")
            return
        }
        // Create a bitmap rep from the image...
        let bitmapRep = NSBitmapImageRep(CGImage: cgImage!)
        // Save the file
        let newRep = bitmapRep.bitmapImageRepByConvertingToColorSpace(NSColorSpace.genericGrayColorSpace(), renderingIntent: NSColorRenderingIntent.Default)
        let data = newRep!.representationUsingType(NSBitmapImageFileType.NSJPEGFileType, properties: [NSImageCompressionFactor: 1])
        
        data!.writeToFile(fname, atomically: false)
    }
    
    func getTitle() -> String{
        return wtitle
    }
    
    func getAppName() -> String{
        return appname
    }
    
    func getURL() -> String{
        var url = String("")
        let applescript = DoAppleScript(applicationName: self.appname)
        
        do{
            url = try applescript.getURL()
        }
        catch {}
        
        return url
        //return self.url
    }
    
    func windowSwitchType() -> String{
        var switchtype = ""
        // Get active window number
        let options = CGWindowListOption(arrayLiteral: CGWindowListOption.ExcludeDesktopElements, CGWindowListOption.OptionOnScreenOnly)
        let windowListInfo = CGWindowListCopyWindowInfo(options, CGWindowID(0))
        let infoList = windowListInfo as NSArray? as? [[String: AnyObject]]
        var active_wnumber = Int()
        var active_wtitle = String("")
        var active_appname = String("")
        
        for entry in infoList!{
            if let data = entry as? NSDictionary
            {
                // Do stuff with window data
                let winid = data.objectForKey("kCGWindowLayer")!
                let wnumber = data.objectForKey("kCGWindowNumber")!
                let winname = (data.objectForKey("kCGWindowName") != nil) ? data.objectForKey("kCGWindowName")! as! String : ""
                let ownername = (data.objectForKey("kCGWindowOwnerName") != nil) ? data.objectForKey("kCGWindowOwnerName") as! String : ""
                if winid as! NSObject == 0 {
                    active_wnumber = Int("\(wnumber as! NSObject)")!
                    active_wtitle = winname
                    active_appname = ownername
                    //print("winid:::::::\(winid as! NSObject)")
                    //print(ownername)
                    //print(winname)
                    // Check whether window number changes
                    if active_appname != self.appname
                    {
                        switchtype = "ApplicationSwitch"
                    }
                    else if active_wnumber != self.wnumber
                    {
                        switchtype = "WindowSwitch"
                    }
                    else if active_wnumber == self.wnumber && active_wtitle != self.wtitle
                    {
                        switchtype = "TabSwitch"
                    }
                    else
                    {
                        switchtype = "OnTheSameWindow"
                    }
                    self.wnumber = active_wnumber
                    self.wtitle = active_wtitle
                    self.appname = active_appname
                    break
                }
            }
        }
        
        //self.url = DoAppleScript(applicationName: self.appname).getURL()
        return switchtype
    }
}
