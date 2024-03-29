---
title: 面向对象与设计模式原则
tags:
  - 设计模式
categories:
  - 设计模式
abbrlink: 5f144119
date: 2020-08-23 18:34:36
---

面向对象思想与设计模式原则。

<!-- more -->

### 面向对象

- 面向对象与设计模式旨在构建可维护、可扩展、可复用、灵活性好的软件应用程序。
- 类是对对象的抽象；抽象类是对类的抽象；接口是对行为的抽象。
- 抽象类是自底而上抽象出来的；接口是自顶向下设计出来的。

### 设计模式原则

1. 开闭原则（Open Close Principle）
定义：软件实体（类、模块、函数等）可以扩展，不可修改。
对扩展开放，对修改关闭。面对需求变化，对程序的改动是通过增加新代码进行，而不是更改现有代码。实现热插拔的效果，使程序具有更好的扩展性，易于维护和升级。想要达到这样的效果，需要使用接口和抽象类。
仅对程序中呈现出频繁变化的那些部分作出抽象，对每个部分都刻意进行抽象不是个好主意。
拒绝不成熟的抽象和抽象本身一样重要。

2. 里氏代换原则（Liskov Substitution Principle）
定义：所有引用基类的地方必须能透明地使用其子类的对象。
里氏代换原则是面向对象设计的基本原则之一。 任何基类可以出现的地方，子类一定可以出现。LSP 是继承复用的基石，只有当派生类可以替换掉基类，且软件单位的功能不受到影响时，基类才能真正被复用，而派生类也能够在基类的基础上增加新的行为。里氏代换原则是对开闭原则的补充。实现开闭原则的关键步骤就是抽象化，而基类与子类的继承关系就是抽象化的具体实现，所以里氏代换原则是对实现抽象化的具体步骤的规范。
侧重于子类不应该重写父类方法，但是很多实际场景是不符合的，许多设计模式本身也不符合这个原则。

3. 依赖倒转原则（Dependence Inversion Principle）
定义：高层模块不应该依赖于低层模块，两者都应该依赖于抽象。抽象不应该依赖于细节，细节应该依赖于抽象。
这个原则是开闭原则的基础。针对接口编程，不针对实现编程。依赖于抽象而不依赖于具体。

4. 接口隔离原则（Interface Segregation Principle）
定义：一个类对另一个类的依赖应该建立在最小的接口上。
接口最小化，使用多个隔离的接口，比使用单个接口要好，降低类之间的耦合度。由此可见，其实设计模式就是从大型软件架构出发、便于升级和维护的软件设计思想，它强调降低依赖，降低耦合。

5. 迪米特法则，又称最少知道原则（Demeter Principle）
定义：一个软件实体应当尽可能少地与其他实体发生相互作用，使得系统功能模块相对独立。
一个实体不应该依赖于其它实体太多细节。
如果两个类不必彼此直接通信，那么这两个类就不应当发生直接的相互作用。如果其中一个类需要调用另一个类的某一个方法，可以通过第三者转发这个调用。强调类之间的松耦合，类似面向接口编程。

6. 单一职责原则（Single responsibility principle）
定义：就一个类而言，应该仅有一个引起它变化的原因。
每个类尽量只负责单一功能，高内聚。

- 另：合成复用原则（Composite Reuse Principle）
尽量使用组合/聚合的方式，而不是使用继承。

### 参考

- 《大话设计模式》
- [设计模式详解（总纲）- 左潇龙](https://www.cnblogs.com/zuoxiaolong/p/pattern1.html)
