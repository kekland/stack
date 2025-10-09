import 'package:flutter/widgets.dart';
import 'package:stack/stack.dart';

({TextEditingController controller, FocusNode focusNode, bool hasFocus, bool isEmpty}) useAbstractTextField({
  TextEditingController? controller,
  FocusNode? focusNode,
}) {
  final _controller = useManagedResource(
    value: controller,
    create: () => TextEditingController(),
    dispose: (v) => v.dispose(),
  );

  final _focusNode = useManagedResource(
    value: focusNode,
    create: () => FocusNode(),
    dispose: (v) => v.dispose(),
  );

  final _hasFocus = useFocusNodeHasFocus(_focusNode);
  final _isEmpty = useTextControllerIsEmpty(_controller);

  return (
    controller: _controller,
    focusNode: _focusNode,
    hasFocus: _hasFocus,
    isEmpty: _isEmpty,
  );
}
