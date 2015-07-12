//
//  ViewController.swift
//  Deci-mate
//
//  Created by Wilson Zhao on 7/11/15.
//  Copyright (c) 2015 Innogen. All rights reserved.
//

import UIKit
import BEMSimpleLineGraph
import KDCircularProgress
import AudioToolbox

class ViewController: UIViewController, BEMSimpleLineGraphDataSource, BEMSimpleLineGraphDelegate, AudioMeterDelegate {
    
    @IBOutlet weak var alertButton: UIButton!
    @IBOutlet weak var labelTimeLeft: UILabel!
    @IBOutlet weak var labelAverage: UILabel!
    @IBOutlet weak var graph: BEMSimpleLineGraphView!
    var graphArray: NSMutableArray = []
    var startTime: NSDate?
    
    var timeRange: NSTimeInterval = 3*60 ///in secs


    var hearingPercent: Float = 1
    var deltaTime: Double = 0.1 //rate percentage is updated
    var resetThreshold: Float = 75
    var vibrateTimer: NSTimer?
    var progress:KDCircularProgress!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startTime = NSDate()

        
        //AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))

        let value = AudioValue()
        value.decibels = 80.0
        graphArray.addObject(value)
        
        labelAverage.font = UIFont(name: "Futura", size: 12)
        labelTimeLeft.font = UIFont(name: "Futura", size: 20)
        
        //setup graph
        graph.animationGraphStyle = BEMLineAnimation.None
        graph.enableReferenceAxisFrame = true
        graph.enableReferenceXAxisLines = true
        graph.enableReferenceYAxisLines = false
        graph.averageLine.enableAverageLine = true
        graph.averageLine.color = UIColor.redColor()
        graph.autoScaleYAxis = true
        graph.enableRightReferenceAxisFrameLine = true
        graph.enableTopReferenceAxisFrameLine = true
        graph.enableXAxisLabel = true
        graph.enableYAxisLabel = true
        graph.labelFont = UIFont(name: "Futura", size: 10)
        //var timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "addValueToGraphArray", userInfo: nil, repeats: true)
        
        // setup meter
        let meter: AudioMeter = AudioMeter()
        meter.initAudioMeter()
        meter.changeAccumulatorTo(131072/32)  //16384; //32768; 65536; 131072;
        meter.delegate = self
        var timer = NSTimer.scheduledTimerWithTimeInterval(deltaTime, target: self, selector: Selector("updatePercentage"), userInfo: nil, repeats: true)

        //setup progress view
        progress = KDCircularProgress(frame: CGRect(x: 0, y: 0, width: 225, height: 225))
        progress.startAngle = 0
        progress.progressThickness = 0.2
        progress.trackThickness = 0.7
        progress.trackColor = UIColor.orangeColor()
        progress.clockwise = true
        progress.center = CGPointMake(view.center.x, view.frame.height - 112)
        progress.gradientRotateSpeed = 2
        progress.roundedCorners = true
        progress.glowMode = .Forward
        progress.angle = 0
        progress.setColors(UIColor.redColor())
        //progress.setColors(UIColor.whiteColor() ,UIColor.orangeColor(), UIColor.redColor())
        view.addSubview(progress)
        
        
        
        self.view.bringSubviewToFront(labelAverage)
        self.view.bringSubviewToFront(alertButton)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfPointsInLineGraph(graph: BEMSimpleLineGraphView) -> Int {
        let num = 45
        if (graphArray.count < num) {
            return graphArray.count
        } else {
            return num
        }
    }
    
    //y values
    func lineGraph(graph: BEMSimpleLineGraphView, valueForPointAtIndex index: Int) -> CGFloat {
        let i = graphArray.count + index - self.numberOfPointsInLineGraph(graph)
        let value: AudioValue = graphArray[i] as! AudioValue
        if value.decibels > 120 {
            return 120.0
        } else {
            return CGFloat(value.decibels)
        }
    }
    
    //x axis labels
    func lineGraph(graph: BEMSimpleLineGraphView, labelOnXAxisForIndex index: Int) -> String {
        let i = graphArray.count + index - self.numberOfPointsInLineGraph(graph)
        let value: AudioValue = graphArray[i] as! AudioValue
        
        let formatter = NSDateFormatter()
        formatter.timeStyle = .MediumStyle
        return formatter.stringFromDate(value.time)
    }
    
    func numberOfGapsBetweenLabelsOnLineGraph(graph: BEMSimpleLineGraphView) -> Int {
        return 4
    }
    
    func numberOfYAxisLabelsOnLineGraph(graph: BEMSimpleLineGraphView) -> Int {
        return 10
    }
    
    func newDataValue(value: Float32) {
        let newValue = AudioValue()
        newValue.power = value
        newValue.decibels = 20.0 * log10(value) + 150;
        graphArray.addObject(newValue)
        graph.reloadGraph()
        let x = CGFloat(graph.calculatePointValueAverage().floatValue)
        graph.averageLine.yValue = x
        if let l = labelAverage {
            l.text = "Average: \(Int(x)) dB"
            
        }
        
        // Delete everything older than a certain value
        for i in graphArray {
            let v: AudioValue = i as! AudioValue
            if v.time.timeIntervalSinceNow < -timeRange {
                graphArray.removeObject(i)
            }
        }
        
        
        if let b = labelTimeLeft {
            let percent = CGFloat(hearingPercent*100)
            //let percent = ((CGFloat(hearingPercent*100)).description as NSString).substringToIndex(5)
            b.text = (String(format: "%.5f", percent)) + "%"
            //CGFloat(maxExposureTimeFordB(graph.calculatePointValueAverage().floatValue)).description
        }
        
    }
    
    func updatePercentage() {
        if graphArray.count > 2 {
            let db = graph.calculatePointValueAverage().floatValue
            hearingPercent -= (percentageLossPerSecond(db) * Float(deltaTime))
            
            
            if db < resetThreshold {
                // Reset it once it reaches a certain threshold
                hearingPercent = 1
            }
            if hearingPercent <= 0.0 {
                self.limitReached()
            }
            
            // set Progress
            progress.angle = Int(hearingPercent*360)
                
            let alpha = CGFloat(1-hearingPercent)*0.5 + 0.5
                
            progress.setColors(UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: alpha))
            
        }
        
    }
    
    func maxExposureTimeFordB(db: Float32) -> Float32 {
        // In Seconds
        return pow(2, ((94-db)/3)) * 60 * 60
    }
    func percentageLossPerSecond(db: Float32) -> Float32 {
        // Converting to seconds
        return 1/maxExposureTimeFordB(db)
    }
    
    func limitReached() {
        //vibrate phone
        vibrateTimer = NSTimer(timeInterval: 1, target: self, selector: "vibrate", userInfo: nil, repeats: true)
        alertButton.hidden = false
        hearingPercent = 1
    }
    
    func vibrate () {
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
    @IBAction func alertButtonPressed(sender: AnyObject) {
        alertButton.hidden = true
        vibrateTimer?.invalidate()
    }
    
}

