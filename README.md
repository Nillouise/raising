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


编码体验：
在做这个项目的时候，我犯了一些错误，主要是没有设计好接口层的交互传参数，对文件的路径已经share的区分没做好，导致错误被传播到代码所以地方，处理起来很难。

目前我采用，不同交互层用不同的vo类的办法，这样令交互的时候跟方便处理，而且可以隔离不同的层的接口，提高同一层稳定性和内聚性，只需要在交互的时候转换一下vo就可以了，这个方法看起来没什么弊端

我还犯了一个错误，在处理smb的连接缓存的时候，试图让应用层来决定初始化，这样很不好，java里对连接池的处理也不是这样，我只需要让smb层面根据hostname、username 做开启连接的处理以及缓存连接就可以了。

我对连接的处理认识不足，导致了这个错误。看起来编程中不同资源的处理定式我还没足够熟悉，想象之后进行图形编程的时候我也会遇到问题吧。
