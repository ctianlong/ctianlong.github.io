---
title: Markdown转Html应用与实践
tags:
  - markdown
  - Java
  - html
categories:
  - Java
abbrlink: f8b8215b
---

本文讲解了两种Markdown文档转Html文档的方式，并将其应用到工作API文档书写和发布中，以此实现更简便高效的API文档发布和使用。

<!-- more -->

## 问题背景

工作项目中经常需要对外提供API接口，并提供对应的接口文档，供调用方阅读使用。

原先使用Word来书写API文档，线下发送文档给API使用者，这种方式较为不便，每当接口发生改动或新增接口时，都要将更新后的文档再次线下发送给使用者，每次发送都需要人工操作，一旦API接入的使用者数量变多，则通知并发送新文档给每一个使用者将会成为一项耗时且繁琐的工作，并且容易出现发送遗漏，导致调用方未能及时获取新的API信息。

同时，Word文档的保存与共享也较为不便，不同人手中的文档可能不是同一个版本，想要及时获取最新版的文档需要人工沟通。

## 解决方案

为了更方便地共享和使用API文档，将文档获取转为线上，向API使用者提供统一的文档网址，通过浏览器访问阅读。

将API文档由原来的Word书写改为Markdown书写，再将Markdown文件转换为Html文档，最后将Html发布到线上地址供访问，同时也可以将Markdown源文件发布到线上地址，供我方技术人员下载，每当需要更新API文档时可在该文件基础上编辑，无需本地保存。

整个流程如下图所示，技术人员只需将最新的Markdown文件上传，后续流程便会自动化进行，其中最关键的一步是将Markdown文件通过程序自动转换为Html，下一小节将讲述如何将其转换为拥有合适页面样式的Html文档。

![api文档markdown转html工作流程](https://static.tongjilab.cn/blog/api文档markdown转html工作流程.png)

## 实现方式

此处介绍两种Markdown转Html的实现方式。

### 第一种方式

借助Github Markdown API实现，只需通过http接口，直接POST请求调用``https://api.github.com/markdown``，传入所需转换的Markdown文本，返回结果即为转换后的Html文档，示例如下，更多参数详见参考文档地址：[Github Markdown API](https://docs.github.com/en/rest/reference/markdown)

```shell
curl \
  -X POST \
  -H "Accept: application/vnd.github.v3+json" \
  -d '{"text": "# Markdown Title Example"}'\
  https://api.github.com/markdown
  
<h1><a id="user-content-markdown-title-example" class="anchor" href="#markdown-title-example" aria-hidden="true"><span aria-hidden="true" class="octicon octicon-link"></span></a>Markdown Title Example</h1>
```

优点：

- 第三方接口直接调用，简便快捷。

- 支持gfm风格（GitHub Flavored Markdown），配合gfm风格样式（如：[https://github.com/sindresorhus/github-markdown-css](https://github.com/sindresorhus/github-markdown-css)）可实现代码高亮等特性。

缺点：

- 不够灵活，完全依赖github第三方实现，无法自定义更多转换设置和细节，如无法在指定标签中加入指定属性。

- 当前接口不支持Toc目录转换。

### 第二种方式

使用开源Markdown转换三方库，推荐``flexmark-java``库，项目中也采用该库实现。

``flexmark-java``是 CommonMark（spec 0.28）解析器的Java实现，是一款具有源级别AST的CommonMark / Markdown Java解析器。它的优势在于解析速度快，灵活性强，而且能够支持自定义AST，允许对解析过程进行精细控制，内置大量解析器和常用扩展，为解析行为和 HTML 属性样式提供了更多转换设置和选项，如gfm扩展用于支持gfm风格样式，Toc扩展用于创建目录和自定义目录层级等，同时也可以自定义扩展来实现业务需求，例如为标签增加自定义属性等。

#### 基本使用方法

``flexmark-java``的使用也很方便，只需简单配置即可满足常规的转换需求，如下代码是项目中的配置。

```java
/**
 * 将入参Markdown文档转换为html文档
 */
public static String mdToHtmlForApiDoc(String md) {
    // 按需添加扩展
	MutableDataSet options = new MutableDataSet().set(Parser.EXTENSIONS, Arrays.asList(
			// 自定义扩展，为<pre>标签添加line-numbers的class，用于prism库代码左侧行号展示
			CodePreLineNumbersExtension.create(),
			AutolinkExtension.create(),
			EmojiExtension.create(),
			StrikethroughExtension.create(),
			TaskListExtension.create(),
			TablesExtension.create(),
			TocExtension.create()
	))
			// set GitHub table parsing options
			.set(TablesExtension.WITH_CAPTION, false)
			.set(TablesExtension.COLUMN_SPANS, false)
			.set(TablesExtension.MIN_HEADER_ROWS, 1)
			.set(TablesExtension.MAX_HEADER_ROWS, 1)
			.set(TablesExtension.APPEND_MISSING_COLUMNS, true)
			.set(TablesExtension.DISCARD_EXTRA_COLUMNS, true)
			.set(TablesExtension.HEADER_SEPARATOR_COLUMN_MATCH, true)
			// setup emoji shortcut options
			// uncomment and change to your image directory for emoji images if you have it setup
//				.set(EmojiExtension.ROOT_IMAGE_PATH, emojiInstallDirectory())
			.set(EmojiExtension.USE_SHORTCUT_TYPE, EmojiShortcutType.GITHUB)
			.set(EmojiExtension.USE_IMAGE_TYPE, EmojiImageType.IMAGE_ONLY);
	return mdToHtml(md, options);
}
private static String mdToHtml(String md, MutableDataSet options) {
	// uncomment to convert soft-breaks to hard breaks
//		options.set(HtmlRenderer.SOFT_BREAK, "<br />\n");
	Parser parser = Parser.builder(options).build();
	HtmlRenderer renderer = HtmlRenderer.builder(options).build();
	Document document = parser.parse(md);
	return renderer.render(document);
}
```

可以根据自身需求配置各种预定义的扩展，控制转化过程以此得到想要的html内容与格式，例如``TablesExtension``用于配置表格参数，``TocExtension``会解析TOC标识生成目录，其它扩展用法可自行探索，上述代码中的`CodePreLineNumbersExtension`为自定义扩展，后续会讲到。举例说明实际效果。

输入示例Markdown文本：

![markdown示例文本](https://static.tongjilab.cn/blog/markdown示例文本.png)

转换后的html文本：

```html
<h2 id="markdown示例文本">Markdown示例文本</h2>
<p>Markdown是一种轻量级的「标记语言」。</p>
<blockquote>
<p>引用文本：Markdown is a text formatting syntax inspired</p>
</blockquote>
<h3 id="普通内容">普通内容</h3>
<ul>
<li><strong>读一本好书，就是在和高尚的人谈话。</strong> ——歌德</li>
<li><em>雇用制度对工人不利，但工人根本无力摆脱这个制度。</em> ——阮一峰</li>
</ul>
<h3 id="表格">表格</h3>
<table>
<thead>
<tr><th align="left">姓名</th><th align="center">年龄</th><th align="right">工作</th></tr>
</thead>
<tbody>
<tr><td align="left">小可爱</td><td align="center">18</td><td align="right">吃可爱多</td></tr>
<tr><td align="left">小小勇敢</td><td align="center">20</td><td align="right">爬棵勇敢树</td></tr>
</tbody>
</table>
<h3 id="代码块">代码块</h3>
<p>语言名称支持: <code>java</code>, <code>python</code>, <code>js</code>, <code>html</code>, <code>bash</code>, <code>json</code>, <code>yml</code>, <code>xml</code> ...</p>
<pre class="line-numbers"><code class="language-java">public class HelloWorld {
  public static void main(String[] args) {
    System.out.println(&quot;Hello,World!&quot;);
  }
}
</code></pre>
```

#### 完善html文档

注意，通过``flexmark-java``转换得到的html文档只包含网页的主体部分，即body标签里的内容，由于没有样式文件配合，还无法呈现美观的显示效果。因此，我们还需在此基础上添加html、head、body等标签，以及引入所需的link、style等样式和脚本文件来完善html文档，使之展示成最终想要的样式。

此处选择github风格的样式文件，直接引入网上开源的css文件（也可自己写样式）。同时引入`prism.js`实现代码高亮，最终html内容如下所示，其中`<article>`标签内填入上一步所得的html文档即可。

```html
<!DOCTYPE html>
<html>
<head>
    <title>示例标题</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/github-markdown-css/5.1.0/github-markdown.min.css"/>
    <style type="text/css">
    .markdown-body {
        box-sizing: border-box;
        min-width: 200px;
        max-width: 980px;
        margin: 0 auto;
        padding: 45px
    }
    @media(max-width:767px) {
        .markdown-body {
            padding: 15px
        }
    }
    </style>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.26.0/themes/prism.min.css"/>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.26.0/plugins/line-numbers/prism-line-numbers.min.css"/>
</head>
<body class="markdown-body">
    <article>
    	！此处替换为上一步转换得到的html文本！
    </article>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.26.0/components/prism-core.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.26.0/plugins/autoloader/prism-autoloader.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.26.0/plugins/line-numbers/prism-line-numbers.min.js"></script>
</body>
</html>
```

最终显示效果如下：

![image-20220528185031568](https://static.tongjilab.cn/blog/image-20220528185031568.png)

#### 自定义解析扩展

用`prims.js`实现代码行号显示时，要求在`<pre>`标签中包含`line-numbers`的class属性，即`<pre class="line-numbers">`，原始转换结果并不包含这个，我们通过自定义解析扩展来实现为标签添加自定义属性，即上文讲到的`CodePreLineNumbersExtension`。

首先自定义`AttributeProvider`的实现类`CodePreLineNumbersAttributeProvider`，代码如下，通过实现`AttributeProvider`来修改元素是`flexmark-java`常用的扩展方式之一，常规的为元素添加属性均可通过该方式实现。

```java
static class CodePreLineNumbersAttributeProvider implements AttributeProvider {
	@Override
	public void setAttributes(@NotNull Node node, @NotNull AttributablePart part, @NotNull MutableAttributes attributes) {
        // 定位到<pre>标签元素进行修改
		if (node instanceof FencedCodeBlock && part == AttributablePart.NODE) {
			attributes.addValue("class", "line-numbers");
		}
	}
	static AttributeProviderFactory Factory() {
		return new IndependentAttributeProviderFactory() {
			@NotNull
			@Override
			public AttributeProvider apply(@NotNull LinkResolverContext context) {
				return new CodePreLineNumbersAttributeProvider();
			}
		};
	}
}
```

然后需要将自定义的`AttributeProvider`通过`HtmlRenderer.Builder.attributeProviderFactory`的方式注册到`CodePreLineNumbersExtension`中即可使用，代码如下。

```java
static class CodePreLineNumbersExtension implements HtmlRenderer.HtmlRendererExtension {
	@Override
	public void rendererOptions(@NotNull MutableDataHolder options) {
		// add any configuration settings to options you want to apply to everything, here
	}
	@Override
	public void extend(@NotNull HtmlRenderer.Builder htmlRendererBuilder, @NotNull String rendererType) {
		htmlRendererBuilder.attributeProviderFactory(CodePreLineNumbersAttributeProvider.Factory());
	}
	static CodePreLineNumbersExtension create() {
		return new CodePreLineNumbersExtension();
	}
}
```

## 总结

除了本文讲到的方式，将Markdown转换为Html的方式还有很多，众多对比之下，`flexmark-java`是相对不错且成熟的解决方案，灵活度高，可定制很多转换设置，同时可自定义扩展来增强功能。本文选择该方式来实现API文档Markdown转html并发布到线上，以此实现更简便高效的API文档发布和使用。









