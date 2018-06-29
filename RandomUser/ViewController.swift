//
//  ViewController.swift
//  RandomUser
//
//  Created by 林奕德 on 2018/4/6.
//  Copyright © 2018年 AppsAdamLin. All rights reserved.
//

import UIKit
import AudioToolbox
struct user {
    var name : String?
    var e_mail : String?
    var number :String?
    var image : String?//圖片網址
}

struct AllData:Decodable {
    var results:[SinglelData]?
    
}
struct SinglelData:Decodable {
    var name :Name?
    var email :String?
    var picture:picture?
    var phone:String?
}
struct Name :Decodable{
    var first:String?
    var last :String
}
struct picture :Decodable{
    var large :String
}

class ViewController: UIViewController {
    @IBOutlet weak var userImage: UIImageView!
    var isDownloading = false
    @IBAction func makeNewUser(_ sender: UIBarButtonItem) {
        if isDownloading == false{
            downloadInfo(withAddress: apiAddress)
        }
    }
    @IBOutlet weak var userName: UILabel!
    var infoTableViewController:InfoTableViewController?
    let apiAddress = "https://randomuser.me/api/"
    var urlSession = URLSession(configuration: .default)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
       //change navigation bar color
        navigationController?.navigationBar.barTintColor = UIColor(red: 0.67, green:0.2, blue: 0.157, alpha: 1)
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor:UIColor.white] //字典 型別 字體白
        
     //  let aUser = user(name: "wei wei", e_mail: "weiweie@yahoo.com", number: "888-8888", image: "http:picture.me")
       // settInfo(user: aUser)
        
        downloadInfo(withAddress: apiAddress)
    }
    
    func settInfo(user:user) {
        userName.text = user.name
        infoTableViewController?.phoneLable.text = user.number
        infoTableViewController?.emailLable.text = user.e_mail
        if let imageAddress =  user.image{
            if  let imageURL = URL(string: imageAddress){
                let task = urlSession.downloadTask(with: imageURL, completionHandler: {
                    (url,response,error) in
                    if error != nil {
                        DispatchQueue.main.async {
                             self.popAlert(withTitle: "Sorry")
                        }
                       self.isDownloading = false
                        return
                    }
                    if let okURL = url{
                        do {
                        let downloadImage = UIImage(data: try Data(contentsOf: okURL))
                            DispatchQueue.main.async {
                                self.userImage.image = downloadImage
                                AudioServicesPlaySystemSound(1000)
                            }
                             self.isDownloading = false
                        }catch{
                            DispatchQueue.main.async {
                                self.popAlert(withTitle: "Sorry")
                            }
                             self.isDownloading = false
                        }
                       
                    }else{
                         self.isDownloading = false
                    }
                })
                task.resume()
              
            }else{
               isDownloading = false
            }
        }else{
             self.isDownloading = false
        }
    }
    func downloadInfo(withAddress webAddress:String) {
        if let url = URL(string: webAddress){
            let task =  urlSession.dataTask(with: url, completionHandler: {
                (data,response,error)in
                if error != nil {
                   let errorCode = (error! as NSError).code
                    if errorCode == -1009{
                        DispatchQueue.main.async {
                            self.popAlert(withTitle: "No Internet connection")
                        }
                        
                    }else{
                        DispatchQueue.main.async {
                            self.popAlert(withTitle: "Sorry")
                        }
                    }
                     self.isDownloading = false
                    return
                }
                if let loadData = data{
                    do{
//                       let json = try JSONSerialization.jsonObject(with: loadData, options:[])
//                        DispatchQueue.main.async {
//                             self .parseJson(json: json)
//                        }
                        let okData = try JSONDecoder().decode(AllData.self, from: loadData) //loadData下載後的資料
                     let firstName =  okData.results?[0].name?.first
                     let lastName =  okData.results?[0].name?.last
                        let fullname:String? = {
                            guard let okFirstName = firstName , let okLastName = lastName else {return nil}
                            return okFirstName + "" + okLastName
                        }()
                        
                     let email =  okData.results?[0].email
                     let phone =   okData.results?[0].phone
                     let picture =   okData.results?[0].picture?.large
                        let aUser = user(name: firstName, e_mail: email, number: phone, image: picture)
                        DispatchQueue.main.async {
                            self.settInfo(user: aUser)
                        }
                    }catch{
                        DispatchQueue.main.async {
                            self.popAlert(withTitle: "Sorry")
                        }
                         self.isDownloading = false
                    }
                      }else{
                     self.isDownloading = false
                }
            })
            task.resume()
        }
      
    }
    func popAlert(withTitle title :String) {
      let alert = UIAlertController(title: title, message: "Please try again later", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "moreInfo"{
           infoTableViewController = segue.destination as? InfoTableViewController
            
        }
        
    }
    func parseJson(json:Any?) {
        if let okJson = json as?[String:Any]{//將資料看成字典 型別key為string 值為any
            if let infoArray = okJson["results"] as? [[String:Any]]{
             let infoDictionary =  infoArray[0]
             let loadName =  userFullName(nameDictionary: infoDictionary["name"])
             let loadEmail =  infoDictionary["email"] as? String
             let loadPhone = infoDictionary["phone"] as? String
             let imageDictionary = infoDictionary["picture"] as? [String:String]
             let loadImageAddress = imageDictionary?["large"]
               let loadUser = user(name: loadName, e_mail: loadEmail, number: loadPhone, image: loadImageAddress)
                settInfo(user: loadUser)//呼叫settInfo函式存入常數loadUser
            }
        }
    }
    func userFullName(nameDictionary:Any?) -> String? {
        if let okDictionary = nameDictionary as? [String:String]{
           let firstName = okDictionary["first"] ?? ""
            let lasttName = okDictionary["last"] ?? ""
            return firstName + "" + lasttName
        }else{
            return nil
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        //make user Image circle
        userImage.layer.cornerRadius = userImage.frame.size.width / 2 //cornerRadius 圓(角)半徑
        userImage.clipsToBounds = true //剪成圓形
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

