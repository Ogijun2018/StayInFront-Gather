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
    // リンクのクリックをデフォルトブラウザで開くためのデリゲート設定
    webView.navigationDelegate = self
    webView.uiDelegate = self
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

// MARK: - リンクをデフォルトブラウザで開く
extension WindowController: WKNavigationDelegate, WKUIDelegate {

  func webView(_ webView: WKWebView,
               createWebViewWith configuration: WKWebViewConfiguration,
               for navigationAction: WKNavigationAction,
               windowFeatures: WKWindowFeatures) -> WKWebView? {
    if let url = navigationAction.request.url {
      NSWorkspace.shared.open(url)
    }
    return nil
  }

  /// ユーザーがクリックしたリンクのうち、Gather以外の外部URLはデフォルトブラウザで開く。
  /// Gather自身(gather.town)のページ遷移やログイン等のリダイレクトはアプリ内に残す。
  func webView(_ webView: WKWebView,
               decidePolicyFor navigationAction: WKNavigationAction,
               decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
    if navigationAction.navigationType == .linkActivated,
       let url = navigationAction.request.url,
       let scheme = url.scheme?.lowercased(),
       scheme == "http" || scheme == "https",
       !isGatherHost(url.host) {
      NSWorkspace.shared.open(url)
      decisionHandler(.cancel)
      return
    }
    decisionHandler(.allow)
  }

  /// gather.town もしくはそのサブドメインかどうか
  private func isGatherHost(_ host: String?) -> Bool {
    guard let host else { return false }
    return host == "gather.town" || host.hasSuffix(".gather.town")
  }
}

// MARK: - カメラ/マイクの許諾
extension WindowController {

  /// getUserMedia に対する許諾要求。
  /// このデリゲートを実装しないと、WebKitが独自の許諾ダイアログを毎回表示し、
  /// その結果はアプリの再起動やページ再読み込みをまたいで保持されない。
  /// Gatherからの要求はアプリ側で常に許可し、許諾の記録をmacOSのプライバシー設定に
  /// 一本化することで、システムのダイアログに一度答えれば以降は何も表示されなくなる。
  func webView(_ webView: WKWebView,
               requestMediaCapturePermissionFor origin: WKSecurityOrigin,
               initiatedByFrame frame: WKFrameInfo,
               type: WKMediaCaptureType,
               decisionHandler: @escaping (WKPermissionDecision) -> Void) {
    // スペース内に埋め込まれた外部サイトなど、Gather以外からの要求はユーザーに委ねる
    guard isGatherHost(origin.host) else {
      decisionHandler(.prompt)
      return
    }
    decisionHandler(.grant)
  }
}

