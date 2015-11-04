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
library w_transport.test.integration.http.form_request.mock_test;

import 'package:test/test.dart';
import 'package:w_transport/w_transport_mock.dart';

import '../../../naming.dart';
import '../mock_endpoints/404.dart';
import '../mock_endpoints/echo.dart';
import '../mock_endpoints/reflect.dart';
import '../integration_config.dart';
import 'suite.dart';

void main() {
  group(integrationHttpMock, () {
    var config = new HttpIntegrationConfig.mock();

    setUp(() {
      configureWTransportForTest();
      mock404Endpoint(config.fourOhFourEndpointUri);
      mockEchoEndpoint(config.echoEndpointUri);
      mockReflectEndpoint(config.reflectEndpointUri);
    });

    runFormRequestSuite(config);

    tearDown(() {
      MockTransports.verifyNoOutstandingExceptions();
    });
  });
}