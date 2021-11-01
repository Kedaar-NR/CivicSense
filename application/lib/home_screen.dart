import 'dart:typed_data';
import 'dart:convert';
import 'dart:async';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_place/google_place.dart';
import 'package:googleapis/civicinfo/v2.dart';
import "package:googleapis_auth/auth_io.dart";
import 'package:getwidget/getwidget.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_tags/flutter_tags.dart';

class HomePage extends StatefulWidget {
  static const routeName = '/home';

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  GooglePlace googlePlace;
  List<AutocompletePrediction> predictions = [];

  @override
  void initState() {
    String apiKey = DotEnv().env['API_KEY'];
    googlePlace = GooglePlace(apiKey);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Civic Connect"),
        backgroundColor: Color.fromARGB(255, 255, 49, 212),
        actions: [
          Builder(
              builder: (context) => // Ensure Scaffold is in context
                  IconButton(
                      icon: Icon(Icons.search, color: Colors.white),
                      onPressed: () => Scaffold.of(context).openDrawer()))
        ],
      ),
      body: Container(
        margin: EdgeInsets.only(right: 20, left: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              decoration: InputDecoration(
                labelText: "Input your address",
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.blue,
                    width: 2.0,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Colors.black54,
                    width: 2.0,
                  ),
                ),
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  autoCompleteSearch(value);
                } else {
                  if (predictions.length > 0 && mounted) {
                    setState(() {
                      predictions = [];
                    });
                  }
                }
              },
            ),
            SizedBox(
              height: 10,
            ),
            Expanded(
                child: new Container(
              child: ListView.builder(
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                itemCount: predictions.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: CircleAvatar(
                      child: Icon(
                        Icons.pin_drop,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(predictions[index].description ?? ""),
                    onTap: () {
                      debugPrint(predictions[index].placeId);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailsPage(
                            placeId: predictions[index].placeId ?? "",
                            googlePlace: googlePlace,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ))
          ],
        ),
      ),
    );
  }

  void autoCompleteSearch(String value) async {
    var result = await googlePlace.autocomplete.get(value);
    if (result != null && result.predictions != null && mounted) {
      setState(() {
        predictions = result.predictions;
      });
    }
  }
}

class DetailsPage extends StatefulWidget {
  final String placeId;
  final GooglePlace googlePlace;
  final List<dynamic> newsData;

  DetailsPage({Key key, this.placeId, this.googlePlace, this.newsData})
      : super(key: key);

  @override
  _DetailsPageState createState() =>
      _DetailsPageState(this.placeId, this.googlePlace, this.newsData);
}

class _DetailsPageState extends State<DetailsPage>
    with SingleTickerProviderStateMixin {
  final String placeId;
  final GooglePlace googlePlace;

  List<dynamic> newsData = [];

  // define your tab controller here

  _DetailsPageState(this.placeId, this.googlePlace, this.newsData);

  DetailsResult detailsResult;
  List<Uint8List> images = [];

  List<Official> representatives = [];
  List<Office> representativeOffices = [];
  Map<String, GeographicDivision> representativeDivisions;
  InAppWebViewController _webViewController;
  String learningUrl;

  @override
  void initState() {
    getDetails(this.placeId);

    super.initState();
  }

  List<List<Color>> colors = <List<Color>>[
    [
      Colors.blueAccent,
      Colors.blue.shade50,
    ],
    [
      Colors.greenAccent,
      Colors.green.shade50,
    ],
    [Colors.cyanAccent, Colors.cyan.shade50]
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 3,
        child: Scaffold(
            appBar: AppBar(
              title: Text("Civic Connect"),
              backgroundColor: Color.fromARGB(255, 255, 49, 212),
              /*actions: [
                Builder(
                    builder: (context) => // Ensure Scaffold is in context
                        IconButton(
                            icon: Icon(Icons.menu, color: Colors.white),
                            onPressed: () => Scaffold.of(context).openDrawer()))
              ]*/
            ),
            floatingActionButton: FloatingActionButton(
              backgroundColor: Colors.blueAccent,
              onPressed: () {
                getDetails(this.placeId);
              },
              child: Icon(Icons.refresh),
            ),
            drawer: Drawer(child: renderProfile()),
            body: Column(children: <Widget>[
              new Container(
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purpleAccent, Colors.purple],
                  ),
                ),
                child: TabBar(
                  indicator: UnderlineTabIndicator(
                      borderSide: BorderSide(width: 5.0),
                      insets: EdgeInsets.symmetric(horizontal: 16.0)),
                  indicatorColor: Colors.white,
                  labelStyle: TextStyle(
                      fontSize: 13.0,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.bold), //For Selected tab
                  unselectedLabelStyle: TextStyle(
                      fontSize: 13.0,
                      fontFamily: 'Roboto'), //For Un-selected Tabs

                  tabs: <Widget>[
                    new Container(
                        width: 220.0,
                        child: Tab(
                          child: Text("Representatives"),
                        )),
                    new Container(
                        width: 100.0,
                        child: Tab(
                          child: Text("Local News"),
                        )),
                    new Container(
                        child: Tab(
                      child: Text("Learn"),
                    )),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: <Widget>[
                    renderElectedTeam(),
                    renderNewsContent(),
                    renderLearnModule(),
                  ],
                ),
              )
            ])));
  }

  ImageProvider getProfileImage(String url) {
    try {
      return NetworkImage(url);
    } catch (e) {}
    return AssetImage('assets/govprofile.png');
  }

  Future<RepresentativeInfoResponse> getCivicInfo(String address) async {
    var httpClient = clientViaApiKey(this.googlePlace.apiKEY);
    final civicinfos = CivicInfoApi(httpClient);
    RepresentativeInfoResponse response = await civicinfos.representatives
        .representativeInfoByAddress(
            address: address,
            includeOffices: true,
            levels: [
          "international",
          "administrativeArea1",
          "administrativeArea2",
          "country",
          "locality",
          "regional",
          "subLocality1",
          "subLocality2",
          "special"
        ],
            roles: [
          "headOfState",
          "headOfGovernment",
          "executiveCouncil",
          "governmentOfficer",
          "legislatorUpperBody",
          "legislatorLowerBody",
          "schoolBoard",
          "specialPurposeOfficer",
          "deputyHeadOfGovernment",
          "highestCourtJudge",
          "judge"
        ]);

    // Handle the results here (response.result has the parsed body).
    //console.log("Response", response.result); this works
    // Here is where I assume the logic goes to loop through and assign the information to the "demo "tag
    return response;
  }

  String extractFromAdress(components, type) {
    for (var i = 0; i < components.length; i++) {
      for (var j = 0; j < components[i].types.length; j++) {
        if (components[i].types[j] == type) {
          return components[i].long_name;
        }
      }
    }
    return "";
  }

  String getOfficialTitle(int roleIndex) {
    for (var i = 0; i < this.representativeOffices.length; i++) {
      Office office = this.representativeOffices[i];
      if (office.officialIndices.contains(roleIndex)) {
        return this.representativeDivisions[office.divisionId].name;
      }
    }
    return "";
  }

  String getOfficialRole(int roleIndex) {
    for (var i = 0; i < this.representativeOffices.length; i++) {
      Office office = this.representativeOffices[i];
      if (office.officialIndices.contains(roleIndex)) {
        return office.name;
      }
    }
    return "";
  }

  String getOfficialLink(Official official, String linkType) {
    List<Channel> channels = official.channels;

    if (channels != null && channels.length > 0) {
      for (var i = 0; i < channels.length; i++) {
        if (channels[i].type == "Twitter" && linkType == "Twitter") {
          return "https://twitter.com/" + channels[i].id;
        }

        if (channels[i].type == "Facebook" && linkType == "Facebook") {
          String fbProtocolUrl;
          if (Platform.isIOS) {
            fbProtocolUrl = 'fb://profile/' + channels[i].id;
          } else {
            fbProtocolUrl = 'fb://page/' + channels[i].id;
          }
          return fbProtocolUrl;
        }

        if (channels[i].type == "YouTube" && linkType == "YouTube") {
          return "https://www.youtube.com/user/" + channels[i].id;
        }
      }
    }

    if (official.emails != null &&
        official.emails.length > 0 &&
        linkType == "Email") {
      return official.emails[0];
    }

    if (official.phones != null &&
        official.phones.length > 0 &&
        linkType == "Phone") {
      return official.phones[0];
    }

    return null;
  }

  void getDetails(String placeId) async {
    var result = await this.googlePlace.details.get(placeId);
    if (result != null && result.result != null && mounted) {
      var repResponse = await getCivicInfo(result.result.formattedAddress);

      setState(() {
        detailsResult = result.result;
        representatives = repResponse.officials;
        representativeOffices = repResponse.offices;
        representativeDivisions = repResponse.divisions;
        images = [];
      });

      String searchQuery =
          extractFromAdress(result.result.addressComponents, "city") +
              "\+trending\+issues";
      print(searchQuery);
      searchQuery = "government";

      var response = await http.get(
          Uri.parse(Uri.encodeFull('https://newsapi.org/v2/top-headlines?q=' +
              searchQuery +
              '&sortBy=popularity')),
          headers: {
            "Accept": "application/json",
            "X-Api-Key": "ab31ce4a49814a27bbb16dd5c5c06608"
          });
      var localData = jsonDecode(response.body);
      if (localData != null && localData["articles"] != null) {
        List<dynamic> localArticles = localData["articles"];
        localArticles.sort((a, b) =>
            a["publishedAt"] != null && b["publishedAt"] != null
                ? b["publishedAt"].compareTo(a["publishedAt"])
                : null);
        // if (mouned) {
        this.newsData = localArticles;
      } else {
        this.newsData = [];
      }

      if (result.result != null && result.result.photos != null) {
        List<Photo> photos = result.result.photos;
        for (var photo in photos) {
          getPhoto(photo.photoReference);
        }
      }
    }
  }

  void getPhoto(String photoReference) async {
    if (photoReference != null) {
      var result = await this.googlePlace.photos.get(photoReference, 40, 40);
      if (result != null && mounted) {
        setState(() {
          images.add(result);
        });
      }
    }
  }

  Widget renderNewsContent() {
    return new Column(children: <Widget>[
      new Expanded(
          child: newsData == null || newsData.length == 0
              ? const Center(child: const CircularProgressIndicator())
              : new ListView.builder(
                  itemCount: -1000 == null ? 0 : newsData.length,
                  padding: new EdgeInsets.all(8.0),
                  itemBuilder: (BuildContext context, int index) {
                    return new Card(
                      elevation: 1.7,
                      child: new Padding(
                        padding: new EdgeInsets.all(10.0),
                        child: new Column(
                          children: [
                            new Row(
                              children: <Widget>[
                                new Padding(
                                  padding: new EdgeInsets.only(left: 4.0),
                                  child: new Text(
                                    timeago.format(DateTime.parse(
                                        newsData[index]["publishedAt"])),
                                    style: new TextStyle(
                                      fontWeight: FontWeight.w400,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                                new Padding(
                                  padding: new EdgeInsets.all(5.0),
                                  child: new Text(
                                    newsData[index]["source"]["name"],
                                    style: new TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            new Row(
                              children: [
                                new Expanded(
                                  child: new GestureDetector(
                                    child: new Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        new Padding(
                                          padding: new EdgeInsets.only(
                                              left: 4.0,
                                              right: 8.0,
                                              bottom: 8.0,
                                              top: 8.0),
                                          child: new Text(
                                            newsData[index]["title"],
                                            style: new TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        new Padding(
                                          padding: new EdgeInsets.only(
                                              left: 4.0,
                                              right: 4.0,
                                              bottom: 4.0),
                                          child: new Text(
                                            newsData[index]["description"],
                                            style: new TextStyle(
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      //flutterWebviewPlugin.launch(
                                      //    newsData["articles"][index]["url"]);
                                    },
                                  ),
                                ),
                                new Column(
                                  children: <Widget>[
                                    new Padding(
                                      padding: new EdgeInsets.only(top: 8.0),
                                      child: new SizedBox(
                                        height: 100.0,
                                        width: 100.0,
                                        child: new Image.network(
                                          newsData[index]["urlToImage"],
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            )
                          ],
                        ), ////
                      ),
                    );
                  },
                ))
    ]);
  }

  void launchUrl(String url) async {
    print("lauching profile " + url);
    await canLaunch(url) ? await launch(url) : throw 'Could not launch $url';
  }

  Widget getSocialWidgets(Official official) {
    List<Widget> widgets = [];
    String repEmailProfile = getOfficialLink(official, "Email");
    String repFBProfile = getOfficialLink(official, "Facebook");
    String repTwitterProfile = getOfficialLink(official, "Twitter");
    String repPhoneProfile = getOfficialLink(official, "Phone");
    if (repPhoneProfile != null) {
      widgets.add(Expanded(
          flex: 1,
          child: Container(
            alignment: Alignment.topLeft,
            child: Column(
              children: <Widget>[
                GFIconButton(
                  onPressed: () {
                    launchUrl("tel://" + repPhoneProfile);
                  },
                  icon: Icon(Icons.phone_rounded),
                  size: GFSize.MEDIUM,
                  shape: GFIconButtonShape.pills,
                )
              ],
            ),
          )));
    }

    if (repEmailProfile != null) {
      widgets.add(Expanded(
        flex: 1,
        child: Container(
            alignment: Alignment.topLeft,
            child: Column(
              children: <Widget>[
                GFIconButton(
                  onPressed: () {
                    launchUrl("mailto://" + repEmailProfile);
                  },
                  icon: Icon(Icons.email_rounded),
                  size: GFSize.MEDIUM,
                  shape: GFIconButtonShape.pills,
                ),
              ],
            )),
      ));
    }

    if (repTwitterProfile != null) {
      widgets.add(Expanded(
        flex: 1,
        child: Container(
            alignment: Alignment.topLeft,
            child: Column(
              children: <Widget>[
                GFIconButton(
                  onPressed: () {
                    launchUrl(repTwitterProfile);
                  },
                  icon: new Image.asset("assets/twitter.png"),
                  size: GFSize.MEDIUM,
                  shape: GFIconButtonShape.pills,
                )
              ],
            )),
      ));
    }

    if (repFBProfile != null) {
      widgets.add(Expanded(
        flex: 1,
        child: Container(
            alignment: Alignment.topLeft,
            child: Column(
              children: <Widget>[
                GFIconButton(
                  onPressed: () {
                    launchUrl(repFBProfile);
                  },
                  icon: Icon(Icons.facebook),
                  size: GFSize.MEDIUM,
                  shape: GFIconButtonShape.pills,
                ),
              ],
            )),
      ));
    }

    return Expanded(flex: 1, child: Row(children: widgets));
  }

  Widget renderElectedTeam() {
    return new Container(
      padding: EdgeInsets.only(left: 5, right: 5),
      child: ListView.builder(
        itemCount: representatives.length, //total no of list items
        itemBuilder: (BuildContext context, int index) {
          String repOffice = getOfficialRole(index);
          String repOfficeDivisionName = getOfficialTitle(index);

          Official representative = representatives[index];
          Widget socialWidgets = getSocialWidgets(representative);

          return GestureDetector(
            onTap: () {
              String profileUrl =
                  representative.urls != null && representative.urls.length > 0
                      ? representative.urls[0]
                      : null;
              showModalBottomSheet<void>(
                  context: context,
                  builder: (BuildContext context) {
                    return Wrap(
                      children: <Widget>[
                        Container(
                            height: 300, child: renderWebView(profileUrl)),
                        ElevatedButton(
                          child: const Text('Close'),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    );
                  });
            },
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: colors[index % colors.length]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  new BoxShadow(
                      color: Colors.black54,
                      blurRadius: 3.5,
                      offset: new Offset(1.0, 2.0)),
                ],
              ),
              margin: EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 10),
              height: 150,
              child: Row(
                children: <Widget>[
                  Expanded(
                    //center of listitem
                    flex: 4,
                    child: Container(
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.only(top: 10, left: 5),
                      child: Column(children: <Widget>[
                        Expanded(
                            flex: 4,
                            child: Container(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    representative.name ?? "",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(repOffice ?? ""),
                                  Text(repOfficeDivisionName ?? ""),
                                ],
                              ),
                            )),
                        Expanded(
                            flex: 4,
                            child: Container(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                    alignment: Alignment.topLeft,
                                    child: socialWidgets))),
                      ]),
                    ),
                  ),
                  Expanded(
                    //right half of listitem
                    flex: 1,
                    child: Container(
                      child: Column(
                        children: <Widget>[
                          Container(
                            alignment: Alignment.topRight,
                            margin:
                                EdgeInsets.only(left: 10, top: 10, right: 5),
                            child: CircleAvatar(
                              backgroundImage: getProfileImage(
                                  representative.photoUrl ?? ""),
                              backgroundColor: Colors.transparent,
                              radius: 40,
                            ),
                          ),
                          Container(
                              alignment: Alignment.topRight,
                              margin: EdgeInsets.only(left: 10, top: 10),
                              child: IconButton(
                                  icon: Icon(Icons.arrow_forward_ios_sharp),
                                  onPressed: () {
                                    if (representative.urls != null &&
                                        representative.urls.length > 0) {
                                      navigateWebPage(
                                          representative.urls[0], context);
                                    }
                                  }))
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void navigateWebPage(String newUrl, BuildContext context) {
    if (newUrl != null) {
      print(newUrl);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebHomePage(
            url: newUrl,
          ),
        ),
      );
    }
  }

  Widget renderLearnModule() {
    return renderWebView(
        "https://lime-antler-a34.notion.site/Learn-Section-of-CivicSense-929b3d0ed4e44246afa3bea90bef74c8");
  }

  Widget renderWebView(String webUrl) {
    return Expanded(
        child: Stack(children: [
      Container(
          decoration: BoxDecoration(
              border: Border.all(color: Color.fromARGB(255, 255, 49, 212))),
          child: InAppWebView(
            initialUrlRequest: URLRequest(url: Uri.parse(webUrl)),
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
              //_webViewController = controller;
            },
            androidOnPermissionRequest: (controller, origin, resources) async {
              return PermissionRequestResponse(
                  resources: resources,
                  action: PermissionRequestResponseAction.GRANT);
            },
          ))
    ]));
  }

  Widget renderProfile() {
    List<String> interests = [
      "Environment",
      "Poverty",
      "Education",
      "Energy",
      "Jobs"
    ];

    return new Container(
      margin: EdgeInsets.only(right: 20, left: 20, top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Expanded(
              child: Container(
                  height: 500,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: ListView(
                      children: <Widget>[
                        ExpansionTile(
                            title: Container(
                              margin: EdgeInsets.only(left: 15, top: 10),
                              child: Text(
                                "Preferences",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            children: [
                              (detailsResult != null) &&
                                      detailsResult.types != null
                                  ? Container(
                                      margin:
                                          EdgeInsets.only(left: 15, top: 10),
                                      height: 50,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: detailsResult.types.length,
                                        itemBuilder: (context, index) {
                                          return Column(children: <Widget>[
                                            Container(
                                              margin:
                                                  EdgeInsets.only(right: 10),
                                              child: Chip(
                                                label: Text(
                                                  detailsResult.types[index],
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                backgroundColor:
                                                    Colors.blueAccent,
                                              ),
                                            )
                                          ]);
                                        },
                                      ),
                                    )
                                  : Container(),
                              Container(
                                margin: EdgeInsets.only(left: 15, top: 10),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Icon(Icons.location_on),
                                  ),
                                  title: Text(
                                    detailsResult != null &&
                                            detailsResult.formattedAddress !=
                                                null
                                        ? '${detailsResult.formattedAddress}'
                                        : "null",
                                  ),
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.only(left: 15, top: 10),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Icon(Icons.location_searching),
                                  ),
                                  title: Text(
                                    detailsResult != null &&
                                            detailsResult.geometry != null &&
                                            detailsResult.geometry.location !=
                                                null
                                        ? ' ${detailsResult.geometry.location.lat.toString()},${detailsResult.geometry.location.lng.toString()}'
                                        : "Geometry: null",
                                  ),
                                ),
                              )
                            ]),
                        Container(
                          margin: EdgeInsets.only(left: 15, top: 10),
                          child: Text(
                            "Interests",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                            margin: EdgeInsets.only(left: 15, top: 10),
                            child: renderTags(interests)),
                        Container(
                            margin: EdgeInsets.only(left: 15, top: 10),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                primary:
                                    Colors.pinkAccent.shade100, // background
                                onPrimary: Colors.white, // foreground
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => HomePage(),
                                  ),
                                );
                              },
                              child: Text('Change Location'),
                            )),
                      ],
                    ),
                  ))),
          SizedBox(
            height: 10,
          ),
          Container(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 200,
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Image.memory(
                        images[index],
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  } //

  Widget renderTags(List<String> tags) {
    List items = tags;

    return Tags(
      symmetry: true,
      columns: 1,
      horizontalScroll: false,
      verticalDirection: VerticalDirection.down,
      itemCount: tags.length,
      itemBuilder: (index) {
        final item = items[index];

        return ItemTags(
          key: Key(index.toString()),
          index: index,
          title: item,
          pressEnabled: true,
          activeColor: Color.fromARGB(255, 255, 49, 212),
          singleItem: false,
          splashColor: Color.fromARGB(255, 245, 109, 232),
          combine: ItemTagsCombine.withTextBefore,
          textScaleFactor: 1,
          textStyle: TextStyle(
            fontSize: 14,
          ),
          removeButton: ItemTagsRemoveButton(onRemoved: () {
            // Remove the item from the data source.
            setState(() {
              // required
              items.removeAt(index);
            });
            //required
            return true;
          }),
          onPressed: (item) => print(item),
        );
      },
    );
  }
}

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
