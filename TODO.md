work:
分类界面：包括tag跟文件名关键字提取
全球化
错误处理
分享功能
历史列表 已做出雏形
各种排序显示：名字，大小，修改时间，除特殊字符的名字排序，

未来功能：
tiwei浏览器
接入官方社区

接入ios：

支持webdav：基本完成

本地浏览：未支持

https://www.jianshu.com/p/369f00a40cc2 ：完美解决flutter Tab/TabBar切换, TabView 页面状态保持: 解决切换目录的时候的刷新以及状态保存的功能

搜索功能：
    tag搜索
    相似文件名合并排列功能
    文件名关键字搜索
    smb目录搜索 完成，但不知道性能如何
    模糊搜索如拼音、中文搜索 完成，但不知道性能如何

webdav服务器很有可能不支持某些api，比如search

空安全改造：flutter 的空安全还在beta，不好改

bug:
公司的电脑上的模拟器出bug了：SevenZipJBinding wasn't initialized successfully last time
不过等app启动后过几分钟再重新调用函数，这个问题就消失了
回家得测测有没有问题

需要找到办法，在切换页面时，缩略图不会从新加载（或者说让加载速度感受不到）：BugFix，有imageCache。

需要处理webdav无法获取ranges数据的问题，但这个优先级很小

home:
广告 废弃，直接收费
支付 废弃，直接收费
数据后台发送 废弃，直接收费

定时翻页 完成
阅读界面   完成
LRU缓存，压缩，缩略图，首页展示  完成
smb传输打断新起链接 废弃
浏览界面跳转  完成
完善SMb管理   完成

变更朝向的功能 已自带
更换数据库   完成


