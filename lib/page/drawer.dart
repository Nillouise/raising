import 'package:flutter/material.dart';




import 'dart:developer';

class SmbInfoVO {
  String smbname;
  String username;
  String password;
  String domain;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:raising/channel/Smb.dart';
import 'package:raising/model/smb_list_model.dart';

  SmbInfoVO(this.smbname, this.username, this.password, this.domain);
}

class SmbDialogWidge extends StatefulWidget {
  SmbManageState smbManageState;

class SmbManage extends StatefulWidget {
  @override
  _SmbDialogWidgeState createState() => _SmbDialogWidgeState(smbManageState);

  SmbDialogWidge(this.smbManageState);
  _SmbManageState createState() => _SmbManageState();
}

class _SmbDialogWidgeState extends State<SmbDialogWidge> {
class _SmbManageState extends State<SmbManage> {
  TextEditingController _smbnameController = new TextEditingController();
  TextEditingController _usernameController = new TextEditingController();
  TextEditingController _passwordController = new TextEditingController();
  TextEditingController _domainController = new TextEditingController();
  TextEditingController _pwdController = new TextEditingController();
  bool pwdShow = false; //密码是否显示明文
  GlobalKey _formKey = new GlobalKey<FormState>();
  SmbManageState smbManageState;
  bool _nameAutoFocus = true;


  _SmbDialogWidgeState(this.smbManageState);



  @override
  Widget build(BuildContext context) {
    return Center(
//    var gm = GmLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text("添加Smb")),
      body: Padding(
          padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              autovalidate: true,
              child: Column(
        mainAxisSize: MainAxisSize.min,
                children: <Widget>[
          Material(
              child: Form(
                  key: _formKey, //设置globalKey，用于后面获取FormState
                  autovalidate: true, //开启自动校验
                  child: Column(children: <Widget>[
                  TextFormField(
                        autofocus: true,
                      autofocus: _nameAutoFocus,
                      controller: _smbnameController,
                      decoration: InputDecoration(
                            labelText: "SMB命名",
                            hintText: "用于标识此SMB链接",
                            icon: Icon(Icons.person)),
                        // 校验用户名
                        labelText: "名字",
                        hintText: "提示",
                        prefixIcon: Icon(Icons.person),
                      ),
                      // 校验用户名（不能为空）
                      validator: (v) {
                          if(v.trim().length==0){
                            return "SMB命名不能为空";
                          }
                          if(smbManageState.smbList.indexOf (_smbnameController.text)!=-1){
                            return "跟现有SMB命名重复";
                          }
                          return null;
//                          return v.trim().length > 0 ? null : "SMB命名不能为空";
                        return v.trim().isNotEmpty ? null : "必填";









                      }),
                  TextFormField(
                        autofocus: true,
                      autofocus: _nameAutoFocus,
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: "用户名",
                            hintText: "Smb的用户名",
                            icon: Icon(Icons.person)),
                        // 校验用户名
                        hintText: "提示",
                        prefixIcon: Icon(Icons.person),
                      ),
                      // 校验用户名（不能为空）
                      validator: (v) {
                          return v.trim().length > 0 ? null : "用户名不能为空";
                        return v.trim().isNotEmpty ? null : "用户名";
                      }),
                  TextFormField(
                        controller: _passwordController,
                    controller: _pwdController,
                    autofocus: !_nameAutoFocus,
                    decoration: InputDecoration(
                        labelText: "密码",
                            hintText: "您的登录密码",
                            icon: Icon(Icons.lock)),
                        obscureText: true,
                        //校验密码
                        hintText: "秘密",
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(pwdShow
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () {
                            setState(() {
                              pwdShow = !pwdShow;
                            });
                          },
                        )),
                    obscureText: !pwdShow,
                    //校验密码（不能为空）
                    validator: (v) {
                          return v.trim().length > 5 ? null : "密码不能少于6位";
                        }),
                    // 登录按钮
                      return v.trim().isNotEmpty ? null : "必填";
                    },
                  ),
                  Padding(
                      padding: const EdgeInsets.only(top: 28.0),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                    padding: const EdgeInsets.only(top: 25),
                    child: ConstrainedBox(
                      constraints: BoxConstraints.expand(height: 55.0),
                      child: RaisedButton(
                              padding: EdgeInsets.all(15.0),
                              child: Text("确定"),
                        color: Theme.of(context).primaryColor,
                        onPressed: _onLogin,
                        textColor: Colors.white,
                              onPressed: () async {
                                //在这里不能通过此方式获取FormState，context不对
                                //print(Form.of(context));

                                // 通过_formKey.currentState 获取FormState后，
                                // 调用validate()方法校验用户名密码是否合法，校验
                                // 通过后再提交数据。
                                if ((_formKey.currentState as FormState)
                                    .validate()) {
//                                  if(smbManageState.smbList.indexOf (_smbnameController.text)!=-1){
//
//                                  }
                                  //验证通过提交数据
//                                  var bool =
//                                      await showDeleteConfirmDialog1(context);
//                                  if (bool) {
//                                    Navigator.of(context).pop(true);
//                                  }
                                }
                              },
                        child: Text("确认"),
                      ),
                    ),
                        ],
                  ),
                    )
                  ])))
                ],
              ),
    );
            ),
    ));
  }
}

class SmbManage extends StatefulWidget {
  SmbManage({Key key}) : super(key: key);
  void _onLogin() async {
    // 提交前，先验证各个表单字段是否合法
    if ((_formKey.currentState as FormState).validate()) {
//      showLoading(context);

  @override
  SmbManageState createState() {
    return SmbManageState();
      SmbListModel smbListModel =
          Provider.of<SmbListModel>(context, listen: false);
      smbListModel.addSmb(Smb()
        ..id = _smbnameController.text
        ..username = _usernameController.text
        ..password = _pwdController.text);
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

class SmbManageState extends State<SmbManage> {
  final smbList = List<String>.generate(20, (i) => "Item ${i + 1}");

  // 弹出对话框
  Future<bool> showAddSmbDialog() {
    return showDialog<bool>(
class HomeDrawer extends StatelessWidget {
  const HomeDrawer({
    Key key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return  Drawer(
        child: MediaQuery.removePadding(
          context: context,
      builder: (ctx) => SmbDialogWidge(this),
    );
  }

  // 弹出对话框
  Future<bool> showDeleteConfirmDialog1() {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("提示"),
          content: Text("您确定要删除当前文件吗?"),
          actions: <Widget>[
            FlatButton(
              child: Text("取消"),
              onPressed: () => Navigator.of(context).pop(), // 关闭对话框
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
            FlatButton(
              child: Text("删除"),
              onPressed: () {
                //关闭对话框并返回true
                Navigator.of(context).pop(true);
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
        );
      },
    );
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
    final title = 'Dismissing Items';

    SmbListModel smbListModel = Provider.of<SmbListModel>(context);
    return ListView.builder(
        scrollDirection: Axis.vertical,
        shrinkWrap: true,
        itemCount: smbList.length,
        itemCount: smbListModel.smbs.length,
        itemBuilder: (context, index) {
          final item = smbList[index];
          final item = smbListModel.smbs[index];

          return Dismissible(
            // Each Dismissible must contain a Key. Keys allow Flutter to
            // uniquely identify widgets.
            key: Key(item),
            key: Key(item.id),
            // Provide a function that tells the app
            // what to do after an item has been swiped away.
            onDismissed: (direction) {
              // Remove the item from the data source.
              setState(() {
                smbList.removeAt(index);
                smbListModel.removeSmb(item.id);
              });

              // Then show a snackbar.
              Scaffold.of(context)
                  .showSnackBar(SnackBar(content: Text("$item dismissed")));
            },
            // Show a red background as the item is swiped away.
            background: Container(color: Colors.red),
            child: ListTile(
              title: Text('$item'),
              onTap: () async {
                //弹出对话框并等待其关闭
                bool delete = await showAddSmbDialog();
                if (delete == null) {
                  print("取消删除");
                } else {
                  print("已确认删除");
                  //... 删除文件
                }
              },
            ),
            child: ListTile(title: Text('${item.id}')),
          );
        });
  }
}

class HomeDrawer extends StatelessWidget {
  const HomeDrawer({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      //移除顶部padding
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildHeader(), //构建抽屉菜单头部
            Expanded(child: _buildMenus(context)), //构建功能菜单
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.red,
      padding: EdgeInsets.only(top: 40, bottom: 200),
    );
  }

  // 构建菜单项
  Widget _buildMenus(BuildContext context) {
    return ListView(
      children: <Widget>[
        ListTile(
          leading: const Icon(Icons.color_lens),
          title: Text("设置"),
//            onTap: () {
//              Navigator.push(context,
//                  MaterialPageRoute(builder: (context) => FormTestRoute()));
//            }
        ),
        ListTile(
          leading: const Icon(Icons.language),
          title: Text("双周排行榜"),
        ),
        ListTile(
          leading: const Icon(Icons.color_lens),
          title: Text("季度排行榜"),
//            onTap: () {
//              Navigator.push(context,
//                  MaterialPageRoute(builder: (context) => FormTestRoute()));
//            }
        ),
        ListTile(
          leading: const Icon(Icons.language),
          title: Text("年度排行榜"),
        ),
        const Divider(
          color: Colors.blueGrey,
          height: 20,
          thickness: 4,
          indent: 0,
          endIndent: 0,
        ),
        ListTile(
          leading: const Icon(Icons.language),
          title: Text("添加SMB链接"),
//            onTap: () {
//              showDialog<bool>(
//                context: context,
//                builder: (ctx) => SmbDialogWidge(),
//              );
////              SmbDialogWidge();
//            }
        ),
        SmbManage(),
        const Divider(
          color: Colors.blueGrey,
          height: 20,
          thickness: 4,
          indent: 0,
          endIndent: 0,
        ),
      ],
    );
  }
}






































































