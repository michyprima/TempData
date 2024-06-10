//
//  GPU.swift
//  TempData
//
//  Created by Michele Primavera on 11/12/23.
//

import Foundation

class GPU {
    var totalSize: Double = 0
    public var usagePercentage : Int = 0
    public var ramPercentage : Int = 0
    
    init() {
        var stats = host_basic_info()
        var count = UInt32(MemoryLayout<host_basic_info_data_t>.size / MemoryLayout<integer_t>.size)
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_info(mach_host_self(), HOST_BASIC_INFO, $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            self.totalSize = Double(stats.max_mem)
            return
        }
        
        self.totalSize = 0
    }
    
    public func update() {
        guard let accelerators = fetchIOService("IOAccelerator") else {
            return
        }
        
        for (_, accelerator) in accelerators.enumerated() {
            guard let stats = accelerator["PerformanceStatistics"] as? [String: Any] else {
                return
            }
            
            ramPercentage = Int(round(Double(stats["In use system memory"] as? Int ?? 0) / totalSize * 100))
            usagePercentage = ((stats["Device Utilization %"] as? Int ?? 0) + (stats["Tiler Utilization %"] as? Int ?? 0) + (stats["Renderer Utilization %"] as? Int ?? 0)) / 3
        }
    }
    
    public func getIOProperties(_ entry: io_registry_entry_t) -> NSDictionary? {
        var properties: Unmanaged<CFMutableDictionary>? = nil
        
        if IORegistryEntryCreateCFProperties(entry, &properties, kCFAllocatorDefault, 0) != kIOReturnSuccess {
            return nil
        }
        
        defer {
            properties?.release()
        }
        
        return properties?.takeUnretainedValue()
    }
    
    public func fetchIOService(_ name: String) -> [NSDictionary]? {
        var iterator: io_iterator_t = io_iterator_t()
        var obj: io_registry_entry_t = 1
        var list: [NSDictionary] = []
        
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching(name), &iterator)
        if result != kIOReturnSuccess {
            print("Error IOServiceGetMatchingServices(): " + (String(cString: mach_error_string(result), encoding: String.Encoding.ascii) ?? "unknown error"))
            return nil
        }
        
        while obj != 0 {
            obj = IOIteratorNext(iterator)
            if let props = getIOProperties(obj) {
                list.append(props)
            }
            IOObjectRelease(obj)
        }
        IOObjectRelease(iterator)
        
        return list.isEmpty ? nil : list
    }
}
