/*
 * Copyright (c) 2015 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import CoreData

class LoginViewController: UIViewController, UITextFieldDelegate {
    var managedObjectContext: NSManagedObjectContext?
    
    @IBOutlet weak var navigationButton: UIButton!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var passwordLabel: UILabel!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }
    
    struct globalId {
       static var userId = "test"
    }
    
    @IBAction func testLogin(_ sender: AnyObject) {
        let email = emailTextField.text
        let pass = passwordTextField.text
        let encodedPass = pass?.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        let myUrl = "https://polar-castle-64141.herokuapp.com/users/remote?email=\(email!)&password=\(encodedPass!)"
        let newUrl = NSURL(string: myUrl)
        let request = NSMutableURLRequest(url: newUrl! as URL)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            (data, response, error) in
            if error != nil {
                print(error)
            } else {
                do {
                    let responseData = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: Any]
                    print(responseData)
                    if let parsedJson = responseData {
                        let userId = parsedJson["id"]
                        print(userId)
                        self.performSegue(withIdentifier: "loginAccepted", sender: nil)
                    }
                } catch {
                    print(error)
                }
            }
        }; task.resume()
        
    }
    
    
   
}
