import 'package:flutter_analyzer/src/parser/parser.dart';

import 'package:test/test.dart';

void main() {
  group('classes', () {
    const SOURCE_CODE = r'''
class MyClass {
  MyClass(this.value, {int extra = 0});
  MyClass.info(this.value, this.a, {int extra, int extra2});
  MyClass.empty({int extra, int extra2 = 0}) : this.value = extra2;
  final int value;
  int a = 0;
  int b = 0;
}

final value = new MyClass();
''';
    final parser = FlutterParser.fromString(SOURCE_CODE);
    final obj = parser.visitor.classes[0];

    test('error check', () {
      expect(parser.result.errors.length == 0, equals(true));
      expect(parser.visitor.classes.length, equals(1));
    });

    test('rename class', () {
      expect(obj.name, equals('MyClass'));
      parser.renameClass('MyClass', 'MyClass1');
      expect(obj.constructors[1].displayName.split('.')[0], equals('MyClass1'));
      expect(obj.name, equals('MyClass1'));
    });

    test('rename variables', () {
      final value = obj.fields[0].variables[0];
      final fieldA = obj.fields[1].variables[0];
      final fieldB = obj.fields[2].variables[0];
      expect(fieldA.name, equals('a'));
      expect(fieldB.name, equals('b'));
      parser.renameVariable('MyClass1', 'a', 'a1');
      parser.renameVariable('MyClass1', 'b', 'b1');
      parser.renameVariable('MyClass1', 'value', 'value0');
      expect(value.name, equals('value0'));
      expect(fieldA.name, equals('a1'));
      expect(fieldB.name, equals('b1'));
    });
  });

  group('methods', () {
    const SOURCE_CODE = r'''
class MyClass extends BaseClass {
  MyClass({this.child, this.title});
  final MyClass? child;

  final String? title;

  MyClass? build() {
    return MyClass(
      title: title,
      child: MyClass(
         title: this.title,
         child: BaseClass(
          title: this.title,
        ),
      ),
    );
  }
}

class BaseClass {
  BaseClass({this.title});
  final String? title;

  MyClass? buildScope() {
    final _base = MyClass();
    return _base.build();
  }

   MyClass? build() {
    return  MyClass(
        title: this.title,
        child: BaseClass(
          title: this.title,
      )
    );
  }
}
''';
    final parser = FlutterParser.fromString(SOURCE_CODE);
    final obj = parser.visitor.classes[0];

    test('error check', () {
      expect(parser.result.errors.length == 0, equals(true));
      expect(parser.visitor.classes.length, equals(2));
    });

    test('rename class', () {
      expect(obj.name, equals('MyClass'));
      parser.renameClass('MyClass', 'MyClass1');
      expect(obj.constructors[0].name, equals(null));
      expect(obj.name, equals('MyClass1'));
    });

    test('rename field', () {
      final field = obj.fields[1].variables[0];
      expect(field.name, equals('title'));
      parser.renameVariable('MyClass1', 'title', 'title1');
      expect(field.name, equals('title1'));
    });

    test('rename method', () {
      final method = obj.methods[0];
      expect(method.name, equals('build'));
      parser.renameClassMethod('MyClass1', 'build', 'build1');
      expect(method.name, equals('build1'));
      // parser.debug();
    });
  });

  group('enums', () {
    const SOURCE_CODE = r'''
enum MyEnum {one, two, three}

class MyClass {
  MyClass({MyEnum type, this.value = MyEnum.one});

  final MyEnum value;
}
''';
    final parser = FlutterParser.fromString(SOURCE_CODE);
    final obj = parser.visitor.enums[0];

    test('error check', () {
      expect(parser.result.errors.length == 0, equals(true));
      expect(parser.visitor.enums.length, equals(1));
    });

    test('check name and values', () {
      expect(obj.name, equals('MyEnum'));
      expect(obj.values[1].name, equals('two'));
    });

    test('rename name and value', () {
      parser.renameEnum('MyEnum', 'MyEnum1');
      parser.renameEnumVal('MyEnum1', 'one', 'one1');
      expect(obj.name, equals('MyEnum1'));
      expect(obj.values[0].name, equals('one1'));
    });
  });

  group('flutter test', () {
    const SOURCE_CODE = r'''
import 'package:flutter/material.dart';
import 'dart:html';

bool test() => true;
bool isDebug = true;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget with You implements Me {
  MyApp({this.value = 0});
  final int value;
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'My App',
      theme: ThemeData.light(),
      home: MyWidget(),
    );
  }
}

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
      // const callback = () {};
      // callback();
      return Scaffold(
        appBar: AppBar(
          title: Text('Flutter Example'),
        ),
      );
  }
}

abstract class Me {
  bool get isTrue => true;
  set isTrue(bool val) {

  }
}

mixin You {

}
''';
    final parser = FlutterParser.fromString(SOURCE_CODE);

    test('error check', () {
      expect(parser.result.errors.length == 0, equals(true));
      expect(parser.visitor.classes.length, equals(3));
    });

    test('check flutter source', () {
      expect(parser.visitor.classes[0].name, equals('MyApp'));
      expect(
          parser.visitor.classes[0].extendsClause, equals('StatelessWidget'));
      expect(parser.visitor.classes[0].implementsClause, equals(['Me']));
      expect(parser.visitor.classes[0].withClause, equals(['You']));
      expect(parser.visitor.classes[1].name, equals('MyWidget'));
      // TODO: Check for "const callback = () {};callback(); return Scaffold(();""
    });
  });
}
