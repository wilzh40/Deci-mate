//
//  ViewController.swift
//  Deci-mate
//
//  Created by Wilson Zhao on 7/11/15.
//  Copyright (c) 2015 Innogen. All rights reserved.
//

import UIKit

class ViewController: UIViewController, AudioMeterDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        let meter: AudioMeter = AudioMeter()
        meter.initAudioMeter()
        meter.changeAccumulatorTo(131072/8)  //16384; //32768; 65536; 131072;
        

        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func newDataValue(value: Float32) {
        // New value appears
    }


}

