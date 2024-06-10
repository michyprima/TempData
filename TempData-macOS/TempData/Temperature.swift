//
//  Temperature.swift
//  TempData
//
//  Created by Michele Primavera on 11/12/23.
//

import Foundation

class Temperature {
    public var CPUHottest : Int = 0
    public var GPUHottest : Int = 0
    public var TotalPower : Int = 0
    
    public func update() {
        CPUHottest = getCPUHottestTemperature()
        GPUHottest = getGPUHottestTemperature()
        TotalPower = getSystemTotalPower()
    }
    
    func getCPUHottestTemperature() -> Int {
        let keys = [
            "Te05",
            "Te0L",
            "Te0P",
            "Te0S",
            "Tf04",
            "Tf09",
            "Tf0A",
            "Tf0B",
            "Tf0D",
            "Tf0E",
            "Tf44",
            "Tf49",
            "Tf4A",
            "Tf4B",
            "Tf4D",
            "Tf4E"
        ]
        
        var maxtemp : Double = -1
        
        for key in keys {
            let read = SMC.shared.getValue(key) ?? -1
            if(read > maxtemp) {
                maxtemp = read
            }
        }
        
        return Int(round(maxtemp))
    }
    
    func getGPUHottestTemperature() -> Int {
        let keys = [
            "Tf14",
            "Tf18",
            "Tf19",
            "Tf1A",
            "Tf24",
            "Tf28",
            "Tf29",
            "Tf2A"
        ]
        
        var maxtemp : Double = -1
        
        for key in keys {
            let read = SMC.shared.getValue(key) ?? -1
            if(read > maxtemp) {
                maxtemp = read
            }
        }
        
        return Int(round(maxtemp))
    }
    
    func getSystemTotalPower() -> Int {
        let read = SMC.shared.getValue("PSTR") ?? -1
        if read > 0 {
            return Int(round(read))
        }
        return 0
    }
}
