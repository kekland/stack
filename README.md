# stack

my extremely opinionated, easy-to-shoot-yourself app architecture for Flutter. but it works pretty well for me.

warning: do not use it in your own apps, as it's extremely tied to my own way of architecturing apps. also, there might be tons of pitfalls that i don't yet realize.

no documentation provided yet, as i'm still iterating on the architecture itself. it'll also contain most of my widget primitives that i use across my apps at some point, once the code there isn't as ugly as it's now :)

i decided to publish this as i'm currently sharing this structure across several projects, and i'm tired of copy-pasting the same code over and over again.

## primary dependencies

- `signals` for pretty much everything state management related. it's fun to use, although can get a bit verbose at times.
- `flutter_hooks` for widget lifecycle management. once i tried it, it's pretty hard to go back to regular `StatefulWidget`s, as hooks allow to compose state/logic in a much cleaner way.
- `get_it` for service location. well, this one is pretty much a classic.

## widgets and ui

the aim when i'm building UIs is to have the micro-interactions and animations feel as native as possible. the layout itself doesn't really matter, but if the gestures and transitions feel non-native, it becomes quite obvious:

- on iOS, buttons and other tappable surfaces can have an opacity or highlight effect when pressed
- on Android, buttons and other tappable surfaces have a ripple effect when pressed
- (and so on)

these are not yet 100% the same as in native, but is close enough. the point of the ui library here is to provide a `Surface` and `GestureSurface` abstractions. `GestureSurface` will automatically apply the correct gesture effect based on the platform and the layout of the surface itself. the consumer-contained ui library should be built on top of these abstractions.
