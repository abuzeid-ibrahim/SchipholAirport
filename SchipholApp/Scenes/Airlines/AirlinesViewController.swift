//
//  AirlinesViewController.swift
//  SchipholApp
//
//  Created by abuzeid on 31.10.20.
//  Copyright © 2020 abuzeid. All rights reserved.
//

import MapKit
import UIKit

final class AirlinesViewController: UIViewController {
    private let userLocationDistanceMeters: CLLocationDistance = 5000
    private let locationManager = LocationManager()

    lazy var mapView: MKMapView = {
        let map = MKMapView()
        map.delegate = self
        return map
    }()

    private let viewModel: AirlinesViewModelType
    init(with viewModel: AirlinesViewModelType = AirlinesViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: Bundle(for: AirlinesViewController.self))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Unsupported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        binding()
        viewModel.loadData()
        locationManager.getCurrentLocation()
    }

    override func viewWillDisappear(_ animated: Bool) {
        locationManager.stopTracking()
        super.viewWillDisappear(animated)
    }
}

extension AirlinesViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else { return nil }

        var annotationView: MKAnnotationView?

        if let annotation = annotation as? MKClusterAnnotation {
            annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier, for: annotation)
        } else if let annotation = annotation as? PointAnnotation {
            annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier, for: annotation)
            annotationView?.clusteringIdentifier = String(describing: PointView.self)
        }

        return annotationView
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation as? PointAnnotation else { return }
        AppNavigator.shared.push(.airportDetails(of: annotation.airport))
        mapView.deselectAnnotation(annotation, animated: false)
    }
}

// MARK: location manager

private extension AirlinesViewController {
    func setup() {
        view.addSubview(mapView)
        mapView.setConstrainsEqualToParentEdges()
        mapView.register(PointView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        mapView.register(PointsClusterView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
    }

    func binding() {
        viewModel.reloadData.subscribe { [weak self] reload in
            let annotations = reload.compactMap(PointAnnotation.init)
            self?.mapView.addAnnotations(annotations)
        }

        viewModel.error.subscribe { [weak self] error in
            guard let self = self, let msg = error else { return }
            self.show(error: msg)
        }
        locationManager.error.subscribe { [weak self] error in
            guard let self = self, let error = error else { return }
            self.show(error: error.message, actions: error.actions)
        }
        locationManager.location.subscribe { [weak self] location in
            guard let self = self,
                let loc = location else { return }
            self.mapView.setRegion(.init(center: loc.coordinate,
                                         latitudinalMeters: self.userLocationDistanceMeters,
                                         longitudinalMeters: self.userLocationDistanceMeters),
                                   animated: true)
        }
    }
}
