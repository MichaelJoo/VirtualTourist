//
//  VirtualTouristClient.swift
//  Virtual-Tourist
//
//  Created by Do Hyung Joo on 15/7/20.
//  Copyright © 2020 Do Hyung Joo. All rights reserved.
//

import Foundation
import CoreData

class VirtualTouristClient {
    
    var dataController: DataController = DataController(modelName: "Virtual_Tourist")
    
    
    enum Endpoints {
        
        case SearchFlickerPhotos
        
        var StringValue: String {
            switch self {
            
            case .SearchFlickerPhotos: return "https://www.flickr.com/services/api/flickr.photos.search.html"
            
            }
        }
        
        var url: URL {
            return URL(string: StringValue)!
        }
        
    }
    
    class func taskforFlickerPOSTRequest<RequestType: Encodable, ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, body: RequestType, completion: @escaping (ResponseType?, Error?) -> Void) {
        
        //Prepare URL Request Object - Why?
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        //Set HTTP Request Header - Why? is this neecessary? why do we set HTTPheader field? when is this necessary?
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        //Encoding a JSON body from a codable struct
        request.httpBody = try? JSONEncoder().encode(body)
        
        //why do we use this URLsession.shared? what purpose this line of code serve?
        let session = URLSession.shared
        
        //what does this line of code involving task serve, what do those components {data, response, error} serve? why are they always in the same pattern?
        let task = session.dataTask(with: request) { data, response, error in
            
            print("task completed")
            
            if error != nil {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            print(String(data: data!, encoding: .utf8)!)
    
            let decoder = JSONDecoder()
            
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data!)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                print(error)
                DispatchQueue.main.async {
                    completion(nil, error)
               }
                
            }
        
        }
        task.resume()
        
    }
    
    class func SearchPhoto (longitude: Double, Latitude: Double, _ completion: @escaping (_ success: Bool, _ error: String?) -> Void) {
        
        let pinData = Pin(context: dataController.viewContext)
        
        let URL = Endpoints.SearchFlickerPhotos.url
        let SearchRequest = SearchPhotoRequest(lat: <#T##Double#>, lon: <#T##Double#>)
        
       
        taskforFlickerPOSTRequest(url: URL, responseType: SearchPhotoResponse.self, body: SearchRequest) { response, error in
            
            if error == nil {
                completion(true, nil)
            } else {
                completion(false, nil)
            }
        }
    }
    
}
