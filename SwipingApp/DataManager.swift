//
//  DataManager.swift
//  SwipingApp
//
//  Created by Thijs Lucassen on 17-11-16.
//
//

import Foundation
import Alamofire
import UIKit
import RealmSwift

let notificationName = Notification.Name("NotificationIdentifier")
let notificationQuery = Notification.Name("NotificationQuery")

class DataManager {
    
    static let sharedInstance = DataManager()
    let realm = try! Realm()
    lazy var realmProductArray: Results<RealmProduct> = { self.realm.objects(RealmProduct.self) }()
    var allProductCodes: RealmProduct!
    lazy var realmSeenProducts: Results<SeenProduct> = { self.realm.objects(SeenProduct.self) }()
    var seenProductCodes: SeenProduct!

    var productCodeArray: [String] = []

    
    // MARK - Get data for menu categories
    
    func getDataFromAPI () {
        
        Alamofire.request("https://ceres-catalog.debijenkorf.nl/catalog/navigation/tree?locale=nl_NL&excludeFields=refinementCount,selected,id,url,complete").responseJSON { response in
            
            if let JSON = response.result.value {
                let jsonDict = JSON as! Dictionary<String, Any>
                
                let jsonData = jsonDict["data"] as! Dictionary<String, Any>
                
                let jsonCat = jsonData["categories"] as! Dictionary<String, Any>
                
                NotificationCenter.default.post(name: notificationName, object: jsonCat)
            }
        }
    }
    
    // MARK - Get data for ChooseProductViewController
    
    func loadProductWith(dict: Dictionary<String,Any>, productCodeArray: [String] = [], completion:@escaping (_ product: [Product]) -> Void) {
        
        var allProducts: [Product] = []
        var imageURLArray: [UIImage] = []
        var filterTypeArray: [String] = []
        let productCategory = dict["name"] as? String
        
        if let productQuery = dict["query"] as? String {
            
            Alamofire.request("https://ceres-catalog.debijenkorf.nl/catalog/navigation/show?query=\(productQuery)").responseJSON { response in
                
                DispatchQueue.global(qos: .background).async {
                    
                    if let productJSON = response.result.value {
                        
                        let jsonDict = productJSON as! Dictionary<String, Any>
                        let jsonData = jsonDict["data"] as! Dictionary<String, Any>
                        let jsonQuery = jsonData["products"] as! [[String : AnyObject]]
                        let pageQuery = jsonData["pagination"] as! Dictionary<String, Any>
                        let nextPage = pageQuery["nextPage"] as! Dictionary<String, Any>
                        let nextPageQuery = nextPage["query"] as! String
                        let filters = jsonData["filters"] as! [[String: AnyObject]]
                        
                        for filterTypes in filters {
                            
                            let filterType = filterTypes["name"] as! String
                            if filterType == "Kleur" {
                                filterTypeArray.append(filterType)
                                //let refinementType = colorRef
                            }
                        }
                        
                        for item in jsonQuery {
                            
                            if let name = item["name"] as? String {
                                let brand = item["brand"] as? Dictionary<String,Any>
                                
                                if let productBrand = brand?["name"] as? String {
                                    
                                    let sellingPrice = item["sellingPrice"] as! Dictionary<String,Any>
                                    let productPrice = sellingPrice["value"] as! Double
                                    var productColor = " "
                                    let currentVariantProduct = item["currentVariantProduct"] as! Dictionary<String,Any>
                                    let productCode = currentVariantProduct["code"] as? String
                                    if let color = currentVariantProduct["color"] as? String {
                                        productColor = color }
                                    else {
                                        productColor = "onbekend" }
                                    if let imageURL = currentVariantProduct["images"] as? [Dictionary<String,Any>] {
                                        let imageProductURL = imageURL[0]
                                        let frontImageURL = imageProductURL["url"] as! String
                                        
                                        let httpURL = "https:\(frontImageURL)"
                                        let url = URL(string: httpURL)
                                        var data = try? Data(contentsOf: url!)
                                        
                                        let webListerString = httpURL.replacingOccurrences(of: "default", with: "web_lister_2x")
                                        let urlString = String(webListerString)
                                        var productImage : UIImage?
                                        data = try? Data(contentsOf: URL(string: urlString!)!)
                                        if data != nil {
                                            productImage = UIImage(data:(data)!)
                                            
                                            
                                            imageURLArray.append(productImage!)
                                        }
                                        
                                        let productImageString = urlString
                                        
                                        let newProduct = Product(productBrand: productBrand, productName: name, productPrice: Float(productPrice), productImage: productImage!, productCode: productCode!, productColor: productColor, productCategory: productCategory!, productImageString: productImageString!)
                                        
                                        allProducts.append(newProduct)
                                        self.productCodeArray.append(productCode!)
                                    }
                                }
                            }
                            DispatchQueue.main.async {
                                if allProducts.count == 2 {
                                    completion(allProducts)
                                }
                            }
                        }
                        DispatchQueue.main.async {
                            completion(allProducts)
                        }
                    }
                }
            }
        }
    }
    
    // MARK - Get data for detailviewcontroller
    
    func getProductsFromProductCodeAPI () {
        
        var allWishListProducts: [AnyObject] = []
        let productCodeQuery = WishList.sharedInstance.productCodeArray
        let productCodeString = productCodeQuery.joined(separator: ",")
        
        Alamofire.request("https://ceres-catalog.debijenkorf.nl/catalog/product/list?productCodes=\(productCodeString)").responseJSON { response in
            
            if let JSON = response.result.value {
                
                let jsonArray = JSON as! Dictionary<String, Any>
                let jsonData = jsonArray["data"] as! [[String : AnyObject]]
                
                for item in jsonData {
                    
                    let jsonProducts = item["product"] as! [String : AnyObject]
                    
                    let productName = jsonProducts["name"] as? String
                    let brand = jsonProducts["brand"] as? Dictionary<String,Any>
                    let productBrand = brand?["name"] as? String
                    
                    let currentVariantProduct = jsonProducts["currentVariantProduct"] as! Dictionary<String,Any>
                    let price = currentVariantProduct["sellingPrice"] as! Dictionary<String,Any>
                    let productPrice = price["value"] as! Float
                    let productCode = jsonProducts["code"] as? String
                    var productColor = ""
                    if let color = currentVariantProduct["color"] as? String {
                        productColor = color }
                    else {
                        productColor = "onbekend" }
                    
                    if let imageURL = currentVariantProduct["images"] as? [Dictionary<String,Any>] {
                        let imageProductURL = imageURL[0]
                        let frontImageURL = imageProductURL["url"] as! String
                        let httpURL = "https:\(frontImageURL)"
                        let webListerString = httpURL.replacingOccurrences(of: "default", with: "web_detail_2x")
                        let url = URL(string: webListerString)
                        let data = try? Data(contentsOf: url!)
                        var productImage : UIImage?
                        if data != nil {
                            productImage = UIImage(data:(data)!)
                        }
                        
                        let newWishListProduct = WishListProduct(productBrand: productBrand!, productName: productName!, productPrice: Float(productPrice), productImage: productImage!, productCode: productCode!, productColor: productColor)
                        
                        
                        allWishListProducts.append(newWishListProduct)
                    }
                }
                NotificationCenter.default.post(name: notificationQuery, object: allWishListProducts)
            }
            
        }
    }
    
    // MARK - DetailProduct
    
    func getDetailProductFromAPI (code: String, completion:@escaping (_ detailProduct: DetailProduct) -> Void) {
        
        var newDetailProduct : DetailProduct?
        var imageURLArray: [UIImage] = []
        
        Alamofire.request("https://ceres-catalog.debijenkorf.nl/catalog/product/list?productCodes=\(code)").responseJSON { response in
            
            if let JSON = response.result.value {
                
                let jsonArray = JSON as! Dictionary<String, Any>
                let jsonData = jsonArray["data"] as! [[String : AnyObject]]
                
                for item in jsonData {
                    var detailProductDescription = ""
                    let jsonProducts = item["product"] as! [String : AnyObject]
                    
                    let productName = jsonProducts["name"] as? String
                    if let description = jsonProducts["description"] as? String {
                        detailProductDescription = description }
                    else {
                        detailProductDescription = "Helaas is er geen beschrijving beschikbaar"
                    }
                    let brand = jsonProducts["brand"] as? Dictionary<String,Any>
                    let productBrand = brand?["name"] as? String
                    
                    let currentVariantProduct = jsonProducts["currentVariantProduct"] as! Dictionary<String,Any>
                    let price = currentVariantProduct["sellingPrice"] as! Dictionary<String,Any>
                    let productPrice = price["value"] as! Float
                    let productCode = jsonProducts["code"] as? String
                    var productColor = ""
                    if let color = currentVariantProduct["color"] as? String {
                        productColor = color }
                    else {
                        productColor = "onbekend" }
                    
                    if let imageURL = currentVariantProduct["images"] as? [Dictionary<String,Any>] {
                        
                        for i in imageURL {
                            
                            let url = i["url"] as! String
                            let httpsURL = "https:\(url)"
                            
                            let webListerString = httpsURL.replacingOccurrences(of: "default", with: "web_lister_2x")
                            
                            let urlString = URL(string: webListerString)
                            let data = try? Data(contentsOf: urlString!)
                            let detailProductImage = UIImage(data: (data)!)
                            
                            imageURLArray.append(detailProductImage!)
                        }
                        
                        let detailProductImages = imageURLArray
                        let productImage = imageURLArray[0]
                        
                        newDetailProduct = DetailProduct(productBrand: productBrand!, productName: productName!, productPrice: productPrice, productImage: productImage, productCode: productCode!, productColor: productColor, detailProductDescription: detailProductDescription, detailProductImages: detailProductImages)
                        
                    }
                }
                completion(newDetailProduct!)
            }
            
        }
    }
}

