import 'form_field.dart';
import 'package:flutter/widgets.dart' hide FormField, FormFieldState;

typedef ValueFormFieldBuilder<T> =
    Widget Function(
      BuildContext context,
      String? errorText,
      T? value,
      ValueChanged<T?> onChanged,
    );

class ValueFormField<T> extends FormField<T> {
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
           final state = _state as FormFieldState<T>;

           return Builder(
             builder: (context) {
               return builder(
                 context,
                 state.errorText,
                 state.value,
                 state.didChange,
               );
             },
           );
         },
       );
}
