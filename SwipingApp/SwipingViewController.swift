//
//  SwipingViewController.swift
//  SwipingApp
//
//  Created by Thijs Lucassen on 18-11-16.
//
//

import UIKit
import Alamofire
import MDCSwipeToChoose

class SwipingViewController: UIViewController, MDCSwipeToChooseDelegate {
    
    @IBOutlet weak var likeButton: UIButton!
    
    @IBAction func likeButtonTapped(_ sender: Any) {
        
    }
    
    var dict = Dictionary<String, Any>()
    var productImageURL = UIImageView()
    var allImages: [UIImage] = []

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func loadImageWith( completion:@escaping (_ image: [UIImage?]) -> Void) {
        
        let productQuery = dict["query"] as! String
        
        
        Alamofire.request("https://ceres-catalog.debijenkorf.nl/catalog/navigation/show?query=\(productQuery)").responseJSON { response in
            
            if let productJSON = response.result.value {
                
                let jsonDict = productJSON as! Dictionary<String, Any>
                let jsonData = jsonDict["data"] as! Dictionary<String, Any>
                let listOfProducts = jsonData["products"] as! [[String : AnyObject]]
                let productItem = listOfProducts[0]
                
                for everyItem in listOfProducts {
                    // Data into object
                    let currentVariantProduct = everyItem["currentVariantProduct"] as! Dictionary<String,Any>
                    
                    if let imageURL = currentVariantProduct["images"] as? [Dictionary<String,Any>] {
                        let imageProductURL = imageURL[0]
                        let frontImageURL = imageProductURL["url"] as! String
                        let httpURL = "https:\(frontImageURL)"
                        let url = URL(string: httpURL)
                        let data = try? Data(contentsOf: url!)
                        
                        var productImage : UIImage?
                        if data != nil {
                            productImage = UIImage(data:(data)!)
                        }
                        
                        self.allImages.append(productImage!)
                    
                    }
                }
                completion(self.allImages)
            }
            
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.loadImageWith { (allImages) in
        
        if allImages.count > 1 {
            
            let options = MDCSwipeToChooseViewOptions()
            options.delegate = self
            options.likedText = "Like"
            options.likedColor = UIColor.green
            options.nopeText = "Hide"
            options.onPan = { state -> Void in
                if state?.thresholdRatio == 1 && state?.direction == MDCSwipeDirection.left {
                    print("Photo Deleted!")
                    
                }
            }
            
            let view = MDCSwipeToChooseView(frame: self.view.bounds, options: options)
            view?.imageView.image = allImages[0]
            
            view?.imageView.contentMode = .scaleAspectFit
            view?.frame.size.height = 400;
//            view?.imageView.frame.insetBy(dx: 30, dy: 30)
//            view?.imageView.frame.size.width = 250;
//            view?.imageView.frame.size.height = 300;
            
            self.view.addSubview(view!)
            
            let viewTwo = MDCSwipeToChooseView(frame: self.view.bounds, options: options)
            viewTwo?.imageView.image = allImages[1]
            
            viewTwo?.imageView.contentMode = .scaleAspectFit
            viewTwo?.frame.size.height = 400;
//            viewTwo?.imageView.frame.size.width = 250;
//            viewTwo?.imageView.frame.size.height = 300;
            
            self.view.addSubview(viewTwo!)
            
            let viewThree = MDCSwipeToChooseView(frame: self.view.bounds, options: options)
            viewThree?.imageView.image = allImages[2]
            
            viewThree?.imageView.contentMode = .scaleAspectFit
            viewThree?.frame.size.height = 400;
//            viewThree?.imageView.frame.size.width = 250;
//            viewThree?.imageView.frame.size.height = 300;
            self.view.addSubview(viewThree!)
        }
    }
    }
    
    func viewDidCancelSwipe(_ view: UIView!) {
        print("couldn't decide, huh?")
    }
    
    func view(_ view: UIView!, shouldBeChosenWith direction: MDCSwipeDirection) -> Bool {
        if (direction == MDCSwipeDirection.left) {
            return true
        }else {
            UIView.animate(withDuration: 0.16, animations: { () -> Void in
                view.transform = CGAffineTransform.identity
                view.center = (view.superview?.center)!
            })
            return true
        }
    }
    func view(_ view: UIView!, wasChosenWith direction: MDCSwipeDirection) {
        if direction == MDCSwipeDirection.left {
            print("photo deleted!")
        }else {
            print("photo saved!")
        }
    }
    
}
