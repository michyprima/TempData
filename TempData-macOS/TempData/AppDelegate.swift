//
//  AppDelegate.swift
//  TempData
//
//  Created by Michele Primavera on 24/12/23.
//

import Foundation
import Cocoa
import MediaPlayer
import DequeModule

class AppDelegate: NSObject, NSApplicationDelegate, USBWatcherDelegate {
    var queue : Deque<Data> = []
    var lastActivity = Date()
    var lastBreak = Date()
    var SongIdentifier : NSNumber = 0
    var oneSecondTimer : Timer?
    let calendar = Calendar.current
    let myLoad = Load()
    let myRAM = RAM()
    let myGPU = GPU()
    let myTemp = Temperature()
    var port : SerialPort?
    var eventMonitor : Any?
    var mediaObservedAdded = false
    var isSending = false
    var lastMinute = -1
    var anyActivity = false
    var watcher : USBWatcher?
    
    func applicationDidFinishLaunching(_: Notification) {
        watcher = USBWatcher(delegate: self)
        //startOneSecondTimer()
    }
    
    @objc func oneSecondTimerFired() {
        if port == nil {
            openSerialPort()
        }
        
        if port != nil {
            myLoad.update()
            myRAM.update()
            myGPU.update()
            myTemp.update()
            
            let buff = [
                0x08,
                UInt8(myTemp.TotalPower & 0xff),
                UInt8(myTemp.TotalPower >> 8),
                UInt8(myTemp.CPUHottest & 0xff),
                UInt8(myTemp.CPUHottest >> 8),
                UInt8(myLoad.cpuPercentage & 0xff),
                UInt8(myLoad.cpuPercentage >> 8),
                UInt8(myRAM.ramPercentage & 0xff),
                UInt8(myRAM.ramPercentage >> 8),
                0, //UInt8(gpuFrequency & 0xff),
                0, //UInt8(gpuFrequency >> 8),
                UInt8(myTemp.GPUHottest & 0xff),
                UInt8(myTemp.GPUHottest >> 8),
                UInt8(myGPU.usagePercentage & 0xff),
                UInt8(myGPU.usagePercentage >> 8),
                UInt8(myGPU.ramPercentage & 0xff),
                UInt8(myGPU.ramPercentage >> 8),
            ]
            
            processMessage(data: buff)
            
            let date = Date()
            
            let minute = calendar.component(.minute, from: date)
            if lastMinute != minute {
                processMessage(data: [
                    0x02,
                    UInt8(calendar.component(.hour, from: date)),
                    UInt8(minute),
                    UInt8(calendar.component(.day, from: date)),
                    UInt8(calendar.component(.month, from: date)),
                    UInt8(calendar.component(.year, from: date)-2000)
                ])
                lastMinute = minute
            }
            
            if(anyActivity) {
                lastActivity = date
                anyActivity = false
            } else {
                if (date.timeIntervalSince(lastActivity) >= 300) {
                    lastBreak = date
                }
            }
            
            if (date.timeIntervalSince(lastBreak) >= 3600) {
                let str1: [UInt8] = Array("Alzati minchione!".utf8)
                let str2: [UInt8] = Array("Non muovi il culo da un'ora!".utf8)
                
                var buff2 : [UInt8] = [
                    0x07,
                    60,
                    1
                ]
                
                buff2.append(contentsOf: str1)
                buff2.append(contentsOf: [UInt8](repeating: 0, count: 50 - str1.count))
                buff2.append(contentsOf: str2)
                buff2.append(contentsOf: [UInt8](repeating: 0, count: 50 - str2.count))
                
                processMessage(data: buff2)
                
                lastBreak = date
            }
        } else {
            stopOneSecondTimer()
        }
    }
    
    func processMessage(data: [UInt8]) {
        queue.append(Data(data))
        if(!isSending) {
            sendMessages()
        }
    }
    
    func sendMessages() {
        isSending = true
        do {
            while(!queue.isEmpty && port != nil) {
                let data = queue.popFirst();
                if(data != nil)  {
                    _ = try port!.writeData(data!)
                    _ = try port!.readByte()
                }
            }
        } catch {
            unregisterSystemEvents()
            stopOneSecondTimer()
            port = nil;
        }
        isSending = false
    }
    
    func openSerialPort() {
        if (port == nil) {
            lastMinute = -1
            queue.removeAll()
            do {
                let serialPorts = SerialFinder.getSerialDevices()
                var selectedPort : SerialFinder.SerialDevice?
                
                
                for serialPort in serialPorts {
                    if serialPort.serialNumber == "EC:DA:3B:98:C3:10" {
                        selectedPort = serialPort
                        break
                    }
                }
                
                if selectedPort != nil {
                    port = SerialPort(path: selectedPort!.path)
                    port!.setSettings(receiveRate: BaudRate.baud921600,
                                      transmitRate: BaudRate.baud921600,
                                      minimumBytesToRead: 1,
                                      timeout: 3,
                                      parityType: ParityType.none,
                                      sendTwoStopBits: false,
                                      dataBitsSize: DataBitsSize.bits8,
                                      useHardwareFlowControl: false,
                                      useSoftwareFlowControl: false,
                                      processOutput: false)
                    
                    try port!.openPort()
                    
                    registerSystemEvents()
                    startOneSecondTimer()
                }
            } catch {
                unregisterSystemEvents()
                stopOneSecondTimer()
                port = nil
            }
        }
    }
    
    func registerSystemEvents() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [NSEvent.EventTypeMask.keyDown, NSEvent.EventTypeMask.mouseMoved],
            handler: self.userActivityEvent
        )
        
        registerForNowPlayingNotifications()
    }
    
    func unregisterSystemEvents() {
        if (eventMonitor != nil) {
            NSEvent.removeMonitor(eventMonitor!)
            unregisterForNowPlayingNotifications()
            eventMonitor = nil
        }
    }
    
    func unregisterForNowPlayingNotifications() {
        let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework"))

        let MRMediaRemoteUnregisterForNowPlayingNotificationsPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteUnregisterForNowPlayingNotifications" as CFString)
        typealias MRMediaRemoteUnregisterForNowPlayingNotificationsFunction = @convention(c) () -> Void
        let MRMediaRemoteUnregisterForNowPlayingNotifications = unsafeBitCast(MRMediaRemoteUnregisterForNowPlayingNotificationsPointer, to: MRMediaRemoteUnregisterForNowPlayingNotificationsFunction.self)
        
        MRMediaRemoteUnregisterForNowPlayingNotifications();
    }
      
    func registerForNowPlayingNotifications() {
        let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework"))

        let MRMediaRemoteRegisterForNowPlayingNotificationsPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteRegisterForNowPlayingNotifications" as CFString)
        typealias MRMediaRemoteRegisterForNowPlayingNotificationsFunction = @convention(c) (DispatchQueue) -> Void
        let MRMediaRemoteRegisterForNowPlayingNotifications = unsafeBitCast(MRMediaRemoteRegisterForNowPlayingNotificationsPointer, to: MRMediaRemoteRegisterForNowPlayingNotificationsFunction.self)

        if(!self.mediaObservedAdded) {
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
                            var buff : [UInt8]
                            
                            self.SongIdentifier = identifier!
                            
                            let songArtist = (information["kMRMediaRemoteNowPlayingInfoArtist"] as! String?) ?? ""
                            let songTitle = (information["kMRMediaRemoteNowPlayingInfoTitle"] as! String?) ?? ""
                            let songAlbum = (information["kMRMediaRemoteNowPlayingInfoAlbum"] as! String?) ?? ""
                            
                            let str1: [UInt8] = Array(songTitle.replaceAccents().prefix(50).utf8)
                            let str2: [UInt8] = Array((songArtist + " - " + songAlbum).replaceAccents().prefix(100).utf8)
                            
                            buff = [
                                0x09,
                                5
                            ]
                            
                            buff.append(contentsOf: str1)
                            buff.append(contentsOf: [UInt8](repeating: 0, count: 50 - str1.count))
                            buff.append(contentsOf: str2)
                            buff.append(contentsOf: [UInt8](repeating: 0, count: 100 - str2.count))
                            
                            self.processMessage(data: buff)
                        }
                    }
                })
            }
            self.mediaObservedAdded = true
        }
        
        MRMediaRemoteRegisterForNowPlayingNotifications(DispatchQueue.main);
    }
    
    func userActivityEvent(event: NSEvent!) {
        anyActivity = true
        switch event.type {
        case .keyDown:
            switch event.keyCode {
            //Print key
            case 105:
                processMessage(data: [event.modifierFlags.contains(NSEvent.ModifierFlags.shift) ? 0x06 : 0x05])
            default:
                return
            }
            break
        default:
            break
        }
    }
    
    func startOneSecondTimer() {
        if(oneSecondTimer == nil) {
            oneSecondTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(oneSecondTimerFired), userInfo: nil, repeats: true)
        }
    }
    
    func stopOneSecondTimer() {
        if (oneSecondTimer != nil) {
            oneSecondTimer!.invalidate()
            oneSecondTimer = nil
        }
    }
    
    func deviceAdded(_ device: io_object_t) {
        if(port == nil) {
            if(device.name() == "USB JTAG/serial debug unit") {
                startOneSecondTimer()
            }
        }
    }
    
    func deviceRemoved(_ device: io_object_t) {}
}
