// Copyright 2015 Workiva Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';
import 'dart:io' as io;

import 'package:dart_dev/dart_dev.dart' show dev, config;
import 'package:dart_dev/util.dart' show TaskProcess, reporter;

import 'server/server.dart' show Server;

Future<Null> main(List<String> args) async {
  // https://github.com/Workiva/dart_dev

  final directories = <String>['example/', 'lib/', 'test/', 'tool/'];

  config.analyze.entryPoints = [
    'lib/',
    'test/',
    'test/unit/',
    'test/integration/',
    'tool/',
    'tool/server/'
  ];

  config.copyLicense.directories = directories;

  config.coverage
    ..pubServe = true
    ..reportOn = ['lib/']
    ..before = [_streamServer, _streamSockJSServer]
    ..after = [_stopServer, _stopSockJSServer];

  config.format.paths = directories;

  config.test
    ..unitTests = [
      'test/unit/http',
      'test/unit/mocks',
      'test/unit/ws',
    ]
    ..integrationTests = [
      'test/integration/global_web_socket_monitor',
      'test/integration/http',
      'test/integration/platforms',
      'test/integration/ws',
    ]
    ..platforms = ['vm', 'chrome']
    ..pubServe = true
    ..before = [_streamServer, _streamSockJSServer]
    ..after = [_stopServer, _stopSockJSServer];

  await dev(args);
}

/// Server needed for integration tests and examples.
Server _server;

/// SockJS Server needed for integration tests.
TaskProcess _sockJSServer;

/// Output from the server (only used if caching the output to dump at the end).
List<String> _serverOutput;

/// Output from the SockJS server.
List<String> _sockJSServerOutput;

Future<Null> _serveExamples() {
  io.Process.runSync('pub', ['get'], workingDirectory: 'example');
  io.Process.start('pub', ['serve', '--port=9000'],
      workingDirectory: 'example');

  return Completer<Null>().future;
}

/// Start the server needed for integration tests and examples and stream the
/// server output as it arrives. The output will be mixed in with output from
/// whichever task is running.
Future<Null> _streamServer() async {
  _server = Server();
  _server.output.listen((line) {
    reporter.log(reporter.colorBlue('    $line'));
  });
  await _server.start();
}

Future<Null> _streamSockJSServer() async {
  _sockJSServer = TaskProcess('node', ['tool/server/sockjs.js']);
  _sockJSServer.stdout.listen((line) {
    reporter.log(reporter.colorBlue('    $line'));
  });
  _sockJSServer.stderr.listen((line) {
    reporter.log(reporter.colorBlue('    $line'));
  });
  // todo: wait for server to start
}

/// Stop the server needed for integration tests and examples.
Future<Null> _stopServer() async {
  if (_serverOutput != null) {
    reporter.logGroup('HTTP Server Logs',
        output: '    ${_serverOutput.join('\n')}');
  }
  await _server.stop();
}

Future<Null> _stopSockJSServer() async {
  if (_sockJSServerOutput != null) {
    reporter.logGroup('SockJS Server Logs',
        output: '    ${_sockJSServerOutput.join('\n')}');
  }
  if (_sockJSServer != null) {
    try {
      _sockJSServer.kill();
    } catch (_) {}
  }
}
