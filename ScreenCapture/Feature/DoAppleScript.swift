//
//  DoAppleScript.swift
//  ScreenCapture
//
//  Created by kin on 12/27/16.
//  Copyright © 2016 Vuong, Thanh T. All rights reserved.
//

import Cocoa

class DoAppleScript: NSObject {
    var applicationName = String()
    var scriptObject = NSAppleScript()
    
    required init(applicationName: String){
        self.applicationName = applicationName
    }
    
    deinit{
        //print("Release Apple Script Object \(applicationName)")
    }
    
    func getURL() -> String{
        var url = String("")
        var script = String("")
        var isDirectory = Bool(false)
        switch self.applicationName {
            case "Safari":
                script = "tell application \"Safari\"\n" +
                    "  get URL of current tab of front window\n" +
                    "end tell"
            case "Google Chrome": //&& !(winname as! String == " ") ??
                script = "tell application \"Google Chrome\"\n" +
                    "  get URL of active tab of front window\n" +
                    "end tell"
            case "Adobe Reader":
                script = "tell application \"System Events\"\n" +
                    "    tell process \"Adobe Reader\"\n" +
                    "        set thefile to value of attribute \"AXDocument\" of front window\n" +
                    "    end tell\n" +
                    "end tell\n" +
                    "set o_set to offset of \"/Users\" in thefile\n" +
                    "set fixFile to characters o_set thru -1 of thefile\n" +
                    "set thefile to fixFile as string\n" +
                    "thefile"
                isDirectory = Bool(true)
            case "Mail":
                script = "set urltext to \"\"\n" +
                    "tell application \"Mail\"\n" +
                    "    set msgs to selection\n" +
                    "    repeat with msg in msgs\n" +
                    "        set urltext to urltext & \"message://\" & \"%%3c\" & message id of msg & \"%%3e,\"\n" +
                    "    end repeat\n" +
                    "end tell"
            case "Microsoft PowerPoint":
                script = "tell application \"Microsoft PowerPoint\"\n" +
                    "    (path of active presentation) & \"/\" & (name of active presentation)\n" +
                    "end tell\n" +
                    "get POSIX path of result"
                isDirectory = Bool(true)
            case "Microsoft Excel":
                script = "tell application \"Microsoft Excel\"\n" +
                    "    ((path of active workbook) as text) & \"/\" & ((name of active workbook) as text)\n" +
                    "end tell\n" +
                    "get POSIX path of result"
                isDirectory = Bool(true)
            case "Microsoft Word":
                script = "try\n" +
                    "        tell application \"System Events\" to tell process \"Microsoft Word\"\n" +
                    "            value of attribute \"AXDocument\" of window 1\n" +
                    "        end tell\n" +
                    "        do shell script \"x=\" & quoted form of result & \"\n" +
                    "        x=${x/#file:\\\\/\\\\/}\n" +
                    "        printf ${x//%%/\\\\\\\\x}\"\n" +
                    "       on error \n" +
                    "       set t to \"\"\n" +
                    "end try"
                isDirectory = Bool(true)
            case "Finder":
                script = "tell application \"Finder\"\n" +
                    "set theWin to front window\n" +
                    "set thePath to (POSIX path of (target of theWin as alias))\n" +
                    "end tell"
                isDirectory = Bool(true)
            default:
                script = ""
        }
        
        url = self.execute(script).stringByReplacingOccurrencesOfString("\n", withString: "")
        if isDirectory {
            url = "file://\(url)"
        }
        
        return url
    }
    
    func execute(appScript: String) -> String {
        let task = NSTask()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e \(appScript)"]
        
        let pipe = NSPipe()
        task.standardOutput = pipe
        task.launch()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output: String = NSString(data: data, encoding: NSASCIIStringEncoding)! as String
        
        return output
        /*var error: NSDictionary?
        scriptObject = NSAppleScript(source: appScript)!
        let output = scriptObject.executeAndReturnError(&error)
        /*if(error != nil)
        {
            print("error: \(error)")
            return "error"
        }
        else
        {
            if output.stringValue != nil{
                return output.stringValue!
            }
            else
            {
                return ""
            }
        }
            /*{
                if output.stringValue != nil{
                    return output.stringValue!
                }
                else
                {
                    return ""
                }
            } else if (error != nil) {
                print("error: \(error)")
                return "error"
            }
        }*/*/*/
        //return ""
    }
}
