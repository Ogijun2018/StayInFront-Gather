//
//  WindowController.swift
//  StayInFront
//
//  Created by jun.ogino on 2023/11/08.
//

import Cocoa
import WebKit

class WindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
        window?.level = .floating
        let webView = WKWebView(frame: self.window!.contentView!.bounds)
        webView.autoresizingMask = [.width, .height]
        // gather townのWeb版は現在Chromeまたはfirefoxのみで動作する（Safariは推奨環境ではないが動作する）
        // それ以外のブラウザでアクセスすると使用できないため、UserAgentを書き換えてSafariとして認識させる
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.4 Safari/605.1.15"
        window!.contentView!.addSubview(webView)

        let appDelegate = NSApp.delegate as? AppDelegate
        appDelegate?.toggleMenuHandler = { [weak self] in
            self?.changeWindowLebel()
        }

        if let url = URL(string: "https://app.gather.town/app") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }

    private func changeWindowLebel() {
        window?.level = window?.level == .normal ? .floating : .normal
    }
}

