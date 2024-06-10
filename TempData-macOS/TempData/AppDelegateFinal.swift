//
//  AppDelegateFinal.swift
//  TempData
//
//  Created by Michele Primavera on 12/12/23.
//

import Foundation
import Cocoa
import MediaPlayer

class AppDelegateFinal: NSObject, NSApplicationDelegate {

    public var F12 = false
    public var Print = false
    public var Shift = false
    public var AnyActivity = false
    public var NewSong = false
    public var SongArtist = ""
    public var SongTitle = ""
    public var SongAlbum = ""
    var SongIdentifier : NSNumber = 0
    //public var SongDuration = ""
    
    func applicationDidFinishLaunching(_: Notification) {
        NSEvent.addGlobalMonitorForEvents(
            matching: [NSEvent.EventTypeMask.keyDown, NSEvent.EventTypeMask.mouseMoved],
            handler: self.printEvent
        )
        
        registerForNowPlayingNotifications()
    }
    
    func registerForNowPlayingNotifications() {
        let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework"))

        let MRMediaRemoteRegisterForNowPlayingNotificationsPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteRegisterForNowPlayingNotifications" as CFString)
        typealias MRMediaRemoteRegisterForNowPlayingNotificationsFunction = @convention(c) (DispatchQueue) -> Void
        let MRMediaRemoteRegisterForNowPlayingNotifications = unsafeBitCast(MRMediaRemoteRegisterForNowPlayingNotificationsPointer, to: MRMediaRemoteRegisterForNowPlayingNotificationsFunction.self)

        let MRMediaRemoteGetNowPlayingInfoPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString)
        typealias MRMediaRemoteGetNowPlayingInfoFunction = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
        let MRMediaRemoteGetNowPlayingInfo = unsafeBitCast(MRMediaRemoteGetNowPlayingInfoPointer, to: MRMediaRemoteGetNowPlayingInfoFunction.self)

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "kMRMediaRemoteNowPlayingInfoDidChangeNotification"), object: nil, queue: nil) { (notification) in
            MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main, { (information) in
                //debugPrint(information)
                let identifier = information["kMRMediaRemoteNowPlayingInfoUniqueIdentifier"] as! NSNumber?
                let mediaType = information["kMRMediaRemoteNowPlayingInfoMediaType"] as! String?
                
                if (identifier != nil && mediaType == "MRMediaRemoteMediaTypeMusic") {
                    if (self.SongIdentifier != identifier) {
                        self.NewSong = true
                        self.SongIdentifier = identifier!
                        self.SongArtist = (information["kMRMediaRemoteNowPlayingInfoArtist"] as! String?) ?? ""
                        self.SongTitle = (information["kMRMediaRemoteNowPlayingInfoTitle"] as! String?) ?? ""
                        self.SongAlbum = (information["kMRMediaRemoteNowPlayingInfoAlbum"] as! String?) ?? ""
                    }
                }
            })
        }
        MRMediaRemoteRegisterForNowPlayingNotifications(DispatchQueue.main);
    }
    
    func printEvent(event: NSEvent!) {
        AnyActivity = true
        switch event.type {
        case .keyDown:
            switch event.keyCode {
            case 111:
                F12 = true
            case 105:
                Print = true
            default:
                return
            }
            Shift = event.modifierFlags.contains(NSEvent.ModifierFlags.shift)
            break
        default:
            break
        }
    }
    
    private func checkPermissions() -> Bool {
        if (AXIsProcessTrusted() == false) {
            print("Need accessibility permissions!")
            let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
            AXIsProcessTrustedWithOptions(options)
            
            return false;
        } else {
            print("Accessibility permissions active")
            return true;
        }
    }
}
