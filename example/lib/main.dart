import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_place/google_place.dart';
import 'package:googleapis/civicinfo/v2.dart';
import "package:googleapis_auth/auth_io.dart";
import 'package:getwidget/getwidget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DotEnv().load('.env');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Civic Voice',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
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
      body: SafeArea(
        child: Container(
          margin: EdgeInsets.only(right: 20, left: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                decoration: InputDecoration(
                  labelText: "Search",
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
                      title: Text(predictions[index].description),
                      onTap: () {
                        debugPrint(predictions[index].placeId);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailsPage(
                              placeId: predictions[index].placeId,
                              googlePlace: googlePlace,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 10, bottom: 10),
                child: Image.asset("assets/powered_by_google.png"),
              ),
            ],
          ),
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

  DetailsPage({Key key, this.placeId, this.googlePlace}) : super(key: key);

  @override
  _DetailsPageState createState() =>
      _DetailsPageState(this.placeId, this.googlePlace);
}

class _DetailsPageState extends State<DetailsPage>
    with SingleTickerProviderStateMixin {
  final String placeId;
  final GooglePlace googlePlace;
  // define your tab controller here

  _DetailsPageState(this.placeId, this.googlePlace);

  DetailsResult detailsResult;
  List<Uint8List> images = [];

  List<Official> representatives = [];
  List<Office> representativeOffices = [];

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
              backgroundColor: Colors.purple.shade100,
              actions: [
                IconButton(
                  icon: Icon(Icons.menu, color: Colors.white),
                  onPressed: () => {},
                )
              ],
            ),
            floatingActionButton: FloatingActionButton(
              backgroundColor: Colors.blueAccent,
              onPressed: () {
                getDetails(this.placeId);
              },
              child: Icon(Icons.refresh),
            ),
            body: Column(children: <Widget>[
              Container(
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purpleAccent, Colors.purple],
                  ),
                ),
                child: TabBar(
                  tabs: <Widget>[
                    Tab(
                      child: Text("Team"),
                    ),
                    Tab(
                      child: Text("Profile"),
                    ),
                    Tab(
                      child: Text("News"),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.only(left: 5, right: 5),
                      child: ListView.builder(
                        itemCount:
                            representatives.length, //total no of list items
                        itemBuilder: (BuildContext context, int index) {
                          Official representative = representatives[index];
                          Office repOffice = representativeOffices[index];
                          return GestureDetector(
                            onTap: () {
                              print("tapped on item $index");
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    colors: colors[index % colors.length]),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  new BoxShadow(
                                      color: Colors.black54,
                                      blurRadius: 3.5,
                                      offset: new Offset(1.0, 2.0)),
                                ],
                              ),
                              margin: EdgeInsets.only(
                                  top: 10, left: 10, right: 10, bottom: 10),
                              height: 150,
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    //left half image avtar of listitem
                                    flex: 1,
                                    child: Container(
                                      alignment: Alignment.topLeft,
                                      margin:
                                          EdgeInsets.only(left: 10, top: 10),
                                      child: CircleAvatar(
                                        backgroundImage: getProfileImage(
                                            representative.photoUrl),
                                        backgroundColor: Colors.transparent,
                                        radius: 30,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    //center of listitem
                                    flex: 2,
                                    child: Container(
                                      alignment: Alignment.center,
                                      padding:
                                          EdgeInsets.only(top: 10, left: 5),
                                      child: Column(
                                        children: <Widget>[
                                          Expanded(
                                              flex: 4,
                                              child: Container(
                                                alignment: Alignment.centerLeft,
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: <Widget>[
                                                    Text(
                                                      representative.name,
                                                      style: TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                    Text(repOffice.name)
                                                  ],
                                                ),
                                              )),
                                          Expanded(
                                            flex: 3,
                                            child: Container(
                                              child: Row(
                                                children: <Widget>[
                                                  Expanded(
                                                    flex: 1,
                                                    child: Container(
                                                        child: Column(
                                                      children: <Widget>[
                                                        GFIconButton(
                                                          onPressed: () {},
                                                          icon: Icon(
                                                              Icons.facebook),
                                                          size: GFSize.MEDIUM,
                                                          shape:
                                                              GFIconButtonShape
                                                                  .pills,
                                                        ),
                                                      ],
                                                    )),
                                                  ),
                                                  Expanded(
                                                    flex: 1,
                                                    child: Container(
                                                        child: Column(
                                                      children: <Widget>[
                                                        GFIconButton(
                                                          onPressed: () {},
                                                          icon: Icon(Icons
                                                              .email_rounded),
                                                          size: GFSize.MEDIUM,
                                                          shape:
                                                              GFIconButtonShape
                                                                  .pills,
                                                        ),
                                                      ],
                                                    )),
                                                  ),
                                                  Expanded(
                                                    flex: 1,
                                                    child: Container(
                                                        child: Column(
                                                      children: <Widget>[
                                                        GFIconButton(
                                                          onPressed: () {},
                                                          icon: Icon(Icons
                                                              .phone_rounded),
                                                          size: GFSize.MEDIUM,
                                                          shape:
                                                              GFIconButtonShape
                                                                  .pills,
                                                        )
                                                      ],
                                                    )),
                                                  )
                                                ],
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    //right half of listitem
                                    flex: 1,
                                    child: Container(
                                      child: Column(
                                        children: <Widget>[
                                          IconButton(
                                            icon: Icon(
                                                Icons.arrow_forward_ios_sharp),
                                            onPressed: () => {},
                                          ),
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
                    ),
                    Container(
                      margin: EdgeInsets.only(right: 20, left: 20, top: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: images.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  width: 250,
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
                          SizedBox(
                            height: 10,
                          ),
                          Expanded(
                              child: Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: ListView(
                              children: <Widget>[
                                Container(
                                  margin: EdgeInsets.only(left: 15, top: 10),
                                  child: Text(
                                    "Details",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                detailsResult != null &&
                                        detailsResult.types != null
                                    ? Container(
                                        margin:
                                            EdgeInsets.only(left: 15, top: 10),
                                        height: 50,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: detailsResult.types.length,
                                          itemBuilder: (context, index) {
                                            return Container(
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
                                            );
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
                                          ? 'Address: ${detailsResult.formattedAddress}'
                                          : "Address: null",
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
                                          ? 'Geometry: ${detailsResult.geometry.location.lat.toString()},${detailsResult.geometry.location.lng.toString()}'
                                          : "Geometry: null",
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ))
                        ],
                      ),
                    ),
                    Container(
                      color: Colors.green,
                    )
                  ],
                ),
              )
            ])));
  }

/*
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Civic Connections"),
          backgroundColor: Colors.blueAccent,
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.blueAccent,
          onPressed: () {
            getDetails(this.placeId);
          },
          child: Icon(Icons.refresh),
        ),
        body: SafeArea(
            child: Container(
                margin: EdgeInsets.only(right: 20, left: 20, top: 20),
                child:
                    Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                  Expanded(
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: ListView(
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        children: <Widget>[
                          Container(
                            margin: EdgeInsets.only(left: 15, top: 10),
                            child: Text(
                              "Representatives",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                              margin: EdgeInsets.only(left: 15, top: 10),
                              child: Container(
                                  margin: EdgeInsets.only(left: 15, top: 10),
                                  height: 500,
                                  child: SizedBox(
                                    height: 300,
                                    child: ListView.builder(
                                      scrollDirection: Axis.vertical,
                                      shrinkWrap: true,
                                      itemCount: representatives.length,
                                      itemBuilder: (context, index) {
                                        Official representative =
                                            representatives[index];
                                        return Container(
                                          margin: EdgeInsets.only(right: 10),
                                          child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: <Widget>[
                                                (representative.photoUrl !=
                                                            null &&
                                                        representative.name
                                                                .contains(
                                                                    "Shoo") ==
                                                            false)
                                                    ? Container(
                                                        margin: EdgeInsets.only(
                                                            right: 50),
                                                        child: CircleAvatar(
                                                          backgroundColor:
                                                              Colors.brown
                                                                  .shade800,
                                                          child:
                                                              const Text('RC'),
                                                        ))
                                                    : Container(),
                                                Chip(
                                                  label: Text(
                                                    representative.name,
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  backgroundColor:
                                                      Colors.blueAccent,
                                                ),
                                                (representative.channels !=
                                                            null &&
                                                        representative.channels
                                                                .length >
                                                            0)
                                                    ? Container(
                                                        height: 100,
                                                        margin: EdgeInsets.only(
                                                            right: 10),
                                                        child: SizedBox(
                                                            height: 50,
                                                            child: ListView
                                                                .builder(
                                                              scrollDirection:
                                                                  Axis.horizontal,
                                                              itemCount:
                                                                  representative
                                                                      .channels
                                                                      .length,
                                                              itemBuilder:
                                                                  (context,
                                                                      idx) {
                                                                return Container(
                                                                    margin: EdgeInsets.only(
                                                                        right:
                                                                            10),
                                                                    child:
                                                                        Expanded(
                                                                      child: Column(
                                                                          mainAxisSize: MainAxisSize
                                                                              .min,
                                                                          children: <
                                                                              Widget>[
                                                                            Text(
                                                                              representative.channels[idx].toString(),
                                                                              style: TextStyle(
                                                                                color: Colors.white,
                                                                              ),
                                                                            )
                                                                          ]),
                                                                    ));
                                                              },
                                                            )))
                                                    : Container(),
                                                (representative.emails !=
                                                            null &&
                                                        representative
                                                                .emails.length >
                                                            0)
                                                    ? Container(
                                                        height: 100,
                                                        margin: EdgeInsets.only(
                                                            right: 10),
                                                        child: SizedBox(
                                                            height: 100,
                                                            child: ListView
                                                                .builder(
                                                              scrollDirection:
                                                                  Axis.vertical,
                                                              shrinkWrap: true,
                                                              itemCount:
                                                                  representative
                                                                      .emails
                                                                      .length,
                                                              itemBuilder:
                                                                  (context,
                                                                      idx) {
                                                                return Container(
                                                                  margin: EdgeInsets
                                                                      .only(
                                                                          right:
                                                                              10),
                                                                  child: Column(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .min,
                                                                      children: <
                                                                          Widget>[
                                                                        Text(
                                                                          representative
                                                                              .emails[idx],
                                                                          style:
                                                                              TextStyle(
                                                                            color:
                                                                                Colors.white,
                                                                          ),
                                                                        )
                                                                      ]),
                                                                );
                                                              },
                                                            )))
                                                    : Container(),
                                                (representative.urls != null &&
                                                        representative
                                                                .urls.length >
                                                            0)
                                                    ? Container(
                                                        height: 100,
                                                        margin:
                                                            EdgeInsets.only(
                                                                right: 10),
                                                        child: SizedBox(
                                                            height: 100,
                                                            child: ListView
                                                                .builder(
                                                                    scrollDirection:
                                                                        Axis
                                                                            .vertical,
                                                                    shrinkWrap:
                                                                        true,
                                                                    itemCount:
                                                                        representative
                                                                            .urls
                                                                            .length,
                                                                    itemBuilder:
                                                                        (context,
                                                                            idx) {
                                                                      return Container(
                                                                          margin: EdgeInsets.only(
                                                                              right:
                                                                                  10),
                                                                          child:
                                                                              Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
                                                                            Text(
                                                                              representative.urls[idx],
                                                                              style: TextStyle(
                                                                                color: Colors.white,
                                                                              ),
                                                                            )
                                                                          ]));
                                                                    })))
                                                    : Container(),
                                                Container(
                                                    margin: EdgeInsets.only(
                                                        right: 10),
                                                    child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: <Widget>[
                                                          Text(
                                                            representative
                                                                .party,
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                          Text(
                                                            representative
                                                                .address
                                                                .toString(),
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ]))
                                              ]),
                                        );
                                      },
                                    ),
                                  ))),
                          Container(
                              margin: EdgeInsets.only(left: 15, top: 5),
                              child: SizedBox(
                                height: 100,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Icon(Icons.location_on),
                                  ),
                                  title: Text(
                                    detailsResult != null &&
                                            detailsResult.formattedAddress !=
                                                null
                                        ? 'Address: ${detailsResult.formattedAddress}'
                                        : "Address: null",
                                  ),
                                ),
                              )),
                          Container(
                              margin: EdgeInsets.only(left: 15, top: 5),
                              child: SizedBox(
                                height: 100,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Icon(Icons.location_searching),
                                  ),
                                  title: Text(
                                    detailsResult != null &&
                                            detailsResult.geometry != null &&
                                            detailsResult.geometry.location !=
                                                null
                                        ? 'GeoLocation: ${detailsResult.geometry.location.lat.toString()},${detailsResult.geometry.location.lng.toString()}'
                                        : "Geometry: null",
                                  ),
                                ),
                              ))
                        ],
                      ),
                    ),
                  ),
                ]))));
  }
*/

  ImageProvider getProfileImage(String url) {
    try {
      return NetworkImage(url);
    } catch (e) {}
    return AssetImage('assets/govprofile.png');
  }

  Future<RepresentativeInfoResponse> getCivicInfo(String address) async {
    var httpClient = clientViaApiKey(this.googlePlace.apiKEY);
    try {
      final civicinfos = CivicInfoApi(httpClient);
      RepresentativeInfoResponse response = await civicinfos.representatives
          .representativeInfoByAddress(
              address: "1680 kevin drive, san jose, ca 95124",
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
      if (response != null && response.officials != null) {
        print(response.officials);
        print(response.offices);

        return response;
      }
    } finally {
      httpClient.close();
    }
    return null;
  }

  void getDetails(String placeId) async {
    var result = await this.googlePlace.details.get(placeId);
    if (result != null && result.result != null && mounted) {
      var repResponse = await getCivicInfo(result.result.adrAddress);

      setState(() {
        detailsResult = result.result;
        representatives = repResponse.officials;
        representativeOffices = repResponse.offices;
        images = [];
      });

      if (result.result.photos != null) {
        for (var photo in result.result.photos) {
          getPhoto(photo.photoReference);
        }
      }
    }
  }

  void getPhoto(String photoReference) async {
    var result = await this.googlePlace.photos.get(photoReference, null, 400);
    if (result != null && mounted) {
      setState(() {
        images.add(result);
      });
    }
  }
}
