# Aware WiFi

[![CI Status](https://img.shields.io/travis/tetujin/com.awareframework.ios.sensor.wifi.svg?style=flat)](https://travis-ci.org/tetujin/com.awareframework.ios.sensor.wifi)
[![Version](https://img.shields.io/cocoapods/v/com.awareframework.ios.sensor.wifi.svg?style=flat)](https://cocoapods.org/pods/com.awareframework.ios.sensor.wifi)
[![License](https://img.shields.io/cocoapods/l/com.awareframework.ios.sensor.wifi.svg?style=flat)](https://cocoapods.org/pods/com.awareframework.ios.sensor.wifi)
[![Platform](https://img.shields.io/cocoapods/p/com.awareframework.ios.sensor.wifi.svg?style=flat)](https://cocoapods.org/pods/com.awareframework.ios.sensor.wifi)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

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

## Example usage

```swift
let wifiSensor = WifiSensor.init(WifiSensor.Config().apply{config in
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
class Observer:WifiObserver {
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
