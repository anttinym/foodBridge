//
//  ServerConnection.swift
//  Food Bridge
//
//  Created by iosdev on 26.4.2018.
//  Copyright © 2018 FoodBridge. All rights reserved.
//

import Foundation
import UIKit

class ServerConnection {
    
    static var baseApi = URL(string: "https://food-recycling.herokuapp.com")
    
    static var token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJfaWQiOiI1YWRlZDM4MmVhODI4YTAwMTRhODNkNGQiLCJhY2Nlc3MiOiJhdXRoIiwiaWF0IjoxNTI0NTkzMDg0fQ.Lmme7NRg7auKR_9KUud2Tx8jE_yYscxKPFhDo_DwioI"
    
    
    
    
    static func fetchFridges (callback: @escaping ([Fridge])->()){
        var fetchedFridges = [Fridge]()
        
        let url = (baseApi!.appendingPathComponent("/api/fridges"))
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "x-auth")
        
        
        
        let task = URLSession.shared.dataTask(with: request){ data, response, error in
            
            if let error = error {
                print ("error: \(error)")
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                print ("error can't parse response")
                fatalError()
            }
            
            if let mimeType = response.mimeType,
                mimeType == "application/json",
                let data = data,
                let dataString = String(data: data, encoding: .utf8) {
                print(dataString)
                let jsonresponse = try? JSONSerialization.jsonObject(with: data, options: [])
                if let fridges = jsonresponse as? [Any]{
                    for fridge in fridges {
                        var fridgeCounter = 0
                        if let fridgeData = fridge as? [String: Any]{
                            
                            guard let foods = fridgeData["posts"] as? [Any] else{
                                print("can't parse foods")
                                continue
                            }
                            
                            
                            
                            if foods.isEmpty{
                                print("empty fridge")
                                continue
                            }
                            
                            guard let description = fridgeData["description"] as? String else{
                                print ("can't parse description")
                                continue
                            }
                            
                            guard let name = fridgeData["name"] as? String else{
                                print ("can't parse name")
                                continue
                            }
                            
                            print("non empty")
                            
                            fridgeCounter += 1
                            
                            var foodInFridge = [Food]()
                            
                            var foodCounter = 0
                            
                            for food in foods {
                                if let foodData = food as? [String:Any]{
                                    guard let description = foodData["description"] as? String else {
                                        print("Can't parse food description")
                                        continue
                                    }
                                    print(description)
                                    
                                    guard let category = foodData["category"] as? String else {
                                        print("Can't parse food category")
                                        continue
                                    }
                                    print(category)
                                    
                                    guard let imgPath = foodData["imgPath"] as? String else {
                                        print("Can't parse food category")
                                        continue
                                    }
                                    
                                    foodCounter += 1
                                    
                                    func addFridge (image: UIImage){
                                        foodCounter -= 1
                                        foodInFridge.append(Food(picture: image, category: Category.Category1, description: description)!)
                                        if foodCounter == 0{
                                            fetchedFridges.append(Fridge(foods: foodInFridge, name: name, description: description))
                                            fridgeCounter -= 1
                                            if fridgeCounter == 0{
                                                DispatchQueue.main.async {
                                                    callback(fetchedFridges)
                                                }
                                            }
                                        }
                                    }
                                    
                                    downloadPhoto(path: imgPath, callback:addFridge)
                                }
                            }
                            
                            fetchedFridges.append(Fridge(foods: foodInFridge, name: name, description: description))
                        }
                    }
                }
            }
            
            
        }
        task.resume()
    }
    
    
    static func uploadFridge (fridge: Fridge, callback:@escaping ()->()){
        
        struct jsonData: Codable {
            let description: String
            let name: String
        }
        
        let data = jsonData(description: fridge.description, name: fridge.name)
        guard let uploadData = try? JSONEncoder().encode(data) else {
            print("can't encode json")
            return
        }
        
        let url = (baseApi!.appendingPathComponent("/api/fridges"))
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "x-auth")
        
        let task = URLSession.shared.uploadTask(with: request, from: uploadData) { data, response, error in
            
            if let error = error {
                print ("error: \(error)")
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                print ("error can't parse response")
                fatalError()
            }
            
            if let mimeType = response.mimeType,
                mimeType == "application/json",
                let data = data,
                let dataString = String(data: data, encoding: .utf8) {
                print(dataString)
                let jsonresponse = try? JSONSerialization.jsonObject(with: data, options: [])
                if let dictionary = jsonresponse as? [String:Any]{
                    if let fridgeID = dictionary["_id"] as? String{
                        uploadFoods(fridgeID: fridgeID)
                    }
                }
            }
            
        }
        task.resume()
        
        func uploadFoods(fridgeID: String){
            for food in fridge.foods {
                uploadFood(food: food, fridgeID: fridgeID)
            }
            DispatchQueue.main.async {
                callback()
            }
        }
    }
    
    private static func uploadFood (food: Food, fridgeID: String) {
        
        struct jsonData: Codable{
            let imgPath: String
            let category: String
            let price: Int
            let description: String
            let fridge: String
        }
        
        func callback (photoPath:String){
            print("got here")
            print(photoPath)
            
            let url = (baseApi!.appendingPathComponent("/api/posts"))
            print(url)
            let tempToken = token
            
            let data = jsonData(imgPath: photoPath, category: food.description, price: 10, description: food.description, fridge: fridgeID)
            
            guard let uploadData = try? JSONEncoder().encode(data) else {
                print("can't encode json")
                return
            }
            
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(tempToken, forHTTPHeaderField: "x-auth")
            
            let task = URLSession.shared.uploadTask(with: request, from: uploadData) { data, response, error in
                
                if let error = error {
                    print ("error: \(error)")
                    return
                }
                
                guard let response = response as? HTTPURLResponse else {
                    print ("error can't parse response")
                    fatalError()
                }
                
                print(response)
                
                print(String(data: data!, encoding: .utf8))
                
            }
            task.resume()
        }
        
        uploadPhoto(food.picture, callback: callback)
    }
    
    static func downloadPhoto(path: String, callback:@escaping (UIImage)->()) {
        let url = (baseApi!.appendingPathComponent("/photos/"+path))
        print (url)
        
        let task = URLSession.shared.dataTask(with: url) {data, response, error in
            if let error = error {
                print ("error: \(error)")
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                print ("error can't parse response")
                fatalError()
            }
            print (response)
            if response.statusCode == 200{
                print("image convertion")
                var image = UIImage(data: data!)
                callback(image!)
            }
        }
        task.resume()
    }
    
    private static func uploadPhoto (_ image:UIImage, callback:@escaping (String) -> ()){
        
        let url = (baseApi!.appendingPathComponent("/api/photos/upload"))
        print(url)
        let tempToken = token
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=---PleaseWork", forHTTPHeaderField: "Content-Type")
        request.setValue(tempToken, forHTTPHeaderField: "x-auth")
        let boundary = "---PleaseWork"
        func createBody(
            boundary: String,
            data: Data,
            mimeType: String,
            filename: String) -> Data {
            let body = NSMutableData()
            let boundaryPrefix = "--\(boundary)\r\n"
            body.appendString(boundaryPrefix)
            body.appendString("Content-Disposition: form-data; name=\"photo\"; filename=\"\(filename)\"\r\n")
            body.appendString("Content-Type: \(mimeType)\r\n\r\n")
            body.append(data)
            body.appendString("\r\n")
            body.appendString("--".appending(boundary.appending("--")))
            return body as Data
        }
        
        let httpBody = createBody(boundary: boundary,
                                  data: UIImageJPEGRepresentation(image, 0.7)!,
                                  mimeType: "image/jpg",
                                  filename: "hello.jpg")
        
        let task = URLSession.shared.uploadTask(with: request, from: httpBody) { data, response, error in
            if let error = error {
                print ("error: \(error)")
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                print ("error can't parse response")
                fatalError()
            }
            
            if let mimeType = response.mimeType,
                mimeType == "application/json",
                let data = data,
                let dataString = String(data: data, encoding: .utf8) {
                print(dataString)
                let jsonresponse = try? JSONSerialization.jsonObject(with: data, options: [])
                if let dictionary = jsonresponse as? [String:String]{
                    callback(dictionary["filename"]!)
                }
            }
        }
        task.resume()
    }
}

extension NSMutableData {
    func appendString(_ string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false)
        append(data!)
    }
}
