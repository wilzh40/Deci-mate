//
//  ViewController.swift
//  Deci-mate
//
//  Created by Wilson Zhao on 7/11/15.
//  Copyright (c) 2015 Innogen. All rights reserved.
//

import UIKit
import BEMSimpleLineGraph

class ViewController: UIViewController, BEMSimpleLineGraphDataSource, BEMSimpleLineGraphDelegate {

    @IBOutlet weak var graph: BEMSimpleLineGraphView!
    var graphArray:NSMutableArray = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let meter: AudioMeter = AudioMeter()
        meter.initAudioMeter()

        
        for index in 1...self.numberOfPointsInLineGraph(graph) {
            graphArray.addObject(CGFloat(random()))
        }
        
        //setup graph
        graph.animationGraphStyle = BEMLineAnimation.None
        graph.enableReferenceAxisFrame = true
        graph.enableReferenceXAxisLines = true
        graph.enableReferenceYAxisLines = true
        
        var timer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: "addValueToGraphArray", userInfo: nil, repeats: true)

        meter.changeAccumulatorTo(131072/8)  //16384; //32768; 65536; 131072;
        

        // Do any additional setup after loading the view, typically from a nib.
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
    
    func addValueToGraphArray() {
        graphArray.addObject(CGFloat(random()))
        graph.reloadGraph()
    }
    
    //x axis labels
    func lineGraph(graph: BEMSimpleLineGraphView, labelOnXAxisForIndex index: Int) -> String {
        return "temp"
    }
}

