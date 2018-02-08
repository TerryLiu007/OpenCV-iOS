//
//  ShowRoundedButton.swift
//  OpenCV-iOS
//
//  Created by TerryLiu on 6/2/18.
//  Copyright © 2018 TerryLiu. All rights reserved.
//

import UIKit

class ShowRoundedButton: UIButton{
    override func awakeFromNib() {
        self.layer.shadowColor = UIColor.darkGray.cgColor
        self.layer.shadowRadius = 15
        self.layer.shadowOpacity = 0.15
        self.layer.cornerRadius = self.frame.height/2
    }
    
}
