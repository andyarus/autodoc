//
//  WebViewController.swift
//  AutodocTestTask
//
//  Created by Andrei Yarmukhametov on 22.06.2026.
//

import WebKit

class WebViewController: UIViewController {
    
    private let webView: WKWebView
    private let url: URL
    
    init(url: URL) {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        self.url = url
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        load()
    }
    
    private func load() {
        let request = URLRequest(url: url)
        webView.load(request)
    }
}
