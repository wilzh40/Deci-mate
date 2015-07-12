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

    @IBOutlet weak var graph: BEMSimpleLineGraphView!
    var graphArray:NSMutableArray = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let meter: AudioMeter = AudioMeter()
        meter.initAudioMeter()
        meter.delegate = self

        
        for index in 1...self.numberOfPointsInLineGraph(graph) {
            graphArray.addObject(70.0)
        }
        
        //setup graph
        graph.animationGraphStyle = BEMLineAnimation.None
        graph.enableReferenceAxisFrame = true
        graph.enableReferenceXAxisLines = true
        graph.enableReferenceYAxisLines = true
        graph.averageLine.enableAverageLine = true
        graph.averageLine.color = UIColor.redColor()
        //var timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "addValueToGraphArray", userInfo: nil, repeats: true)

        meter.changeAccumulatorTo(131072/32)  //16384; //32768; 65536; 131072;
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfPointsInLineGraph(graph: BEMSimpleLineGraphView) -> Int {
        return 100
    }
    
    //y values
    func lineGraph(graph: BEMSimpleLineGraphView, valueForPointAtIndex index: Int) -> CGFloat {
        let i = graphArray.count + index - self.numberOfPointsInLineGraph(graph)
        return graphArray.objectAtIndex(i) as! CGFloat
    }
    
    //x axis labels
    func lineGraph(graph: BEMSimpleLineGraphView, labelOnXAxisForIndex index: Int) -> String {
        let date = NSDate()
        let formatter = NSDateFormatter()
        formatter.timeStyle = .ShortStyle
        return formatter.stringFromDate(date)
    }

    func newDataValue(value: Float32) {
        if value == 0 {
            graphArray.addObject(70.0)
        } else {
            graphArray.addObject(CGFloat(value))
        }
        
        let newValue = AudioValue()
        newValue.power = value
        newValue.decibels = 20.0 * log10(value);
        
        graph.reloadGraph()
        graph.averageLine.yValue = CGFloat(graph.calculatePointValueAverage().floatValue)
    }

}

