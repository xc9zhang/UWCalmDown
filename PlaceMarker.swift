//
//  PlaceMarker.swift
//  Feed Me
//
//  Created by xiao bing zhang on 2016-05-22.
//  Copyright © 2016 Ron Kliffer. All rights reserved.
//

import UIKit

class PlaceMarker: GMSMarker {
  
  // 1
  let place: GooglePlace
  
  // 2
  init(place: GooglePlace) {
    self.place = place
    super.init()
    
    position = place.coordinate
    icon = UIImage(named: place.placeType+"_pin")
    groundAnchor = CGPoint(x: 0.5, y: 1)
    appearAnimation = kGMSMarkerAnimationPop
  }
  
}

class UWPlaceMarker: GMSMarker {
  var uw_name: String
  var count: Int
  var placeType: String
  
  // 2
  init(coordinate : CLLocationCoordinate2D,type:String,lot_name:String, current_count:Int) {
   
    uw_name = lot_name
    count = current_count
    placeType = type
    super.init()
    position = coordinate
    icon = UIImage(named: placeType+"_pin")
    groundAnchor = CGPoint(x: 0.5, y: 1)
    appearAnimation = kGMSMarkerAnimationPop
    title = String(current_count)
  }
  
}
