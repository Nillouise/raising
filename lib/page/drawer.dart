import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raising/model/ExploreNavigator.dart';
import 'package:raising/model/HostModel.dart';

//此类还没重构完成
class HostManage extends StatefulWidget {
  final HostPO hostId;

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

  HostPO host;
  static const List<String> _HostTypeDrawList = HostPO.hostTypeValues;
  String _selectedHostType = "WebDav";

  bool needAccount = true;

  HostPO getCurrentHostPO(HostModel hostModel, String hostId) {
    return hostModel.searchById(hostId);
  }

  bool checkHostNickNameDuplicate(HostModel hostModel, String hostNickName) {
    return hostModel.checkDuplicate(hostNickName);
  }

  @override
  void initState() {
    super.initState();
    if (widget.hostId != null) {
      _nickController.text = widget.hostId.nickName;
      _hostnameController.text = widget.hostId.hostname;
      _usernameController.text = widget.hostId.username;
      _pwdController.text = widget.hostId.password;
      needAccount = widget.hostId.needAccount;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("添加Host")),
        body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  children: <Widget>[
                    DropdownButton(
//                      hint: Text('Please choose a location'), // Not necessary for Option 1
                      value: _selectedHostType,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedHostType = newValue;
                        });
                      },
                      items: _HostTypeDrawList.map((location) {
                        return DropdownMenuItem(
                          child: new Text(location),
                          value: location,
                        );
                      }).toList(),
                    ),
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
                            if (widget.hostId != null && widget.hostId.nickName == v) {
                              return null;
                            }
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
                        readOnly: !needAccount,
                        style: needAccount
                            ? null
                            : TextStyle(
                                decoration: TextDecoration.lineThrough,
                                decorationColor: const Color(0xff000000),
                              ),
                        decoration: InputDecoration(
                            labelText: "用户名",
                            hintText: "提示",
                            prefixIcon: Icon(Icons.person),
                            suffixIcon: TextButton(
//                              icon: Icon(pwdShow ? Icons.visibility_off : Icons.visibility),
                              child: Text("无需账号"),
                              onPressed: () {
                                setState(() {
//                                  pwdShow = !pwdShow;
                                  needAccount = !needAccount;
                                });
                              },
                            )),
                        // 校验用户名（不能为空）
                        validator: (v) {
                          if (!needAccount) {
                            return null;
                          }
                          return v.trim().isNotEmpty ? null : "用户名";
                        }),
                    TextFormField(
                      controller: _pwdController,
                      autofocus: !_nameAutoFocus,
                      readOnly: !needAccount,
                      style: needAccount
                          ? null
                          : TextStyle(
                              decoration: TextDecoration.lineThrough,
                              decorationColor: const Color(0xff000000),
                            ),
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
                        if (!needAccount) {
                          return null;
                        }
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
            )));
  }

  void _onSubmit() async {
    //TODO:这里漏了服务器的种类。
    // 提交前，先验证各个表单字段是否合法
    if ((_formKey.currentState as FormState).validate()) {
//      showLoading(context);
      HostModel hostModel = Provider.of<HostModel>(context, listen: false);
      HostPO po = HostPO()
        ..nickName = _nickController.text
        ..hostname = _hostnameController.text
        ..username = needAccount ? _usernameController.text : ""
        ..password = needAccount ? _pwdController.text : ""
        ..needAccount = needAccount
        ..type = _selectedHostType;

      if (widget.hostId != null) {
        //修复host
        hostModel.replace(po..id = widget.hostId.id);
      } else {
        //添加host
        hostModel.insert(po..id = _nickController.text + "##~##" + (new DateTime.now().millisecondsSinceEpoch).toString());
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
                          hostId: item,
                        ));
                  }),
              onTap: () {
                //TODO: 改成host的分类
                ExploreNavigator catalog = Provider.of<ExploreNavigator>(context, listen: false);
                catalog.refreshHost(item);
                Navigator.of(context).pop();
              },
            ),
          );
        });
  }
}
