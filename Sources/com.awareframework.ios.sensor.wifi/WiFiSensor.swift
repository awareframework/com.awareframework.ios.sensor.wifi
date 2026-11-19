//
//  Wifi.swift
//  com.aware.ios.sensor.wifi
//
//  Created by Yuuki Nishiyama on 2018/10/18.
//

import UIKit
import com_awareframework_ios_core
import NetworkExtension
import SystemConfiguration.CaptiveNetwork
import Network

extension Notification.Name {
    public static let actionAwareWiFiStart    = Notification.Name(WiFiSensor.ACTION_AWARE_WIFI_START)
    public static let actionAwareWiFiStop     = Notification.Name(WiFiSensor.ACTION_AWARE_WIFI_STOP)
    public static let actionAwareWiFiSync     = Notification.Name(WiFiSensor.ACTION_AWARE_WIFI_SYNC)
    public static let actionAwareWiFiSyncCompletion     = Notification.Name(WiFiSensor.ACTION_AWARE_WIFI_SYNC_COMPLETION)
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
    
    public static let ACTION_AWARE_WIFI_SYNC_COMPLETION = "com.awareframework.ios.sensor.wifi.SENSOR_SYNC_COMPLETION"
    public static let EXTRA_STATUS = "status"
    public static let EXTRA_ERROR = "error"
    public static let EXTRA_OBJECT_TYPE = "objectType"
    public static let EXTRA_TABLE_NAME = "tableName"
    
    public var CONFIG = Config()
    
    private var networkMonitor = NWPathMonitor()
    private var wifiMonitor = NWPathMonitor(requiredInterfaceType: .wifi)
    private var cellularMonitor = NWPathMonitor(requiredInterfaceType: .cellular)
    private let queue = DispatchQueue.global(qos: .background)
    /// Rows are written here, in the order the access points were found, off the main thread.
    /// `.utility`, since storing data is not work the user waits for.
    private let saveQueue = DispatchQueue(label: "com.awareframework.ios.sensor.wifi.save", qos: .utility)
    // 現在のネットワーク状態
    var isConnected: Bool = false
    var isWifiConnected: Bool = false
    var cellularConnected: Bool = false
    
    var timer:Timer? = nil
    
    public class Config:SensorConfig{
      
        public var sensorObserver:WiFiObserver?
        
        public var scanIntervalSeconds = 60.0
        
        public override init() {
            super.init()
            dbTableName = WiFiScanData.databaseTableName
            self.dbPath = "aware_wifi"
        }
        
        public func apply(closure:(_ config:WiFiSensor.Config) -> Void ) -> Self {
            closure(self)
            return self
        }
        
        public override func set(config: Dictionary<String, Any>) {
            super.set(config: config)
            if let scanIntervalSeconds = config["scanIntervalSeconds"] as? Double {
                self.scanIntervalSeconds = scanIntervalSeconds
            }
        }
    }
    
    public override convenience init(){
        self.init(WiFiSensor.Config())
    }
    

    /// Creates this sensor's tables if they do not exist yet, so that the first save does not fail.
    /// Failures are logged: without the tables, the data cannot be saved or uploaded.
    private func initializeTables() {
        guard CONFIG.dbType == .sqlite else { return }
        guard let queue = (dbEngine as? SQLiteEngine)?.getSQLiteInstance() else {
            print(WiFiSensor.TAG, "[Error] Cannot open the database '\(CONFIG.dbPath)'. The tables are not created.")
            return
        }
        let tables: [(name: String, create: () throws -> Void)] = [
            (WiFiScanData.databaseTableName, { try WiFiScanData.createTable(queue: queue) }),
            (WiFiDeviceData.databaseTableName, { try WiFiDeviceData.createTable(queue: queue) }),
        ]
        for table in tables {
            do {
                try table.create()
            } catch {
                print(WiFiSensor.TAG, "[Error] Cannot create the table '\(table.name)': \(error)")
            }
        }
    }

    public init(_ config:WiFiSensor.Config){
        super.init()
        CONFIG = config
        initializeDbEngine(config: config)
        initializeTables()
        super.syncConfig = DbSyncConfig().apply { c in
            c.dispatchQueue = DispatchQueue(label: "com.awareframework.ios.sensor.wifi.sync.queue")
        }
    }
    
    public override func start() {
        // NWPathMonitor cannot be reused after cancel(), so create fresh instances each time
        networkMonitor = NWPathMonitor()
        wifiMonitor = NWPathMonitor(requiredInterfaceType: .wifi)
        cellularMonitor = NWPathMonitor(requiredInterfaceType: .cellular)

        networkMonitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                self.isConnected = true
            }else{
                self.isConnected = false
            }
//            print("network:", self.isConnected)
        }
        networkMonitor.start(queue: queue)

        wifiMonitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                self.isWifiConnected = true
            }else{
                self.isWifiConnected = false
            }
//            print("wifi: ", self.isWifiConnected)
        }
        wifiMonitor.start(queue: queue)
        
        
        cellularMonitor.pathUpdateHandler = {path in
            if path.status == .satisfied {
                self.cellularConnected = true
            }else {
                self.cellularConnected = false
            }
//            print("cellular: ", self.cellularConnected)
        }
        cellularMonitor.start(queue: queue)
        
        
        if timer == nil {
            let scanBlock = { [weak self] in
                guard let self = self, self.isWifiConnected else { return }
                self.getNetworkInfos { [weak self] networkInfos in
                    guard let self = self else { return }
                    for info in networkInfos {
                        self.saveNetworkInfo(info)
                    }
                }
            }
            // Scan immediately on start, then on each interval
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { scanBlock() }
            timer = Timer.scheduledTimer(withTimeInterval: CONFIG.scanIntervalSeconds, repeats: true, block: { _ in
                scanBlock()
            })
        }
        
        self.notificationCenter.post(name: .actionAwareWiFiStart, object: self)
    }
    
    public override func stop() {
        
        if let uwTimer = timer {
            uwTimer.invalidate()
            timer = nil
        }
        
        self.wifiMonitor.cancel()
        self.cellularMonitor.cancel()
        self.networkMonitor.cancel()
        
        self.notificationCenter.post(name: .actionAwareWiFiStop, object: self)
    }
    
    
    
    /// The tables of this sensor, with the type of their rows (for the sync completion notification).
    static let tables: [(name: String, type: Any.Type)] = [
        (WiFiScanData.databaseTableName, WiFiScanData.self),
        (WiFiDeviceData.databaseTableName, WiFiDeviceData.self),
    ]

    /// One engine per table, used for upload. An engine uploads only the table named in its config,
    /// so each table needs its own engine. `dbEngine` is reused for the table it already names.
    /// (Up to now one engine was synced once per table, so only one table was ever uploaded.)
    var syncEngines: [String: Engine] = [:]

    private func syncEngine(for tableName: String) -> Engine? {
        if let engine = syncEngines[tableName] { return engine }
        let engine: Engine
        if let main = dbEngine, main.config.tableName == tableName {
            engine = main
        } else {
            engine = Engine.Builder()
                .setPath(CONFIG.dbPath)
                .setType(CONFIG.dbType)
                .setHost(CONFIG.dbHost)
                .setEncryptionKey(CONFIG.dbEncryptionKey)
                .setTableName(tableName)
                .build()
        }
        syncEngines[tableName] = engine
        return engine
    }

    public override func sync(force: Bool = false) {
        guard let base = self.syncConfig else { return }
        base.debug = self.CONFIG.debug
        for table in WiFiSensor.tables {
            // A copy per table, so that each table keeps its own completion handler and queue
            let c = base.copy()
            c.dispatchQueue = DispatchQueue(label: "com.awareframework.ios.sensor.wifi.sync.\(table.name)")
            c.completionHandler = { (status, error) in
                var userInfo: Dictionary<String,Any> = [WiFiSensor.EXTRA_STATUS: status,
                                                        WiFiSensor.EXTRA_TABLE_NAME: table.name,
                                                        WiFiSensor.EXTRA_OBJECT_TYPE: table.type]
                if let e = error { userInfo[WiFiSensor.EXTRA_ERROR] = e }
                self.notificationCenter.post(name: .actionAwareWiFiSyncCompletion, object: self, userInfo: userInfo)
            }
            syncEngine(for: table.name)?.startSync(c)
        }
        self.notificationCenter.post(name: .actionAwareWiFiSync, object: self)
    }
    
    //////////////////////////////////
    
    struct NetworkInfo {
        public let interface:String
        public let ssid:String
        public let bssid:String
        public let security:String
        init(_ interface:String, _ ssid:String, _ bssid:String, _ security:String = "") {
            self.interface = interface
            self.ssid = ssid
            self.bssid = bssid
            self.security = security
        }
    }
    
    private func saveNetworkInfo(_ info: NetworkInfo) {
        var scanData = WiFiScanData.init()
        scanData.timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        scanData.label = self.CONFIG.label
        scanData.ssid = info.ssid
        scanData.bssid = info.bssid
        scanData.security = info.security
        if let engine = self.dbEngine {
            saveQueue.async { engine.save([scanData]) }
        }
        // NEHotspotNetwork.fetchCurrent does not say which thread it calls back on: call the
        // observer and post the notifications on the main thread
        let notify = {
            if let wifiObserver = self.CONFIG.sensorObserver {
                wifiObserver.onWiFiAPDetected(data: scanData)
            }
            self.notificationCenter.post(name: .actionAwareWiFiCurrentAP,
                                         object: self,
                                         userInfo: [WiFiSensor.EXTRA_DATA: scanData.toDictionary()])
            self.notificationCenter.post(name: .actionAwareWiFiNewDevice,
                                         object: self,
                                         userInfo: [WiFiSensor.EXTRA_DATA: scanData.toDictionary()])
        }
        if Thread.isMainThread { notify() } else { DispatchQueue.main.async(execute: notify) }
    }

    func getNetworkInfos(completion: @escaping ([NetworkInfo]) -> Void) {
        if #available(iOS 14.0, *) {
            NEHotspotNetwork.fetchCurrent { network in
                guard let network = network else {
                    completion([])
                    return
                }
                let security: String
                if #available(iOS 15.0, *) {
                    security = self.securityTypeLabel(network.securityType)
                } else {
                    security = ""
                }
                completion([NetworkInfo("en0", network.ssid, network.bssid, security)])
            }
            return
        }
        completion(getLegacyNetworkInfos())
    }

    private func getLegacyNetworkInfos() -> Array<NetworkInfo> {
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

    @available(iOS 15.0, *)
    private func securityTypeLabel(_ securityType: NEHotspotNetworkSecurityType) -> String {
        switch securityType {
        case .open:
            return "open"
        case .WEP:
            return "wep"
        case .personal:
            return "personal"
        case .enterprise:
            return "enterprise"
        case .unknown:
            return "unknown"
        @unknown default:
            return "unknown"
        }
    }
    
    public override func set(label:String){
        self.CONFIG.label = label
        self.notificationCenter.post(name: .actionAwareWiFiSetLabel, object: self, userInfo: [WiFiSensor.EXTRA_LABEL:label])
    }
}
