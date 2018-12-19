//
//  ViewController.swift
//  LocationPicker
//
//  Created by Ashiq Uz Zoha on 18/12/18.
//  Copyright © 2018 DISL. All rights reserved.
//

import UIKit
import Alamofire
import MapKit
import SwiftyJSON
import ActionKit

class Place {
    var address: String?
    var postCode: String?
    var latitude: Double?
    var longitude: Double?
    
    func toString () -> String {
        var str: [String] = []
        if let address = self.address {
            str.append("Address: \(address)")
        }
        
        if let postCode = self.postCode {
            str.append("PostCode: \(postCode)")
        }
        
        if let lat = self.latitude {
            str.append(String(format: "Lat: %lf", lat))
        }
        
        if let lng = self.longitude {
            str.append(String(format: "Lng: %lf", lng))
        }
        
        return str.joined(separator: "\n")
    }
}

class ViewController: UIViewController {

    @IBOutlet var postCodeField: UITextField!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var locationPin: UIImageView!
    @IBOutlet var myLocationButton: UIButton!
    @IBOutlet var containerView: UIView!
    @IBOutlet var activityIndicatorView: UIActivityIndicatorView!
    
    var currentPlace: Place!
    var suggestions : [String]?
    var sTableView: UITableView?
    
    let color = UIColor(red: 0.0, green: (172.0/255.0), blue: (195.0/255.0), alpha: 1.0)
    
    var locationPinPointinView: CGPoint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        self.applyStyles()
        
        let defaults = UserDefaults.standard
        let lat = defaults.double(forKey: "lat")
        let lng = defaults.double(forKey: "lng")
        let location = CLLocationCoordinate2DMake(lat, lng)
        
        self.postCodeField.delegate = self
        self.activityIndicatorView.stopAnimating()
        
        self.mapView.setCenter(location, animated: true)
        self.mapView.setUserTrackingMode(.follow, animated: true)
        self.mapView.showsUserLocation = true
        self.centerMapOnLocation(location: CLLocation(latitude: lat, longitude: lng))
        
        self.postCodeField.addControlEvent(.editingChanged) {
            if let partial = self.postCodeField.text {
                if partial.count > 1 {
                    self.fetchPostCodes(partial: partial)
                } else {
                    if let _ = self.sTableView {
                        self.sTableView?.removeFromSuperview()
                        self.sTableView = nil
                    }
                }
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let locationPinFrame = self.locationPin.frame
        let pinWidth = locationPinFrame.size.width
        let pinHeight = locationPinFrame.size.height
        let x = locationPinFrame.origin.x + (pinWidth/2)
        let y = locationPinFrame.origin.y + pinHeight
        self.locationPinPointinView = CGPoint(x: x, y: y)
    }
    
    func applyStyles () {
        self.containerView.layer.cornerRadius = 5.0
        self.containerView.clipsToBounds = true
        
        self.myLocationButton.layer.cornerRadius = 20.0
        self.myLocationButton.clipsToBounds = true
        
        let ml = UIImage(named: "baseline_my_location_black_24pt")?.withRenderingMode(.alwaysTemplate)
        self.myLocationButton.setImage(ml, for: .normal)
        self.myLocationButton.backgroundColor = color
        self.myLocationButton.tintColor = UIColor.white
        
        var pimg = self.locationPin.image
        pimg = pimg?.withRenderingMode(.alwaysTemplate)
        self.locationPin.image = pimg
        self.locationPin.tintColor = color
    }

    @IBAction func onClickDoneButton () {
        if self.currentPlace != nil {
            let controller = UIAlertController(title: "Place", message: self.currentPlace.toString(), preferredStyle: .alert)
            controller.addAction(UIAlertAction(title: "Okay", style: .destructive, handler: nil))
            self.present(controller, animated: true, completion: nil)
        } else {
            print("place not set")
        }
    }
    
    @IBAction func onClickMyLocation () {
        let defaults = UserDefaults.standard
        let lat = defaults.double(forKey: "lat")
        let lng = defaults.double(forKey: "lng")
        let location = CLLocation(latitude: lat, longitude: lng)
        self.centerMapOnLocation(location: location)
    }
    
    func centerMapOnLocation(location: CLLocation) {
        let regionRadius: CLLocationDistance = 1000
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func updateAddress () {
        
        guard let point = self.locationPinPointinView else {
            print("point nil")
            return
        }
    
        let pinLocation = self.mapView.convert(point, toCoordinateFrom: self.view)
        let location = CLLocation(latitude: pinLocation.latitude, longitude: pinLocation.longitude)
        let geocoder = CLGeocoder()
        self.activityIndicatorView.startAnimating()
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if let placemark = placemarks?.first {
                
                self.currentPlace = Place()
                
                var address: [String] = []
                if let name = placemark.name {
                    address.append(name)
                }
                
                if let locality = placemark.locality {
                    address.append(locality)
                }
                
                if let postCode = placemark.postalCode {
                    address.append(postCode)
                    self.postCodeField.text = postCode
                    self.currentPlace.postCode = postCode
                } else {
                    self.postCodeField.text = ""
                    self.currentPlace.postCode = ""
                }
                
                if let adminArea = placemark.administrativeArea {
                    address.append(adminArea)
                }
                
                let fullAddress = address.joined(separator: ", ")
                self.addressLabel.text = fullAddress
                self.currentPlace.address = fullAddress
                self.currentPlace.latitude = location.coordinate.latitude
                self.currentPlace.longitude = location.coordinate.longitude
                
            } else if let error = error {
                print("reverse geocode error = \(error.localizedDescription)")
            }
            
            self.activityIndicatorView.stopAnimating()
        }
    }
}

extension ViewController: MKMapViewDelegate {
    
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        if let _ = self.locationPinPointinView {
            self.updateAddress()
        } else {
            print("mapViewDidFinishLoadingMap = [point is nil]")
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if let _ = self.locationPinPointinView {
            self.updateAddress()
        } else {
            print("regionDidChangeAnimated = [point is nil]")
        }
    }
    
    func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError error: Error) {
        print("mapViewDidFailLoadingMap = [\(error.localizedDescription)]")
    }
}

extension ViewController {
    func fetchPostCodes (partial: String) {
    
        let charSet = CharacterSet.alphanumerics.inverted
        let zip = partial.components(separatedBy: charSet).joined(separator: "")
        print("stripped = \(zip)")
        
        guard zip.count > 0 else {
            print("postcode is empty")
            return
        }
        
        let url = "http://api.postcodes.io/postcodes/" + zip + "/autocomplete"
        Alamofire.request(url).responseJSON { response in
            if let json = response.result.value {
                let mJson = JSON(json)
                if let status = mJson["status"].int, status == 200 {
                    if let result = mJson["result"].array {
                        var codes: [String] = []
                        result.forEach({ (code) in
                            codes.append(code.stringValue)
                        })
                        print("for \(zip) : \(codes)")
                        self.suggestions = codes
                        self.showSuggestions()
                    }
                }
            }
        }
    }
    
    func fetchLocationFromPostcode (postCode: String) {
        
        guard postCode.count > 0 else {
            print("postcode is empty")
            return
        }
        
        let charSet = CharacterSet.alphanumerics.inverted
        let zip = postCode.components(separatedBy: charSet).joined(separator: "")
        print("stripped = \(zip)")
        
        self.activityIndicatorView.startAnimating()
        let url = "http://api.postcodes.io/postcodes/" + zip
        Alamofire.request(url).responseJSON { response in
            print(response as Any)
            self.activityIndicatorView.stopAnimating()
            if let json = response.result.value {
                let mJson = JSON(json)
                print(mJson)
                if let status = mJson["status"].int, status == 200 {
                    if let lat = mJson["result"]["latitude"].double {
                        if let lng = mJson["result"]["longitude"].double  {
                            let location = CLLocation(latitude: lat, longitude: lng)
                            self.centerMapOnLocation(location: location)
                        }
                    }
                }
            }
        }
    }
    
    func validatePostCode (postCode: String, onComplete: @escaping (Bool) -> ()) {
        guard postCode.count > 0 else {
            print("postcode is empty")
            onComplete(false)
            return
        }
        
        let charSet = CharacterSet.alphanumerics.inverted
        let zip = postCode.components(separatedBy: charSet).joined(separator: "")
        print("stripped = \(zip)")
        
        self.activityIndicatorView.startAnimating()
        let url = "http://api.postcodes.io/postcodes/" + zip + "/validate"
        Alamofire.request(url).responseJSON { response in
            print(response as Any)
            self.activityIndicatorView.stopAnimating()
            if let json = response.result.value {
                let mJson = JSON(json)
                print(mJson)
                if let status = mJson["status"].int, status == 200 {
                    onComplete(mJson["result"].boolValue)
                } else {
                    onComplete(false)
                }
            } else {
                onComplete(false)
            }
        }
    }
    
    func showSuggestions () {
        
        if let _ = self.sTableView {
            self.sTableView!.removeFromSuperview()
            self.sTableView = nil
        }
        
        let rect = CGRect(x: self.containerView.frame.origin.x + 10, y: self.containerView.frame.origin.y + 50, width: self.postCodeField.frame.size.width, height: 400.0)
        self.sTableView = UITableView(frame: rect, style: .plain)
        self.sTableView?.dataSource = self
        self.sTableView?.delegate = self
        self.sTableView?.tableFooterView = UIView(frame: .zero)
        self.view.addSubview(self.sTableView!)
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let postCode = self.postCodeField.text, postCode.count > 0 {
            self.validatePostCode(postCode: postCode) { (valid) in
                print("valid post code = \(valid)")
                if valid == true {
                    self.fetchLocationFromPostcode(postCode: postCode)
                } else {
                    let controller = UIAlertController(title: "Not a valid UK postcode", message: "Please enter a valid UK postcode", preferredStyle: .alert)
                    controller.addAction(UIAlertAction(title: "Close", style: .destructive, handler: nil))
                    self.present(controller, animated: true, completion: nil)
                }
            }
        }
        if let _ = self.sTableView {
            self.sTableView!.removeFromSuperview()
            self.sTableView = nil
        }
        self.postCodeField.resignFirstResponder()
        return true
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let suggestions = self.suggestions {
            return suggestions.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell!
        if let c = tableView.dequeueReusableCell(withIdentifier: "cell") {
            cell = c
        } else {
            cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        cell.textLabel?.text = self.suggestions?[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let suggestions = self.suggestions {
            self.postCodeField.text = suggestions[indexPath.row]
            if let _ = self.sTableView {
                self.sTableView!.removeFromSuperview()
                self.sTableView = nil
            }
            self.postCodeField.resignFirstResponder()
            self.fetchLocationFromPostcode(postCode: suggestions[indexPath.row])
        }
    }
}
