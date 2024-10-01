import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as m;

import '../widget/all.dart';
import 'configs.dart';
import 'toc.dart';

///use [MarkdownGenerator] to transform markdown data to [Widget] list, so you can render it by any type of [ListView]
class MarkdownGenerator {
  final Iterable<m.InlineSyntax> inlineSyntaxList;
  final Iterable<m.BlockSyntax> blockSyntaxList;
  final EdgeInsets linesMargin;
  final List<SpanNodeGeneratorWithTag> generators;
  final SpanNodeAcceptCallback? onNodeAccepted;
  final m.ExtensionSet? extensionSet;
  final TextNodeGenerator? textGenerator;
  final SpanNodeBuilder? spanNodeBuilder;
  final RichTextBuilder? richTextBuilder;
  final RegExp? splitRegExp;
  List<m.Node> allNodes = [];
  MarkdownGenerator({
    this.inlineSyntaxList = const [],
    this.blockSyntaxList = const [],
    this.linesMargin = const EdgeInsets.symmetric(vertical: 8),
    this.generators = const [],
    this.onNodeAccepted,
    this.extensionSet,
    this.textGenerator,
    this.spanNodeBuilder,
    this.richTextBuilder,
    this.splitRegExp,
  });

  List<String> allLines = [];

  ///convert [data] to widgets
  ///[onTocList] can provider [Toc] list
  List<Widget> buildWidgets(String data,
      {ValueCallback<List<Toc>>? onTocList, MarkdownConfig? config}) {
    final mdConfig = config ?? MarkdownConfig.defaultConfig;
    final m.Document document = m.Document(
      extensionSet: extensionSet ?? m.ExtensionSet.gitHubFlavored,
      encodeHtml: false,
      inlineSyntaxes: inlineSyntaxList,
      blockSyntaxes: blockSyntaxList,
    );
    final regExp = splitRegExp ?? WidgetVisitor.defaultSplitRegExp;
    final List<String> lines = data.split(regExp);

    allLines.clear();
    allLines.addAll(lines);

    final List<m.Node> nodes = document.parseLines(lines);
    allNodes.clear();
    allNodes.addAll(nodes);
    final List<Toc> tocList = [];
    final visitor = WidgetVisitor(
        config: mdConfig,
        generators: generators,
        textGenerator: textGenerator,
        richTextBuilder: richTextBuilder,
        splitRegExp: regExp,
        onNodeAccepted: (node, index) {
          onNodeAccepted?.call(node, index);
          if (node is HeadingNode) {
            final listLength = tocList.length;
            tocList.add(
                Toc(node: node, widgetIndex: index, selfIndex: listLength));
          }
        });
    final spans = visitor.visit(nodes);
    onTocList?.call(tocList);
    final List<Widget> widgets = [];
    for (var span in spans) {
      final textSpan = spanNodeBuilder?.call(span) ?? span.build();
      final richText = richTextBuilder?.call(textSpan) ?? Text.rich(textSpan);
      widgets.add(Padding(padding: linesMargin, child: richText));
    }
    return widgets;
  }

  String getTextContent() {
    return allLines.join("\r\n");
  }

  bool onCheckboxTaped(String text) {
    var success = false;
    var taskElementArr = [];
    for (var node in allNodes) {
      var element = node as m.Element;
      if (element.tag == "ul"
          && element.attributes['class'] == 'contains-task-list'
          && element.children?.isNotEmpty == true) {
        taskElementArr.add(element);
      }
    }

    var tapedNodes = [];
    if (taskElementArr.isNotEmpty) {
      for (var element in taskElementArr) {
        var nodes = _checkboxContainer(element, text);
        if (nodes.isNotEmpty) {
          tapedNodes.addAll(nodes);
        }
      }
    }

    if (tapedNodes.length == 1) {
      var lineIndexArr = [];
      int index = 0;
      for (var line in allLines) {
        if (line.contains(text)) {
          lineIndexArr.add(index);
        }
        index++;
      }

      if (lineIndexArr.isNotEmpty) {
        for (var index in lineIndexArr) {
          var line = allLines[index];
          if (line.contains("[x]")) {
            allLines[index] = line.replaceFirst("[x]", "[ ]");
            success = true;
          }
          else if (line.contains("[ ]")){
            allLines[index] = line.replaceFirst("[ ]", "[x]");
            success = true;
          }
        }
      }
    }

    return success;
  }

  List _checkboxContainer(m.Element nodeElement, String text) {
    var tapedNodes = [];
    for (var child in nodeElement.children!) {
      if (child.textContent == text && child is m.Element && child.children?.isNotEmpty == true) {
        tapedNodes.add(child);
        // for (var node in child.children!) {
        //   if (node is m.Element && node.tag == "input") {
        //     if (node.attributes['checked'] == 'false') {
        //       node.attributes['checked'] = 'true';
        //     }
        //     else {
        //       node.attributes['checked'] = 'false';
        //     }
        //   }
        // }
      }
    }

    return tapedNodes;
  }
}

typedef SpanNodeBuilder = TextSpan Function(SpanNode spanNode);

typedef RichTextBuilder = Widget Function(InlineSpan span);
