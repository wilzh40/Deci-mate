//
//  SettingsViewController .swift
//  Deci-mate
//
//  Created by Wilson Zhao on 7/12/15.
//  Copyright (c) 2015 Innogen. All rights reserved.
//

import Foundation
import UIKit
import XLForm

class SettingsViewController:  XLFormViewController, XLFormDescriptorDelegate {
    
    var centerVCRef: ViewController!
    
    override func viewDidLoad() {
        centerVCRef = self.evo_drawerController?.centerViewController!.childViewControllers[0] as! ViewController
        self.initializeForm()
        self.navigationController?.navigationBar.titleTextAttributes = [NSFontAttributeName:UIFont(name:"Futura",size:20.00)!]
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationController?.view.layoutSubviews()
    
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        
    }
    
    func initializeForm() {
        
        var form : XLFormDescriptor
        var section : XLFormSectionDescriptor
        var row : XLFormRowDescriptor
        
        form = XLFormDescriptor(title: "Settings") as XLFormDescriptor
        
        // User Account
        section = XLFormSectionDescriptor.formSectionWithTitle("Soundcloud Account") as XLFormSectionDescriptor
        
        form.addFormSection(section)
        
        // Display Duplicates?
        row = XLFormRowDescriptor(tag: "resetThreshold", rowType: XLFormRowDescriptorTypeBooleanSwitch, title: "Display Duplicates")
        row.cellConfig.setObject(UIFont(name:"Futura",size:15.00)!, forKey: "textLabel.font")
        row.value = true
        section.addFormRow(row)
        
        self.form = form


    }
}
