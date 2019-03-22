//
//  PhotoCell.swift
//  VirtualTourist
//
//  Created by MAC on 26/01/2019.
//  Copyright © 2019 MAC. All rights reserved.
//

import Foundation
import UIKit
class PhotoCell: UICollectionViewCell {
    var imageUrl: String = ""
    @IBOutlet weak var selectedView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var imageFlikr: UIImageView!
}
