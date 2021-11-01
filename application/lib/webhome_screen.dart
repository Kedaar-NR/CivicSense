import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebHomePage extends StatefulWidget {
  final String url;

  WebHomePage({Key key, this.url}) : super(key: key);

  @override
  _WebHomePageState createState() => _WebHomePageState(this.url);
}

class _WebHomePageState extends State<WebHomePage> {
  final String url;
  InAppWebViewController _webViewController;

  _WebHomePageState(this.url);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text("Civic Connect"),
            backgroundColor: Color.fromARGB(255, 255, 49, 212),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            )),
        body: Container(
            child: Column(children: <Widget>[
          Expanded(
            child: Container(
              child: InAppWebView(
                  initialUrlRequest: URLRequest(url: Uri.parse(this.url)),
                  initialOptions: InAppWebViewGroupOptions(
                      crossPlatform: InAppWebViewOptions(
                        useShouldOverrideUrlLoading: true,
                        mediaPlaybackRequiresUserGesture: false,
                      ),
                      android: AndroidInAppWebViewOptions(
                        useHybridComposition: true,
                      ),
                      ios: IOSInAppWebViewOptions(
                        allowsInlineMediaPlayback: true,
                      )),
                  onWebViewCreated: (InAppWebViewController controller) {
                    this._webViewController = controller;
                  },
                  androidOnPermissionRequest:
                      (InAppWebViewController controller, String origin,
                          List<String> resources) async {
                    return PermissionRequestResponse(
                        resources: resources,
                        action: PermissionRequestResponseAction.GRANT);
                  }),
            ),
          ),
        ])));
  }
}
