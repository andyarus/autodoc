//
//  AppCoordinator.swift
//  AutodocTestTask
//
//  Created by Andrei Yarmukhametov on 22.06.2026.
//

import UIKit

protocol AppCoordinatorProtocol: AnyObject {
    var navigationController: UINavigationController { get }
    func start() -> UINavigationController
    func alert(title: String?, message: String?, confirmAction: (() -> Void)?)
    func open(url: URL)
}

extension AppCoordinatorProtocol {
    func alert(title: String? = nil, message: String? = nil, confirmAction: (() -> Void)? = nil) {
        alert(title: title, message: message, confirmAction: confirmAction)
    }
}

@MainActor
final class AppCoordinator: AppCoordinatorProtocol {
    
    var navigationController: UINavigationController
    private var networkClient: NetworkClientProtocol
    
    init() {
        navigationController = UINavigationController()
        networkClient = NetworkClient()
    }
    
    func start() -> UINavigationController {
        let networkService = NewsNetworkService(client: networkClient)
        let vm = NewsViewModel(coordinator: self, networkService: networkService)
        let vc = NewsViewController(viewModel: vm)
        navigationController.setViewControllers([vc], animated: true)
        return navigationController
    }
    
    func alert(title: String?, message: String?, confirmAction: (() -> Void)? = nil) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        
        if let confirmBlock = confirmAction {
            let confirmAction = UIAlertAction(title: "OK", style: .default) { _ in
                confirmBlock()
            }
            alert.addAction(confirmAction)
        }
        
        navigationController.visibleViewController?.present(alert, animated: true, completion: nil)
    }
    
    func open(url: URL) {
        let vc = WebViewController(url: url)
        navigationController.present(vc, animated: true)
    }
}
