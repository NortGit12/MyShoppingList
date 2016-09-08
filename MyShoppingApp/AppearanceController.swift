//
//  AppearanceController.swift
//  MyShoppingApp
//
//  Created by Jeff Norton on 9/8/16.
//  Copyright © 2016 JCN. All rights reserved.
//

import UIKit

class AppearanceController {
    
    //==================================================
    // MARK: - Method(s)
    //==================================================
    
    static func initializeAppearanceDefaults() {
        
        // UINavigationBar
        
        let titleTextAttributes = [
            NSForegroundColorAttributeName: UIColor.whiteColor()
            , NSFontAttributeName: UIFont(name: "Avenir Next", size: 20.0)!
        ]
        
        UINavigationBar.appearance().barTintColor = .basicBlueColor()
        UINavigationBar.appearance().titleTextAttributes = titleTextAttributes
        UINavigationBar.appearance().tintColor = .whiteColor()
        
        // UIBarItem
        
        UIBarItem.appearance().setTitleTextAttributes(titleTextAttributes, forState: .Normal)
        
        // Toolbar
        
        UIToolbar.appearance().tintColor = UIColor.redColor()
        
        // TabBar
        
        UITabBar.appearance().backgroundColor = .purpleColor()
        UITabBar.appearance().tintColor = .whiteColor()
    }
}
