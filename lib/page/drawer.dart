import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raising/channel/SmbChannel.dart';
import 'package:raising/image/ExploreFile.dart';
import 'package:raising/model/ExploreNavigator.dart';
import 'package:raising/model/HostModel.dart';

//此类还没重构完成
class HostManage extends StatefulWidget {
  final String hostId;

  @override
  _HostManageState createState() => _HostManageState();

  HostManage({this.hostId});
}

class _HostManageState extends State<HostManage> {
  TextEditingController _nickController = new TextEditingController();
  TextEditingController _hostnameController = new TextEditingController();
  TextEditingController _usernameController = new TextEditingController();
  TextEditingController _pwdController = new TextEditingController();
  bool pwdShow = false; //密码是否显示明文
  GlobalKey _formKey = new GlobalKey<FormState>();
  bool _nameAutoFocus = true;

  HostPO getCurrentHostPO(HostModel hostModel, String hostId) {
    return hostModel.searchById(hostId);
  }

  bool checkHostNickNameDuplicate(HostModel hostModel, String hostNickName) {
    return hostModel.checkDuplicate(hostNickName);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hostId != null) {
      HostModel hostModel = Provider.of<HostModel>(context, listen: false);
      HostPO host = getCurrentHostPO(hostModel, widget.hostId);
      if (host != null) {
        _nickController.text = host.nickName;
        _hostnameController.text = host.hostname;
        _usernameController.text = host.username;
        _pwdController.text = host.password;
      }
    }

    return Scaffold(
        appBar: AppBar(title: Text("添加Host")),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              children: <Widget>[
                TextFormField(
                    autofocus: _nameAutoFocus,
                    controller: _nickController,
//                    initialValue: initSmbName,
                    decoration: InputDecoration(
                      labelText: "昵称",
                      hintText: "命名服务器的昵称",
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) {
                      if (v.trim().isEmpty) {
                        return "必填";
                      }
                      HostModel hostModel = Provider.of<HostModel>(context, listen: false);
//                      hostname.checkDuplicate(_nickController.text);
                      if (checkHostNickNameDuplicate(hostModel, v)) {
                        return "跟现有昵称重复";
                      }
                      return null;
                    }),
                TextFormField(
                    controller: _hostnameController,
//                    initialValue: initSmbName,
                    decoration: InputDecoration(
                      labelText: "Host",
                      hintText: "Host ip 地址",
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) {
                      if (v.trim().isEmpty) {
                        return "必填";
                      }
                      return null;
                    }),
                TextFormField(
                    autofocus: _nameAutoFocus,
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: "用户名",
                      hintText: "提示",
                      prefixIcon: Icon(Icons.person),
                    ),
                    // 校验用户名（不能为空）
                    validator: (v) {
                      return v.trim().isNotEmpty ? null : "用户名";
                    }),
                TextFormField(
                  controller: _pwdController,
                  autofocus: !_nameAutoFocus,
                  decoration: InputDecoration(
                      labelText: "密码",
                      hintText: "Smb密码",
                      prefixIcon: Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(pwdShow ? Icons.visibility_off : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            pwdShow = !pwdShow;
                          });
                        },
                      )),
                  obscureText: !pwdShow,
                  //校验密码（不能为空）
                  validator: (v) {
                    return v.trim().isNotEmpty ? null : "必填";
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 25),
                  child: ConstrainedBox(
                    constraints: BoxConstraints.expand(height: 55.0),
                    child: RaisedButton(
                      color: Theme.of(context).primaryColor,
                      onPressed: _onSubmit,
                      textColor: Colors.white,
                      child: Text("确认"),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  void _onSubmit() async {
    //TODO:这里漏了服务器的种类。
    // 提交前，先验证各个表单字段是否合法
    if ((_formKey.currentState as FormState).validate()) {
//      showLoading(context);
      HostModel hostModel = Provider.of<HostModel>(context, listen: false);
      if (widget.hostId != null) {
        //修复host
        hostModel.replace(HostPO()
          ..id = widget.hostId
          ..nickName = _nickController.text
          ..hostname = _hostnameController.text
          ..username = _usernameController.text
          ..password = _pwdController.text
          ..type = "webdav");
      } else {
        //添加host
        hostModel.insert(HostPO()
          ..id = _nickController.text + "##~##" + (new DateTime.now().millisecondsSinceEpoch).toString()
          ..nickName = _nickController.text
          ..hostname = _hostnameController.text
          ..username = _usernameController.text
          ..password = _pwdController.text
          ..type = "webdav");
      }
      Navigator.of(context).pop();
    }
  }
}

///// Mix-in [DiagnosticableTreeMixin] to have access to [debugFillProperties] for the devtool
//class SmbListManage with ChangeNotifier, DiagnosticableTreeMixin {
//  List<Smb> smblist;
//  int _count = 0;
//
//  int get count => _count;
//
//  void increment() {
//    _count++;
//    notifyListeners();
//  }
//
//  /// Makes `Counter` readable inside the devtools by listing all of its properties
//  @override
//  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
//    super.debugFillProperties(properties);
//    properties.add(IntProperty('count', count));
//  }
//}

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
        child: MediaQuery.removePadding(
      context: context,
      //移除抽屉菜单顶部默认留白
      removeTop: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 38.0),
            child: Row(
              children: <Widget>[
//                    Padding(
//                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                      child: ClipOval(
//                        child: Image.asset(
//                          "imgs/avatar.png",
//                          width: 80,
//                        ),
//                      ),
//                    ),
                Text(
                  "Wendux",
                  style: TextStyle(fontWeight: FontWeight.bold),
                )
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('设置'),
                ),
                const Divider(
                  color: Colors.grey,
                  height: 20,
                  thickness: 3,
                  indent: 0,
                  endIndent: 0,
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('添加Smb链接'),
                  onTap: () {
                    showDialog(context: context, child: HostManage());
                  },
                ),
                HostListDrawer(),
              ],
            ),
          ),
        ],
      ),
    ));
  }
}

class HostListDrawer extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _HostListDrawerState();
  }
}

class _HostListDrawerState extends State<HostListDrawer> {
  @override
  Widget build(BuildContext context) {
    HostModel hostsModel = Provider.of<HostModel>(context);
    return ListView.builder(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        itemCount: hostsModel.hosts.length,
        itemBuilder: (context, index) {
          final item = hostsModel.hosts[index];

          return Dismissible(
            // Each Dismissible must contain a Key. Keys allow Flutter to
            // uniquely identify widgets.
            key: Key(item.id),
            // Provide a function that tells the app
            // what to do after an item has been swiped away.
            onDismissed: (direction) {
              // Remove the item from the data source.
              setState(() {
                hostsModel.remove(index);
              });

              // Then show a snackbar.
              Scaffold.of(context).showSnackBar(SnackBar(content: Text("$item dismissed")));
            },
            // Show a red background as the item is swiped away.
            background: Container(color: Colors.red),
            child: ListTile(
              title: Text('${item.nickName}'),
              trailing: IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: () {
                    showDialog(
                        context: context,
                        child: HostManage(
                          hostId: item.id,
                        ));
                  }),
              onTap: () {
                //TODO: 改成host的分类
                ExploreNavigator catalog = Provider.of<ExploreNavigator>(context, listen: false);
                WebdavExploreFile webdavExploreFile = WebdavExploreFile(item);
                SmbChannel.explorefiles = [webdavExploreFile];
                catalog.refresh(webdavExploreFile, "");
                Navigator.of(context).pop();
              },
            ),
          );
        });
  }
}
