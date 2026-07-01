import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:diaryapp/main.dart';
import 'package:diaryapp/sql_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    final dbFile = File('diaryawie.db');
    if (await dbFile.exists()) {
      await dbFile.delete();
    }
  });

  testWidgets('app initializes and shows the diary home page', (tester) async {
    await initializeApp();
    await tester.pumpWidget(const MyApp());

    expect(find.text("Wani's Diary"), findsOneWidget);
  });

  test('create, list, and delete diary entries', () async {
    final id = await SQLHelper.createDiary('Happy', 'Finished my assignment');
    final diaries = await SQLHelper.getDiaries();

    expect(id, greaterThan(0));
    expect(diaries.length, 1);
    expect(diaries.first['feeling'], 'Happy');
    expect(diaries.first['description'], 'Finished my assignment');

    await SQLHelper.deleteDiary(id);
    final afterDelete = await SQLHelper.getDiaries();

    expect(afterDelete, isEmpty);
  });
}
