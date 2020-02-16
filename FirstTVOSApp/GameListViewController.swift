//
//  GameListViewController.swift
//  FirstTVOSApp
//
//  Created by ShanOvO on 2020/2/12.
//  Copyright © 2020 ShanOvO. All rights reserved.
//

import UIKit
import TVUIKit

class GameListViewController: UIViewController {

    private let cellIdentifier = "GameListCollectionViewCell"
    
    @IBOutlet weak var gameListCollectionView: UICollectionView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var gameImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(red: 37/255, green: 37/255, blue: 37/255, alpha: 1)
        setupViews()
    }

    private func setupViews() {
        gameListCollectionView.dataSource = self
        gameListCollectionView.delegate = self
        gameListCollectionView.backgroundColor = .clear
        
        gameImageView.clipsToBounds = true
        gameImageView.layer.cornerRadius = 10
        gameImageView.backgroundColor = UIColor(red: 40/255, green: 40/255, blue: 40/255, alpha: 1)
        
        let backgroundImage = UIImage(named: "switch_background_image.jpg")
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.image = backgroundImage
    }
}

extension GameListViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Game.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! GameListCollectionViewCell
        
        cell.backgroundColor = .clear
        cell.gameNameLabel.text = Game.allCases[indexPath.row].getGameName()
        
        return cell
    }
}

extension GameListViewController: UICollectionViewDelegate {
    
}

extension GameListViewController: UICollectionViewDelegateFlowLayout {
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

extension GameListViewController {
    enum Game: CaseIterable {
        case werewolf
        case guessSongNameByLyrics
        case guessSongNameBySinging
        
        func getGameName() -> String {
            switch self {
            case .werewolf:
                return "狼人殺"
            case .guessSongNameByLyrics:
                return "猜歌（by 歌詞）"
            case .guessSongNameBySinging:
                return "猜歌（by 唱歌）"
            }
        }
    }
}

class GameListCollectionViewCell: UICollectionViewCell {
 
    var cardView: TVCardView!
    var gameNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupButtonView()
        setupNameLabel()
    }
    
    private func setupButtonView() {
        cardView = TVCardView()
        cardView.backgroundColor = .clear
        cardView.contentView.backgroundColor = .darkGray
        
        addSubview(cardView)
        cardView.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            cardView.centerXAnchor.constraint(equalTo: centerXAnchor),
            cardView.centerYAnchor.constraint(equalTo: centerYAnchor),
            cardView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 1.0),
            cardView.heightAnchor.constraint(equalTo: heightAnchor, multiplier: 1.0)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    private func setupNameLabel() {
        gameNameLabel = UILabel()
        gameNameLabel.textColor = .white
        gameNameLabel.text = "txt"
        gameNameLabel.numberOfLines = 0
        gameNameLabel.font = UIFont(name: "Avenir Next Medium", size: 50)
        gameNameLabel.textAlignment = .left
        cardView.contentView.addSubview(gameNameLabel)
        gameNameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let constraints = [
            gameNameLabel.centerYAnchor.constraint(equalTo: cardView.contentView.centerYAnchor),
            gameNameLabel.leadingAnchor.constraint(equalTo: cardView.contentView.leadingAnchor, constant: 20),
            gameNameLabel.widthAnchor.constraint(equalTo: cardView.contentView.widthAnchor, multiplier: 0.8),
            gameNameLabel.heightAnchor.constraint(equalTo: cardView.heightAnchor)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
}
