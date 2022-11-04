import 'package:flutter/material.dart';
import '../main.dart';
import '../widgets/recent_chapters_widget.dart';
import '../services/data_source.dart';
import '../widgets/popular_manga_widget.dart';
import '../screens/favorite_screen.dart';
import '../utils/constants.dart';
import '../models/home_manga_module.dart';
import '../services/database_helper.dart';
import '../widgets/settings.dart';

class ShonenJumpState extends State<ShonenJump> {
  ShonenJumpState({Key? key}) : super();
  Future? recentMangaFuture;
  Future? popularMangaFuture;
  var _isDark;
  // refresh data every 15 minutes
  static const int minutes = 15;

  @override
  void initState() {
    super.initState();
    recentMangaFuture = getMangas('R', 'recent_manga');
    popularMangaFuture = getMangas('P', 'popular_manga');
  }

  // ignore: non_constant_identifier_names
  getMangas(String TAG, String table) async {
    if (await getOfflineManga(table) != null) {
      List<MangaModule> res = await getOfflineManga(table) as List<MangaModule>;
      if (DateTime.fromMillisecondsSinceEpoch(res[0].timeStamp)
                  .add(const Duration(minutes: minutes))
                  .millisecondsSinceEpoch <
              DateTime.now().millisecondsSinceEpoch &&
          await DataSource.isConnectedToInternet() == true) {
        print('data expired');
        var ress = (TAG == 'R')
            ? await DataSource.getLatestManga()
            : await DataSource.getPopularManga();
        await DatabaseHelper.db.clearTable(table);
        for (MangaModule manga in ress) {
          await DatabaseHelper.db.insertHomeManga(manga, table);
        }
        return ress;
      } else {
        print("data is usable");
        return res;
      }
    } else if (await DataSource.isConnectedToInternet() == true) {
      var res = (TAG == 'R')
          ? await DataSource.getLatestManga()
          : await DataSource.getPopularManga();
      for (MangaModule manga in res) {
        await DatabaseHelper.db.insertHomeManga(manga, table);
      }
      return res;
    } else {
      return null;
    }
  }

  getOfflineManga(String table) async {
    var res = await DatabaseHelper.db.getManga(table);
    return res;
  }

  // TODO: swipe to refresh
  refresh() async {}

  @override
  Widget build(context) {
    _isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Manga',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headline1,
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.menu,
          ),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Settings(),
            ),
          ),
          iconSize: 27.0,
          enableFeedback: true,
          splashRadius: 15.0,
        ),
        actions: <Widget>[

        ],
      ),
      body: NotificationListener<OverscrollIndicatorNotification>(
        onNotification: (OverscrollIndicatorNotification overscroll) {
          overscroll.disallowIndicator();
          return true;
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: <Widget>[
              Image.asset('assets/images/mangamain.jpg'),
              Container(
                margin: const EdgeInsets.fromLTRB(5, 10, 0, 5),
                width: double.infinity,
                child: const Text(
                  "Recent Chapters",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
              Container(
                height: 250,
                margin: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: FutureBuilder(
                  future: recentMangaFuture,
                  builder: (context, AsyncSnapshot snapshot) {
                    if (snapshot.data == null) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    } else {
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: snapshot.data.length,
                        itemBuilder: (context, int index) => recentChapterCard(
                            manga: snapshot.data[index], context: context),
                      );
                    }
                  },
                ),
              ),
              Container(
                margin: const EdgeInsets.fromLTRB(5, 10, 0, 5),
                width: double.infinity,
                child: const Text(
                  "Hot Updates",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.start,
                ),
              ),
              Container(
                height: 250,
                margin: const EdgeInsets.fromLTRB(5, 0, 0, 0),
                child: FutureBuilder(
                  future: popularMangaFuture,
                  builder: (context, AsyncSnapshot snapshot) {
                    if (snapshot.data == null) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    } else {
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                       // physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data.length,
                        itemBuilder: (context, int index) => recentChapterCard(
                            manga: snapshot.data[index], context: context),
                      );
                    }
                  },
                ),
              ),

              //image
            ],
          ),
        ),
      ),
    );
  }
}
