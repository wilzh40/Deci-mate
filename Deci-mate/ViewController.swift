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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        AudioMeter().initAudioMeter()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfPointsInLineGraph(graph: BEMSimpleLineGraphView) -> Int {
        return 5
    }
    
    func lineGraph(graph: BEMSimpleLineGraphView, valueForPointAtIndex index: Int) -> CGFloat {
        return 5
    }
}

