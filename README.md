# AWARE: WiFi

[![CI rtatus](https://img.shields.io/travis/awareframework/com.awareframework.ios.sensor.wifi.svg?style=flat)](https://travis-ci.org/awareframework/com.awareframework.ios.sensor.wifi)
[![Version](https://img.shields.io/cocoapods/v/com.awareframework.ios.sensor.wifi.svg?style=flat)](https://cocoapods.org/pods/com.awareframework.ios.sensor.wifi)
[![License](https://img.shields.io/cocoapods/l/com.awareframework.ios.sensor.wifi.svg?style=flat)](https://cocoapods.org/pods/com.awareframework.ios.sensor.wifi)
[![Platform](https://img.shields.io/cocoapods/p/com.awareframework.ios.sensor.wifi.svg?style=flat)](https://cocoapods.org/pods/com.awareframework.ios.sensor.wifi)

This sensor allows us to handle WiFi conditions and events.

## Requirements
iOS 10 or later

## Installation

com.awareframework.ios.sensor.wifi is available through [CocoaPods](https://cocoapods.org). 

1. To install it, simply add the following line to your Podfile:

```ruby
pod 'com.awareframework.ios.sensor.wifi'
```

2. Import com.awareframework.ios.sensor.wifi library into your source code.
```swift
import com_awareframework_ios_sensor_wifi
```

3. Turn ON `Access WiFi Information` capability on the Xcode project

## Public functions

### WifiSensor

* `init(config:WiFiSensor.Config?)` : Initializes the WiFi sensor with the optional configuration.
* `start()`: Starts the WiFi sensor with the optional configuration.
* `stop()`: Stops the service.


### WifiSensor.Config

Class to hold the configuration of the sensor.

#### Fields

+ `sensorObserver: WiFiObserver`: Callback for live data updates.
+ `enabled: Boolean` Sensor is enabled or not. (default = `false`)
+ `debug: Boolean` enable/disable logging to `Logcat`. (default = `false`)
+ `label: String` Label for the data. (default = "")
+ `deviceId: String` Id of the device that will be associated with the events and the sensor. (default = "")
+ `dbEncryptionKey` Encryption key for the database. (default = `null`)
+ `dbType: Engine` Which db engine to use for saving data. (default = `Engine.DatabaseType.NONE`)
+ `dbPath: String` Path of the database. (default = "aware_wifi")
+ `dbHost: String` Host for syncing the database. (default = `null`)

## Broadcasts

+ `WiFiSensor.ACTION_AWARE_WIFI_CURRENT_AP` currently connected to this AP. In the extras, `WiFiSensor.EXTRA_DATA` includes the WiFiData in json string format.
+ `WiFiSensor.ACTION_AWARE_WIFI_NEW_DEVICE` new WiFi AP device detected. In the extras, `WiFiSensor.EXTRA_DATA` includes the WiFiData in json string format.
+ `WiFiSensor.ACTION_AWARE_WIFI_SCAN_STARTED` WiFi scan started
+ `WiFiSensor.ACTION_AWARE_WIFI_SCAN_ENDED` WiFi scan ended.

## Data Representations

### WiFi Scan Data

| Field     | Type   | Description                                                     |
| --------- | ------ | --------------------------------------------------------------- |
| bssid     | String | currently connected access point MAC address                    |
| ssid      | String | currently connected access point network name                   |
| deviceId  | String | AWARE device UUID                                               |
| label     | String | Customizable label. Useful for data calibration or traceability |
| timestamp | Long   | Unixtime milliseconds since 1970                                |
| timezone  | Int    | WiFi of the device                                              |
| os        | String | Operating system of the device (ex. android)                    |

## Example usage

```swift
let wifiSensor = WiFiSensor.init(WifiSensor.Config().apply{config in
    config.sensorObserver = Observer()
    config.dbType = .REALM
    config.debug = true
    // more configuration ...
})
// To start the sensor
wifiSensor.start()

// To stop the sensor
wifiSensor.stop()
```

```swift
// Implement an interface of WifiObserver
class Observer:WiFiObserver {
    func onWiFiAPDetected(data: WiFiScanData) {
        // Your code here ..
    }

    func onWiFiDisabled() {
        // Your code here ..
    }

    func onWiFiScanStarted() {
        // Your code here ..
    }

    func onWiFiScanEnded() {
        // Your code here ..
    }
}
```

## License

Copyright (c) 2018 AWARE Mobile Context Instrumentation Middleware/Framework (http://www.awareframework.com)

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
