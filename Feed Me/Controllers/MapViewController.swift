//
//  MapViewController.swift
//  Feed Me
//
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


// UW API KEY: "5e62f79a0204cec9f1e7ae20df39c410" //

import UIKit
import Alamofire
import SwiftyJSON
import MapKit

class MapViewController: UIViewController {
  
  let locationManager = CLLocationManager()
  
  @IBOutlet weak var mapCenterPinImage: UIImageView!
  @IBOutlet weak var pinImageVerticalConstraint: NSLayoutConstraint!
  @IBOutlet weak var mapView: GMSMapView!
  @IBOutlet weak var addressLabel: UILabel!

    
  var searchedTypes = ["bakery", "bar", "cafe", "grocery_or_supermarket", "restaurant"]
  
  override func viewDidLoad() {

    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    locationManager.delegate = self
    locationManager.requestWhenInUseAuthorization()
    
    mapView.delegate = self
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "Types Segue" {
      let navigationController = segue.destinationViewController as! UINavigationController
      let controller = navigationController.topViewController as! TypesTableViewController
      controller.selectedTypes = searchedTypes
      controller.delegate = self
    }
  }
}

// MARK: - TypesTableViewControllerDelegate
extension MapViewController: TypesTableViewControllerDelegate {
  func typesController(controller: TypesTableViewController, didSelectTypes types: [String]) {
    searchedTypes = controller.selectedTypes.sort()
    dismissViewControllerAnimated(true, completion: nil)
  }
}

// MARK: - CLLocationManagerDelegate
//1

extension MapViewController: CLLocationManagerDelegate {
  
  func fetchNearbyPlaces() {
    // 1
    mapView.clear()
    // 2
    Alamofire.request(.GET, "https://api.uwaterloo.ca/v2/parking/watpark.json", parameters: ["key": "5e62f79a0204cec9f1e7ae20df39c410"])
      .validate()
      .responseJSON { response in
        //debugPrint(response)
        switch response.result {
        case .Success(let data):
          let json = JSON(data)
          if let items = json["data"].array {
            for item in items {
              
              let lot_name = item["lot_name"].stringValue
              let current_count = item["current_count"].intValue
              
              let lat = item["latitude"].doubleValue as CLLocationDegrees
              let lng = item["longitude"].doubleValue as CLLocationDegrees
              
              let coordinate = CLLocationCoordinate2DMake(lat, lng)
              
              let marker = UWPlaceMarker(coordinate: coordinate, type: "car",lot_name:lot_name,current_count:current_count)
              // 4
              marker.map = self.mapView
            }
          }
        case .Failure(let error):
          print("Request failed with error: \(error)")
        }
    }
  }
  
  
  // 2
  func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
    // 3
    if status == .AuthorizedWhenInUse {
      
      // 4
      // locationManager.startUpdatingLocation()
      
      let uwaterloo = GMSCameraPosition.cameraWithLatitude(43.4723, longitude: -80.5449, zoom: 14)
      mapView.camera = uwaterloo
      
      fetchNearbyPlaces()
      
      //5
      // mapView.myLocationEnabled = true
      // mapView.settings.myLocationButton = true
    }
  }
  
  // 6
  func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    if let location = locations.first {
      
      // 7
      mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 200, bearing: 0, viewingAngle: 0)
      
      // 8
      locationManager.stopUpdatingLocation()
      
      fetchNearbyPlaces()
    }
    
  }
  
  func reverseGeocodeCoordinate(coordinate: CLLocationCoordinate2D) {
    
    // 1
    let geocoder = GMSGeocoder()
    
    
    // 2
    geocoder.reverseGeocodeCoordinate(coordinate) { response, error in
      
      self.addressLabel.unlock()
      
      if let address = response?.firstResult() {
        // 3
        let lines = address.lines as [String]!
        self.addressLabel.text = lines.joinWithSeparator("\n")
        
        let labelHeight = self.addressLabel.intrinsicContentSize().height
        self.mapView.padding = UIEdgeInsets(top: self.topLayoutGuide.length, left: 0, bottom: labelHeight, right: 0)
        
        // 4
        UIView.animateWithDuration(0.25) {
          
          
          self.pinImageVerticalConstraint.constant = ((labelHeight - self.topLayoutGuide.length) * 0.5)
          self.view.layoutIfNeeded()
        }
      }
      
      
    }
  }
  
}


// MARK: - GMSMapViewDelegate
extension MapViewController: GMSMapViewDelegate {
  // Tap Gesture Property
  
  
  func mapView(mapView: GMSMapView, idleAtCameraPosition position: GMSCameraPosition) {
    reverseGeocodeCoordinate(position.target)
   }
  func mapView(mapView: GMSMapView, willMove gesture: Bool) {
    addressLabel.lock()
    
    if (gesture) {
      mapCenterPinImage.fadeIn(0.25)
      mapView.selectedMarker = nil
    }
  
  }
  
  
  func mapView(mapView: GMSMapView, markerInfoContents marker: GMSMarker) -> UIView? {
    // 1
    let placeMarker = marker as! UWPlaceMarker
    
    // 2
    if let infoView = UIView.viewFromNibName("MarkerInfoView") as? MarkerInfoView {
      // 3
      infoView.nameLabel.text = placeMarker.uw_name
      infoView.countLabel.text = String(placeMarker.count) + " space(s) available"
      
      // 4
      return infoView
    } else {
      return UIView()
      
    }
  }
  
  func mapView(mapView: GMSMapView, didTapMarker marker: GMSMarker) -> Bool {
    mapCenterPinImage.fadeOut(0.25)
    return false
  }
  
  func didTapMyLocationButtonForMapView(mapView: GMSMapView) -> Bool {
    mapCenterPinImage.fadeIn(0.25)
    mapView.selectedMarker = nil
    return false
  }
  func mapView(mapView: GMSMapView, didTapInfoWindowOfMarker marker: GMSMarker) {
    let placeMarker = marker as! UWPlaceMarker
    
    let coordinate = placeMarker.position
    let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary:nil))
    mapItem.name = placeMarker.uw_name
    mapItem.openInMapsWithLaunchOptions([MKLaunchOptionsDirectionsModeDriving : MKLaunchOptionsDirectionsModeKey])  }
  
}