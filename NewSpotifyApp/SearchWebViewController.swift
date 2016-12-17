//
//  SearchWebViewController.swift
//  NewSpotifyApp
//
//  Created by Romain Brunie on 12/13/16.
//  Copyright © 2016 Romain Brunie. All rights reserved.
//

import UIKit

class SearchWebViewController: UIViewController {

    @IBOutlet var webView: UIWebView!
    var artist = String()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let urlString = "https://fr.wikipedia.org/wiki/" + artist
        print(artist)
        print(urlString)
        let newURL = urlString.replacingOccurrences(of: " ", with: "_")
        let url = NSURL(string: newURL)
        let request = NSURLRequest(url: url as! URL)
        print(request)
        webView.loadRequest(request as URLRequest)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
