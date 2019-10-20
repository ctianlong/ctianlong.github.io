---
title: 设计模式 - 创建型
tags:
  - 设计模式
categories:
  - 设计模式
abbrlink: d69916f0
date: 2019-09-27 20:14:21
---

创建型设计模式简介。

<!-- more -->

### 创建型设计模式

- 创建型模式(Creational Pattern)对类的实例化过程进行了抽象，能够将软件模块中对象的创建和对象的使用分离。为了使软件的结构更加清晰，外界对于这些对象只需要知道它们共同的接口，而不清楚其具体的实现细节，使整个系统的设计更加符合单一职责原则。
- 创建型模式提供了一种在创建对象的同时隐藏创建逻辑的方式，而不是使用 new 运算符直接实例化对象，这使得程序在判断针对某个给定实例需要创建哪些对象时更加灵活。

#### 简单工厂模式
1个抽象类或接口；n个实现类；1个工厂类根据不同输入标识new不同实现类对象。简便易用、但不符合开闭原则。可以考虑用注解消除elseif。
<center><img style="border-radius: 0.3125em; box-shadow: 0 2px 4px 0 rgba(34,36,38,.12),0 2px 10px 0 rgba(34,36,38,.08);" src="http://static.tongjilab.cn/blog/20191019193513.png"><div style="display: inline-block; color: #999; padding: 2px;">简单工厂模式</div></center>

#### 工厂方法模式
定义一个用于创建对象的接口，让子类决定实例化哪一个类。工厂方法使一个类的实例化延迟到其子类。工厂方法实现时，客户端需要决定实例化哪一个工厂来实现运算类。
将简单工厂模式中的工厂类变为一个工厂抽象接口和多个具体生成对象的工厂。
工厂方法把简单工厂的内部逻辑判断移到了客户端代码来进行。若想增加功能，简单工厂模式要修改工厂类，工厂方法需要增加新的工厂实现类以及改客户端。符合开闭原则。
应用举例：JDBC中Driver和Connection；集合框架中Iterable和Iterator
<center><img style="border-radius: 0.3125em; box-shadow: 0 2px 4px 0 rgba(34,36,38,.12),0 2px 10px 0 rgba(34,36,38,.08);" src="http://static.tongjilab.cn/blog/20191019194441.png"><div style="display: inline-block; color: #999; padding: 2px;">工厂方法模式</div></center>

#### 抽象工厂模式
提供一个创建一系列相关或相互依赖对象的接口（抽象工厂接口中的createXXX方法），而无需指定它们具体的类。在工厂方法基础上增加多种产品。
应用举例：JDK集合框架中，两个产品：Iterator和ListIterator，工厂接口：List，具体工厂类：LinkedList和ArrayList
<center><img style="border-radius: 0.3125em; box-shadow: 0 2px 4px 0 rgba(34,36,38,.12),0 2px 10px 0 rgba(34,36,38,.08);" src="http://static.tongjilab.cn/blog/20191020084431.png"><div style="display: inline-block; color: #999; padding: 2px;">抽象工厂模式</div></center>

#### 单例模式
保证一个类仅有一个实例，并提供一个访问它的全局访问点。对唯一实例的受控访问。
懒汉式，需要考虑线程安全：使用双重检验锁DCL，判断两次实例是否存在，加一次锁，同时将instance声明为volatile，禁止指令重排序。
饿汉式，static final field
内部类（推荐）、枚举（防止反序列化）
<center><img style="border-radius: 0.3125em; box-shadow: 0 2px 4px 0 rgba(34,36,38,.12),0 2px 10px 0 rgba(34,36,38,.08);" src="http://static.tongjilab.cn/blog/20191020084627.png"><div style="display: inline-block; color: #999; padding: 2px;">单例模式</div></center>

#### 原型模式
从一个对象再创建另外一个可定制的对象，不需要知道创建的细节。Cloneable接口。
初始化信息不发生变化的情况下，克隆是创建对象最好的方式，既隐藏对象创建的细节，又对性能大大提高（不用执行new方法）。
Cloneable, clone(),深复制、浅复制。
<center><img style="border-radius: 0.3125em; box-shadow: 0 2px 4px 0 rgba(34,36,38,.12),0 2px 10px 0 rgba(34,36,38,.08);" src="http://static.tongjilab.cn/blog/20191020084806.png"><div style="display: inline-block; color: #999; padding: 2px;">原型模式</div></center>

#### 建造者模式
将一个复杂对象的构建与它的表示分离，使得同样的构建过程可以创建不同的表示。
1个建造者接口，定义建造的各个步骤；n个具体建造者，实现接口，构建和装配具体的产品；1个指挥者聚合一个建造者，指挥建造过程。
常见的一种使用方式可以去除Builder和Director，由Client充当Director角色，同时ConcreteBuilder作为Product的静态内部类。
<center><img style="border-radius: 0.3125em; box-shadow: 0 2px 4px 0 rgba(34,36,38,.12),0 2px 10px 0 rgba(34,36,38,.08);" src="http://static.tongjilab.cn/blog/20191020084858.png"><div style="display: inline-block; color: #999; padding: 2px;">建造者模式</div></center>

### 参考

- 《大话设计模式》
- [设计模式大杂烩（24种设计模式的总结以及学习设计模式的几点建议）- 左潇龙](http://www.zuoxiaolong.com/blog/article.ftl?id=100)