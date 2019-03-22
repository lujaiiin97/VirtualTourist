//
//  Extensions pin + photos.swift
//  VirtualTourist
//
//  Created by MAC on 26/01/2019.
//  Copyright © 2019 MAC. All rights reserved.
//

import Foundation
import CoreData


extension Pin {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
         date = Date()
    }
}

extension Photo {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        date = Date()
    }
    @NSManaged public var image: NSData?
    @NSManaged public var imageUrl: String?
    @NSManaged public var title: String?

}
