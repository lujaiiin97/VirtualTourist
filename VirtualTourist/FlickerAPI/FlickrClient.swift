//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by MAC on 26/01/2019.
//  Copyright © 2019 MAC. All rights reserved.
//

import Foundation
import UIKit


class FlickrClient : NSObject {
    var session = URLSession.shared
    override init() {
        super.init()
    }
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }
    func BoundingBoxString(latitude: Double, longitude: Double) -> String {
        
        let minimumLon = max(longitude - FlickrClient.SearchBBoxHalfWidth, FlickrClient.SearchLonRange.0)
        let minimumLat = max(latitude  - FlickrClient.SearchBBoxHalfHeight, FlickrClient.SearchLatRange.0)
        let maximumLon = min(longitude + FlickrClient.SearchBBoxHalfWidth, FlickrClient.SearchLonRange.1)
        let maximumLat = min(latitude  + FlickrClient.SearchBBoxHalfHeight, FlickrClient.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    
    private func convertDataWithCompletionHandler<D: Decodable>(_ data: Data,decode:D.Type, completionHandlerForConvertData: (_ result: AnyObject?, _ error: NSError?) -> Void) {
        
        
        do {
            let obj = try JSONDecoder().decode(decode, from: data)
            completionHandlerForConvertData(obj as AnyObject, nil)
            
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
    }
    
    func taskForGETMethod<D: Decodable>(parameters: [String:AnyObject],decode:D.Type, completionHandlerForGET: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        
        var parametersWithApiKey = parameters
        var request = NSMutableURLRequest(url: tmdbURLFromParameters(parametersWithApiKey))
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForGET(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            guard (error == nil)
                else {
                    sendError("\(error!.localizedDescription)")
                    return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            self.convertDataWithCompletionHandler(data, decode:decode,completionHandlerForConvertData: completionHandlerForGET)
            
        }
        
        task.resume()
        return task
        
    }
    
    private func tmdbURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = FlickrClient.FlickrConstants.ApiScheme
        components.host = FlickrClient.FlickrConstants.ApiHost
        components.path = FlickrClient.FlickrConstants.ApiPath
        
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
            
        }
        
        let url = components.url!
        return url
    }
}

extension FlickrClient {
    
    func downloadImage(url:URL, completion: @escaping (_ data: Data?,_ error: Error?) -> Void){
        let dataTask = URLSession.shared.dataTask(with: url) { data, response, error in
            if error == nil {
                if let data = data {
                    completion(data,nil)
                }
            }else {
                completion(nil,error)
            }
        }
        dataTask.resume()
    }
    
    
    func FlickerPhotos(latitude:Double ,longitude:Double, totalPages: Int?, _ completionHandlerForFlickerPhoto: @escaping (_ success: Bool,_ photoData: [Any]?,_   :String?, _ errorString: String? , _ result: Data?) -> Void) {
        
        var page: Int {
            if let totalPages = totalPages {
                let page = min(totalPages, 4000, FlickrClient.ParameterValues.PhotosPerPage)
                return Int(arc4random_uniform(UInt32(page)) + 1)
            }
            return 1
        }
        let bBox = self.BoundingBoxString(latitude: latitude, longitude: longitude)
        
        
        let parameters = [
            FlickrClient.ParameterKeys.Method           : FlickrClient.ParameterValues.SearchMethod
            , FlickrClient.ParameterKeys.APIKey         : FlickrClient.ParameterValues.APIKey
            , FlickrClient.ParameterKeys.Format         : FlickrClient.ParameterValues.ResponseFormat
            , FlickrClient.ParameterKeys.Extras         : FlickrClient.ParameterValues.MediumURL
            , FlickrClient.ParameterKeys.NoJSONCallback : FlickrClient.ParameterValues.DisableJSONCallback
            , FlickrClient.ParameterKeys.SafeSearch     : FlickrClient.ParameterValues.UseSafeSearch
            , FlickrClient.ParameterKeys.BoundingBox    : bBox
            , FlickrClient.ParameterKeys.PhotosPerPage  : FlickrClient.ParameterValues.PhotosPerPage
            , FlickrClient.ParameterKeys.Page           : "\(page)"
            ] as [String : Any]
        
        
        
        _ = taskForGETMethod( parameters: parameters as [String : AnyObject] , decode: FlikerResbonse.self) { (result, error) in
            if let error = error {
                completionHandlerForFlickerPhoto(false ,nil ,nil,"\(error.localizedDescription)",nil)
            }else {
                let newResult = result as! FlikerResbonse
                let result = newResult.photos.photo
                if newResult.photos.photo.isEmpty {
                    
                    let noPhoto = "This pin has no images!"
                    
                    completionHandlerForFlickerPhoto(true ,nil ,noPhoto,nil,nil)
                } else {
                    completionHandlerForFlickerPhoto(true ,result,nil,nil,nil)
                    
                }
                
            }
        }
        
    }
}
