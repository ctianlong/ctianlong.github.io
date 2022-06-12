---
title: Java OkHttp 一个cookie引发的故障
tags:
  - java
  - http
categories:
  - Java
abbrlink: 918e6e08
date: 2022-04-01 15:25:58
---

本文讲解由于OkHttp的cookie相关的配置导致的问题产生与解决。

<!-- more -->

# 项目场景：

公司业务在腾讯广告平台推广投放，需要对接广告平台，通过API接口上报用户行为转化数据。

---

# 问题描述

项目为Java工程，采用OkHttp开源库实现后台API接口上报，原先一直运行无误，突然某天凌晨运营反馈上报数据异常，公司内部平台显示订单全部上报成功，而腾讯广告后台接受数量一直为0。上报接口地址为：``https://api.weixin.qq.com/marketing/user_actions/add``


---

# 原因分析：

通过增加日志排查接口上报的实际返回结果如下，发现该响应不符合接口文档中的响应字段定义，而且根据错误描述，该接口根本不涉及到``timestamp``, ``nonce``参数，理论上不应该返回此种错误响应。

```json
{
	"code": 12000,
	"message": "Your request is missing a required parameter which is one of access_token, timestamp and nonce.",
	"message_cn": "您的请求缺少必须参数：access_token,timestamp,nonce"
}
```

正常情况下上报成功的响应结果应该如下。

```json
{
	"errcode": 0,
	"errmsg": ""
}
```

项目中采用Gson反序列化返回结果，接受对象定义如下，对象中对errcode有默认值0的定义，因此对于之前的错误响应会将其视作正确返回，造成公司内部平台全部标记为正常上报，而腾讯广告平台侧实际并没有成功接受。

```java
public class WxAdResult implements Serializable {
    private int errcode = 0;
    private String errmsg;
    //省略...
}
```

之所以对errcode默认赋值为0，是因为预期该接口必定会返回errcode，成功时值为0，失败时为对应的错误码，而此次问题中并没有返回errcode，却返回了code参数，参数名称竟然都不一样，没有对应的说明文档可供查询，让人困扰。

随后联系腾讯的技术人员，询问该接口为何会返回这种不符合预期的错误响应，对方答复是我们的API接口调用请求中携带了不安全的cookie，导致在对方网关层就将该请求拦截过滤，类似请求被风控拦截，网关返回的错误响应便是如此结构。（吐槽：像这种传递了非法cookie的请求被拦截为何会返回一个参数缺失的响应，而且和业务接口API描述文档中的字段名称定义不一致，令人费解）

找到了问题所在，再来看为何我们的API请求中会带上此种cookie，cookie名称为`__jsluid_h`，项目使用OkHttp库进行http请求调用，检查了关于cookie的配置，发现初始化`OkHttpClient`时使用了一个自定义的`CookieJar`，代码如下，而该`CookieJar`会将项目中该`OkHttpClient`调用的所有请求的响应返回的cookie（如果有）带入到下一次请求中，也就是说假如其它某个接口响应返回了例如`__jsluid_h`的cookie，则下一次请求中便会带上该cookie进行访问，直到再来一次请求的响应返回了非空的cookie，便会将此前的cookie覆盖，若后续请求的响应一直不含有cookie，则请求一直会带上`__jsluid_h`的cookie，导致所有后续请求都被风控拦截。由于OkHttp库的工具类封装是以前同事做的，所以也不知道为何要采用这样的cookie策略，属于前人留下的坑。
```java
/**
* 部分配置，更改前
*/
OkHttpClient.Builder builder = new OkHttpClient.Builder()
			.cookieJar(new DefaultCookieJar());
/**
* 自定义cookie策略
*/
class DefaultCookieJar implements CookieJar{
	List<Cookie> cookies;
	@Override
	public void saveFromResponse(HttpUrl url, List<Cookie> cookies) {
		this.cookies = cookies;
	}
	@Override
	public List<Cookie> loadForRequest(HttpUrl url) {
		if (cookies != null)
            return cookies;
        return new ArrayList<Cookie>();
	}
}
```

---

# 解决方案：
更改`CookieJar`策略，改为默认的`NO_COOKIES`，使每一次请求都不携带任何cookie信息，代码如下。
```java
/**
* 部分配置，更改后
*/
OkHttpClient.Builder builder = new OkHttpClient.Builder()
			.cookieJar(CookieJar.NO_COOKIES);
```

同时对原有的返回结果封装对象进行修改，避免此种特殊情况下的结果正确性误判。
```java
public class WxAdResult implements Serializable {
    //防止反序列化后默认值被当做成功处理
    private int code = -99999;
    private String errmsg;
    //省略...
}
```
