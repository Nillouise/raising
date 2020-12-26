# raising

LAN comic reader app

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

+架构设计：
+
+SMB、webDav、本机文件、数据库设计、缓存、缩略图、文件缓存、错误处理，解压，界面表现，vo的设计。
+
+由于解压跟SMB、webDav、本机文件都是耦合在一起的，而且解压可能会查出各种信息，所以应当使用同一个VO类作为
+所有涉及解压的函数，另一方面，同一个字段应当代表同一个意思，因为可能出现的信息是有限的，所以这种做法应该没什么问题。
+这里不应该用多个不同的vo代表不同的东西，而是应当用字段代表不同的东西，这样api会更灵活。
+
+数据设计方面，小数据量应当直接存成json，而不是单独开字段，增加开发的灵活性，大量数据的不需要索引、检索的字段也应当存成json。
+
+由于缓存机制有问题，不能保存vo，只能保存图片二进制，当然也可以用数据库存vo相关的信息，而且要兼容不同的协议如smb、webdav，
+所以缓存应当使用单独的原子api，用到时再进行组合。而不是单独使用一个api，拿不到缓存就去拿原来的东西
+压缩，缓存，获取数据，不应该放在一个接口中，而是原子性地使用。
+
+文件的唯一标识，
+
+
+设计错误总结目录：
+对于字段会频繁变动的metaVO，应当直接使用插件生成，而不是在网站上生成，而且metaVO应当直接贴合数据库。
+
+大量类跟SMB 绑定在一起，没什么先见之明，连半年的规划都没做好。
+
+目前的功能组织已经很混乱了。
+
+
+
+我先前的设计把解压跟smb的连接耦合在一起了，导致现在要重做才能支持webdav协议，犯了愚蠢的错误，对不同功能的之间的连接没有好的认识。
+


编码体验：
在做这个项目的时候，我犯了一些错误，主要是没有设计好接口层的交互传参数，对文件的路径以及share的区分没做好，导致错误被传播到代码所有地方，处理起来很难。

目前我采用，不同交互层用不同的vo类的办法，这样令交互的时候跟方便处理，而且可以隔离不同的层的接口，提高同一层稳定性和内聚性，只需要在交互的时候转换一下vo就可以了，这个方法看起来没什么弊端

我还犯了一个错误，在处理smb的连接缓存的时候，试图让应用层来决定初始化，这样很不好，java里对连接池的处理也不是这样，我只需要让smb层面根据hostname、username 做开启连接的处理以及缓存连接就可以了。

我对连接的处理认识不足，导致了这个错误。看起来编程中不同资源的处理定式我还没足够熟悉，想象之后进行图形编程的时候我也会遇到问题吧。
