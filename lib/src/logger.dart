/*
 Copyright (c) 2022- Kajus Wurster <kjzl-dev@gmx.de; github:kjzl>

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:logging/logging.dart';

initLogging({
  required bool releaseMode,
  required File rootLoggerLogFile,
  required String filenameExtension,
  Codec<String, List<int>> fileCodec = utf8,
}) {
  FileLogger._codec = fileCodec;
  FileLogger._rootLoggerFile = rootLoggerLogFile;
  FileLogger._filenameExension = filenameExtension;

  IOSink out = stdout.nonBlocking;

  Logger.root.onRecord.listen((record) {
    if (Level.FINEST.compareTo(record.level) >= 0) {
      log(record.message,
          name: record.loggerName,
          stackTrace: record.stackTrace,
          error: record.error,
          level: record.level.value,
          sequenceNumber: record.sequenceNumber,
          zone: record.zone,
          time: record.time);
    }
    if (Level.FINER.compareTo(record.level) >= 0) {
      postEvent(
          "log.${record.loggerName}.{record.level.toString()}", record.toMap());
    }
    if (Level.FINE.compareTo(record.level) >= 0) {
      out.writeln(record);
      if (record.error != null) {
        out.addError(record.error!, record.stackTrace);
      }
    }
    if (releaseMode && Level.CONFIG.compareTo(record.level) >= 0) {
      FileLogger.writeForNamed(record.toString(), record.loggerName);
    }
  });
}

extension FileLogger on Logger {
  static final Map<String, File> _files = {};
  static Codec<String, List<int>>? _codec;
  static Future _writer = Future.value(null);
  static File? __rootLoggerFile;
  static String? __filenameExtension;

  static Directory? get _rootLoggerDir => __rootLoggerFile?.parent;

  static set _filenameExension(String s) => __filenameExtension ??= s;

  static set _rootLoggerFile(File file) =>
      _files[Logger.root.name] = __rootLoggerFile ??= file;

  static void writeForNamed(String msg, String loggerName) {
    if (_codec == null) {
      throw StateError("codec is not set");
    }
    _writer = _writer.then((value) => _files.putIfAbsent(loggerName, () {
          if (__rootLoggerFile == null) {
            throw StateError("rootLoggerFile is not set");
          }
          return __rootLoggerFile!;
        }).writeAsBytes(_codec!.encoder.convert(msg), mode: FileMode.append));
  }

  void useFile(String fileName) {
    if (__rootLoggerFile == null) {
      throw StateError("rootLoggerFile is not set");
    }
    _files.putIfAbsent(name,
        () => File("${_rootLoggerDir?.path}\\$fileName.$__filenameExtension"));
  }
}

extension MappableLogRecord on LogRecord {
  Map<String, dynamic> toMap() => {
        "t": time,
        "logger": loggerName,
        "level": level,
        "seqNum": sequenceNumber,
        "msg": message,
        "obj": object,
        "zone": zone,
        "error": error,
        "stackTrace": stackTrace
      };
}
