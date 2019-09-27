---
title: WebsphereMQ V8 解决客户机连接报2035错误码
tags:
  - WebsphereMQ
categories:
  - MQ
abbrlink: 46226b28
date: 2017-02-06 16:34:36
---

本文介绍应用程序与`WebsphereMQ`连接的两种模式，以及对客户机连接模式下报2035错误码给出解决方法。

<!-- more -->

## 连接模式

应用程序与MQ服务器端的连接模式有两种：**本地绑定** 和 **客户机连接**。本地绑定模式仅适用于应用程序和MQ服务器运行在同一台机器上，而客户机连接模式则没有此限制，可用于两者运行在不同机器或同一台机器上。不过当应用程序和和MQ 服务器运行于同一台机器上时，一般推荐使用本地绑定模式，该模式下两者通过进程间通讯 (IPC) 协议进行通信，传输效率较高，且不受网络状况影响。

- 本地绑定模式配置比较简单，一般情况下，只要在应用程序中提供队列管理器名称，即可连接到本地MQ服务器上的队列管理器上，不需要提供MQ服务器主机名，监听端口和服务器连接通道名称。
- 客户机连接模式比本地绑定模式配置稍微复杂，需要在MQ服务器中创建服务器连接通道，注意此处的通道类型为服务器连接通道，该通道名称需要在应用程序中配置，比如配置在`MQEnvironment.channel`属性中，此外还需要配置队列管理器所在的主机名，监听端口。

## 解决客户机连接报2035错误码

本地绑定模式的连接一般不会出什么问题，而在客户机连接模式时可能出现`MQRC_NOT_AUTHORIZED - 2035`错误，解决这个问题需要注意以下几点。

#### 队列管理器是否开启通道认证记录

通道认证记录用来允许或阻止客户端应用程序对MQ队列管理器的连接，如果开启了，则需要保证当前的通道认证记录中的配置项允许你的应用程序通过你选定的服务器连接通道进行连接。常见的认证规则可以通过用户名、IP地址等进行允许或阻止连接的控制，具体的配置方法这里不作详述，需要注意的是队列管理器内置的系统对象，包括各种通道和通道认证记录，可以通过下图所示方式在MQ Explorer查看。如果你使用的是队列管理器内置的服务器连接通道，比如`SYSTEM.DEF.SVRCONN`，则需要考虑内置的通道认证记录，比如默认的`SYSTEM.*` 配置禁用了所有的系统通道，可以将该配置项删除，也可以修改该配置项。
<center><img style="border-radius: 0.3125em; box-shadow: 0 2px 4px 0 rgba(34,36,38,.12),0 2px 10px 0 rgba(34,36,38,.08);" src="http://static.tongjilab.cn/blog/20190926235859.png"><div style="display: inline-block; color: #999; padding: 2px;">队列管理器内置的各种系统通道</div></center>

<center><img style="border-radius: 0.3125em; box-shadow: 0 2px 4px 0 rgba(34,36,38,.12),0 2px 10px 0 rgba(34,36,38,.08);" src="http://static.tongjilab.cn/blog/20190927000022.png"><div style="display: inline-block; color: #999; padding: 2px;">队列管理器内置的通道认证记录</div></center>

关于通道认证记录所造成的访问问题，最简单直接的方式便是将通道认证记录功能关闭，不过这样也就失去了对客户应用程序的连接授权控制。可以通过命令行指令关闭通道认证记录。

```bash
RUNMQSC 队列管理器名称
ALTER QMGR CHLAUTH(DISABLED)
```

也可以通过MQ Explorer关闭。

<center><img style="border-radius: 0.3125em; box-shadow: 0 2px 4px 0 rgba(34,36,38,.12),0 2px 10px 0 rgba(34,36,38,.08);" src="http://static.tongjilab.cn/blog/20190927000055.png"></center>

#### 注意服务器连接通道的`MCAUSER`（MCA用户标识）属性

该属性表示通过该通道连接的应用程序在和队列管理器进行通信时所使用的用户名称，其值必须为MQ服务器上的`mqm`组内的用户，否则便会出现2035错误。需要注意，如果`MCAUSER`为空，则使用运行MQ应用程序所在的操作系统上的用户名称；如果`MCAUSER`不为空，则使用该值作为应用程序连接通道时使用的用户名称。

<center><img style="border-radius: 0.3125em; box-shadow: 0 2px 4px 0 rgba(34,36,38,.12),0 2px 10px 0 rgba(34,36,38,.08);" src="http://static.tongjilab.cn/blog/20190927000219.png"></center>

可以通过命令行指令修改：

```bash
RUNMQSC 队列管理器名称
ALTER CHL(通道名) CHLTYPE(SVRCONN) MCAUSER('指定的用户标识')
```

#### V8版本与服务器连接默认需要密码认证

网上很多资料关于解决2035错误的方法都是对于Websphere MQ V7.x 的，我使用的是V8.0，使用网上的解决方法仍然会报2035错误，后来发现在V8.0中需要多注意一个配置才能解决2035错误。参考：[http://stackoverflow.com/questions/25911557/websphere-mq-v8-mqrc-not-authorized-2035](http://stackoverflow.com/questions/25911557/websphere-mq-v8-mqrc-not-authorized-2035)。

**在V8中，与服务器的连接默认需要密码去认证**，可以通过配置队列管理器的连接认证选项来解决。

- 通过以下命令行指令，将连接认证选项中的`SYSTEM.DEFAULT.AUTHINFO.IDPWOS`的属性配置为`OPTIONAL`。

```bash
ALTER AUTHINFO(SYSTEM.DEFAULT.AUTHINFO.IDPWOS) AUTHTYPE(IDPWOS) CHCKCLNT(OPTIONAL)
```
- 或者直接将连接认证选项置为空，将其完全关闭，指令如下.

```bash
ALTER QMGR CONNAUTH('')
```

在执行完上述两条命令中的任一条后，都需要刷新连接认证的缓存，指令如下。

```bash
REFRESH SECURITY TYPE(CONNAUTH)
```

除了上面两种命令行方式，也可以通过MQ Explorer关闭连接认证，如下图，在队列管理器的扩展属性中将连接认证一栏置为空即可。

<center><img style="border-radius: 0.3125em; box-shadow: 0 2px 4px 0 rgba(34,36,38,.12),0 2px 10px 0 rgba(34,36,38,.08);" src="http://static.tongjilab.cn/blog/20190927001434.png"></center>

---

***通过以上注意点，一般可以解决连接MQ服务器的2035错误。***