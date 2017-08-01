//
//  ServiceController.swift
//  vKclub
//
//  Created by HuySophanna on 26/6/17.
//  Copyright © 2017 HuySophanna. All rights reserved.
//

import Foundation
import UIKit

class ServiceController: UIViewController {
    override func viewDidLoad() {
        
    }
    @IBAction func GotoBookpage(_ sender: Any) {
         self.performSegue(withIdentifier: "SgGotoBookpage", sender: self)
    }
 }
class BookingViewController: UIViewController {
    var propertyData: [String: AnyObject]!
    @IBOutlet weak var webView: UIWebView!
    
    @IBOutlet weak var noInternet: UILabel!
    let internetConnection = InternetConnection()
    override func viewDidLoad() {
        super.viewDidLoad()
        if InternetConnection.isConnectedToNetwork() {
            noInternet.alpha = 0
        } else{
            self.PresentAlertController(title: "Something went wrong", message: "Please Check you internet connection ", actionTitle: "Got it")
            return
        }
        
        let url = NSURL (string: "http://vkirirom.com/en/reservation.php")
        let requestObj = URLRequest(url: url! as URL)
        webView.loadRequest(requestObj)
        UIComponentHelper.PresentActivityIndicator(view: self.view, option: true)
        let when = DispatchTime.now() + 3 // change 2 to desired number of seconds
        DispatchQueue.main.asyncAfter(deadline: when) {
            UIComponentHelper.PresentActivityIndicator(view: self.view, option: false)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func CancelBtn(_ sender: Any) {
        dismiss(animated: true, completion: nil)
        
    }
 }
