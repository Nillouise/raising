import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raising/channel/Smb.dart';
import 'package:raising/model/smb_list_model.dart';
import 'package:raising/model/smb_navigation.dart';

class SmbManage extends StatefulWidget {
  @override
  _SmbManageState createState() => _SmbManageState();
}

class _SmbManageState extends State<SmbManage> {
  TextEditingController _smbIpController = new TextEditingController();
  TextEditingController _smbnameController = new TextEditingController();
  TextEditingController _usernameController = new TextEditingController();
  TextEditingController _pwdController = new TextEditingController();
  bool pwdShow = false; //密码是否显示明文
  GlobalKey _formKey = new GlobalKey<FormState>();
  bool _nameAutoFocus = true;

  @override
  Widget build(BuildContext context) {
//    SmbListModel smbListModel =
//        Provider.of<SmbListModel>(context, listen: false);
//    String initSmbName = "SMB#" + (smbListModel.smbs.length + 1).toString();
//    _smbnameController.text = initSmbName;
//    var gm = GmLocalizations.of(context);
    return Scaffold(
        appBar: AppBar(title: Text("添加Smb")),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            autovalidate: true,
            child: Column(
              children: <Widget>[
                TextFormField(
                    autofocus: _nameAutoFocus,
                    controller: _smbnameController,
//                    initialValue: initSmbName,
                    decoration: InputDecoration(
                      labelText: "SMB昵称",
                      hintText: "命名本SMB的昵称",
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) {
                      if (v.trim().isEmpty) {
                        return "必填";
                      }
                      SmbListModel smbListModel =
                          Provider.of<SmbListModel>(context, listen: false);
                      smbListModel.checkDuplicate(_smbnameController.text);
                      if (smbListModel.checkDuplicate(v)) {
                        return "跟现有Smb链接重复";
                      }
                      return null;
                    }),
                TextFormField(
                    controller: _smbIpController,
//                    initialValue: initSmbName,
                    decoration: InputDecoration(
                      labelText: "Host",
                      hintText: "Smb ip 地址",
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
                        icon: Icon(
                            pwdShow ? Icons.visibility_off : Icons.visibility),
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
    // 提交前，先验证各个表单字段是否合法
    if ((_formKey.currentState as FormState).validate()) {
//      showLoading(context);

      SmbListModel smbListModel =
          Provider.of<SmbListModel>(context, listen: false);

      smbListModel.addSmb(Smb()
        ..id = _smbnameController.text
        ..hostname = _smbIpController.text
        ..username = _usernameController.text
        ..password = _pwdController.text);
      Navigator.of(context).pop();
//      }
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
                    showDialog(context: context, child: SmbManage());
                  },
                ),
                SmbDrawer(),
              ],
            ),
          ),
        ],
      ),
    ));
  }
}

class SmbDrawer extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return _SmbDrawerState();
  }
}

class _SmbDrawerState extends State<SmbDrawer> {
  @override
  Widget build(BuildContext context) {
    SmbListModel smbListModel = Provider.of<SmbListModel>(context);
    return ListView.builder(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        itemCount: smbListModel.smbs.length,
        itemBuilder: (context, index) {
          final item = smbListModel.smbs[index];

          return Dismissible(
            // Each Dismissible must contain a Key. Keys allow Flutter to
            // uniquely identify widgets.
            key: Key(item.id),
            // Provide a function that tells the app
            // what to do after an item has been swiped away.
            onDismissed: (direction) {
              // Remove the item from the data source.
              setState(() {
                smbListModel.removeSmb(item.id);
              });

              // Then show a snackbar.
              Scaffold.of(context)
                  .showSnackBar(SnackBar(content: Text("$item dismissed")));
            },
            // Show a red background as the item is swiped away.
            background: Container(color: Colors.red),
            child: ListTile(
              title: Text('${item.id}'),
              onTap: () {
                SmbListModel smbListModel =
                    Provider.of<SmbListModel>(context, listen: false);
                var smb = smbListModel.smbById(item.id);
                smb.init();
                SmbNavigation smbNavigation =
                    Provider.of<SmbNavigation>(context, listen: false);
                smbNavigation.refresh(context, "", item.id);
                Navigator.of(context).pop();
//                smbListModel.
//                Smb.pushConfig(item.id, hostname, shareName, domain, username, password, path, searchPattern)
              },
            ),
          );
        });
  }
}
