import XCTest
import com_awareframework_ios_sensor_wifi
import com_awareframework_ios_sensor_core

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testControllers(){
        
        let sensor = WiFiSensor.init(WiFiSensor.Config().apply{ config in
            config.debug = true
            // config.dbType = .REALM
        })
        
        /// test set label action ///
        let expectSetLabel = expectation(description: "set label")
        let newLabel = "hello"
        let labelObserver = NotificationCenter.default.addObserver(forName: .actionAwareWiFiSetLabel, object: nil, queue: .main) { (notification) in
            let dict = notification.userInfo;
            if let d = dict as? Dictionary<String,String>{
                XCTAssertEqual(d[WiFiSensor.EXTRA_LABEL], newLabel)
            }else{
                XCTFail()
            }
            expectSetLabel.fulfill()
        }
        sensor.set(label:newLabel)
        wait(for: [expectSetLabel], timeout: 5)
        NotificationCenter.default.removeObserver(labelObserver)
        
        /// test sync action ////
        let expectSync = expectation(description: "sync")
        let syncObserver = NotificationCenter.default.addObserver(forName: Notification.Name.actionAwareWiFiSync , object: nil, queue: .main) { (notification) in
            expectSync.fulfill()
            print("sync")
        }
        sensor.sync()
        wait(for: [expectSync], timeout: 5)
        NotificationCenter.default.removeObserver(syncObserver)
        
        
//        #if targetEnvironment(simulator)
//
//        print("Controller tests (start and stop) require a real device.")
//
//        #else
        
        //// test start action ////
        let expectStart = expectation(description: "start")
        let observer = NotificationCenter.default.addObserver(forName: .actionAwareWiFiStart,
                                                              object: nil,
                                                              queue: .main) { (notification) in
                                                                expectStart.fulfill()
                                                                print("start")
        }
        sensor.start()
        wait(for: [expectStart], timeout: 5)
        NotificationCenter.default.removeObserver(observer)
        
        
        /// test stop action ////
        let expectStop = expectation(description: "stop")
        let stopObserver = NotificationCenter.default.addObserver(forName: .actionAwareWiFiStop, object: nil, queue: .main) { (notification) in
            expectStop.fulfill()
            print("stop")
        }
        sensor.stop()
        wait(for: [expectStop], timeout: 5)
        NotificationCenter.default.removeObserver(stopObserver)
        
//        #endif
    }
    
    func testWiFiData(){
        let wifiDeviceDict = WiFiDeviceData().toDictionary()
        XCTAssertNil(wifiDeviceDict["macAddress"])
        XCTAssertNil(wifiDeviceDict["bssid"])
        XCTAssertNil(wifiDeviceDict["ssid"])
        
        let wifiScanDict = WiFiScanData().toDictionary()
        XCTAssertEqual(wifiScanDict["bssid"] as! String, "")
        XCTAssertEqual(wifiScanDict["ssid"] as! String, "")
        XCTAssertEqual(wifiScanDict["security"] as! String, "")
        XCTAssertEqual(wifiScanDict["frequency"] as! Int, 0)
        XCTAssertEqual(wifiScanDict["rssi"] as! Int, 0)
    }
    
    func testConfig(){
        let interval = 3;
        let config :Dictionary<String,Any> = ["interval":interval]
        
        var sensor = WiFiSensor.init(WiFiSensor.Config(config));
        XCTAssertEqual(interval, sensor.CONFIG.interval)
        
        sensor = WiFiSensor.init(WiFiSensor.Config().apply{config in
            config.interval = interval
        });
        XCTAssertEqual(sensor.CONFIG.interval, interval)
        
        sensor = WiFiSensor.init()
        sensor.CONFIG.set(config: config)
        XCTAssertEqual(interval, sensor.CONFIG.interval)
        
        sensor.CONFIG.interval = -5
        XCTAssertEqual(sensor.CONFIG.interval, 1)
    }
    
    func testSyncModule(){
        #if targetEnvironment(simulator)
        
        print("This test requires a real WiFi.")
        
        #else
        // success //
        let sensor = WiFiSensor.init(WiFiSensor.Config().apply{ config in
            config.debug = true
            config.dbType = .REALM
            config.dbHost = "node.awareframework.com:1001"
            config.dbPath = "sync_db"
        })
        if let engine = sensor.dbEngine as? RealmEngine {
            engine.removeAll(WiFiScanData.self)
            for _ in 0..<100 {
                engine.save(WiFiScanData())
            }
        }
        let successExpectation = XCTestExpectation(description: "success sync")
        let observer = NotificationCenter.default.addObserver(forName: Notification.Name.actionAwareWiFiSyncCompletion,
                                                              object: sensor, queue: .main) { (notification) in
                                                                if let userInfo = notification.userInfo{
                                                                    if let status = userInfo["status"] as? Bool {
                                                                        if status == true {
                                                                            successExpectation.fulfill()
                                                                        }
                                                                    }
                                                                }
        }
        sensor.sync(force: true)
        wait(for: [successExpectation], timeout: 20)
        NotificationCenter.default.removeObserver(observer)
        
        ////////////////////////////////////
        
        // failure //
        let sensor2 = WiFiSensor.init(WiFiSensor.Config().apply{ config in
            config.debug = true
            config.dbType = .REALM
            config.dbHost = "node.awareframework.com.com" // wrong url
            config.dbPath = "sync_db"
        })
        let failureExpectation = XCTestExpectation(description: "failure sync")
        let failureObserver = NotificationCenter.default.addObserver(forName: Notification.Name.actionAwareWiFiSyncCompletion,
                                                                     object: sensor2, queue: .main) { (notification) in
                                                                        if let userInfo = notification.userInfo{
                                                                            if let status = userInfo["status"] as? Bool {
                                                                                if status == false {
                                                                                    failureExpectation.fulfill()
                                                                                }
                                                                            }
                                                                        }
        }
        if let engine = sensor2.dbEngine as? RealmEngine {
            engine.removeAll(WiFiScanData.self)
            for _ in 0..<100 {
                engine.save(WiFiScanData())
            }
        }
        sensor2.sync(force: true)
        wait(for: [failureExpectation], timeout: 20)
        NotificationCenter.default.removeObserver(failureObserver)
        
        #endif
    }
}
