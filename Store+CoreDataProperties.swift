//
//  Store+CoreDataProperties.swift
//  MyShoppingApp
//
//  Created by Jeff Norton on 8/22/16.
//  Copyright © 2016 JCN. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Store {

    @NSManaged var name: String
    @NSManaged var image: NSData
    @NSManaged var categories: NSOrderedSet
    @NSManaged var items: NSOrderedSet?

}
