//
//  ViewController.swift
//  com.awareframework.ios.sensor.wifi
//
//  Created by tetujin on 11/20/2018.
//  Copyright (c) 2018 tetujin. All rights reserved.
//

import UIKit
import com_awareframework_ios_sensor_wifi

class ViewController: UIViewController {

    var sensor:WiFiSensor?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        sensor = WiFiSensor.init(WiFiSensor.Config().apply{ config in
            config.debug = true
            config.sensorObserver = Observer()
        })
        sensor?.start()
    }

    class Observer:WiFiObserver{
        func onWiFiAPDetected(data: WiFiScanData) {
            print(#function)
        }
        
        func onWiFiDisabled() {
            print(#function)
        }
        
        func onWiFiScanStarted() {
            print(#function)
        }
        
        func onWiFiScanEnded() {
            print(#function)
        }
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

