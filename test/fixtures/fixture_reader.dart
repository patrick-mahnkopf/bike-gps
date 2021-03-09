import 'dart:io';

File fixtureFile(String name) => File('test/fixtures/$name');
String fixture(String name) => fixtureFile(name).readAsStringSync();
