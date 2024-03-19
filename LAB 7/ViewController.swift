//
//  ViewController.swift
//  Lab7GPS
//
//  Created by user238292 on 3/18/24.
//
import UIKit
import CoreLocation
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate {
    

    @IBOutlet weak var startTrip: UIButton!
    @IBOutlet weak var stopTrip: UIButton!
    @IBOutlet weak var lblcrntSpd: UILabel!
    @IBOutlet weak var lblmaxSpd: UILabel!
    @IBOutlet weak var lblavrgSpd: UILabel!
    @IBOutlet weak var lbldstnce: UILabel!
    @IBOutlet weak var lblmaxAcc: UILabel!
    @IBOutlet weak var topbar: UIView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var bottambar: UIView!
    
    let locationManager = CLLocationManager()
    var Tripstart = false
    var startTripTime: Date?
    var currentSpeed: CLLocationSpeed = 0.0
    var maxSpeed: CLLocationSpeed = 0.0
    var distance: CLLocationDistance = 0.0
    var maxAcceleration: Double = 0.0
    var previousLocation: CLLocation?
    var speed: [CLLocationSpeed] = []
    var lastSpeed: CLLocationSpeed = 0.0
    var timetaken: TimeInterval = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLocationManager()
        
    }
    
    func setupUI(){
        topbar.backgroundColor = .gray
        bottambar.backgroundColor = .gray
        lblcrntSpd.text = "0 km/h"
        lblmaxSpd.text = "0 km/h"
        lblavrgSpd.text = "0 km/h"
        lbldstnce.text = "0 km"
        lblmaxAcc.text = "0 m/s²"
    }
    func setupLocationManager(){
        Tripstart = false
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        locationManager.stopUpdatingLocation()
    }
    
    @IBAction func startButton(_ sender: Any) {
        locationManager.requestAlwaysAuthorization()
        Tripstart = true
        startTripTime = Date()
        timetaken = 0
        startUpdatingLocation()
    }
    
    @IBAction func stopButton(_ sender: Any) {
        Tripstart = false
        stopUpdatingLocation()
        TripSummary()
        bottambar.backgroundColor = .gray
        currentSpeed = 0.0
        maxSpeed = 0.0
        distance = 0.0
        maxAcceleration = 0.0
        speed = []
        previousLocation = nil
        updateUI()
    }
    
    func startUpdatingLocation(){
        locationManager.startUpdatingLocation()
        speed = []
        previousLocation = nil
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        bottambar.backgroundColor = .green
    }
    func stopUpdatingLocation(){
        locationManager.stopUpdatingLocation()
        mapView.showsUserLocation = false
        mapView.userTrackingMode = .none
    }
    func updateUI(){
        lblcrntSpd.text = String(format: "%.1f km/h",currentSpeed * 3.6)
        lblmaxSpd.text = String(format: "%.1f km/h", maxSpeed * 3.6)
        lblavrgSpd.text = speed.isEmpty ? "0 km/h" : String(format: "%.1f km/h ",(speed.reduce(0,+)/Double(speed.count)) * 3.6)
        lbldstnce.text = String(format: "%.1f km", distance / 1000)
        lblmaxAcc.text = String(format: "%.1f m/s²",maxAcceleration)
        if currentSpeed * 3.6 > 115{
            topbar.backgroundColor = .red
            topbar.isHidden = false
        } else{
            topbar.backgroundColor = .gray
            topbar.isHidden = true
        }
        let averageSpeed = timetaken > 0 ? distance / timetaken : 0
        lblavrgSpd.text = String(format: "%.1f km/h", averageSpeed * 3.6)

    }
    func TripSummary() {
        let timetaken = startTripTime != nil ? Date().timeIntervalSince(startTripTime!) : 0
        let averageSpeed = timetaken > 0 ? distance / timetaken : 0
        var lastSpeed = 0.0
        var accelerations: [Double] = []
        for spid in speed {
            let currentAcceleration = (spid - lastSpeed) / (timetaken / Double(speed.count))
            accelerations.append(currentAcceleration)
            lastSpeed = spid
        }
        maxAcceleration = accelerations.max() ?? 0.0
        lblavrgSpd.text = String(format: "%.1f km/h", averageSpeed * 3.6)
        lblmaxAcc.text = String(format: "%.2f m/s²", maxAcceleration)
        speed = []
        distance = 0.0
        maxSpeed = 0.0
        startTripTime = nil
    }
}
extension ViewController{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, Tripstart else {return}
        let spid = location.speed >= 0 ? location.speed : 0
        currentSpeed = spid
        maxSpeed = max(maxSpeed, currentSpeed)
        speed.append(currentSpeed)
        
        if let strttrp = startTripTime {
                timetaken = Date().timeIntervalSince(strttrp)
            }
        
        if let previousLocation = previousLocation {
            let timeInterval = location.timestamp.timeIntervalSince(previousLocation.timestamp)
            if timeInterval > 0 {
                let Acceleration = abs(spid - lastSpeed) / timeInterval
                maxAcceleration = max(maxAcceleration, Acceleration)
                let totaldistance = location.distance(from: previousLocation)
                distance += totaldistance


            }
        }
        
        lastSpeed = spid
        previousLocation = location
        
        let averageSpeed = timetaken > 0 ? distance / timetaken : 0
        lblavrgSpd.text = String(format: "%.1f km/h", averageSpeed * 3.6)
        updateUI()
    }
}
