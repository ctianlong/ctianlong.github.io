---
title: 设计模式 - 行为型
tags:
  - 设计模式
categories:
  - 设计模式
abbrlink: ef6a83ef
date: 2020-11-12 15:25:58
---

行为型设计模式简介。

<!-- more -->

### 行为型设计模式

行为型模式(Behavioral Pattern)关注对象之间的通信。其不仅仅关注类和对象的结构，而且重点关注它们之间的相互作用，以及对在不同的对象之间划分责任和算法的抽象化。
通过行为型模式，可以更加清晰地划分类与对象的职责，并研究系统在运行时实例对象之间的交互。在系统运行时，对象并不是孤立的，它们可以通过相互通信与协作完成某些复杂功能，一个对象在运行时也将影响到其他对象的运行。
行为型模式分为类行为型模式和对象行为型模式两种：
- 类行为型模式：类的行为型模式使用继承关系在几个类之间分配行为，类行为型模式主要通过多态等方式来分配父类与子类的职责。
- 对象行为型模式：对象的行为型模式则使用对象的聚合关联关系来分配行为，对象行为型模式主要是通过对象关联等方式来分配两个或多个类的职责。根据“合成复用原则”，系统中要尽量使用关联关系来取代继承关系，因此大部分行为型设计模式都属于对象行为型设计模式。

#### 策略模式
定义算法家族，分别封装，可以相互替换，让算法的变化不影响使用算法的客户。
1个抽象算法类；n个具体算法类；1个上下文，包含1个抽象算法类成员变量，用于维护1个具体算法类对象，并提供1个上下文接口方法，在其内部调用抽象算法类接口方法。
可以和简单工厂相结合，在上下文的构造方法中传入不同标识，由此给内部的抽象算法类成员变量创建不同的具体算法类对象。
<center><img style="border-radius: 0.3125em; box-shadow: 0 2px 4px 0 rgba(34,36,38,.12),0 2px 10px 0 rgba(34,36,38,.08);" src="https://static.tongjilab.cn/blog/20191020215533.png"><div style="display: inline-block; color: #999; padding: 2px;">策略模式</div></center>

#### 观察者模式（发布-订阅模式）
定义一种一对多的依赖关系，让多个观察者对象同时监听某一个主题对象。这个主题对象在状态发生变化时，会通知所有观察者对象，使它们能够自动更新自己。
Java类库：Observer（观察者接口）和Observable（被观察者类，主题）。
对比：事件驱动模式，事件源/事件/监听器。
<center><img style="border-radius: 0.3125em; box-shadow: 0 2px 4px 0 rgba(34,36,38,.12),0 2px 10px 0 rgba(34,36,38,.08);" src="https://static.tongjilab.cn/blog/20191020215639.png"><div style="display: inline-block; color: #999; padding: 2px;">观察者模式</div></center>

#### 迭代器模式
提供一种方法顺序访问一个聚合对象中各个元素，而又不暴露该对象的内部表示。
Java集合类库：Iterable, Iterator, 迭代器作为集合内部类实现，有效利用集合内部状态，并隐藏实现细节。
foreach语法：数组、Iterable接口实现类。
<center><img style="border-radius: 0.3125em; box-shadow: 0 2px 4px 0 rgba(34,36,38,.12),0 2px 10px 0 rgba(34,36,38,.08);" src="https://static.tongjilab.cn/blog/20191020215842.png"><div style="display: inline-block; color: #999; padding: 2px;">迭代器模式</div></center>

#### 职责链模式
使多个对象都有机会处理请求，从而避免请求的发送者和接受者之间的耦合关系。将这些对象连成一条链，沿着该链传递该请求，直到有一个对象处理它为止。
客户端与具体的处理者解耦，客户端只认识一个Hanlder接口，降低了客户端（即请求发送者）与处理者的耦合度。
客户端和处理者都不关心职责链的具体结构，而是交给职责链的创造者，也正因为如此，当在职责链中添加处理者的时候，这对客户端和处理者来说，都是透明的，二者不知道也不必要知道职责链的变化。
<center><img style="border-radius: 0.3125em; box-shadow: 0 2px 4px 0 rgba(34,36,38,.12),0 2px 10px 0 rgba(34,36,38,.08);" src="https://static.tongjilab.cn/blog/20191020220808.png"><div style="display: inline-block; color: #999; padding: 2px;">职责链模式</div></center>

#### 模板方法模式
定义一个操作中的算法的骨架，而将一些步骤延迟到子类中。模板方法使得子类可以不改变一个算法的结构即可重定义该算法的某些特定步骤。
模板方法模式通过把不变行为搬移到超类，去除子类中的重复代码来体现代码复用。
为了不强制子类实现不必要的抽象方法，但又不剥夺子类自由选择的权利，我们可以在抽象父类提供一个默认的空实现，来让子类自由选择是否要覆盖掉这些方法。
Java应用举例：类加载器ClassLoader定义好查找类的算法，保证双亲委派机制
<center><img style="border-radius: 0.3125em; box-shadow: 0 2px 4px 0 rgba(34,36,38,.12),0 2px 10px 0 rgba(34,36,38,.08);" src="https://static.tongjilab.cn/blog/20191020221044.png"><div style="display: inline-block; color: #999; padding: 2px;">模板方法模式</div></center>

#### 访问者模式
表示一个作用于某对象结构中的各元素的操作。它使你可以在不改变各元素的类的前提下定义作用于这些元素的新操作。
元素：数据结构，接受访问者
访问者：作用于数据结构上的操作、算法，分别实现每一种具体元素的访问操作
对象结构：一个抽象表述，可理解为具有容器性质或者复合对象特性的类，含有一组元素，并且可以迭代这些元素，供访问者访问。
将数据结构和作用于结构上的操作解耦合，适用于数据结构相对稳定算法又易变化的系统。
倾斜的开闭原则：增加操作（访问者）容易，符合开闭原则，此为优点；增加新的数据结构（元素）困难，会破坏开闭原则，此为缺点。
通过两次动态单分派（动态多态）实现伪动态双分派（Java是静态多分派、动态单分派语言）。
进一步，可以将元素提炼出层次结构，针对层次结构提供操作的方法，能够实现针对层次定义操作以及跨越层次定义操作。
<center><img style="border-radius: 0.3125em; box-shadow: 0 2px 4px 0 rgba(34,36,38,.12),0 2px 10px 0 rgba(34,36,38,.08);" src="https://static.tongjilab.cn/blog/20191020221542.png"><div style="display: inline-block; color: #999; padding: 2px;">访问者模式</div></center>

#### 命令模式
将一个请求封装为一个对象，从而使你可用不同的请求对象对客户进行参数化；对请求排队或记录请求日志，以及支持可撤销的操作。
在软件系统中，“行为请求者”与“行为实现者”通常呈现一种“紧耦合”。但在某些场合，比如要对行为进行“记录、撤销/重做、事务”等处理，这种无法抵御变化的紧耦合是不合适的。在这种情况下，需要将“行为请求者”与“行为实现者”解耦，可以将一组行为抽象为对象，实现二者之间的松耦合。
类比：需求方client——产品经理invoker——程序员receiver，需求/bug/问题相当于command
<center><img style="border-radius: 0.3125em; box-shadow: 0 2px 4px 0 rgba(34,36,38,.12),0 2px 10px 0 rgba(34,36,38,.08);" src="https://static.tongjilab.cn/blog/20191020224429.png"><div style="display: inline-block; color: #999; padding: 2px;">命令模式</div></center>

#### 状态模式
当一个对象的内在状态改变时允许改变其行为，这个对象看起来像是改变了其类。
控制对象状态的条件表达式过于复杂，把状态的判断逻辑转移到表示不同状态的一系列类中，简化复杂的判断逻辑。
结构上与策略模式相似。
<center><img style="border-radius: 0.3125em; box-shadow: 0 2px 4px 0 rgba(34,36,38,.12),0 2px 10px 0 rgba(34,36,38,.08);" src="https://static.tongjilab.cn/blog/20191020233459.png"><div style="display: inline-block; color: #999; padding: 2px;">状态模式</div></center>

#### 解释器模式
给定一个语言，定义它的文法的一种表示，并定义一个解释器，这个解释器使用该表示来解释语言中的文字。
上下文无关文法：终结符、非终结符、规则集合、起始符号（非终结符号集的一个元素）
<center><img style="border-radius: 0.3125em; box-shadow: 0 2px 4px 0 rgba(34,36,38,.12),0 2px 10px 0 rgba(34,36,38,.08);" src="https://static.tongjilab.cn/blog/20191020233556.png"><div style="display: inline-block; color: #999; padding: 2px;">解释器模式</div></center>

#### 中介者模式
用一个中介对象来封装一系列的对象交互。中介者使各对象不需要显式地相互引用，从而使其耦合松散，而且可以独立地改变它们之间的交互。
解决一系列对象之间复杂的耦合关系，往往是“多对多”耦合关系，采用一个中介者对象将这一系列对象集中管理，而各个对象也将自己与其它对象的交互行为委托给中介者处理，从而减少这一系列对象之间的耦合。
<center><img style="border-radius: 0.3125em; box-shadow: 0 2px 4px 0 rgba(34,36,38,.12),0 2px 10px 0 rgba(34,36,38,.08);" src="https://static.tongjilab.cn/blog/20191020234246.png"><div style="display: inline-block; color: #999; padding: 2px;">中介者模式</div></center>

#### 备忘录模式
在不破坏封装性的前提下，捕获一个对象的内部状态，并在该对象之外保存这个状态。该对象可以借此恢复到原先保存的状态。
发起者：创建包含自身状态的一份备忘录，可通过备忘录恢复自身状态；
备忘录：保存发起者的某一时刻的内部状态；
管理者：保存、管理备忘录；
优点：发起者无需管理自己的状态，备份到外部，可以给外部提供一个操作该对象内部状态的接口，保持封装的边界。
缺点：备忘录信息所占用资源可能较大，管理者无法预知备份的信息大小。
<center><img style="border-radius: 0.3125em; box-shadow: 0 2px 4px 0 rgba(34,36,38,.12),0 2px 10px 0 rgba(34,36,38,.08);" src="https://static.tongjilab.cn/blog/20191020234856.png"><div style="display: inline-block; color: #999; padding: 2px;">备忘录模式</div></center>

### 参考

- 《大话设计模式》
- [设计模式大杂烩（24种设计模式的总结以及学习设计模式的几点建议）- 左潇龙](http://www.zuoxiaolong.com/blog/article.ftl?id=100)