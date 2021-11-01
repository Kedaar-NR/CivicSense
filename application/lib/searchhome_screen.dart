import 'package:flutter/material.dart';
import 'package:google_place/google_place.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'civichome_screen.dart';

class SearchHomePage extends StatefulWidget {
  static const routeName = '/home';

  @override
  _SearchHomePageState createState() => _SearchHomePageState();
}

class _SearchHomePageState extends State<SearchHomePage> {
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
                          builder: (context) => CivicHomePage(
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
