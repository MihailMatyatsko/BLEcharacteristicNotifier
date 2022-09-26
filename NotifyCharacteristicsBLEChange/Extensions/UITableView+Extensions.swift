//
//  UITableView+Extensions.swift
//  hahajk
//
//  Created by Mihail Matyatsko on 19.09.2022.
//

import UIKit

extension UITableView {

    func dequeueCell<T: UITableViewCell>(of type: T.Type, for indexPath: IndexPath) -> T {
        let identifier = String(describing: type)
        let cell = dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! T
        return cell
    }

    func registerCellNibs(for classes: [AnyClass]) {
        classes.map({ String(describing: $0)}).forEach {
            register(UINib(nibName: $0, bundle: nil), forCellReuseIdentifier: $0)
        }
    }
    
    func registerHeaderFooterNib<T: UITableViewHeaderFooterView>(view: T.Type) {
        let identifier = String(describing: view)
        register(UINib(nibName: identifier, bundle: nil), forHeaderFooterViewReuseIdentifier: identifier)
    }
    
    func dequeueHeaderFooter<T: UITableViewHeaderFooterView>(of type: T.Type) -> T {
        let identifier = String(describing: type)
        let view = dequeueReusableHeaderFooterView(withIdentifier: identifier) as! T
        return view
    }
    
    func reloadData(with duration: Double, _ completion: ( () -> Void )? ) {
        UIView.animate(withDuration: duration, animations: { [weak self] in
            self?.reloadData()
        }, completion: { _ in
            completion?()
        })
    }
    
}
