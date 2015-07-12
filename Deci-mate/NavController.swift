//
//  NavController.swift
//  Deci-mate
//
//  Created by Wilson Zhao on 7/12/15.
//  Copyright (c) 2015 Innogen. All rights reserved.
//
import Foundation
import UIKit

class NavController: UINavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureToolbar()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // #pragma mark - Navigation bar data source
    
    func configureToolbar() {
        var b = UIBarButtonItem(barButtonSystemItem: .Search, target: self, action: Selector("toggle"))

       // self.navigationItem.setRightBarButtonItem(UIBarButtonItem(barButtonSystemItem: .Search, target: self, action: "barButtonItemClicked:"), animated: true)
    }
    
    func toggle() {
        self.evo_drawerController?.openDrawerSide(.Left, animated: true, completion: nil)

    }
    func barButtonItemClicked(sender:AnyObject){
        self.evo_drawerController?.openDrawerSide(.Left, animated: true, completion: nil)
    }
    
  }