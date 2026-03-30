import 'package:flutter/widgets.dart';
import 'package:stack/stack.dart';

class MyController extends Controller {
  MyController() : super(logger: Logger('example.MyController'));

  static MyController watch(BuildContext context) => context.watch<MyController>();
  static MyController read(BuildContext context) => context.read<MyController>();

  late final _count = $prop($signal(0));
  get count => _count.value;
}
