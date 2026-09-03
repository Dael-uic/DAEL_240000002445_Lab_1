import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.tealAccent),
      ),
      // HomeShell is the PARENT. It never gets unmounted itself -- it just
      // decides whether or not the CHILD widget (LifecycleTrackerChild) exists
      // in the widget tree. That's what lets us demonstrate dispose().
      home: const HomeShell(title: 'DAEL - 240000002445 (Lab 1)'),
    );
  }
}

/// ---------------------------------------------------------------------
/// PARENT SHELL
/// ---------------------------------------------------------------------
/// This widget's only job is to hold the MOUNT / UNMOUNT toggle button and
/// to conditionally build (or not build) the child widget below it.
///
/// When _isChildMounted flips from true -> false, Flutter removes
/// LifecycleTrackerChild from the widget tree entirely. Because that widget
/// is a StatefulWidget, removing it triggers its State object's dispose()
/// method -- this is our live demonstration of memory cleanup.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.title});

  final String title;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  // Controls whether the child widget currently exists in the tree.
  bool _isChildMounted = true;

  void _toggleChild() {
    // setState() tells Flutter "the data driving this UI has changed, please
    // rerun build() and reconcile the widget tree against the new data."
    // Flutter does NOT automatically know _isChildMounted changed -- Dart
    // fields are just plain memory, so without setState() the framework
    // would never rebuild and the screen would not reflect the new value.
    setState(() {
      _isChildMounted = !_isChildMounted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        // If _isChildMounted is false, we build a simple placeholder instead
        // of LifecycleTrackerChild. This is the line that actually adds/removes
        // the child from the widget tree.
        child: _isChildMounted
            ? LifecycleTrackerChild()
            : const Text(
                'Child widget is UNMOUNTED.\nCheck the Debug Console for dispose() logs.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleChild,
        icon: Icon(_isChildMounted ? Icons.stop_circle : Icons.play_circle),
        label: Text(_isChildMounted ? 'UNMOUNT CHILD' : 'MOUNT CHILD'),
      ),
    );
  }
}

/// ---------------------------------------------------------------------
/// CHILD WIDGET
/// ---------------------------------------------------------------------
/// This is the widget being mounted/unmounted by the parent shell above.
/// It owns two runtime resources that live outside Flutter's normal
/// widget/element tree and therefore do NOT get cleaned up automatically:
///   1. a Timer.periodic (the "App Runtime Ticker")
///   2. a TextEditingController (the managed input field)
/// Both MUST be manually released in dispose(), or they will keep running /
/// keep holding memory even after the widget disappears from the screen --
/// this is exactly what a RAM leak looks like in a mobile app.
///
/// Every stage of this widget's life prints a numbered console line
/// (0 = constructor, 1 = createState, 2 = initState, 3 = build,
/// 4 = dispose) so the exact engine execution order is visible in the
/// Debug Console, with indented sub-lines showing WHAT triggered each
/// rebuild (a timer tick vs. a user tap).
class LifecycleTrackerChild extends StatefulWidget {
  // NOTE: this constructor is intentionally NOT const. A const constructor
  // can't run a body/print statement, and we want proof, every time this
  // widget is instantiated, that its "blueprint" was created.
  LifecycleTrackerChild({super.key}) {
    print('0. [CONSTRUCTOR] Widget blueprint created.');
  }

  @override
  State<LifecycleTrackerChild> createState() {
    print('1. [createState] Creating State object for LifecycleTrackerChild.');
    return _LifecycleTrackerChildState();
  }
}

class _LifecycleTrackerChildState extends State<LifecycleTrackerChild> {
  int _counter = 0;

  // Tracks how many seconds this widget has been alive on screen.
  int _secondsElapsed = 0;

  // The active runtime resources we are responsible for cleaning up.
  Timer? _periodicTimer;
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    // initState() runs exactly ONCE, right when this State object is first
    // created -- before the very first build(). It's the correct place to
    // set up long-lived resources (timers, controllers, listeners,
    // subscriptions) because it only fires a single time per widget
    // lifetime, unlike build().
    print('2. [initState] Executing one-time initializations...');

    // Instantiate the controller here (not in build()!) so we don't
    // accidentally create a brand-new controller -- and lose whatever the
    // user typed -- every time build() reruns.
    _textController = TextEditingController();

    // Timer.periodic keeps firing every 1 second until we explicitly cancel
    // it. If we never cancel it, it will keep running (and keep a
    // reference to this State object alive) even after the widget is
    // removed from the screen -- a classic Flutter memory leak.
    _periodicTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _secondsElapsed++;
      print('   🔄[Timer Ticker] Active for $_secondsElapsed s (Triggers build)');
      // setState() tells Flutter "the data driving this UI has changed,
      // please rerun build() and reconcile the widget tree." Without this
      // call, _secondsElapsed would still increment in memory, but the
      // screen (and the numbered "3. [build]" log below) would never
      // update to show it.
      setState(() {});
    });
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
      print('   👉 [User Action] Increment clicked. Counter: $_counter');
    });
  }

  void _decrementCounter() {
    setState(() {
      _counter--;
      print('   👉 [User Action] Decrement clicked. Counter: $_counter');
    });
  }

  void _resetCounter() {
    setState(() {
      _counter = 0;
      print('   👉 [User Action] Reset clicked. Counter: $_counter');
    });
  }

  @override
  Widget build(BuildContext context) {
    // build() reruns EVERY time setState() is called (from the counter
    // buttons or from the 1-second timer tick). Flutter re-executes this
    // method to produce a fresh widget description, then diffs it against
    // the previous tree and only repaints the pixels that actually
    // changed. That's why build() can be called dozens of times per second
    // (once per timer tick here) without becoming a performance problem.
    print('3. [build] Repainting UI Canvas... (Counter: $_counter | Ticker: ${_secondsElapsed}s)');

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'App Runtime Ticker: $_secondsElapsed s',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 16),

        const Text('You have pushed the button this many times:'),
        Text(
          '$_counter',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: _counter > 10
                    ? Colors.red
                    : _counter < 0
                        ? Colors.amber
                        : Theme.of(context).colorScheme.primary,
              ),
        ),

        if (_counter > 15 || _counter < -5)
          const Text(
            'Danger Zone!',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),

        const SizedBox(height: 24),

        // Managed input field: the TextField below is "controlled" because
        // its content is driven entirely by _textController rather than by
        // internal, hidden state. Whoever owns the controller (us) can read,
        // set, or clear the field's text at any time.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'Managed Input Field',
              border: OutlineInputBorder(),
              hintText: 'Type something...',
            ),
          ),
        ),

        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FloatingActionButton(
              heroTag: 'inc',
              onPressed: _incrementCounter,
              tooltip: 'Increment',
              child: const Icon(Icons.add),
            ),
            const SizedBox(width: 10),
            FloatingActionButton(
              heroTag: 'dec',
              onPressed: _decrementCounter,
              tooltip: 'Decrement',
              child: const Icon(Icons.remove),
            ),
            const SizedBox(width: 10),
            FloatingActionButton(
              heroTag: 'reset',
              onPressed: _resetCounter,
              tooltip: 'Reset',
              child: const Icon(Icons.refresh),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    // dispose() runs exactly ONCE, right before this State object is
    // permanently destroyed (e.g. when the parent shell unmounts this
    // widget). It is MANDATORY to release any resource that lives outside
    // Flutter's widget tree here:
    //   - Timer.periodic keeps a reference alive and keeps firing forever
    //     if not cancelled, even after the widget is gone from screen.
    //   - TextEditingController holds native platform text-editing state
    //     and listener callbacks that will never be garbage collected if
    //     not explicitly disposed.
    // Skipping this step is exactly how mobile apps develop RAM leaks: the
    // widget disappears visually, but its resources keep consuming memory
    // and CPU cycles in the background indefinitely.
    print('4. [dispose] Cleaning up resources to prevent memory leaks!');

    _periodicTimer?.cancel();
    print('   🧹 Cleaned: _periodicTimer.cancel()');

    _textController.dispose();
    print('   🧹 Cleaned: _textController.dispose()');

    // super.dispose() must be called last, after our own cleanup, to let
    // the framework finish tearing down the State object.
    super.dispose();
  }
}