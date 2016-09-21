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
    
    static let fontName = "Avenir Next"
    static let fontSize: CGFloat = 20.0
    
    static func initializeAppearanceDefaults() {
        
        // UINavigationBar
        
        let titleTextAttributes = [
            NSForegroundColorAttributeName: UIColor.whiteColor()
            , NSFontAttributeName: UIFont(name: AppearanceController.fontName, size: AppearanceController.fontSize)!
        ]
        
        UINavigationBar.appearance().barTintColor = .basicBlueColor()
        UINavigationBar.appearance().titleTextAttributes = titleTextAttributes
        UINavigationBar.appearance().tintColor = .whiteColor()
        
        // UIBarItem
        
        UIBarItem.appearance().setTitleTextAttributes(titleTextAttributes, forState: .Normal)
        
        // Toolbar
        
        UIToolbar.appearance().tintColor = UIColor.redColor()
        
        // TabBar
        
        UITabBar.appearance().barTintColor = .basicBlueColor()
        
        let unselectedTabBarTextColor = UIColor(red: 0.757, green: 0.757, blue: 0.757, alpha: 1.00)
        let selectedTabBarTextColor = UIColor.whiteColor()
        
        let unselectedTabBarAttributes = [NSFontAttributeName: UIFont(name: AppearanceController.fontName, size: AppearanceController.fontSize)!, NSForegroundColorAttributeName: unselectedTabBarTextColor]
        let selectedTabBarAttributes = [NSFontAttributeName: UIFont(name: AppearanceController.fontName, size: AppearanceController.fontSize)!, NSForegroundColorAttributeName: selectedTabBarTextColor]
        
        UITabBarItem.appearance().setTitleTextAttributes(unselectedTabBarAttributes, forState: .Normal)
        UITabBarItem.appearance().setTitleTextAttributes(selectedTabBarAttributes, forState: .Selected)
    }
}
