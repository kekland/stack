# staggerable

a mini-plugin for staggering the appearance of its children.

note: minor pitfall is that the order of the staggering is dependent on the build order of the widgets. in most cases this is fine, but if there's a more complex layout, the order might not be what you expect.

## usage

```dart
Widget build(BuildContext context) {
  return StaggerableContainer(
    child: Column(
      children: [
        StaggeringWidget(Text('child 1')),
        StaggeringWidget(Text('child 2')),
        StaggeringWidget(Text('child 3')),
      ],
    ),
  );
}
```
