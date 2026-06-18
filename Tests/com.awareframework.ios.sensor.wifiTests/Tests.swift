import XCTest
import com_awareframework_ios_sensor_wifi
import com_awareframework_ios_core

class Tests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testControllers(){

        let sensor = WiFiSensor.init(WiFiSensor.Config().apply{ config in
            config.debug = true
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
        XCTAssertEqual(wifiDeviceDict["macAddress"] as? String, "")
        XCTAssertEqual(wifiDeviceDict["bssid"] as? String, "")
        XCTAssertEqual(wifiDeviceDict["ssid"] as? String, "")

        let wifiScanDict = WiFiScanData().toDictionary()
        XCTAssertEqual(wifiScanDict["bssid"] as! String, "")
        XCTAssertEqual(wifiScanDict["ssid"] as! String, "")
        XCTAssertEqual(wifiScanDict["security"] as! String, "")
        XCTAssertEqual(wifiScanDict["frequency"] as! Int, 0)
        XCTAssertEqual(wifiScanDict["rssi"] as! Int, 0)
    }

    func testConfig(){
        let scanIntervalSeconds = 3.0
        let config: Dictionary<String,Any> = ["scanIntervalSeconds": scanIntervalSeconds]

        var sensor = WiFiSensor.init(WiFiSensor.Config(config))
        XCTAssertEqual(scanIntervalSeconds, sensor.CONFIG.scanIntervalSeconds)

        sensor = WiFiSensor.init(WiFiSensor.Config().apply { cfg in
            cfg.scanIntervalSeconds = scanIntervalSeconds
        })
        XCTAssertEqual(sensor.CONFIG.scanIntervalSeconds, scanIntervalSeconds)

        sensor = WiFiSensor.init()
        sensor.CONFIG.set(config: config)
        XCTAssertEqual(scanIntervalSeconds, sensor.CONFIG.scanIntervalSeconds)

        sensor.CONFIG.scanIntervalSeconds = -5
        XCTAssertEqual(sensor.CONFIG.scanIntervalSeconds, -5.0)
    }

    func testSyncModule(){
        #if targetEnvironment(simulator)

        print("This test requires a real WiFi.")

        #else
        // success //
        let sensor = WiFiSensor.init(WiFiSensor.Config().apply{ config in
            config.debug = true
            config.dbHost = "node.awareframework.com:1001"
            config.dbPath = "sync_db"
        })
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
        sensor2.sync(force: true)
        wait(for: [failureExpectation], timeout: 20)
        NotificationCenter.default.removeObserver(failureObserver)

        #endif
    }
}
