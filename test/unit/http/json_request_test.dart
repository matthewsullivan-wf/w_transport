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

@TestOn('browser || vm')
library w_transport.test.unit.http.json_request_test;

import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:w_transport/w_transport.dart';
import 'package:w_transport/w_transport_mock.dart';

import '../../naming.dart';

void main() {
  Naming naming = new Naming()
    ..testType = testTypeUnit
    ..topic = topicHttp;

  group(naming.toString(), () {
    group('JsonRequest', () {
      setUp(() {
        configureWTransportForTest();
      });

      test('content-type cannot be set manually', () {
        JsonRequest request = new JsonRequest();
        expect(() => request.contentType = null, throwsUnsupportedError);
      });

      test('setting entire body (Map)', () {
        Map json = {'field': 'value'};
        JsonRequest request = new JsonRequest()..body = json;
        expect(request.body, equals(json));
      });

      test('setting entire body (List)', () {
        List json = [
          {'field': 'value'}
        ];
        JsonRequest request = new JsonRequest()..body = json;
        expect(request.body, equals(json));
      });

      test('setting entire body (invalid JSON)', () {
        JsonRequest request = new JsonRequest();
        expect(() {
          request.body = new Stream.fromIterable([]);
        }, throws);
      });

      test('setting fields incrementally', () {
        FormRequest request = new FormRequest()
          ..fields['field1'] = 'value1'
          ..fields['field2'] = 'value2';
        expect(
            request.fields, equals({'field1': 'value1', 'field2': 'value2'}));
      });

      test('setting body in request dispatcher is supported (Map)', () async {
        Uri uri = Uri.parse('/test');

        Completer body = new Completer();
        MockTransports.http.when(uri, (FinalizedRequest request) async {
          body.complete((request.body as HttpBody).asString());
          return new MockResponse.ok();
        });

        JsonRequest request = new JsonRequest();
        Map json = {'field': 'value'};
        await request.post(uri: uri, body: json);
        expect(await body.future, equals(JSON.encode(json)));
      });

      test('setting body in request dispatcher is supported (List)', () async {
        Uri uri = Uri.parse('/test');

        Completer body = new Completer();
        MockTransports.http.when(uri, (FinalizedRequest request) async {
          body.complete((request.body as HttpBody).asString());
          return new MockResponse.ok();
        });

        JsonRequest request = new JsonRequest();
        List json = [
          {'field': 'value'}
        ];
        await request.post(uri: uri, body: json);
        expect(await body.future, equals(JSON.encode(json)));
      });

      test('setting body in request dispatcher should throw if invalid',
          () async {
        Uri uri = Uri.parse('/test');

        JsonRequest request = new JsonRequest();
        expect(request.post(uri: uri, body: UTF8), throws);
      });

      test('body should be unmodifiable once sent', () async {
        Uri uri = Uri.parse('/test');
        MockTransports.http.expect('POST', uri);
        JsonRequest request = new JsonRequest();
        await request.post(uri: uri);
        expect(() {
          request.body = {'too': 'late'};
        }, throwsStateError);
      });

      test('content-length cannot be set manually', () {
        Request request = new Request();
        expect(() {
          request.contentLength = 10;
        }, throwsUnsupportedError);
      });

      test('setting encoding should update content-type', () {
        JsonRequest request = new JsonRequest();
        expect(request.contentType.parameters['charset'], equals(UTF8.name));

        request.encoding = LATIN1;
        expect(request.contentType.parameters['charset'], equals(LATIN1.name));

        request.encoding = ASCII;
        expect(request.contentType.parameters['charset'], equals(ASCII.name));
      });

      test('setting encoding should not be allowed once sent', () async {
        Uri uri = Uri.parse('/test');
        MockTransports.http.expect('GET', uri);
        JsonRequest request = new JsonRequest();
        await request.get(uri: uri);
        expect(() {
          request.encoding = LATIN1;
        }, throwsStateError);
      });
    });
  });
}
