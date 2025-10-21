import 'package:flutter/material.dart';
import 'package:stack/src/widgets/input/form/form_field.dart';

typedef ValueFormFieldBuilder<T> =
    Widget Function(
      BuildContext context,
      T? value,
      String? errorText,
      ValueChanged<T?> onChanged,
    );

class ValueFormField<T> extends StFormField<T> {
  ValueFormField({
    super.key,
    required ValueFormFieldBuilder<T> builder,
    super.initialValue,
    super.autovalidateMode,
    super.enabled,
    super.onChanged,
    super.validator,
  }) : super(
         builder: (_state) {
           final state = _state as StFormFieldState<T>;

           return Builder(
             builder: (context) {
               return builder(
                 context,
                 state.value,
                 state.errorText,
                 state.didChange,
               );
             },
           );
         },
       );
}
