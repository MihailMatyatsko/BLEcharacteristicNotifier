//
//  UIViewController+Extensions.swift
//  CleanSwiftArc
//
//  Created by Mihail Matyatsko on 19.09.2022.
//

import UIKit

extension UIViewController {
    
    static func loadFromXib<T: UIViewController>() -> T {
        return T(nibName: String(describing: T.self), bundle: nil)
    }
    
}
