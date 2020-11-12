import 'package:flutter/material.dart';
import 'package:raising/dao/Repository.dart';
import 'package:raising/page/rank.dart';
import 'package:sqflite/sqflite.dart';

class CrudSql extends StatefulWidget {
  final String tablename;

  CrudSql(this.tablename);

  @override
  _CrudSqlState createState() {
    return _CrudSqlState();
  }
}

class _CrudSqlState extends State<CrudSql> {
  static Database _db;

  Future<List<Map<String, dynamic>>> listData() async {
    _db = Repository.db;
    List<Map<String, dynamic>> list = await _db.transaction((txn) async {
      return await txn.rawQuery("SELECT * FROM " + widget.tablename);
//      return await txn.rawQuery("PRAGMA table_info(" + widget.tablename + ");");
    });
    return list;
  }

  Future<bool> deleteData(Map<String, dynamic> data) async {
    _db = Repository.db;
    return await _db.transaction((txn) async {
      List<Map<String, dynamic>> tab = await txn.rawQuery("PRAGMA table_info(" + widget.tablename + ");");
      for (Map<String, dynamic> t in tab) {
        if (t['pk'] == 1) {
          await txn.rawDelete("delete from " + widget.tablename + " where " + t['name'] + "= ?", [data[t['name']]]);
          return true;
        }
      }
      return false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: listData(),
      builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            // 请求失败，显示错误
            return Text("Error: ${snapshot.error}");
          } else {
            return ListView.builder(
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                itemCount: snapshot.data.length,
                itemBuilder: (context, index) {
                  final item = snapshot.data[index];

                  return Dismissible(
                    // Each Dismissible must contain a Key. Keys allow Flutter to
                    // uniquely identify widgets.
                    key: Key(index.toString()),
                    // Provide a function that tells the app
                    // what to do after an item has been swiped away.
                    onDismissed: (direction) {
                      // Remove the item from the data source.
                      setState(() async {
                        await deleteData(item);
                        // Then show a snackbar.
                        Scaffold.of(context).showSnackBar(SnackBar(content: Text("$item dismissed")));
                      });
                    },
                    // Show a red background as the item is swiped away.
                    background: Container(color: Colors.red),
                    child: ListTile(
                      title: Text('${item}'),
                      trailing: IconButton(icon: Icon(Icons.settings), onPressed: () {}),
                      onTap: () async {
//                        await deleteData(item);
                      },
                    ),
                  );
                });
          }
        }

        return Center(child: CircularProgressIndicator());
      },
    );
  }
}

class TablesSql extends StatefulWidget {
  TablesSql({Key key}) : super(key: key);

  @override
  _TablesSqlState createState() {
    return _TablesSqlState();
  }
}

class _TablesSqlState extends State<TablesSql> {
  static Database _db;

  Future<List<Map<String, dynamic>>> listTableName() async {
    _db = Repository.db;
    List<Map<String, dynamic>> list = await _db.transaction((txn) async {
      return await txn.rawQuery("SELECT * FROM sqlite_master where type = ? ORDER BY name;", ['table']);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: listTableName(),
      builder: (BuildContext context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            // 请求失败，显示错误
            return Text("Error: ${snapshot.error}");
          } else {
            return ListView.builder(
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                itemCount: snapshot.data.length,
                itemBuilder: (context, index) {
                  final item = snapshot.data[index];

                  return Dismissible(
                    // Each Dismissible must contain a Key. Keys allow Flutter to
                    // uniquely identify widgets.
                    key: Key(index.toString()),
                    // Provide a function that tells the app
                    // what to do after an item has been swiped away.
                    onDismissed: (direction) {
                      // Remove the item from the data source.
//                      setState(() {
//                        smbListModel.removeSmb(item.id);
//                      });

                      // Then show a snackbar.
//                      Scaffold.of(context).showSnackBar(SnackBar(content: Text("$item dismissed")));
                    },
                    // Show a red background as the item is swiped away.
                    background: Container(color: Colors.red),
                    child: ListTile(
                      title: Text('${item["name"]}'),
                      trailing: IconButton(
                          icon: Icon(Icons.settings),
                          onPressed: () {
//                            showDialog(
//                                context: context,
//                                child: SmbManage(
//                                  smbId: item.id,
//                                ));
                          }),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => Scaffold(body: CrudSql(item["name"]))),
                        );
                      },
                    ),
                  );
                });
          }
        }

        return Center(child: CircularProgressIndicator());
      },
    );
  }
}

class TestPage extends StatelessWidget {
  TestPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List lst = [TablesSql()];

    return Scaffold(
        body: Column(
      children: <Widget>[
        FlatButton(
            onPressed: () async {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Scaffold(body: ScorePage((page, size) async {
                          return await Repository.rankFileKey14("score14 desc", page, size);
                        }))),
              );
            },
            child: Text(
              "rankPage",
              style: TextStyle(fontSize: 18.0),
            )),
        FlatButton(
            onPressed: () async {
              var rankFileKey14 = await Repository.rankFileKey14("score14 desc", 0, 10);
              print(rankFileKey14);
            },
            child: Text(
              "测试数据库",
              style: TextStyle(fontSize: 18.0),
            )),
        TablesSql()
      ],
    ));
  }
}
