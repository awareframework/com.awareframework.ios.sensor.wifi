//
//  Wifi.swift
//  com.aware.ios.sensor.wifi
//
//  Created by Yuuki Nishiyama on 2018/10/18.
//

import UIKit
import com_awareframework_ios_sensor_core
import Reachability
import NetworkExtension
import SystemConfiguration.CaptiveNetwork

extension Notification.Name {
    public static let actionAwareWiFiStart    = Notification.Name(WiFiSensor.ACTION_AWARE_WIFI_START)
    public static let actionAwareWiFiStop     = Notification.Name(WiFiSensor.ACTION_AWARE_WIFI_STOP)
    public static let actionAwareWiFiSync     = Notification.Name(WiFiSensor.ACTION_AWARE_WIFI_SYNC)
    public static let actionAwareWiFiSetLabel = Notification.Name(WiFiSensor.ACTION_AWARE_WIFI_SET_LABEL)
    
    public static let actionAwareWiFiCurrentAP   = Notification.Name(WiFiSensor.ACTION_AWARE_WIFI_CURRENT_AP)
    public static let actionAwareWiFiNewDevice   = Notification.Name(WiFiSensor.ACTION_AWARE_WIFI_NEW_DEVICE)
    public static let actionAwareWiFiScanStarted = Notification.Name(WiFiSensor.ACTION_AWARE_WIFI_SCAN_STARTED)
    public static let actionAwareWiFiScanEnded   = Notification.Name(WiFiSensor.ACTION_AWARE_WIFI_SCAN_ENDED)
}

public protocol WiFiObserver{
    func onWiFiAPDetected(data: WiFiScanData)
    func onWiFiDisabled()
    func onWiFiScanStarted()
    func onWiFiScanEnded()
}

public class WiFiSensor: AwareSensor {

    public static let TAG = "Aware::WiFi"
    
    /**
     * Received event: Fire it to start the WiFi sensor.
     */
    public static let ACTION_AWARE_WIFI_START = "com.aware.sensor.wifi.SENSOR_START"
    
    /**
     * Received event: Fire it to stop the WiFi sensor.
     */
    public static let ACTION_AWARE_WIFI_STOP = "com.aware.sensor.wifi.SENSOR_STOP"
    
    /**
     * Received event: Fire it to sync the data with the server.
     */
    public static let ACTION_AWARE_WIFI_SYNC = "com.aware.sensor.wifi.SYNC"
    
    /**
     * Received event: Fire it to set the data label.
     * Use [EXTRA_LABEL] to send the label string.
     */
    public static let ACTION_AWARE_WIFI_SET_LABEL = "com.aware.sensor.wifi.SET_LABEL"
    
    /**
     * Label string sent in the intent extra.
     */
    public static let EXTRA_LABEL = "label"
    
    /**
     * Fired event: currently connected to this AP
     */
    public static let ACTION_AWARE_WIFI_CURRENT_AP = "ACTION_AWARE_WIFI_CURRENT_AP"
    
    /**
     * Fired event: new WiFi AP device detected.
     * [WiFiSensor.EXTRA_DATA] contains the JSON version of the discovered device.
     */
    public static let ACTION_AWARE_WIFI_NEW_DEVICE = "ACTION_AWARE_WIFI_NEW_DEVICE"
    
    /**
     * Contains the JSON version of the discovered device.
     */
    public static let EXTRA_DATA = "data"
    
    /**
     * Fired event: WiFi scan started.
     */
    public static let ACTION_AWARE_WIFI_SCAN_STARTED = "ACTION_AWARE_WIFI_SCAN_STARTED"
    
    /**
     * Fired event: WiFi scan ended.
     */
    public static let ACTION_AWARE_WIFI_SCAN_ENDED = "ACTION_AWARE_WIFI_SCAN_ENDED"
    
    /**
     * Broadcast receiving event: request a WiFi scan
     */
    public static let ACTION_AWARE_WIFI_REQUEST_SCAN = "ACTION_AWARE_WIFI_REQUEST_SCAN"
    
    public var CONFIG = Config()
    
    let reachability = Reachability()
    
    var timer:Timer? = nil
    
    public class Config:SensorConfig{
      
        public var sensorObserver:WiFiObserver?
        
        public var interval: Int = 1 // min
        
        public override init() {
            super.init()
            self.dbPath = "aware_wifi"
        }
        
        public func apply(closure:(_ config:WiFiSensor.Config) -> Void ) -> Self {
            closure(self)
            return self
        }
    }
    
    public override convenience init(){
        self.init(WiFiSensor.Config())
    }
    
    public init(_ config:WiFiSensor.Config){
        super.init()
        CONFIG = config
        initializeDbEngine(config: config)
    }
    
    public override func start() {
        
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: Double(CONFIG.interval)*60.0, repeats: true, block: { timer in
                
                self.notificationCenter.post(name: .actionAwareWiFiScanStarted, object: nil)
                if let observer = self.CONFIG.sensorObserver{
                    observer.onWiFiScanStarted()
                }
                
                
                if let uwReachability = self.reachability{
                    if uwReachability.connection == .wifi {
                        let networkInfos = self.getNetworkInfos()
                        
                        for info in networkInfos{
                            // send a WiFiScanData via observer
                            let scanData = WiFiScanData.init()
                            scanData.ssid = info.ssid
                            scanData.bssid = info.bssid
                            
                            if let engine = self.dbEngine {
                                engine.save(scanData, WiFiScanData.TABLE_NAME)
                            }
                            if let wifiObserver = self.CONFIG.sensorObserver {
                                wifiObserver.onWiFiAPDetected(data: scanData)
                            }
                            self.notificationCenter.post(name: .actionAwareWiFiNewDevice,
                                                         object: nil,
                                                         userInfo: [WiFiSensor.EXTRA_DATA: scanData.toDictionary()])
                        }
                        
                        
                    }
                }
                
                
                Timer.scheduledTimer(withTimeInterval: 60, repeats: false, block: { timer in
                    self.notificationCenter.post(name: .actionAwareWiFiScanEnded, object: nil)
                    if let observer = self.CONFIG.sensorObserver{
                        observer.onWiFiScanEnded()
                    }
                })
            })
        }
        
        // start WiFi reachability/unreachable monitoring
        if let uwReachability = reachability{
            do{
                // reachable events
                uwReachability.whenReachable = { reachability in
                    switch reachability.connection {
                    case .wifi:
                        let networkInfos = self.getNetworkInfos()
                        for info in networkInfos{
                            // send a WiFiScanData via observer
                            let scanData = WiFiScanData.init()
                            scanData.ssid = info.ssid
                            scanData.bssid = info.bssid
                            if let observer = self.CONFIG.sensorObserver {
                                observer.onWiFiAPDetected(data: scanData)
                            }
                            // save a WiFiDeviceData info to the local-storage
                            if let engin = self.dbEngine {
                                let deviceData = WiFiDeviceData()
                                deviceData.bssid = scanData.bssid
                                deviceData.ssid = scanData.ssid
                                engin.save(deviceData,WiFiDeviceData.TABLE_NAME)
                                self.notificationCenter.post(name: .actionAwareWiFiCurrentAP,
                                                             object: nil,
                                                             userInfo: [WiFiSensor.EXTRA_DATA: deviceData.toDictionary()])
                            }
                        }
                        
                        break
                    case .cellular, .none:
                        if let observer = self.CONFIG.sensorObserver {
                            observer.onWiFiDisabled()
                        }
                        break
                    }
                }
                try uwReachability.startNotifier()
            } catch {
                print("\(WiFiSensor.TAG)\(error)")
            }
        }
        
        self.notificationCenter.post(name: .actionAwareWiFiStart, object:nil)
    }
    
    public override func stop() {
        
        if let uwTimer = timer {
            uwTimer.invalidate()
            timer = nil
        }
        
        if let uwReachability = reachability{
            uwReachability.stopNotifier()
        }
        
        self.notificationCenter.post(name: .actionAwareWiFiStop, object: nil)
    }
    
    public override func sync(force: Bool = false) {
        if let engine = self.dbEngine {
            let config = DbSyncConfig.init().apply{ config in
                config.debug = CONFIG.debug
            }
            engine.startSync(WiFiDeviceData.TABLE_NAME, WiFiDeviceData.self, config)
            engine.startSync(WiFiScanData.TABLE_NAME, WiFiScanData.self, config)
        }
        self.notificationCenter.post(name: .actionAwareWiFiSync, object: nil)
    }
    
    //////////////////////////////////
    
    struct NetworkInfo {
        public let interface:String
        public let ssid:String
        public let bssid:String
        init(_ interface:String, _ ssid:String,_ bssid:String) {
            self.interface = interface
            self.ssid = ssid
            self.bssid = bssid
        }
    }
    
    func getNetworkInfos() -> Array<NetworkInfo> {
        // https://forums.developer.apple.com/thread/50302
        guard let interfaceNames = CNCopySupportedInterfaces() as? [String] else {
            return []
        }
        let networkInfos:[NetworkInfo] = interfaceNames.compactMap{ name in
            guard let info = CNCopyCurrentNetworkInfo(name as CFString) as? [String:AnyObject] else {
                return nil
            }
            guard let ssid = info[kCNNetworkInfoKeySSID as String] as? String else {
                return nil
            }
            guard let bssid = info[kCNNetworkInfoKeyBSSID as String] as? String else {
                return nil
            }
            return NetworkInfo(name, ssid,bssid)
        }
        return networkInfos
    }
}
