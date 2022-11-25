目前项目结构
├── global.lua      一些全局的设置，比如内置模式、packages
├── packages        packages 描述
│   ├── libcurl
│   ├── openssl
│   └── zlib
├── projects        项目，目前只有shared、static表示全动态、全静态编译的库
│   ├── shared
│   └── static
├── readme.txt
└── src
    └── main.c      Hello World! 只是用来承接库的引用，可以加入自己的测试用例

Q:为什么尝试使用 xmake 来描述库构建过程
A:1.虽然我们目前内部库发布没有太多平台、架构、rel/dbg组合，但是通过代码流程化描述库构建过程一是可以标准化该发布过程，
    避免全手工操作的繁琐和犯错。并更加便捷的切换编译链工具、rel/dbg 等等特性，更快捷的发布。
  2.xmake 自带 xrepo 已经提供了标准化模板，对于我们的需求，我们只需要进行少量定制化。
  3.xmake 已经兼容了各种源码构建工具，cmake、autoconf、perl环境等等，可以帮助我们更快捷的于全平台构建 package

Q:默认编译产物在哪
A:Linux上位于~/.xmake/packages;windows上位于 用户目录C:\Users\用户名\AppData\Local\.xmake\packages

Q:如何更好的组织这个项目的结构
A:个人为这是一个开放性的问题，在一定规则内，xmake 给到了我们较多的权限和自由，也使一些操作有了更多的可能性。
  

recommend1:如果你想重新整理发布路径，我目前认为是通过 hook on_install 动作来完成
recommend2:现在需要提供buildhash、version这些信息看着有些蹩脚，但目前没什么更好的方案。
  后续可将这部分数据放置于配置文件中，实时读取
