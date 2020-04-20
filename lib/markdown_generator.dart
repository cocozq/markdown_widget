import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as m;

import 'config/html_support.dart';
import 'config/style_config.dart';
import 'config/widget_config.dart';
import 'markdown_helper.dart';
import 'markdown_toc.dart';

class MarkdownGenerator {
  MarkdownGenerator({
    @required String data,
    WidgetConfig widgetConfig,
    StyleConfig styleConfig,
    EdgeInsetsGeometry childMargin,
  }) {
    final m.Document document = m.Document(
        extensionSet: m.ExtensionSet.gitHubFlavored,
        encodeHtml: false,
        inlineSyntaxes: [TaskListSyntax()]);
    final List<String> lines = data.split(RegExp(r'\r?\n'));
    List<m.Node> nodes = document.parseLines(lines);
    _tocList = LinkedHashMap();
    _helper = MarkdownHelper(wConfig: widgetConfig);
    _widgets = [];
    nodes.forEach((element) {
      _widgets.add(_generatorWidget(element, childMargin));
    });
  }

  List<Widget> _widgets;
  LinkedHashMap<int, Toc> _tocList;
  MarkdownHelper _helper;

  List<Widget> get widgets => _widgets;

  LinkedHashMap<int, Toc> get tocList => _tocList;

  final _customTagPattern = RegExp(r'<(?<tag>\w+).*?/>');

  final _customTagAttributesPattern =
      RegExp(r'(?<name>\w+)\s*=\s*"(?<value>\w+)"');

  bool _canParseCustomTag(m.Text node) => _customTagPattern.hasMatch(node.text);

  m.Element _parseCustomTag(m.Text node) {
    String text = node.text;
    var tagMatch = _customTagPattern.firstMatch(text);
    String tag = tagMatch.namedGroup('tag');
    Map<String, String> attributes = {};
    for (var attributeMatch in _customTagAttributesPattern.allMatches(text)) {
      attributes[attributeMatch.namedGroup('name')] =
          attributeMatch.namedGroup('value');
    }
    return m.Element.withTag(tag)..attributes.addAll(attributes);
  }

  Widget _generatorWidget(m.Node node, EdgeInsetsGeometry childMargin) {
    if (node is m.Text) {
      // markdown can not parse custom html tag, see dart-lang/markdown/issues/285.
      // So we parse it manually here.
      // Now in order for simplicity, we only support self close custom tag
      // with attributes like <avatar name="cow" size="24" />.
      // Alternative we can parse more complex custom tag using html lib using
      // parseFragment('<avatar name="cow" size="24">nickName: <span>Tom</span>.</avatar>')
      if (!_canParseCustomTag(node)) {
        return _helper.getPWidget(m.Element(p, [node]));
      }
      node = _parseCustomTag(node);
    }
    ;
    final tag = (node as m.Element).tag;
    Widget result;
    switch (tag) {
      case h1:
        _tocList[_widgets.length] = Toc(
            node.textContent.replaceAll(htmlRep, ''),
            tag,
            _widgets.length,
            _tocList.length,
            0);
        result = _helper.getTitleWidget(node, h1);
        break;
      case h2:
        _tocList[_widgets.length] = Toc(
            node.textContent.replaceAll(htmlRep, ''),
            tag,
            _widgets.length,
            _tocList.length,
            1);
        result = _helper.getTitleWidget(node, h2);
        break;
      case h3:
        _tocList[_widgets.length] = Toc(
            node.textContent.replaceAll(htmlRep, ''),
            tag,
            _widgets.length,
            _tocList.length,
            2);
        result = _helper.getTitleWidget(node, h3);
        break;
      case h4:
        _tocList[_widgets.length] = Toc(
            node.textContent.replaceAll(htmlRep, ''),
            tag,
            _widgets.length,
            _tocList.length,
            3);
        result = _helper.getTitleWidget(node, h4);
        break;
      case h5:
        _tocList[_widgets.length] = Toc(
            node.textContent.replaceAll(htmlRep, ''),
            tag,
            _widgets.length,
            _tocList.length,
            4);
        result = _helper.getTitleWidget(node, h5);
        break;
      case h6:
        _tocList[_widgets.length] = Toc(
            node.textContent.replaceAll(htmlRep, ''),
            tag,
            _widgets.length,
            _tocList.length,
            5);
        result = _helper.getTitleWidget(node, h6);
        break;
      case p:
        result = _helper.getPWidget(node);
        break;
      case pre:
        result = _helper.getPreWidget(node);
        break;
      case ul:
        result = _helper.getUlWidget(node, 0);
        break;
      case ol:
        result = _helper.getOlWidget(node, 0);
        break;
      case hr:
        result = _helper.getHrWidget(node);
        break;
      case table:
        result = _helper.getTableWidget(node);
        break;
      case blockquote:
        result = _helper.getBlockQuote(node);
        break;
      default:
        result = _helper.getCustomWidget(node);
    }
    if (result == null) print('tag:$tag not catched!');
    return Container(
      child: result ?? Container(),
      margin: childMargin ??
          (result == null ? null : EdgeInsets.only(top: 5, bottom: 5)),
    );
  }

  void clear() {
    _tocList.clear();
    _widgets.clear();
  }
}

///Thanks for https://github.com/flutter/flutter_markdown/blob/4cc79569f6c0f150fc4e9496f594d1bfb3a3ff54/lib/src/widget.dart
class TaskListSyntax extends m.InlineSyntax {
  static final String _pattern = r'^ *\[([ xX])\] +';

  TaskListSyntax() : super(_pattern);

  @override
  bool onMatch(m.InlineParser parser, Match match) {
    m.Element el = m.Element.withTag('input');
    el.attributes['type'] = 'checkbox';
    el.attributes['disabled'] = 'true';
    el.attributes['checked'] = '${match[1].trim().isNotEmpty}';
    parser.addNode(el);
    return true;
  }
}
