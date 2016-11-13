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
import CoreLocation
import HealthKit

let DetailSegueName = "RunDetails"

class NewRunViewController: UIViewController {
  var managedObjectContext: NSManagedObjectContext?

  var run: Run!
  var seconds = 0.0
  var distance = 0.0
    lazy var locationManager: CLLocationManager = {
        var _locationManager = CLLocationManager()
        _locationManager.delegate = self
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest
        _locationManager.activityType = .fitness
        
        //Movement threshold for new events
        _locationManager.distanceFilter = 10.0
        return _locationManager
    }()
    
    lazy var locations = [CLLocation]()
    lazy var timer = Timer()
    
    
  @IBOutlet weak var promptLabel: UILabel!
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var distanceLabel: UILabel!
  @IBOutlet weak var paceLabel: UILabel!
  @IBOutlet weak var startButton: UIButton!
  @IBOutlet weak var stopButton: UIButton!

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    startButton.isHidden = false
    promptLabel.isHidden = false

    timeLabel.isHidden = true
    distanceLabel.isHidden = true
    paceLabel.isHidden = true
    stopButton.isHidden = true
    locationManager.requestAlwaysAuthorization()
  }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer.invalidate()
    }
    
    func eachSecond(_ timer: Timer) {
        seconds += 1
        let secondsQuantity = HKQuantity(unit: HKUnit.second(), doubleValue: seconds)
        timeLabel.text = "Time: " + secondsQuantity.description
        let distanceQuantity = HKQuantity(unit: HKUnit.meter(), doubleValue: distance)
        distanceLabel.text = "Distance: " + distanceQuantity.description
        let paceUnit = HKUnit.second().unitDivided(by: HKUnit.meter())
        let paceQuantity = HKQuantity(unit: paceUnit, doubleValue: seconds / distance)
        paceLabel.text = "Pace: " + paceQuantity.description
    }
    
    func startLocationUpdates() {
        locationManager.startUpdatingLocation()
    }

  @IBAction func startPressed(_ sender: AnyObject) {
    startButton.isHidden = true
    promptLabel.isHidden = true

    timeLabel.isHidden = false
    distanceLabel.isHidden = false
    paceLabel.isHidden = false
    stopButton.isHidden = false
    seconds = 0.0
    distance = 0.0
    locations.removeAll(keepingCapacity: false)
    timer = Timer.scheduledTimer(timeInterval: 1,
                                 target: self,
                                 selector: "eachSecond:",
                                 userInfo: nil,
                                 repeats: true)
    startLocationUpdates()
  }

  @IBAction func stopPressed(_ sender: AnyObject) {
    let actionSheet = UIActionSheet(title: "Hike Stopped", delegate: self, cancelButtonTitle: "Cancel", destructiveButtonTitle: nil, otherButtonTitles: "Save", "Discard")
    actionSheet.actionSheetStyle = .default
    actionSheet.show(in: view)
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let detailViewController = segue.destination as? DetailViewController {
      detailViewController.run = run
    }
  }
    
    func saveRun() {
        //1
        let savedRun = NSEntityDescription.insertNewObject(forEntityName: "Run", into: managedObjectContext!) as! Run
        print(savedRun)
        savedRun.distance = distance as NSNumber
        savedRun.duration = seconds as NSNumber
        savedRun.timestamp = NSDate() as Date
        
        //2
        var savedLocations = [AnyObject]()
        for location in locations {
            let savedLocation = NSEntityDescription.insertNewObject(forEntityName: "Location", into: managedObjectContext!) as! Location
            savedLocation.timestamp = location.timestamp
            savedLocation.latitude = location.coordinate.latitude as NSNumber
            savedLocation.longitude = location.coordinate.longitude as NSNumber
            savedLocations.append(savedLocation)
        }
        
        savedRun.locations = NSOrderedSet(array: savedLocations)
        run = savedRun
       
        
        //3
        var error: NSError?
        let success = managedObjectContext!.save
    }
}

// MARK: UIActionSheetDelegate
extension NewRunViewController: UIActionSheetDelegate {
  func actionSheet(_ actionSheet: UIActionSheet, clickedButtonAt buttonIndex: Int) {
    //save
    
    if buttonIndex == 1 {
      saveRun()
      performSegue(withIdentifier: DetailSegueName, sender: nil)
    }
      //discard
    else if buttonIndex == 2 {
      navigationController?.popToRootViewController(animated: true)
    }
  }
}
//MARK: CLLocationManagerDelegate
extension NewRunViewController: CLLocationManagerDelegate {
     func locationManager(_ manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]) {
        for location in locations as! [CLLocation] {
            if location.horizontalAccuracy < 20 {
                //update disctance
                if self.locations.count > 0 {
                    distance += location.distance(from: self.locations.last!)
                }
                //save location
                self.locations.append(location)
            }
        }
        }
}
