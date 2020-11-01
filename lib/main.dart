import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raising/dao/MetaPO.dart';
import 'package:raising/dao/Repository.dart';
import 'package:raising/page/drawer.dart';
import 'package:raising/page/home.dart';

import 'model/smb_list_model.dart';
import 'model/smb_navigation.dart';

void main() => runApp(MyApp());

//class MyApp extends StatelessWidget {
//  // This widget is the root of your application.
//  @override
//  Widget build(BuildContext context) {
//    return MaterialApp(
//      title: 'Flutter Demo',
//      theme: ThemeData(
//        // This is the theme of your application.
//        //
//        // Try running your application with "flutter run". You'll see the
//        // application has a blue toolbar. Then, without quitting the app, try
//        // changing the primarySwatch below to Colors.green and then invoke
//        // "hot reload" (press "r" in the console where you ran "flutter run",
//        // or simply save your changes to "hot reload" in a Flutter IDE).
//        // Notice that the counter didn't reset back to zero; the application
//        // is not restarted.
//        primarySwatch: Colors.blue,
//      ),
//      home: MyHomePage(title: 'Flutter Demo Home Page'),
//    );
//  }
//}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return init();
//    return Scaffold(body: Container(child: TestSlider()));
  }
}

void onStart(SmbListModel model) async {
  await Repository.init();
  await model.loadTodos();
  MetaPo meta = await Repository.getMetaData();
  Duration difference = meta.fileKeyScoreChangeDay.difference(DateTime.now());
  if (difference.inDays.abs() > 0) {
    await Repository.minFileKeyScore14(exp(-0.085 * difference.inDays.abs()));
    await Repository.minFileKeyScore60(exp(-0.02 * difference.inDays.abs()));
  }
  await Repository.saveMetaData(meta);
}

Widget init() {
  // 方法二
  Timer.periodic(Duration(milliseconds: 30000), (timer) async {
    await Repository.getAllInfo();

//    print('一秒钟后输出');
    // 每隔 1 秒钟会调用一次，如果要结束调用
//    timer.cancel();
  });
  return MultiProvider(
      providers: [
        ChangeNotifierProvider<SmbListModel>(
          create: (context) {
            var smbListModel = SmbListModel();
//            Repository.init().then((value) => smbListModel..loadTodos());
            onStart(smbListModel);
            return smbListModel;
          },
          lazy: false,
        ),
        ChangeNotifierProvider<SmbNavigation>(create: (context) => SmbNavigation(), lazy: false),
      ],
      child: MaterialApp(
          title: 'Infinite List Sample',
//        home: InfList(),
          home: Scaffold(
            drawer: HomeDrawer(),
            body: RaisingHome(),
            floatingActionButton: FloatingActionButton(
                //悬浮按钮，用于测试
                child: Icon(Icons.search),
                onPressed: () {
                  Repository.testInsertFileKeyScore();
                }),
          )));
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      drawer: HomeDrawer(),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.display1,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
