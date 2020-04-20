import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as m;

class WidgetConfig {
  WidgetBuilder p;
  WidgetBuilder pre;
  WidgetBuilder ul;
  WidgetBuilder ol;
  WidgetBuilder block;
  WidgetBuilder hr;
  WidgetBuilder table;
  WidgetBuilder custom;

  WidgetConfig({
    this.p,
    this.pre,
    this.ul,
    this.ol,
    this.block,
    this.hr,
    this.table,
    this.custom,
  });
}

typedef Widget WidgetBuilder(m.Element node);
