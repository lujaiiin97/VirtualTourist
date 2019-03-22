//
//  FlickrConstants.swift
//  VirtualTourist
//
//  Created by MAC on 26/01/2019.
//  Copyright © 2019 MAC. All rights reserved.
//

import Foundation

extension FlickrClient {

    static let SearchBBoxHalfWidth = 0.2
    static let SearchBBoxHalfHeight = 0.2
    static let SearchLatRange = (-90.0, 90.0)
    static let SearchLonRange = (-180.0, 180.0)
    
    
    struct FlickrConstants {

        static let ApiKey = "89683b20777c856ed2029089cf5c4836"
        static let ApiScheme = "https"
        static let ApiHost = "api.flickr.com"
        static let ApiPath = "/services/rest"
        
    }

     struct ParameterKeys {
        static let Method = "method"
        static let APIKey = "api_key"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
        static let Extras = "extras"
        static let SafeSearch = "safe_search"
        static let PhotosPerPage = "per_page"
        static let BoundingBox = "bbox"
        static let Page = "page"
        
    }
    
    struct ParameterValues {
        static let SearchMethod = "flickr.photos.search"
        static let APIKey = "89683b20777c856ed2029089cf5c4836"
        static let ResponseFormat = "json"
        static let DisableJSONCallback = "1"
        static let MediumURL = "url_m"
        static let UseSafeSearch = "1"
        static let PhotosPerPage = 30
        
    }
    
    
}
