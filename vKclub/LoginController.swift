//
//  LoginController.swift
//  vKclub
//
//  Created by HuySophanna on 30/5/17.
//  Copyright © 2017 HuySophanna. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseAuth
import FBSDKLoginKit
import CoreData
class LoginController: UIViewController,UITextFieldDelegate {
    let personService = UserProfileCoreData()
    @IBOutlet weak var pwTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var signInBtn: UIButton!
    @IBOutlet weak var signInFBBtn: UIButton!
    let User = UserProfile(context: manageObjectContext)
}

//  APP LIFE CYCLE
extension LoginController {
    override func viewDidLoad() {
        usetoLogin = false
        hideKeyboardWhenTappedAround()
        UIComponentHelper.PresentActivityIndicator(view: self.view, option: false)
        BtnUI()
        TextField()
        signInFBBtn.addTarget(self, action: #selector(FBSignIn), for: .touchUpInside)
        
    }
}

// APP UI
extension LoginController {
   func vlidationDeviceInuseAlert(){
        self.PresentAlertController(title: "Warning", message: "You can not use one account with two devices.You had chooiced the new device", actionTitle: "Okay")
    }
    func BtnUI() {
        UIComponentHelper.MakeBtnWhiteBorder(button: signInBtn, color: UIColor.white)
        MakeFBBorderBtn(button: signInFBBtn)
        
    }
    
    func TextField() {
        MakeLeftViewIconToTextField(textField: emailTextField, icon: "user_left_icon")
        MakeLeftViewIconToTextField(textField: pwTextField, icon: "pw_icon")
        self.emailTextField.delegate = self
        self.pwTextField.delegate = self
    }
    
    func MakeFBBorderBtn(button: UIButton) {
        button.backgroundColor = UIColor(red:0.23, green:0.35, blue:0.60, alpha:1.0)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor(red:0.23, green:0.35, blue:0.60, alpha:1.0).cgColor
        button.layer.cornerRadius = 5
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case self.emailTextField:
            pwTextField.becomeFirstResponder()
        default:
            pwTextField.resignFirstResponder()
            self.SignInClicked(self)
        }
        return true
    }
    
    func MakeLeftViewIconToTextField(textField: UITextField, icon: String) {
        let imageView = UIImageView();
        let image = UIImage(named: icon);
        imageView.image = image;
        imageView.frame = CGRect(x: Int(textField.frame.height / 3), y: Int(textField.frame.height / 3), width: Int(textField.frame.height / 2.5), height: Int(textField.frame.height / 2.5))
        textField.addSubview(imageView)
        let leftView = UIView.init(frame: CGRect(x: 10, y: 10, width: textField.frame.height, height: 25))
        textField.leftView = leftView;
        textField.leftViewMode = UITextFieldViewMode.always
        
    }
}

// APP Button Action

extension LoginController {
    
    func FBSignIn(){
        iflogoutforfirebase = false
        InternetConnection.second = 0
        InternetConnection.countTimer.invalidate()
        UIComponentHelper.PresentActivityIndicator(view: self.view, option: true)
        let fbLoginManager = FBSDKLoginManager()
        fbLoginManager.logIn(withReadPermissions: ["public_profile", "email"], from: self) { (result, error) in
            if error != nil {
                UIComponentHelper.PresentActivityIndicator(view: self.view, option: false)
                self.PresentAlertController(title: "Error", message: "Invail login ,Please try again later", actionTitle: "Okay")
                print("eroor", error!)
            } else if (result?.isCancelled)! {
                UIComponentHelper.PresentActivityIndicator(view: self.view, option: false)
                print("Facebook Cancelled")
            } else {
                guard let accessToken = FBSDKAccessToken.current() else {
                    UIComponentHelper.PresentActivityIndicator(view: self.view, option: false)
                    print("Failed to get access token")
                    return
                }
                InternetConnection.CountTimer()
                let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.tokenString)
                Auth.auth().signIn(with: credential, completion: { (user, error) in
                    if InternetConnection.second == 15 {
                        InternetConnection.countTimer.invalidate()
                        InternetConnection.second = 0
                        UIComponentHelper.PresentActivityIndicator(view: self.view, option: false)
                        return
                    }
                    if error == nil {
                        InternetConnection.countTimer.invalidate()
                        InternetConnection.second = 0
                        if let currentUser = Auth.auth().currentUser {
                            var getFBimageUrl  : URL = currentUser.photoURL!
                            let str = currentUser.photoURL?.absoluteString
                            let index = str?.index((str?.startIndex)!, offsetBy: 30)
                            let url : String = (str?.substring(to: index!))!
                            let fbphotourl:String = "https://scontent.xx.fbcdn.net/"
                            if url == fbphotourl {
                                let urlphoto: String = "https://graph.facebook.com/"
                                let picturelink:String = "/picture?width=320&height=320"
                                let FBImageUrl : String = urlphoto+FBSDKAccessToken.current().userID+picturelink
                                getFBimageUrl = URL(string:FBImageUrl)!
                            }
                            let chageProfileuser = currentUser.createProfileChangeRequest()
                            chageProfileuser.photoURL = getFBimageUrl
                            chageProfileuser.commitChanges { (error) in
                                
                            }
                            self.getDataFromUrl(url: getFBimageUrl){
                                (data, response, error)  in
                                guard let data = data, error == nil
                                    else {
                                        return
                                }
                                let image = data as NSData?
                                
                                
                                guard let imageFB = UIImage(data: image! as Data) else {
                                    return
                                }
                                let newimag = UIComponentHelper.resizeImage(image: imageFB, targetSize: CGSize(width: 400, height: 400))
                                let imageProfiles = UIImagePNGRepresentation(newimag)
                                if (currentUser.email == nil){
                                    UIComponentHelper.PresentActivityIndicator(view: self.view, option: false)
                                    self.create(username: (currentUser.displayName)!,email: "someone@gamil.com",facebook: true, imagData: imageProfiles! as NSData)
                                } else {
                                    self.create(username: (user?.displayName)!,email: (user?.email)!,facebook: true, imagData: imageProfiles! as NSData)
                                }
                            }
                            self.validation(uid : (Auth.auth().currentUser?.uid)!)
                            

                           
                            //self.performSegue(withIdentifier: "SegueToDashboard", sender: self)
                        }
                        
                        //                           LinphoneManager.enableRegistration()
                        
                        
                    } else {
                        InternetConnection.countTimer.invalidate()
                        InternetConnection.second = 0
                        UIComponentHelper.PresentActivityIndicator(view: self.view, option: false)
                        let alertController = UIAlertController(title: "Login Error", message: "Your account had used with other account with the same email", preferredStyle: .alert)
                        let okayAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
                        alertController.addAction(okayAction)
                        self.present(alertController, animated: true, completion: nil)
                        
                        return
                    }
                });
            }
        }
    }
    @IBAction func SignInClicked(_ sender: Any) {
        iflogoutforfirebase = false
        
        UIComponentHelper.PresentActivityIndicator(view: self.view, option: true)
        InternetConnection.second = 0
        InternetConnection.countTimer.invalidate()
        if emailTextField.text == "" && pwTextField.text == "" {
            UIComponentHelper.PresentActivityIndicator(view: self.view, option: false)
            PresentAlertController(title: "Warning", message: "Please enter your email", actionTitle: "Got it")
            return
            
        }
        if ( emailTextField.text?.isEmpty)! {
            UIComponentHelper.PresentActivityIndicator(view: self.view, option: false)
            PresentAlertController(title: "Warning", message: "Please enter your email", actionTitle: "Got it")
            return
        }
        if (pwTextField.text?.isEmpty)! {
            UIComponentHelper.PresentActivityIndicator(view: self.view, option: false)
            PresentAlertController(title: "Warning", message: "Please enter your password", actionTitle: "Go it")
            return
        } else {
            
            //handle firebase sign in
            InternetConnection.CountTimer()
            Auth.auth().signIn(withEmail: emailTextField.text!, password: pwTextField.text!) { (user, error) in
                if InternetConnection.second == 15 {
                    InternetConnection.countTimer.invalidate()
                    InternetConnection.second = 0
                    UIComponentHelper.PresentActivityIndicator(view: self.view, option: false)
                    return
                }
                InternetConnection.countTimer.invalidate()
                InternetConnection.second = 0
                if error == nil {
                    if (user?.isEmailVerified)!{
                        // if user don't have name and imageprofile
                        if(user?.photoURL == nil){
                            let img = UIImage(named: "profile-icon")
                            let newImage = UIComponentHelper.resizeImage(image: img!, targetSize: CGSize(width: 400, height: 400))
                            let imageProfiles = UIImagePNGRepresentation(newImage)
                            
                            self.create(username: (user?.displayName)!,email : (user?.email)!,facebook: false, imagData: imageProfiles! as NSData  )
                            
                            
                        } else {
                            self.getDataFromUrl(url: (user?.photoURL!)!){
                                (data, response, error)  in
                                guard let data = data, error == nil
                                    else {
                                        return
                                }
                                let image = data as NSData?
                                self.create(username: (user?.displayName)!,email : (user?.email)!,facebook: false, imagData: image!  )
                            }
                            
                        }
                        self.validation(uid : (Auth.auth().currentUser?.uid)!)
                        
                        //                       self.performSegue(withIdentifier: "SegueToDashboard", sender: self)
                        //                      LinphoneManager.enableRegistration()
                        
                    } else {
                        UIComponentHelper.PresentActivityIndicator(view: self.view, option: false)
                        self.PresentAlertController(title: "Confirmation", message: "Please verify your email address with a link that we have already sent you to proceed login in", actionTitle: "Okay")
                    }
                } else {
                    UIComponentHelper.PresentActivityIndicator(view: self.view, option: false)
                    let check: String = (error?.localizedDescription)!
                    print(check,"||")
                    switch check {
                    case "There is no user record corresponding to this identifier. The user may have been deleted.":
                        self.PresentAlertController(title: "Error", message: "The username and password you entered did not match our records. Please double-check and try again.", actionTitle: "Okay")
                        break
                    case "The password is invalid or the user does not have a password.":
                        Auth.auth().fetchProviders(forEmail: self.emailTextField.text!, completion: { (accData, error) in
                            if error == nil{
                                if accData == nil {
                                    self.PresentAlertController(title: "Something went wrong", message: "The email you entered did not match our records. Please double-check and try again.", actionTitle: "Got it")
                                    return
                                }
                                
                                for i in accData! {
                                    if i == "facebook.com"{
                                        self.PresentAlertController(title: "Something went wrong", message: "Your account is linked with Facebook. Please Sign in with Facebook Instead.", actionTitle: "Got it")
                                        return
                                        
                                    } else {
                                        self.PresentAlertController(title: "Something went wrong", message: "Please provide a valid password.", actionTitle: "Got it")
                                        return
                                    }
                                    
                                }
                            } else {
                                self.PresentAlertController(title: "Error", message: (error?.localizedDescription)!, actionTitle: "Okay")
                                return
                                
                            }
                        })
                        
                        break
                    default:
                        self.PresentAlertController(title: "Error", message: (error?.localizedDescription)!, actionTitle: "Okay")
                        break
                        
                        
                    }
                    
                    
                }
            }
        }
    }
    @IBAction func CreateAccount(_ sender: Any) {
        performSegue(withIdentifier: "SegueToCreateAcc", sender: self)
    }
    
    @IBAction func ForgotPWClicked(_ sender: Any) {
        performSegue(withIdentifier: "SegueToForgotPW", sender: self)
    }
    
    
    
}
// Login Help function
extension LoginController {
    
//    func ValidationMutipleLogin() {
//        if ValidationDeviceToken.deviceIdObject.deviceId {
//            ifLogin = false
//            personService.deleteAllData(entity: "Extension")
//            UserDefaults.standard.set(false, forKey: "loginBefore")
//            databaseRef.child("userDeviceId").child((Auth.auth().currentUser?.uid)!).child("status").setValue("false")
//        }
//    }
    
    
    func getDataFromUrl(url: URL, completion: @escaping (_ data: Data?, _  response: URLResponse?, _ error: Error?) -> Void) {
        URLSession.shared.dataTask (with: url) { (data, response, error) in
            completion(data, response, error)
            }.resume()
    }
    
    func create(username:String, email:String, facebook: Bool, imagData: NSData){
        var people : [UserProfile] = [User]
        let firstPerson =  personService.getByIdUserProfile(_id: (people[0].objectID))!
        if firstPerson.isInserted {
            firstPerson.facebookProvider = facebook
            firstPerson.imageData = imagData
            firstPerson.username  = username
            firstPerson.email     = email
            personService.updateUserProfile(_updatedPerson: firstPerson)
        }
    }
    func validation(uid : String) {
        let deviceId  =  UIDevice.current.identifierForVendor!.uuidString
        
        databaseRef.child("userDeviceId").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            // Get user value
            let value = snapshot.value as? NSDictionary
            if value == nil  {
                databaseRef.child("userDeviceId").child(uid).child("device").setValue(deviceId)
                databaseRef.child("userDeviceId").child(uid).child("device").setValue(Auth.auth().currentUser?.email)
                Screen.goToMainController()
            } else {
            
                let device = value?["device"] as? String ?? ""
                if device == deviceId {
                    Screen.goToMainController()
                } else {
                    if device.isEmpty {
                        databaseRef.child("userDeviceId").child(uid).child("device").setValue(deviceId)
                        Screen.goToMainController()
                    }else{
                        UIComponentHelper.PresentActivityIndicator(view: self.view, option: false)
                        self.vlidationDeviceInuse()
                    }
                }
            }
            
            
            // ...
        }) { (error) in
            UIComponentHelper.PresentActivityIndicator(view: self.view, option: false)
            self.PresentAlertController(title: "Error", message: error.localizedDescription, actionTitle: "Okay")
        }
            
        

    }
    func vlidationDeviceInuse() {
        let LocationPermissionAlert = UIAlertController(title: "Warning", message: "You can not use one account with two devices.You had chooiced the new device", preferredStyle: UIAlertControllerStyle.alert)
        LocationPermissionAlert.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
        UIApplication.topViewController()?.present( LocationPermissionAlert, animated: true, completion: nil)
    }
    
}



