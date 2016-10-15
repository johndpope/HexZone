import UIKit
import Mapbox

import CoreLocation

// Constants

let zoomLevel = 11.9
let hexSize = CGFloat(12)
let sanFranciscoBoundingBox = [CLLocationCoordinate2D(latitude: 37.78156937014928, longitude: -122.51060485839844),
                               CLLocationCoordinate2D(latitude: 37.71668926284967, longitude: -122.49790191650392),
                               CLLocationCoordinate2D(latitude: 37.73977029560411, longitude: -122.38391876220702),
                               CLLocationCoordinate2D(latitude: 37.78781006166096, longitude: -122.3928451538086),
                               CLLocationCoordinate2D(latitude: 37.804358908571395, longitude: -122.40829467773436),
                               CLLocationCoordinate2D(latitude: 37.802460048862656, longitude: -122.47009277343749),
                               CLLocationCoordinate2D(latitude: 37.78726741375342, longitude: -122.48554229736328),
                               CLLocationCoordinate2D(latitude: 37.78156937014928, longitude: -122.51060485839844)];

class ViewController: UIViewController {

    @IBOutlet weak var mapView: MGLMapView!
    
    var sourceIdentifiers = [String]()
    var layerIdentifiers = [String]()
    var surgeZones = [[CLLocationCoordinate2D]]()
    var surgeIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        mapView.styleURL = MGLStyle.lightStyleURL(withVersion: 9)
        mapView.centerCoordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        mapView.zoomLevel = zoomLevel
        
        // zone 1
        surgeZones.append([CLLocationCoordinate2D(latitude: 37.78401144262929, longitude: -122.40975379943849),
                           CLLocationCoordinate2D(latitude: 37.77702418710145, longitude: -122.41009712219238),
                           CLLocationCoordinate2D(latitude: 37.772410879746595, longitude: -122.42271423339842)])
        // zone 2
        surgeZones.append([CLLocationCoordinate2D(latitude: 37.75571915770573, longitude: -122.4203109741211),
                           CLLocationCoordinate2D(latitude: 37.7494757572745, longitude: -122.41387367248535)])
        
        // zone 3
        surgeZones.append([CLLocationCoordinate2D(latitude: 37.794592824285104, longitude: -122.41653442382812),
                           CLLocationCoordinate2D(latitude: 37.795813655432426, longitude: -122.42237091064453),
                           CLLocationCoordinate2D(latitude: 37.7975770425844, longitude: -122.43352890014648),
                           CLLocationCoordinate2D(latitude: 37.779805600955584, longitude: -122.41395950317383),
                           CLLocationCoordinate2D(latitude: 37.78306175736387, longitude: -122.40966796874999),
                           CLLocationCoordinate2D(latitude: 37.78631777032694, longitude: -122.40486145019531)])
    }
    
    // MARK: Actions
    
    @IBAction func didTapTimeButton(_ sender: AnyObject) {
        
        removePreviousSurge()
        
        surgeIndex = surgeIndex + 1
        surgeIndex = surgeIndex % surgeZones.count
        loadSurgeZones(index: surgeIndex)
        
    }
    
    func removePreviousSurge() {
        for layerId in layerIdentifiers {
            if let layer = mapView.style().layer(withIdentifier: layerId) {
                mapView.style().remove(layer)
            }
        }
        for sourceId in sourceIdentifiers {
            if let source = mapView.style().source(withIdentifier: sourceId) {
                mapView.style().remove(source)
            }
        }
    }
}

// MARK: Load source and layers 

extension ViewController {
    
    func loadSurgeZones(index: Int) {
        for coordinate in surgeZones[index] {
            loadSurgeLayer(surgeCoordinate: coordinate, surgeItensity: 0.5, surgeDistance: 500)
            loadSurgeLayer(surgeCoordinate: coordinate, surgeItensity: 0.25, surgeDistance: 1000)
            loadSurgeLayer(surgeCoordinate: coordinate, surgeItensity: 0.1, surgeDistance: 1500)
        }
    }
    
    func loadSurgeLayer(surgeCoordinate: CLLocationCoordinate2D, surgeItensity: Double, surgeDistance: Double) {
        let features = generateFeatures(surgeCoordinate: surgeCoordinate, surgeDistance: surgeDistance)
        
        let sourceId = "source-\(surgeItensity)-\(surgeCoordinate.latitude)-\(surgeCoordinate.longitude)"
        let source = MGLGeoJSONSource(identifier: sourceId, features: features, options: nil)
        mapView.style().add(source)
        sourceIdentifiers.append(sourceId)
        
        let layerId = "layer-\(surgeItensity)-\(surgeCoordinate.latitude)-\(surgeCoordinate.longitude)"
        let layer = MGLFillStyleLayer(identifier: layerId, source: source)
        layer.fillColor = UIColor.purple
        layer.fillOpacity = NSNumber(floatLiteral: surgeItensity)
        mapView.style().add(layer)
        layerIdentifiers.append(layerId)
    }
    
    func generateFeatures(surgeCoordinate: CLLocationCoordinate2D?, surgeDistance: Double?) -> [MGLPolygonFeature] {
        var features = [MGLPolygonFeature]()
        var oddRow = false
        
        for i in stride(from: 0, to: view.frame.height, by: hexSize * 1.525) {
            for j in stride(from: 0, to: view.frame.width, by: hexSize * 1.75) {
                let adjustedJ = oddRow ? j + hexSize * 0.875 : j
                let point = CGPoint(x: adjustedJ, y: i)
                let pointCoordinate = mapView.convert(point, toCoordinateFrom: view)
                
                if contains(polygon: sanFranciscoBoundingBox, test: pointCoordinate) {
                    
                    let corners = hexCorners(center: point, size: hexSize)
                    var coordinates = pointsToCoordinates(points: corners)
                    let feature: MGLPolygonFeature = MGLPolygonFeature.init(coordinates: &coordinates, count: UInt(coordinates.count), interiorPolygons: nil)
                    
                    if surgeCoordinate != nil {
                        let surgeLocation = CLLocation(latitude: surgeCoordinate!.latitude, longitude: surgeCoordinate!.longitude)
                        let testLocation = CLLocation(latitude: pointCoordinate.latitude, longitude: pointCoordinate.longitude)
                        if surgeLocation.distance(from: testLocation) < surgeDistance! {
                            features.append(feature)
                        }
                    } else {
                        features.append(feature)
                    }
                }
            }
            
            oddRow = !oddRow
        }
        
        return features;
    }
}

// MARK: MGLMapViewDelegate

extension ViewController: MGLMapViewDelegate {

    func mapViewDidFinishLoadingMap(_ mapView: MGLMapView) {
        loadSurgeZones(index: surgeIndex)
    }
    
    func mapViewDidFinishRenderingMap(_ mapView: MGLMapView, fullyRendered: Bool) {
        print("test")
    }
    
}

// MARK: Geometry

extension ViewController {
    
    func hexCorners(center: CGPoint, size: CGFloat) -> [CGPoint] {
        var corners = [CGPoint]()
        for index in 0...5 {
            let corner = hexCorner(center: center, size: size, index: index)
            corners.append(corner)
        }
        
        // close shape
        corners.append(corners.first!)
        
        return corners
    }
    
    func hexCorner(center: CGPoint, size: CGFloat, index: Int) -> CGPoint {
        let angleDegrees = CLLocationDegrees(60 * index + 30)
        let angleRadians = (MGLRadiansFromDegrees(angleDegrees))
        let x = center.x + size * cos(angleRadians)
        let y = center.y + size * sin(angleRadians)
        
        return CGPoint(x: x, y: y)
    }
    
    func pointsToCoordinates(points: [CGPoint]) -> [CLLocationCoordinate2D] {
        var coordinates = [CLLocationCoordinate2D]()
        for point in points {
            coordinates.append(mapView.convert(point, toCoordinateFrom: view))
        }
        
        return coordinates
    }
    
    func contains(polygon: [CLLocationCoordinate2D], test: CLLocationCoordinate2D) -> Bool {
        var pJ=polygon.last!
        var contains = false
        for pI in polygon {
            if ( ((pI.longitude >= test.longitude) != (pJ.longitude >= test.longitude)) &&
                (test.latitude <= (pJ.latitude - pI.latitude) * (test.longitude - pI.longitude) / (pJ.longitude - pI.longitude) + pI.latitude) ){
                contains = !contains
            }
            pJ=pI
        }
        return contains
    }
}
