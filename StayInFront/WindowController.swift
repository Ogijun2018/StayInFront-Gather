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

        // MARK: setting closure
        let appDelegate = NSApp.delegate as? AppDelegate
        appDelegate?.toggleMenuHandler = { [weak self] in
            self?.changeWindowLebel()
        }

        // MARK: setting webView
        // 日本語入力(IME)の変換確定Returnが、Web側に「Enter」として漏れて
        // チャットが意図せず送信される問題への対処。
        // WebKitでは compositionend の後に keydown(Enter, isComposing:false) が
        // 漏れて飛ぶため、変換確定中だけでなく「確定直後のEnter」もキャプチャ段階で
        // 握りつぶし、ページの送信ハンドラに届かないようにする。
        let imeGuardScript = WKUserScript(
            source: """
            (function () {
                var confirmedAt = 0;
                document.addEventListener('compositionend', function () {
                    confirmedAt = Date.now();
                }, true);
                document.addEventListener('keydown', function (e) {
                    if (e.key !== 'Enter') { return; }
                    // 変換確定中、またはSafari/WebKitが確定直後に漏らすEnterは送信させない
                    if (e.isComposing || e.keyCode === 229 || Date.now() - confirmedAt < 50) {
                        e.stopPropagation();
                        e.stopImmediatePropagation();
                        confirmedAt = 0; // 確定Enterは一度だけ握りつぶす
                    }
                }, true);
            })();
            """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.addUserScript(imeGuardScript)

        let webView = WKWebView(frame: self.window!.contentView!.bounds, configuration: configuration)
        webView.autoresizingMask = [.width, .height]
        // gather townのWeb版は現在Chromeまたはfirefoxのみで動作する（Safariは推奨環境ではないが動作する）
        // それ以外のブラウザでアクセスすると使用できないため、UserAgentを書き換えてSafariとして認識させる
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.4 Safari/605.1.15"
        if let url = URL(string: "https://app.gather.town/app") {
            let request = URLRequest(url: url)
            webView.load(request)
        }

        // MARK: setting window
        guard let window else { return }
        window.title = "Gather - StayInFront"
        window.contentView?.addSubview(webView)
        window.level = .floating
    }

    private func changeWindowLebel() {
        window?.level = window?.level == .normal ? .floating : .normal
    }
}

