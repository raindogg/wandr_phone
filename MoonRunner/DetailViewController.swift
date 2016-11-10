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
import MapKit
import HealthKit
import Foundation

class DetailViewController: UIViewController, UITextFieldDelegate {
  var run: Run!
  var locationPoints = [[Double]]()
  var APIPoints = [[Double]]()
  var isPublic = "true"
  var length = ""

  


  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var distanceLabel: UILabel!
  @IBOutlet weak var dateLabel: UILabel!
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var paceLabel: UILabel!
  @IBOutlet weak var titleField: UITextField!
  @IBOutlet weak var publicSwitch: UISwitch!
  @IBOutlet weak var publicLabel: UILabel!
  @IBOutlet weak var requestActivity: UIActivityIndicatorView!
    
    
  override func viewDidLoad() {
    super.viewDidLoad()
    titleField.delegate = self
    configureView()
    getPoints()
    filterPoints()
    
  }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Hide the keyboard.
        textField.resignFirstResponder()
        return true
    }

  func configureView() {
    let distanceQuantity = HKQuantity(unit: HKUnit.meter(), doubleValue: run.distance.doubleValue)
    distanceLabel.text = "Distance: " + distanceQuantity.description
    length = run.distance.stringValue
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    dateLabel.text = dateFormatter.string(from: run.timestamp)
    let secondsQuantity = HKQuantity(unit: HKUnit.second(), doubleValue: run.duration.doubleValue)
    timeLabel.text = "Time: " + secondsQuantity.description
    let paceUnit = HKUnit.second().unitDivided(by: HKUnit.meter())
    let paceQuantity = HKQuantity(unit: paceUnit, doubleValue: run.duration.doubleValue / run.distance.doubleValue)
    paceLabel.text = "Pace: " + paceQuantity.description
    requestActivity.isHidden = true
  }
    
    
    func getPoints() {
      let newLocations = run.locations.array as! [Location]
        for location in newLocations {
            var locationRow = [Double]()
            locationRow.append(location.latitude.doubleValue)
            locationRow.append(location.longitude.doubleValue)
            locationPoints.append(locationRow)
        }
    }
    
    func filterPoints() {
        APIPoints.append(locationPoints.first!)
        for(index, value) in locationPoints.enumerated() {
            if index % 10 == 0 {
                APIPoints.append(value)
            }
        }
        APIPoints.append(locationPoints.last!)
    }
    
    func displayStatus(conditional: Bool) {
         self.requestActivity.isHidden = true
        if conditional == true {
            self.distanceLabel.text = "Trek saved!"
        } else {
            self.distanceLabel.text = "Mistakes were made."
        }
    }

    @IBAction func setPublic(_ sender: UISwitch) {
        if publicSwitch.isOn {
            publicLabel.text = "Yes"
            isPublic = "true"
        } else {
            publicLabel.text = "No"
            isPublic = "false"
        }
    }
    
    @IBAction func updateProfile(_ sender: AnyObject) {
        requestActivity.isHidden = false
        requestActivity.startAnimating()
        let title = "&title=\(titleField.text!)"
        let encodedTitle = title.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
        let requestLength = "&length=" + length
        let requestPublic = "&public=" + isPublic
        let firstUrl = "https://polar-castle-64141.herokuapp.com/treks/?user_id=1" + encodedTitle! + requestLength + requestPublic
        let myUrl = NSURL(string: firstUrl)
        print(myUrl)
        let request = NSMutableURLRequest(url: myUrl! as URL)
        print(request)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            (data, response, error) in
            if error != nil {
                print(error)
                self.displayStatus(conditional: false)
            } else {
                do {
                    print(response)
                    let responseData = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? [String: Any]
                    if let parsedJson = responseData {
                         let trekId = parsedJson["id"]
                        if trekId == nil {
                         self.displayStatus(conditional: false)
                        }
                        for point in self.APIPoints {
                            let baseUrl = "https://polar-castle-64141.herokuapp.com/points/?"
                            let trek_id = "trek_id=\(trekId!)&"
                            let nextParams = "start=false&end=false&"
                            let firstLat = point[0]
                            let firstLon = point[1]
                            let firstPoints = "latitude=\(firstLat)&longitude=\(firstLon)"
                            let firstCall = baseUrl + trek_id + nextParams + firstPoints
                            let nextURL = NSURL(string: firstCall)
                            let request = NSMutableURLRequest(url: nextURL! as URL)
                            request.httpMethod = "POST"
                            request.addValue("application/json",
                                             forHTTPHeaderField: "Accept")
                            let task = URLSession.shared.dataTask(with: request as URLRequest) {
                                data, response, error in
                                if error != nil {
                                    print("Error \(error)")
                                    self.displayStatus(conditional: false)
                                } else {
                                    self.displayStatus(conditional: true)
                                }
                                
                            }
                            task.resume()
                        }
                    }
                } catch {
                    print(error)
                }
            }
            
        }
        task.resume()
        }
}

