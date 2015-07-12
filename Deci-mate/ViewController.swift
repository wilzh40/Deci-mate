//
//  ViewController.swift
//  Deci-mate
//
//  Created by Wilson Zhao on 7/11/15.
//  Copyright (c) 2015 Innogen. All rights reserved.
//

import UIKit
import BEMSimpleLineGraph

class ViewController: UIViewController, BEMSimpleLineGraphDataSource, BEMSimpleLineGraphDelegate, AudioMeterDelegate {

    @IBOutlet weak var labelAverage: UILabel!
    @IBOutlet weak var graph: BEMSimpleLineGraphView!
    var graphArray: NSMutableArray = []
    var startTime: NSDate?
    var timeRange: NSTimeInterval = 3
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startTime = NSDate()
        
 
        
        let value = AudioValue()
        value.decibels = 80.0
        graphArray.addObject(value)
        
        labelAverage.font = UIFont(name: "Futura", size: 12)
        self.view.bringSubviewToFront(labelAverage)
        
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

        

        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfPointsInLineGraph(graph: BEMSimpleLineGraphView) -> Int {
        let num = 20
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
        
    }

}

