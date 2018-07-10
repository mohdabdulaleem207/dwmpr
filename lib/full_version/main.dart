// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;

import 'github/graphql.dart' as graphql;
import 'github/user.dart';
import 'github/pullrequest.dart';

import 'review_code.dart';
import 'utils.dart';

// Github brand colors
// https://gist.github.com/christopheranderton/4c88326ab6a5604acc29
final Color githubBlue = Color(0xff4078c0);
final Color githubGrey = Color(0xff333000);
final Color githubPurple = Color(0xff6e5494);

void main() => runApp(MyApp());

// Root widget of the app
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Dude, Where's My Pull Request?",
      theme: ThemeData(
        primaryColor: githubGrey,
        accentColor: githubBlue,
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
            child: FutureBuilder(
          future: graphql.user(),
          builder: _buildUser,
        )));
  }
}

/// Displays the app's main body, and is dependent on the UserDetails inherited widget
class Body extends StatelessWidget {
  final User user;
  Body(this.user);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: UserBanner(user),
        ),
        Expanded(
          child: FutureBuilder(
              // Hardcoding user for testing purposes
              // future: openPullRequestReviews(user.login),
              future: graphql.openPullRequestReviews('hixie'),
              builder: _buildPRList),
        ),
      ],
    );
  }
}

/// Displays the user's login and avatar
class UserBanner extends StatelessWidget {
  final User user;
  UserBanner(this.user);

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      CircleAvatar(backgroundImage: NetworkImage(user.avatarUrl), radius: 50.0),
      Text(
        user.login,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25.0),
      ),
    ]);
  }
}

/// Displays a list of pull requests, from the PullRequestDetails inherited widget
class PullRequestList extends StatelessWidget {
  final List<PullRequest> prs;
  PullRequestList(this.prs);

  @override
  Widget build(BuildContext context) => ListView(
        children: prs
            .map((pr) => RepoWidget(pr))
            .toList(),
      );
}

class RepoWidget extends StatelessWidget {
  final PullRequest pullRequest;
  RepoWidget(this.pullRequest);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(pullRequest.repo.name),
      subtitle: Text(pullRequest.title),
      onTap: () async {
        var result = await http
            .get(pullRequest.diffUrl)
            .then((response) => response.body);
        return Navigator.push(context,
            MaterialPageRoute(builder: (context) => ReviewPage(result, pullRequest.url)));
      },
      trailing: Row(
        children: <Widget>[
          Icon(Icons.star, color: githubPurple),
          Text(prettyPrintInt(pullRequest.repo.starCount)),
        ],
      ),
    );
  }
}

Widget _buildUser(BuildContext context, AsyncSnapshot<User> snapshot) {
  if (snapshot.connectionState == ConnectionState.done)
    return Body(snapshot.data);
  else
    return CircularProgressIndicator();
}

Widget _buildPRList(BuildContext context, AsyncSnapshot<List<PullRequest>> snapshot) {
    if (snapshot.connectionState == ConnectionState.done) {
      return snapshot.data.length != 0
          ? PullRequestList(snapshot.data)
          : Center(child: Text('No PR reviews for you'));
    } else {
      return Center(child: CircularProgressIndicator());
    }
}