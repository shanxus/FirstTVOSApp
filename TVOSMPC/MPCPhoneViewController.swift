//
//  ViewController.swift
//  TVOSMPC
//
//  Created by ShanOvO on 2020/2/18.
//  Copyright © 2020 ShanOvO. All rights reserved.
//

import UIKit

class MPCPhoneViewController: UIViewController {
    
    @IBOutlet weak var numberCollectionView: UICollectionView!
    
    @IBOutlet weak var yourCharacterLabel: UILabel!
    
    private let cellIdentifier = "numberCellIdentifier"
    
    private var viewModel: MPCPhoneViewModel?
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    private var disabledItems: [Int] = []
    
    private let numberEnabledImageName: String = "werewolf_number_enabled"
    private let numberDisabledImageName: String = "werewolf_number_disabled"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        numberCollectionView.dataSource = self
        numberCollectionView.delegate = self
        
        viewModel = MPCPhoneViewModel()
        viewModel?.delegate = self
    }
    
    func enableAllNumbers() {
        disabledItems.removeAll()
        numberCollectionView.reloadData()
    }
    
    func disableAllNumbers() {
        disabledItems.removeAll()
        for i in 0..<9 {
            disabledItems.append(i)
        }
        numberCollectionView.reloadData()
    }
    
}

extension MPCPhoneViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 9
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! NumberCollectionViewCell
        
        cell.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        cell.numberLabel.text = "\(indexPath.item + 1)"
        
        return cell
    }
}

extension MPCPhoneViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let width = collectionView.frame.width / 3
        
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

extension MPCPhoneViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("did select: \(indexPath)")
    }
}

extension MPCPhoneViewController: MPCPhoneViewModelDelegate {
    func didUpdateCharacter(as title: String) {
                
        yourCharacterLabel.text = String(format: "Your character is %@", title)
    }
    
    func shouldDisableNumbers() {
        
    }
    
    func shouldEnableNumbers() {
        
    }
}

class NumberCollectionViewCell: UICollectionViewCell {
    
    var backgroundColorView: UIView!
    var numberLabel: UILabel!
    
    var stateImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupViews()
    }
    
    private func setupViews() {
        /// Background color.
        backgroundColorView = UIView()
        backgroundColorView.backgroundColor = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1)
        backgroundColorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backgroundColorView)
        
        let constraints = [
            backgroundColorView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            backgroundColorView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            backgroundColorView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            backgroundColorView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ]
        
        NSLayoutConstraint.activate(constraints)
        
        /// Number label.
        numberLabel = UILabel()
        numberLabel.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 1)
        numberLabel.textAlignment = .center
        numberLabel.clipsToBounds = true
        numberLabel.layer.cornerRadius = 10
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(numberLabel)
        
        let labelConstraints = [
            numberLabel.widthAnchor.constraint(equalTo: widthAnchor),
            numberLabel.heightAnchor.constraint(equalTo: heightAnchor),
            numberLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            numberLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ]
        
        NSLayoutConstraint.activate(labelConstraints)
                
        /// State image view.
        let disabledImage = UIImage(named: "werewolf_number_disabled")?.withRenderingMode(.alwaysTemplate)
        stateImageView = UIImageView(image: disabledImage)
        stateImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stateImageView)
        
        let stateImageViewConstraints = [
            stateImageView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            stateImageView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            stateImageView.widthAnchor.constraint(equalToConstant: 24),
            stateImageView.heightAnchor.constraint(equalToConstant: 24)
        ]
        
        NSLayoutConstraint.activate(stateImageViewConstraints)
    }
}
