//
//  ViewController.swift
//  FirstTVOSApp
//
//  Created by ShanOvO on 2020/2/9.
//  Copyright © 2020 ShanOvO. All rights reserved.
//

import UIKit
import TVUIKit

class ViewController: UIViewController {
    
    let cellIdentifier = "HomeCollectionViewCell"
    
    @IBOutlet weak var homeImageView: UIImageView!
    @IBOutlet weak var homeNameLabel: UILabel!
    @IBOutlet weak var homeAddressLabel: UILabel!
    
    @IBOutlet weak var homeCollectionView: CustomFocusCollectionView!
    @IBOutlet weak var itemDescriptionLabel: UILabel!
    
    private var locationService: LocationService?
    
    override var preferredFocusedView: UIView? {
        get {
            return homeCollectionView
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupHomeInformationViews()
        setupLocationService()
        
        WerewolfService.shared.startGame(with: .people6)
    }

    override func shouldUpdateFocus(in context: UIFocusUpdateContext) -> Bool {
        return true
    }
    
    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        
        if let cell = context.nextFocusedView as? UICollectionViewCell, let index = homeCollectionView.indexPath(for: cell)?.item {
            itemDescriptionLabel.text = HomeItem.allCases[index].getItemDescription()
        }
    }
    
    private func setupHomeInformationViews() {
        
        /// Home image.
        homeImageView.clipsToBounds = true
        homeImageView.layer.cornerRadius = homeImageView.frame.size.width / 2
        let image = UIImage(named: "SSH_home.jpg")
        homeImageView.image = image
        homeImageView.contentMode = .scaleAspectFill
        
        /// Home collection view.
        homeCollectionView.dataSource = self
        homeCollectionView.delegate = self
    }
    
    private func setupLocationService() {
        locationService = LocationService()
        locationService?.delegate = self
        locationService?.getCurrentLocation(completion: nil)
    }
}

extension ViewController: LocationServiceDelegate {
    func dataSourceDidUpdate() {
        
    }
    
    func didGetUserFriendlyAddress(_ address: LocationService.UserFriendlyAddress) {
        let country = address.country ?? ""
        let subAdministrativeArea = address.subAdministrativeArea ?? ""
        let locality = address.locality ?? ""
        let name = address.name ?? ""
        
        homeAddressLabel.text = "\(country), \(subAdministrativeArea), \(locality), \(name)"
    }
}

extension ViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 5
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! HomeCollectionViewCell
        cell.backgroundColor = .clear
        
        let itemImageName = HomeItem.allCases[indexPath.item].getItemImageName()
        let itemName = HomeItem.allCases[indexPath.item].getItemName()
        
        cell.posterView.image = UIImage(named: itemImageName)
        cell.posterView.title = itemName
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldUpdateFocusIn context: UICollectionViewFocusUpdateContext) -> Bool {
        return true
    }
}

extension ViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, canFocusItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("[didSelectItemAt: \(indexPath.item)]")
        
        let gameListViewController = UIStoryboard(name: "GameListViewController", bundle: .main).instantiateViewController(identifier: "GameListViewController") as! GameListViewController
        navigationController?.pushViewController(gameListViewController, animated: true)
    }
}

extension ViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 400, height: 400)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}


class HomeCollectionViewCell: UICollectionViewCell {
    
    var posterView: TVPosterView!
    
    override var preferredFocusedView: UIView? {
        get {
            return posterView
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupPosterView()
    }
    
    private func setupPosterView() {
        posterView = TVPosterView()
        posterView.focusSizeIncrease = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
        addSubview(posterView)
        posterView.translatesAutoresizingMaskIntoConstraints = false
        
        let constraints = [
            posterView.leadingAnchor.constraint(equalTo: leadingAnchor),
            posterView.trailingAnchor.constraint(equalTo: trailingAnchor),
            posterView.topAnchor.constraint(equalTo: topAnchor),
            posterView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
}

extension ViewController {
    enum HomeItem: CaseIterable {
        case clock
        case media
        case weather
        case game
        case drone
        
        func getItemImageName() -> String {
            switch self {
            case .clock:
                return "resized_clock.jpg"
            case .media:
                return "media.jpg"
            case .weather:
                return "weather.jpg"
            case .game:
                return "game_play.jpg"
            case .drone:
                return "dji.jpg"
            }
        }
        
        func getItemName() -> String {
            switch self {
            case .clock:
                return "Clock"
            case .media:
                return "Media"
            case .weather:
                return "Weather Forecast"
            case .game:
                return "Games"
            case .drone:
                return "Drone"
            }
        }
        
        func getItemDescription() -> String {
            switch self {
            case .clock:
                return "[description]"
            case .media:
                return "[description]"
            case .weather:
                return "[description]"
            case .game:
                return "[description]"
            case .drone:
                return "[description]"
            }
        }
    }
}

class CustomFocusCollectionView: UICollectionView {
    
}
