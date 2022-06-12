---
title: 设计模式 - 结构型
tags:
  - 设计模式
categories:
  - 设计模式
abbrlink: 5f8379c7
date: 2020-10-04 21:08:15
---

结构型设计模式简介。

<!-- more -->

### 结构型设计模式

结构型模式(Structural Pattern)关注类和对象的组合。其描述如何将类或者对象结合在一起形成更大的结构，就像搭积木，可以通过简单积木的组合形成复杂的、功能更为强大的结构。
结构型模式可以分为类结构型模式和对象结构型模式：
- 类结构型模式关心类的组合，由多个类可以组合成一个更大的系统，在类结构型模式中一般只存在**继承**和**实现**关系。
- 对象结构型模式关心类与对象的**组合**，通过关联关系使得在一个类中定义另一个类的实例对象，然后通过该对象调用其方法。根据“合成复用原则”，在系统中尽量使用关联关系来替代继承关系，因此大部分结构型模式都是对象结构型模式。

#### 代理模式
为其他对象提供一种代理以控制对这个对象的访问。
静态代理（结构上类似装饰器）：例如数据库连接池不真正关闭连接，可用静态代理；
动态代理：例如Java中基于接口的动态代理，Proxy, InvocationHandler, 本质上是先生成class文件再加载生成类，该生成类继承Proxy类并实现入参接口数组中的各个接口，该类持有入参InvocationHandler实例以及接口数组的所有Method对象。
<center><img style="border-radius: 0.3125em; box-shadow: 0 2px 4px 0 rgba(34,36,38,.12),0 2px 10px 0 rgba(34,36,38,.08);" src="https://static.tongjilab.cn/blog/20191020091220.png"><div style="display: inline-block; color: #999; padding: 2px;">代理模式</div></center>

#### 装饰器模式
不必改变原类文件和使用继承的情况下，动态扩展一个对象的功能，动态给一个对象添加一些额外的职责，做代码增强。就增加功能来说，装饰模式比生成子类更加灵活。也可以叫做“复合”设计。
举例：对HttpRequest进行装饰，增加字符编码、过滤敏感词、HTML转义等功能；JAVA IO体系，其中的FilterInputStream即是装饰基类。
<center><img style="border-radius: 0.3125em; box-shadow: 0 2px 4px 0 rgba(34,36,38,.12),0 2px 10px 0 rgba(34,36,38,.08);" src="https://static.tongjilab.cn/blog/20191020090949.png"><div style="display: inline-block; color: #999; padding: 2px;">装饰器模式</div></center>

#### 适配器模式
将一个类的接口转换成客户希望的另一个接口。Adapter模式使得原本由于接口不兼容而不能一起工作的那些类可以一起工作。
实现方式区分：类适配器和对象适配器。
使用目的区分：特殊适配器和缺省适配器。
<center><img style="border-radius: 0.3125em; box-shadow: 0 2px 4px 0 rgba(34,36,38,.12),0 2px 10px 0 rgba(34,36,38,.08);" src="https://static.tongjilab.cn/blog/20191020093358.png"><div style="display: inline-block; color: #999; padding: 2px;">适配器模式</div></center>

#### 外观模式
为子系统的一组接口提供一个一致的界面，此模式定义了一个高层接口，该接口使得这一子系统更加容易使用。
1. 实际使用当中，接口并不是必须的，虽说根据依赖倒置原则，无论是处于高层的外观层，还是处于底层的子系统，都应该依赖于抽象，但是这会倒置子系统的每一个实现都要对应一个接口，从而导致系统的复杂性增加，所以这样做并不是必须的。
2. 外观接口当中并不一定是子系统中某几个功能的组合，也可以是将子系统中某一个接口的某一功能单独暴露给客户端。
3. 外观接口如果需要暴露给客户端很多的功能的话，可以将外观接口拆分为若干个外观接口，如此便会形成一层外观层。
<center><img style="border-radius: 0.3125em; box-shadow: 0 2px 4px 0 rgba(34,36,38,.12),0 2px 10px 0 rgba(34,36,38,.08);" src="https://static.tongjilab.cn/blog/20191020101359.png"><div style="display: inline-block; color: #999; padding: 2px;">外观模式</div></center>

#### 桥接模式
将抽象部分与它的实现部分分离，使它们都可以独立地变化。抽象与实现之间的聚合。
在软件系统中，某些类型由于自身的逻辑，它具有两个或多个维度的变化，可以用桥接模式来应对这种“多维度的变化”，一个维度一个接口，并聚合于最外层抽象中。
<center><img style="border-radius: 0.3125em; box-shadow: 0 2px 4px 0 rgba(34,36,38,.12),0 2px 10px 0 rgba(34,36,38,.08);" src="https://static.tongjilab.cn/blog/20191020205057.png"><div style="display: inline-block; color: #999; padding: 2px;">桥接模式</div></center>

#### 组合模式
将对象组合成树形结构以表示“部分-整体”的层次结构。组合模式使得用户对单个对象和组合对象的使用具有一致性。
树形结构：比如文件系统，对叶子节点和非叶子节点定义统一的操作，客户端无需关心底层具体实现。
<center><img style="border-radius: 0.3125em; box-shadow: 0 2px 4px 0 rgba(34,36,38,.12),0 2px 10px 0 rgba(34,36,38,.08);" src="https://static.tongjilab.cn/blog/20191020205310.png"><div style="display: inline-block; color: #999; padding: 2px;">组合模式</div></center>

#### 享元模式
运用共享技术有效地支持大量细粒度的对象。
它使用共享物件，用来尽可能减少内存使用量以及分享资讯给尽可能多的相似物件；它适合用于当大量物件只是重复因而导致无法令人接受的使用大量内存。通常物件中的部分状态是可以分享的，称为**内部状态**，相对的，**外部状态**则是随外部环境而变化的状态，是无法共享的状态。
享元工厂用于提供可以共享的封装内部状态的对象。
<center><img style="border-radius: 0.3125em; box-shadow: 0 2px 4px 0 rgba(34,36,38,.12),0 2px 10px 0 rgba(34,36,38,.08);" src="https://static.tongjilab.cn/blog/20191020205426.png"><div style="display: inline-block; color: #999; padding: 2px;">享元模式</div></center>

### 参考

- 《大话设计模式》
- [设计模式大杂烩（24种设计模式的总结以及学习设计模式的几点建议）- 左潇龙](http://www.zuoxiaolong.com/blog/article.ftl?id=100)