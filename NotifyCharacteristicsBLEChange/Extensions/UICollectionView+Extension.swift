//
//  UICollectionView+Extension.swift
//  hahajk
//
//  Created by Mihail Matyatsko on 19.09.2022.
//

import UIKit

extension UICollectionView {
    
    func register<T: UICollectionViewCell>(_ cellType: T.Type) {
        let cellName = String(describing: cellType)
        register(UINib(nibName: cellName, bundle: Bundle(for: cellType)), forCellWithReuseIdentifier: cellName)
    }
    
    func registerWithoutNib<T: UICollectionViewCell>(_ cellType: T.Type) {
        let cellName = String(describing: cellType)
        register(T.self, forCellWithReuseIdentifier: cellName)
    }
    
    func register<T: UICollectionReusableView>(header: T.Type) {
        register(supplementaryView: header, of: UICollectionView.elementKindSectionHeader)
    }
    
    func register<T: UICollectionReusableView>(footer: T.Type) {
        register(supplementaryView: footer, of: UICollectionView.elementKindSectionFooter)
    }
    
    private func register<T: UICollectionReusableView>(supplementaryView: T.Type, of kind: String) {
        let name = String(describing: supplementaryView)
        register(UINib(nibName: name, bundle: nil), forSupplementaryViewOfKind: kind, withReuseIdentifier: name)
    }
    
    func dequeueCell<T: UICollectionViewCell>(of type: T.Type, for indexPath: IndexPath) -> T {
        let identifier = String(describing: type)
        let cell = dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath) as! T
        
        return cell
    }
    
    func dequeueHeader<T: UICollectionReusableView>(of type: T.Type, for indexPath: IndexPath) -> T {
        return dequeueSupplementaryView(of: type, kind: UICollectionView.elementKindSectionHeader, for: indexPath)
    }
    
    func dequeueFooter<T: UICollectionReusableView>(of type: T.Type, for indexPath: IndexPath) -> T {
        return dequeueSupplementaryView(of: type, kind: UICollectionView.elementKindSectionFooter, for: indexPath)
    }
    
    private func dequeueSupplementaryView<T: UICollectionReusableView>(of type: T.Type, kind: String, for indexPath: IndexPath) -> T {
        let identifier = String(describing: type)
        let view = dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: identifier, for: indexPath) as! T
        
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
