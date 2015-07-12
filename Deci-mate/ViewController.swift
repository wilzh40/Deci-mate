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
import Alamofire
import SwiftyJSON

class ViewController: UIViewController, BEMSimpleLineGraphDataSource, BEMSimpleLineGraphDelegate, AudioMeterDelegate {
    
    @IBOutlet weak var weatherIcon: UIImageView!
    @IBOutlet weak var labelWeather: UILabel!
    @IBOutlet weak var labelPercent: UILabel!
    @IBOutlet weak var alertButton: UIButton!
    @IBOutlet weak var labelTimeLeft: UILabel!
    @IBOutlet weak var labelAverage: UILabel!
    @IBOutlet weak var graph: BEMSimpleLineGraphView!
    var graphArray: NSMutableArray = []
    var startTime: NSDate?
    
    var timeRange: NSTimeInterval = 3*60 ///in secs
    
    let topPadding: CGFloat = 200
    let bottomPadding: CGFloat = 10
    
    
    var hearingPercent: Float = 1
    var deltaTime: Double = 0.1 //rate percentage is updated
    var resetThreshold: Float = 75
    var vibrateTimer: NSTimer?
    var progress:KDCircularProgress!
    var weather:String?
    var safe: Bool = true
    var weatherIconUrl:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startTime = NSDate()
        
        limitReached()
        //AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        
        let value = AudioValue()
        value.decibels = 80.0
        graphArray.addObject(value)
        
        labelAverage.font = UIFont(name: "Futura", size: 12)
        labelPercent.font = UIFont(name: "Futura", size: 20)
        labelTimeLeft.font = UIFont(name: "Futura", size: 12)
        labelWeather.font = UIFont(name: "Futura", size: 20)
        
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
        progress = KDCircularProgress(frame: CGRect(x: bottomPadding, y: 0, width: view.frame.size.width - bottomPadding*2, height: view.frame.size.width-bottomPadding*2))
        progress.startAngle = 0
        progress.progressThickness = 0.2
        progress.trackThickness = 0.7
        progress.trackColor = UIColor.orangeColor()
        progress.clockwise = true
        progress.center = CGPointMake(view.center.x, view.frame.height - 170)
        progress.gradientRotateSpeed = 2
        progress.roundedCorners = true
        progress.glowMode = .Forward
        progress.angle = 0
        progress.setColors(UIColor.redColor())
        //progress.setColors(UIColor.whiteColor() ,UIColor.orangeColor(), UIColor.redColor())
        view.addSubview(progress)
        
        self.view.bringSubviewToFront(labelWeather)
        self.view.bringSubviewToFront(weatherIcon)
        self.view.bringSubviewToFront(labelAverage)
        self.view.bringSubviewToFront(alertButton)
        loadWeather()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfPointsInLineGraph(graph: BEMSimpleLineGraphView) -> Int {
        let num = 30
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
        
        // Update graph labels
        let x = CGFloat(graph.calculatePointValueAverage().floatValue)
        graph.averageLine.yValue = x
        if let a = labelAverage {
            a.text = "Average: \(Int(x)) dB"
            
        }
        
        // See if it's a safe level
        safe = (graph.calculatePointValueAverage().floatValue<resetThreshold) ? true : false
        
        
        if let b = labelPercent {
            let percent = CGFloat(hearingPercent*100)
            //let percent = ((CGFloat(hearingPercent*100)).description as NSString).substringToIndex(5)
            b.text = (String(format: "%.5f", percent)) + "%"
            //CGFloat(maxExposureTimeFordB(graph.calculatePointValueAverage().floatValue)).description
        }
        
        if let c = labelTimeLeft {
            if !safe {
                let seconds = maxExposureTimeFordB(graph.calculatePointValueAverage().floatValue)
                let (h, m, s) = secondsToHoursMinutesSeconds(Int(seconds))
                c.text =  ("\(h) Hours, \(m) Min, \(s) Sec")
            } else {
                c.text = "SAFE"
            }
        }
        
        
        // Delete everything older than a certain value
        for i in graphArray {
            let v: AudioValue = i as! AudioValue
            if v.time.timeIntervalSinceNow < -timeRange {
                graphArray.removeObject(i)
            }
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
        // NIOSH
        //return pow(2, ((94-db)/3)) * 60 * 60
        
        // OSHA
        return pow(2, ((105-db)/5)) * 60 * 60
        
    }
    func percentageLossPerSecond(db: Float32) -> Float32 {
        // Converting to seconds
        return 1/maxExposureTimeFordB(db)
    }
    
    func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
        //let (h, m, s) = secondsToHoursMinutesSeconds (seconds)
        //println ("\(h) Hours, \(m) Minutes, \(s) Seconds")
    }
    
    func limitReached() {
        //vibrate phone
        var timer =  NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: Selector("vibrate"), userInfo: nil, repeats: true)
        alertButton.hidden = false
        
        hearingPercent = 1
    }
    
    func vibrate() {
        //AudioServicesPlayAlertSound(UInt32(kSystemSoundID_Vibrate))
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        // AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
    @IBAction func alertButtonPressed(sender: AnyObject) {
        alertButton.hidden = true
        vibrateTimer?.invalidate()
    }
    
    func loadWeather() {
        let URL = "http://api.wunderground.com/api/262af78a0c11d0fb/conditions/q/CA/San_Francisco.json"
        Alamofire.request(.GET, URL)
            .responseSwiftyJSON ({ (request, response, responseJSON, error) in
                println(request)
                
                if error != nil {
                    println(error)
                } else {
                    self.weather = responseJSON["current_observation"]["feelslike_f"].string!
                    self.weatherIconUrl = responseJSON["current_observation"]["icon_url"].string!
                    self.labelWeather.text = self.weather! + "° F"
                    self.weatherIcon.image = UIImage(data: NSData(contentsOfURL: NSURL(string: self.weatherIconUrl!)!)!)
                }
            })
    }
}

