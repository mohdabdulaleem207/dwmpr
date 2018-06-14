import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'dart:convert';
import 'package:bidirectional_scroll_view/bidirectional_scroll_view.dart';

void main() => runApp(MyApp());

// Bunch o'hard-coded stuff that will get updated from the response of the JSON/GraphQL API.
// General info about a repo (example): https://api.github.com/repos/efortuna/memechat
// PRs (example): https://api.github.com/repos/flutter/flutter/pulls
var profilePic = 'https://avatars0.githubusercontent.com/u/2112792?v=4';
var username = 'efortuna';
var repoInfo = {
  'name': 'A Repository',
  'stargazers_count': '3',
  'forks_count': '5',
};
// Example URL.
var diffUrl =
    'https://patch-diff.githubusercontent.com/raw/flutter/flutter/pull/18193.diff';

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Dude, Where's My Pull Request?",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            leading: Icon(FontAwesomeIcons.github),
            title: Text("Dude, Where's My Pull Request?")),
        body: Center(
          child: Column(
            children: <Widget>[
              CircleAvatar(
                  backgroundImage: NetworkImage(profilePic), radius: 50.0),
              Text(username,
                  style:
                      TextStyle(fontWeight: FontWeight.bold, fontSize: 32.0)),
              Expanded(
                child:
                    ListView(children: List.generate(15, (i) => RepoWidget())),
              ),
            ],
          ),
        ));
  }
}

class RepoWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListTile(
        title: Text(repoInfo['name']),
        // Might want to change how we navigate to the PRs. Maybe a FAB somewhere?
        onTap: () async {
          var result =
              await http.get(diffUrl).then((response) => response.body);
          return Navigator.push(context,
              MaterialPageRoute(builder: (context) => ReviewPage(result)));
        },
        trailing: Row(children: [
          Icon(Icons.star),
          Text(repoInfo['stargazers_count']),
          Icon(FontAwesomeIcons.codeBranch),
          Text(repoInfo['forks_count'])
        ]));
  }
}

class FancyFab extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => FancyFabState();
}

class FancyFabState extends State<FancyFab> with TickerProviderStateMixin {
  AnimationController _controller;

  static const List<IconData> icons = const [
    Icons.check,
    Icons.do_not_disturb,
    Icons.thumb_up,
    Icons.thumb_down,
    FontAwesomeIcons.heart
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(icons.length, (int index) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: _controller, curve: Curves.easeOut),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FloatingActionButton(
              heroTag: null,
              backgroundColor: Theme.of(context).cardColor,
              mini: true,
              child: Icon(icons[index], color: Theme.of(context).accentColor),
              onPressed: () {
                if (icons[index] == Icons.check) {
                  acceptPR(context);
                } else if (icons[index] == Icons.do_not_disturb) {
                  closePR(context);
                } else {
                  addEmoji(context, icons[index]);
                }
                Navigator.pop(context);
              },
            ),
          ),
        );
      }).toList()
        ..add(
          FloatingActionButton(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, Widget child) {
                return Transform.rotate(
                  angle: _controller.value * math.pi,
                  child:
                      Icon(_controller.isDismissed ? Icons.code : Icons.close),
                );
              },
            ),
            onPressed: () {
              if (_controller.isDismissed) {
                _controller.forward();
              } else {
                _controller.reverse();
              }
            },
          ),
        ),
    );
  }

  acceptPR(BuildContext context) {
    // TODO(efortuna): Implement.
    var url = 'https://api.github.com/repos/efortuna/test_commits/pulls/1';
    http.put('$url/merge');
  }

  closePR(BuildContext context) {
    // TODO(efortuna): Implement.
  }

  void addEmoji(BuildContext context, IconData icon) {
    // TODO(efortuna): Implement.
  }
}

class ReviewPage extends StatelessWidget {
  final String prDiff;

  // Yes, this assumes only one review per repo. We could add a button for
  // "next review" or something if we wanted.
  ReviewPage(this.prDiff);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Review Pull Request')),
      body: BidirectionalScrollViewPlugin(
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child:
              RichText(softWrap: false, text: TextSpan(children: styledCode())),
        ),
      ),
      floatingActionButton: FancyFab(),
    );
  }

  List<TextSpan> styledCode() {
    var lines = <TextSpan>[];
    for (var line in LineSplitter.split(prDiff)) {
      var color = Colors.black;
      if (line.startsWith('+')) {
        color = Colors.green;
      } else if (line.startsWith('-')) {
        color = Colors.red;
      }
      lines.add(TextSpan(
          text: line + '\n',
          style: TextStyle(color: color, fontFamily: 'monospace')));
    }
    return lines;
  }
}