//
//  SerialFinder.swift
//  TempData
//
//  Created by Michele Primavera on 13/12/23.
//

import Foundation
import IOKit
import IOKit.serial

class SerialFinder {
    public struct SerialDevice {
        public let path:String
        public var name:String? // USB Product Name
        public var vendorName:String? //USB Vendor Name
        public var serialNumber:String? //USB Serial Number
        public var vendorId:Int? //USB Vendor id
        public var productId:Int? //USB Product id
        
        init(path:String) {
            self.path = path
        }
    }
    
    private static func getParentProperty(device:io_object_t, key:String) -> AnyObject? {
        return IORegistryEntrySearchCFProperty(device, kIOServicePlane, key as CFString, kCFAllocatorDefault, IOOptionBits(kIORegistryIterateRecursively | kIORegistryIterateParents))
    }
    
    static func getDeviceProperty(device:io_object_t, key:String) -> AnyObject? {
        let cfKey = key as CFString
        let propValue = IORegistryEntryCreateCFProperty(device, cfKey, kCFAllocatorDefault, 0)
        
        return propValue?.takeRetainedValue()
    }
    
    static func getSerialDevices() -> [SerialDevice] {
        var portIterator: io_iterator_t = 0
        var result: kern_return_t = KERN_FAILURE
        let classesToMatch = IOServiceMatching(kIOSerialBSDServiceValue) as NSMutableDictionary
        classesToMatch[kIOSerialBSDTypeKey] = kIOSerialBSDAllTypes
        result = IOServiceGetMatchingServices(kIOMainPortDefault, classesToMatch, &portIterator)
        
        var newSerialDevices:[SerialDevice] = []

        if result == KERN_SUCCESS {
            while case let serialPort = IOIteratorNext(portIterator), serialPort != 0 {
                guard let calloutDevice = getDeviceProperty(device: serialPort, key: kIOCalloutDeviceKey) as? String else {
                    continue
                }
                
                var sd = SerialDevice(path: calloutDevice)
                sd.name = getParentProperty(device: serialPort, key: "USB Product Name") as? String
                sd.vendorName = getParentProperty(device: serialPort, key: "USB Vendor Name") as? String
                sd.serialNumber = getParentProperty(device: serialPort, key: "USB Serial Number") as? String
                sd.vendorId = getParentProperty(device: serialPort, key: "idVendor") as? Int
                sd.productId = getParentProperty(device: serialPort, key: "idProduct") as? Int
                
                newSerialDevices.append(sd)
                IOObjectRelease(serialPort)
            }
            IOObjectRelease(portIterator)
        }
        
        return newSerialDevices
    }
}
