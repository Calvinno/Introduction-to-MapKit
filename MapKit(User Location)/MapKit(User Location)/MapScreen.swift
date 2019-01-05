//
//  ViewController.swift
//  MapKit(User Location)
//
//  Created by Calvin Cantin on 2019-01-02.
//  Copyright © 2019 Calvin Cantin. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapScreen: UIViewController{
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var adressLabel: UILabel!
    
    let locationManager = CLLocationManager()
    let regionInMeters:Double = 10000
    var previousLocation: CLLocation?
    var directionsArray:[MKDirections] = [MKDirections]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkLocationService()
    }
    
    func setupLocationManager()
    {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func centerViewOnUserLocation()
    {
        if let location = locationManager.location?.coordinate
        {
            let region = MKCoordinateRegion(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    func checkLocationService()
    {
        if CLLocationManager.locationServicesEnabled()
        {
            setupLocationManager()
            checkLocationAutorisation()
        }
        else
        {
            
        }
    }
    
    func checkLocationAutorisation()
    {
        switch CLLocationManager.authorizationStatus()
        {
        case .authorizedWhenInUse:
            // Do map stuff
            startTrackingUserLocation()
        case .denied:
            // Show alert instructing them how to turn on the permissions
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            break
        case .restricted:
            break
        case .authorizedAlways:
            break
        }
    }
    
    func startTrackingUserLocation()
    {
        mapView.showsUserLocation = true
        centerViewOnUserLocation()
        locationManager.startUpdatingLocation()
        previousLocation = getCenterLocation(for: mapView)
    }
    
    func getCenterLocation(for mapView: MKMapView) -> CLLocation
    {
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    func getDirections()
    {
        guard let location = locationManager.location?.coordinate else
        {
            //TODO: Inform user we don'thave their current location
            return
        }
        
        let request = createDirectionsRequest(from: location)
        let direction = MKDirections(request: request)
        resetMapView(withTheNew: direction)
        
        direction.calculate { [unowned self] (response, error) in
            guard let response = response else {return} // TODO: Show response not available in an alert
            
            for route in response.routes
            {
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
        
        
    }
    
    func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request
    {
        let destinationCoordinate       = getCenterLocation(for: mapView).coordinate
        let statingLocation             = MKPlacemark(coordinate: coordinate)
        let destination                 = MKPlacemark(coordinate: destinationCoordinate)
        
        let request                     = MKDirections.Request()
        request.source                  = MKMapItem(placemark: statingLocation)
        request.destination             = MKMapItem(placemark: destination)
        request.transportType           = .automobile
        request.requestsAlternateRoutes = true
        
        return request
    }
    
    func resetMapView(withTheNew directions: MKDirections)
    {
        mapView.removeOverlays(mapView.overlays)
        for direction in directionsArray
        {
            direction.cancel()
        }
        directionsArray.removeAll()
        directionsArray.append(directions)
        
    }
    @IBAction func goButtonTapped(_ sender: UIButton) {
        getDirections()
    }
}

extension MapScreen: CLLocationManagerDelegate
{
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAutorisation()
    }
}
extension MapScreen: MKMapViewDelegate
{
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool)
    {
        let center = getCenterLocation(for: mapView)
        let geoCoder = CLGeocoder()
        guard let previousLocation = self.previousLocation else {return}
        
        guard center.distance(from: previousLocation) > 50 else {return}
        self.previousLocation = center
        
        geoCoder.cancelGeocode()
        
        geoCoder.reverseGeocodeLocation(center) {[weak self] (placemarks, error) in
            guard let self = self else {return}
            
            if let _ = error
            {
                // TODO: Show alert informing the user
                return
            }
            guard let placemark = placemarks?.first else
            {
                // TODO: Show alert informing the user
                return
            }
            let streetNumber = placemark.subThoroughfare ?? ""
            let streetName = placemark.thoroughfare ?? ""
            
            DispatchQueue.main.async {
                self.adressLabel.text = "\(streetNumber) \(streetName)"
            }
            
        }
        
    }
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .blue
        
        return renderer
    }
}
