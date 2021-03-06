//
//  WifiData.swift
//  com.aware.ios.sensor.core
//
//  Created by Yuuki Nishiyama on 2018/10/18.
//

import UIKit
import RealmSwift
import com_awareframework_ios_sensor_core

public class WiFiDeviceData: AwareObject {
    
    public static var TABLE_NAME = "wifiDeviceData"
    
    @objc dynamic public var macAddress: String? = nil
    @objc dynamic public var bssid: String? = nil
    @objc dynamic public var ssid: String? = nil
    
    public override func toDictionary() -> Dictionary<String, Any> {
        var dict = super.toDictionary()
        dict["macAddress"] = macAddress
        dict["bssid"] = bssid
        dict["ssid"] = ssid
        return dict
    }
    
}
