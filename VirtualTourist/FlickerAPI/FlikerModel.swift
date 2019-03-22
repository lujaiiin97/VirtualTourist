//
//  FlikerModel.swift
//  VirtualTourist
//
//  Created by MAC on 26/01/2019.
//  Copyright © 2019 MAC. All rights reserved.
//

import Foundation
struct FlikerResbonse : Codable {
    let photos : Photos
    let stat : String
    
}

struct Photos : Codable {
    let perpage : Int
    let photo : [PhotoParse]
    
}

struct PhotoParse : Codable {
    let id : String
    let url_m : String
    
}
