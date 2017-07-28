import UIKit
import CoreData
import Firebase
import Photos
import MessageUI


class MenuController: UIViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate,MFMessageComposeViewControllerDelegate {
    var imagePicker : UIImagePickerController = UIImagePickerController()
    
    let personService = UserProfileCoreData()
    let Checklocation = DashboardController()
    let storageRef = Storage.storage().reference()
    let currentUser = Auth.auth().currentUser
    var loginControllerInstance: LoginController = LoginController()
    let internetConnection = InternetConnection()
    var facebookCheck : Bool = false
    @IBOutlet weak var EmergencyBtn: UIButton!
    @IBOutlet weak var contactBtn: UIButton!
    @IBOutlet weak var settingBtn: UIButton!
    @IBOutlet weak var imageProfile: UIButton!
    @IBOutlet weak var urlTextView: UITextField!
    @IBOutlet weak var EmailBtn: UILabel!
    @IBOutlet weak var EditBtn: UIButton!
    @IBOutlet weak var userName: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
        self.imagePicker.allowsEditing = true
        
        let provider = currentUser?.providerData
        
        for i in provider!{
            let providerfb = i.providerID
            switch providerfb {
            case "facebook.com":
                facebookCheck = true
                
                FBProvider()
            case "password"    :
                facebookCheck = false
                EmailProvider()
            default:
                print("Unknown provider ID: \(provider!)")
                return
            }
            
        }
        
        //make responsive rounded user profile picture
        imageProfile.frame = CGRect(x: EditBtn.frame.origin.x, y: imageProfile.bounds.width / 5, width: (view.bounds.width * 35) / 100, height: (view.bounds.width * 35) / 100)
        imageProfile.layer.cornerRadius = imageProfile.bounds.width / 2
        imageProfile.imageView?.contentMode = .scaleAspectFill
        imageProfile.contentHorizontalAlignment = .fill
        imageProfile.contentVerticalAlignment = .fill

    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func Logout(_ sender: Any) {
        personService.deleteAllData(entity: "UserProfile")
        personService.deleteAllData(entity: "SipCallData")
        try! Auth.auth().signOut()
        if self.storyboard != nil {
            
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let newViewController = storyBoard.instantiateViewController(withIdentifier: "loginController") as! LoginController
            self.present(newViewController, animated: true, completion: nil)
            
        }
    }
    
    @IBAction func AccProviderBtn(_ sender: Any) {
        if EditBtn.tag == 0 {
            PresentAlertController(title: "FB Linked", message: "Your account link with Facebook", actionTitle: "Okay")
            
            
        }else{
            performSegue(withIdentifier:"GotoEditProfile", sender: self)        }
    }
    
    func FBProvider(){
        userName.text =  currentUser?.displayName
        EmailBtn.text = currentUser?.email
        let facebookProvider = NSPredicate(format: "facebookProvider = 1")
        let fb_lgoin = personService.getUserProfile(withPredicate: facebookProvider)
        EditBtn.setTitle("FBLinked", for: .normal)
        if fb_lgoin == [] {
            if currentUser?.photoURL == nil {
            } else {
                let data = try? Data(contentsOf: (currentUser?.photoURL)!)
                
                if data != nil {
                    let image = UIImage(data: data!)
                    let newimag = UIComponentHelper.resizeImage(image: image!, targetSize: CGSize(width: 400, height: 400))
                    imageProfile.setImage(newimag, for: .normal)
                }
            }
        } else {
            for i in fb_lgoin {
                // if user no internet still they can get imageProfile from coredata
                let img = UIImage(data: i.imageData! as Data)
                let newimag = UIComponentHelper.resizeImage(image: img!, targetSize: CGSize(width: 400, height: 400))
                imageProfile.setImage(newimag, for: .normal)
                
            }
            
        }
    }
    
    @IBAction func didTapTakePicture(_ sender: Any) {
        let alertController = UIAlertController(title: nil, message: "Upload Profile Picture", preferredStyle: .actionSheet)
        
        let defaultAction = UIAlertAction(title: "Take Photo", style: .default, handler: { (alert: UIAlertAction!) -> Void in
            self.TakePhoto()

        })
        
        let deleteAction = UIAlertAction(title: "Select from Photo Library", style: .default, handler: { (alert: UIAlertAction!) -> Void in
            self.SelectPhotoFromLibrary()
            
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alertController.addAction(defaultAction)
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        self.present(alertController, animated: true, completion: nil)
        
        }
    
    func EmailProvider(){
        EditBtn.tag = 1
        EmailBtn.text = currentUser?.email
        userName.text =  currentUser?.displayName
        let emailProvider = NSPredicate(format: "facebookProvider = 0")
        let email_lgoin = personService.getUserProfile(withPredicate: emailProvider)
        if email_lgoin == [] {
          if currentUser?.photoURL == nil {
            } else {
                let data = try? Data(contentsOf: (currentUser?.photoURL)!)
                
                if data != nil {
                    let image = UIImage(data: data!)
                    let newimag = UIComponentHelper.resizeImage(image: image!, targetSize: CGSize(width: 400, height: 400))
                    imageProfile.setImage(newimag, for: .normal)
                  }
                }
        } else {
            for i in email_lgoin {
                    // if user no internet still they can get imageProfile from coredata
                    let img = UIImage(data: i.imageData! as Data)
                    let newimag = UIComponentHelper.resizeImage(image: img!, targetSize: CGSize(width: 400, height: 400))
                    imageProfile.setImage(newimag, for: .normal)
            }
            
        }
  }
    
    func TakePhoto(){
        if internetConnection.isConnectedToNetwork() {
            print("have internet")
        } else{
            self.PresentAlertController(title: "Something went wrong", message: "Can not upload to server. Please Check you internet connection ", actionTitle: "Got it")
            return
        }
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) == true {
            self.imagePicker.sourceType = .camera
            self.present(imagePicker, animated: true)
        } else {
            print("no work")
            
        }
        
    }
    
    func SelectPhotoFromLibrary(){
        if internetConnection.isConnectedToNetwork() {
            print("have internet")
        } else {
            self.PresentAlertController(title: "Something went wrong", message: "Can not upload to server. Please Check you internet connection ", actionTitle: "Got it")
            return
        }
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary) == true {
            self.imagePicker.sourceType = .photoLibrary
            self.present(imagePicker, animated: true)
        } else {
           
        }
    }
    
    @IBAction func EmergencySOS(_ sender: Any){
        if (UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad) {
            self.PresentAlertController(title: "Something went wrong", message: "Your device doesn't support with this feature ", actionTitle: "Got it")
            
            return
        }
        let Check : String =  Checklocation.CheckUserLocation()
        if Check == "inKirirom" {
            self.inKirirom()
            
        } else if (Check == "offKirirom") {
            PresentAlertController(title: "Something went wrong", message: "You off kirirom,so You can not use EmergencySOS function", actionTitle: "Got it")
        } else if( Check == "identifying"){
            PresentAlertController(title: "Something went wrong", message: "Please Allow your location", actionTitle: "Got it")
        } else {
            PresentAlertController(title: "Something went wrong", message: "Please Allow your location", actionTitle: "Got it")
        }
        
    }
    
    func inKirirom(){
        let smsAlert = UIAlertController(title: "EmergencySOS", message: "We will generate a SMS along with your current location to our supports. We suggest you not to move far away from your current position, as we're trying our best to get there as soon as possible. \n (Standard SMS rates may apply)", preferredStyle: UIAlertControllerStyle.alert)
        
        smsAlert.addAction(UIAlertAction(title: "Okay", style: .default, handler: { (action: UIAlertAction!) in
            self.SMS()
        }))
        
        smsAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(smsAlert, animated: true, completion: nil)
    }
    
    //send SMS
    func SMS(){
        let currentLocaltion_lat = String(Checklocation.lat)
        let currentLocation_long = String(Checklocation.long)
        print(currentLocaltion_lat)
        if (MFMessageComposeViewController.canSendText()) {
            let phone = "+13343758067"
            let message = "Please help! I'm currently facing an emergency problem. Here is my Location: http://maps.google.com/?q="+currentLocaltion_lat+","+currentLocation_long+""
            let controller = MFMessageComposeViewController()
            controller.body = message
            controller.recipients = [phone]
            controller.messageComposeDelegate = self as MFMessageComposeViewControllerDelegate
            self.present(controller, animated: true, completion: nil)
        }
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        switch (result.rawValue) {
        case MessageComposeResult.cancelled.rawValue:
            print("Message was cancelled")
            self.dismiss(animated: true, completion: nil)
        case MessageComposeResult.failed.rawValue:
            print("Message failed")
            self.dismiss(animated: true, completion: nil)
        case MessageComposeResult.sent.rawValue:
            print("Message was sent")
            self.dismiss(animated: true, completion: nil)
        default:
            break;
        }
    }
    
    
    @IBAction func settingBtn(_ sender: Any) {
        performSegue(withIdentifier:"GotoSetting", sender: self)
    }
    
    
    @IBAction func contactusBtn(_ sender: Any) {
        if (UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad) {
            self.PresentAlertController(title: "Something went wrong", message: "Your device doesn't support with this feature ", actionTitle: "Got it")
            
           return
        }
        let alertController = UIAlertController(title: nil, message: "Contact us", preferredStyle: .actionSheet)
        
        let defaultAction = UIAlertAction(title: "English Speaker: (+855) 78 777 284", style: .default, handler: { (alert: UIAlertAction!) -> Void in
            guard let number = URL(string: "tel://" + "078777284" ) else { return }
            UIApplication.shared.open(number, options: [:], completionHandler: nil)
            
        })
        
        let deleteAction = UIAlertAction(title: "Khmer Speaker: (+855) 96 2222 735", style: .default, handler: { (alert: UIAlertAction!) -> Void in
            guard let number = URL(string: "tel://" + "0962222735" ) else { return }
            UIApplication.shared.open(number, options: [:], completionHandler: nil)
            
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(defaultAction)
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
         UIComponentHelper.PresentActivityIndicator(view: self.view, option: true)
        var selectedImageFromPicker : UIImage?
        print(info)
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage{
            selectedImageFromPicker = originalImage
            }
        if let setectImage = selectedImageFromPicker{
            let newImage = UIComponentHelper.resizeImage(image: setectImage, targetSize: CGSize(width: 400, height: 400))
            let imageProfiles = UIImagePNGRepresentation(newImage)
            let riversRef = storageRef.child("userprofile-photo").child((currentUser?.displayName)!)
            _ = riversRef.putData(imageProfiles! , metadata: nil) { (metadata, error) in
                guard let metadata = metadata else {
                        return
                }
                // Metadata contains file metadata such as size, content-type, and download URL.
                let downloadURL = metadata.downloadURL()!.absoluteString
                print(downloadURL)
                let url = NSURL(string: downloadURL) as URL?
                let chageProfileimage = self.currentUser?.createProfileChangeRequest()
                chageProfileimage?.photoURL =  url
                chageProfileimage?.commitChanges { (error) in
                }
                UIComponentHelper.PresentActivityIndicator(view: self.view, option: false)
                self.imageProfile.setImage(setectImage, for: .normal)
                // if Facebook login Update Image
                if self.facebookCheck {
                    self.FBProviderUpdateImage(image: imageProfiles! as NSData)
                    
                } else {
                    self.EmailProviderUpdateImage(image: imageProfiles! as NSData)
                }
                
            }
            
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // update image to Core
    func EmailProviderUpdateImage(image: NSData){
        
        let emailProvider = NSPredicate(format: "facebookProvider = 0")
        let email_lgoin = personService.getUserProfile(withPredicate: emailProvider)
        for i in email_lgoin {
            print("Email done")
            i.imageData = image
            personService.updateUserProfile(_updatedPerson: i)
            
        }
    }
    
    // update image to Core
    func FBProviderUpdateImage(image : NSData){
        let facebookProvider = NSPredicate(format: "facebookProvider = 1")
        let fb_lgoin = personService.getUserProfile(withPredicate: facebookProvider)
        for i in fb_lgoin {
            print("facebook done")
            i.imageData = image
            personService.updateUserProfile(_updatedPerson: i)
            
        }
     
    }
   
}


