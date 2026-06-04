import Foundation
import com_awareframework_ios_core
import GRDB

public struct WiFiScanData: BaseDbModelSQLite {
    public var id: Int64?
    public var timestamp: Int64 = 0
    public var deviceId: String = AwareUtils.getCommonDeviceId()
    public var label: String = ""
    public var timezone: Int = AwareUtils.getTimeZone()
    public var os: String = "iOS"
    public var jsonVersion: Int = 1
    public static let databaseTableName = "wifiScanData"

    public var bssid: String = ""
    public var ssid: String = ""
    public var security: String = ""
    public var frequency: Int = 0
    public var rssi: Int = 0

    public init() {}
    public init(_ dict: Dictionary<String, Any>) {
        timestamp = dict["timestamp"] as? Int64 ?? 0
        label     = dict["label"] as? String ?? ""
        deviceId  = dict["deviceId"] as? String ?? AwareUtils.getCommonDeviceId()
        bssid     = dict["bssid"] as? String ?? ""
        ssid      = dict["ssid"] as? String ?? ""
        security  = dict["security"] as? String ?? ""
        frequency = dict["frequency"] as? Int ?? 0
        rssi      = dict["rssi"] as? Int ?? 0
    }
    public static func createTable(queue: DatabaseQueue) throws {
        try queue.write { db in try db.create(table: databaseTableName, ifNotExists: true) { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("deviceId",.text).notNull(); t.column("timestamp",.integer).notNull()
            t.column("label",.text).notNull(); t.column("bssid",.text).notNull()
            t.column("timezone",.integer).notNull(); t.column("os",.text).notNull()
            t.column("jsonVersion",.integer).notNull()
            t.column("ssid",.text).notNull(); t.column("security",.text).notNull()
            t.column("frequency",.integer).notNull(); t.column("rssi",.integer).notNull()
        }}
    }
    public func toDictionary() -> Dictionary<String, Any> {
        ["id": id ?? -1, "timestamp": timestamp, "deviceId": deviceId, "label": label,
         "bssid": bssid, "ssid": ssid, "security": security,
         "frequency": frequency, "rssi": rssi]
    }
}
