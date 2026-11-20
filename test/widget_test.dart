import 'package:camera_app/models/storage_object.dart';
import 'package:camera_app/services/in_memory_storage_service.dart';
import 'package:camera_app/views/home_page.dart';
import 'package:camera_app/viewmodels/storage_view_model.dart';
import 'package:camera_app/widgets/name_input_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

Widget buildApp({
  InMemoryStorageService? storage,
  List<StorageObject> initialObjects = const [],
}) {
  final store = storage ?? InMemoryStorageService();
  for (final object in initialObjects) {
    // Seed synchronously for tests.
    // ignore: discarded_futures
    store.save(object);
  }
  return ChangeNotifierProvider(
    create: (_) => StorageViewModel(storage: store),
    child: const MaterialApp(home: HomePage()),
  );
}

/// Finds [text] inside a saved-scan list cell (excludes the favorite pad).
Finder cellText(String text) =>
    find.descendant(of: find.byType(ListTile), matching: find.text(text));

void main() {
  testWidgets('home page shows scan button and title', (tester) async {
    await tester.pumpWidget(buildApp());

    expect(find.byKey(const Key('scan_button')), findsOneWidget);
    expect(find.text('Scan QR / Barcode'), findsOneWidget);
    expect(find.text('Take Photo'), findsNothing);
    expect(find.text('Discount Card App'), findsWidgets);
  });

  testWidgets('shows empty state when there are no saved scans', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Saved scans'), findsOneWidget);
    expect(find.text('No saved scans yet'), findsOneWidget);
  });

  testWidgets('lists saved scan objects', (tester) async {
    await tester.pumpWidget(
      buildApp(
        initialObjects: const [
          StorageObject(id: '1', name: 'qrCode', data: 'https://a.dev'),
          StorageObject(id: '2', name: 'ean13', data: '5901234123457'),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(cellText('qrCode'), findsOneWidget);
    expect(cellText('https://a.dev'), findsOneWidget);
    expect(cellText('ean13'), findsOneWidget);
    expect(cellText('5901234123457'), findsOneWidget);

    // Favorite pad shows the first (most recent) record.
    expect(
      tester.widget<Text>(find.byKey(const Key('favorite_name'))).data,
      'ean13',
    );
    expect(find.byKey(const Key('favorite_barcode')), findsOneWidget);
  });

  testWidgets('delete buttons appear only in edit mode', (tester) async {
    final storage = InMemoryStorageService();
    await storage.save(
      const StorageObject(id: '1', name: 'qrCode', data: 'abc'),
    );

    await tester.pumpWidget(buildApp(storage: storage));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('delete_1')), findsNothing);
    expect(find.text('Edit'), findsOneWidget);

    await tester.tap(find.byKey(const Key('edit_toggle_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('delete_1')), findsOneWidget);
    expect(find.byIcon(Icons.drag_indicator), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);

    await tester.tap(find.byKey(const Key('edit_toggle_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('delete_1')), findsNothing);
    expect(find.text('Edit'), findsOneWidget);
  });

  testWidgets('delete button removes an item in edit mode', (tester) async {
    final storage = InMemoryStorageService();
    await storage.save(
      const StorageObject(id: '1', name: 'qrCode', data: 'abc'),
    );

    await tester.pumpWidget(buildApp(storage: storage));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('edit_toggle_button')));
    await tester.pumpAndSettle();

    expect(find.text('abc'), findsOneWidget);

    await tester.tap(find.byKey(const Key('delete_1')));
    await tester.pumpAndSettle();

    expect(find.text('abc'), findsNothing);
    expect(find.text('No saved scans yet'), findsOneWidget);
    expect(await storage.getAll(), isEmpty);
  });

  testWidgets('tapping cell in edit mode opens rename dialog', (tester) async {
    final storage = InMemoryStorageService();
    await storage.save(
      const StorageObject(id: '1', name: 'qrCode', data: 'abc'),
    );

    await tester.pumpWidget(buildApp(storage: storage));
    await tester.pumpAndSettle();

    // Tapping outside edit mode opens the barcode dialog, not rename.
    await tester.tap(cellText('qrCode'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('name_field')), findsNothing);
    expect(find.byKey(const Key('barcode_dialog')), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('barcode_dialog')), findsNothing);

    await tester.tap(find.byKey(const Key('edit_toggle_button')));
    await tester.pumpAndSettle();

    await tester.tap(cellText('qrCode'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('name_field')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('name_field')), 'My QR code');
    await tester.tap(find.byKey(const Key('save_button')));
    await tester.pumpAndSettle();

    expect(cellText('My QR code'), findsOneWidget);
    expect(find.text('qrCode'), findsNothing);
    expect((await storage.getAll()).single.name, 'My QR code');
  });

  testWidgets('rename dialog offers color schemes and saves selection', (
    tester,
  ) async {
    final storage = InMemoryStorageService();
    await storage.save(
      const StorageObject(id: '1', name: 'qrCode', data: 'abc'),
    );

    await tester.pumpWidget(buildApp(storage: storage));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('edit_toggle_button')));
    await tester.pumpAndSettle();
    await tester.tap(cellText('qrCode'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('color_picker')), findsOneWidget);
    expect(find.byKey(const Key('color_blue')), findsOneWidget);

    await tester.tap(find.byKey(const Key('color_blue')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save_button')));
    await tester.pumpAndSettle();

    expect((await storage.getAll()).single.color, 'blue');
  });

  testWidgets('scan name dialog has no color picker', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => const NameInputDialog(
                  title: 'Name this qrCode',
                  initialName: 'qrCode',
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('name_field')), findsOneWidget);
    expect(find.byKey(const Key('color_picker')), findsNothing);
  });

  testWidgets('tapping cell shows generated barcode with bold name', (
    tester,
  ) async {
    final storage = InMemoryStorageService();
    await storage.save(
      const StorageObject(id: '1', name: 'qrCode', data: 'https://a.dev'),
    );

    await tester.pumpWidget(buildApp(storage: storage));
    await tester.pumpAndSettle();

    await tester.tap(cellText('qrCode'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('barcode_dialog')), findsOneWidget);
    expect(find.byKey(const Key('barcode_name')), findsOneWidget);
    expect(find.byKey(const Key('barcode_image')), findsOneWidget);
    expect(find.text('https://a.dev'), findsWidgets);

    // Rename dialog must not appear in view mode.
    expect(find.byKey(const Key('name_field')), findsNothing);
  });

  testWidgets('barcode dialog does not open in edit mode', (tester) async {
    final storage = InMemoryStorageService();
    await storage.save(
      const StorageObject(id: '1', name: 'qrCode', data: 'abc'),
    );

    await tester.pumpWidget(buildApp(storage: storage));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('edit_toggle_button')));
    await tester.pumpAndSettle();

    await tester.tap(cellText('qrCode'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('barcode_dialog')), findsNothing);
    expect(find.byKey(const Key('name_field')), findsOneWidget);
  });
}
