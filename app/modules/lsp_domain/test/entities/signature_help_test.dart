import 'package:flutter_test/flutter_test.dart';
import 'package:lsp_domain/lsp_domain.dart';

void main() {
  group('SignatureHelp', () {
    late List<SignatureInformation> signatures;

    setUp(() {
      signatures = [
        const SignatureInformation(
          label: 'print(Object? object)',
          documentation: 'Prints an object to the console',
          parameters: [
            ParameterInformation(
              label: 'object',
              documentation: 'The object to print',
            ),
          ],
        ),
        const SignatureInformation(
          label: 'print(String message, {bool newline = true})',
          documentation: 'Prints a message',
          parameters: [
            ParameterInformation(label: 'message'),
            ParameterInformation(label: 'newline'),
          ],
        ),
      ];
    });

    group('creation', () {
      test('should create signature help with signatures', () {
        // Act
        final help = SignatureHelp(signatures: signatures);

        // Assert
        expect(help.signatures, equals(signatures));
        expect(help.activeSignature, isNull);
        expect(help.activeParameter, isNull);
      });

      test('should create signature help with active signature', () {
        // Act
        final help = SignatureHelp(
          signatures: signatures,
          activeSignature: 0,
        );

        // Assert
        expect(help.activeSignature, equals(0));
      });

      test('should create signature help with active parameter', () {
        // Act
        final help = SignatureHelp(
          signatures: signatures,
          activeSignature: 0,
          activeParameter: 0,
        );

        // Assert
        expect(help.activeParameter, equals(0));
      });

      test('should create empty signature help', () {
        // Act
        const help = SignatureHelp.empty;

        // Assert
        expect(help.signatures, isEmpty);
      });
    });

    group('currentSignature', () {
      test('should return null for empty signatures', () {
        // Arrange
        const help = SignatureHelp.empty;

        // Assert
        expect(help.currentSignature, isNull);
      });

      test('should return first signature when activeSignature is null', () {
        // Arrange
        final help = SignatureHelp(signatures: signatures);

        // Assert
        expect(help.currentSignature, equals(signatures[0]));
      });

      test('should return active signature', () {
        // Arrange
        final help = SignatureHelp(
          signatures: signatures,
          activeSignature: 1,
        );

        // Assert
        expect(help.currentSignature, equals(signatures[1]));
      });

      test('should return null for out of bounds active signature', () {
        // Arrange
        final help = SignatureHelp(
          signatures: signatures,
          activeSignature: 10,
        );

        // Assert
        expect(help.currentSignature, isNull);
      });

      test('should return null for negative active signature', () {
        // Arrange
        final help = SignatureHelp(
          signatures: signatures,
          activeSignature: -1,
        );

        // Assert
        expect(help.currentSignature, isNull);
      });
    });

    group('equality', () {
      test('should be equal with same signatures', () {
        final help1 = SignatureHelp(signatures: signatures);
        final help2 = SignatureHelp(signatures: signatures);

        expect(help1, equals(help2));
      });

      test('should not be equal with different active signature', () {
        final help1 = SignatureHelp(
          signatures: signatures,
          activeSignature: 0,
        );

        final help2 = SignatureHelp(
          signatures: signatures,
          activeSignature: 1,
        );

        expect(help1, isNot(equals(help2)));
      });
    });

    group('overloaded functions', () {
      test('should handle multiple overloads', () {
        // Arrange
        final help = SignatureHelp(
          signatures: signatures,
          activeSignature: 0,
        );

        // Assert
        expect(help.signatures.length, equals(2));
        expect(help.signatures[0].label, contains('Object?'));
        expect(help.signatures[1].label, contains('String'));
      });

      test('should navigate between overloads', () {
        final help = SignatureHelp(
          signatures: signatures,
          activeSignature: 0,
        );

        final nextOverload = help.copyWith(activeSignature: 1);

        expect(nextOverload.currentSignature, equals(signatures[1]));
      });
    });
  });

  group('SignatureInformation', () {
    group('creation', () {
      test('should create with label', () {
        // Act
        const signature = SignatureInformation(
          label: 'myFunction(int arg)',
        );

        // Assert
        expect(signature.label, equals('myFunction(int arg)'));
        expect(signature.documentation, isNull);
        expect(signature.parameters, isNull);
      });

      test('should create with documentation', () {
        // Act
        const signature = SignatureInformation(
          label: 'test()',
          documentation: 'A test function',
        );

        // Assert
        expect(signature.documentation, equals('A test function'));
      });

      test('should create with parameters', () {
        // Act
        const signature = SignatureInformation(
          label: 'add(int a, int b)',
          parameters: [
            ParameterInformation(label: 'a'),
            ParameterInformation(label: 'b'),
          ],
        );

        // Assert
        expect(signature.parameters, isNotNull);
        expect(signature.parameters!.length, equals(2));
      });

      test('should create with active parameter', () {
        // Act
        const signature = SignatureInformation(
          label: 'test(int arg)',
          activeParameter: 0,
        );

        // Assert
        expect(signature.activeParameter, equals(0));
      });
    });

    group('equality', () {
      test('should be equal with same label', () {
        const sig1 = SignatureInformation(label: 'test()');
        const sig2 = SignatureInformation(label: 'test()');

        expect(sig1, equals(sig2));
      });

      test('should not be equal with different label', () {
        const sig1 = SignatureInformation(label: 'test1()');
        const sig2 = SignatureInformation(label: 'test2()');

        expect(sig1, isNot(equals(sig2)));
      });
    });

    group('complex signatures', () {
      test('should handle optional parameters', () {
        const signature = SignatureInformation(
          label: 'greet(String name, {String? title})',
          parameters: [
            ParameterInformation(label: 'name', documentation: 'The name'),
            ParameterInformation(label: 'title', documentation: 'Optional title'),
          ],
        );

        expect(signature.parameters!.length, equals(2));
        expect(signature.label, contains('String? title'));
      });

      test('should handle default parameter values', () {
        const signature = SignatureInformation(
          label: 'configure({bool enabled = true, int timeout = 5000})',
        );

        expect(signature.label, contains('= true'));
        expect(signature.label, contains('= 5000'));
      });
    });
  });

  group('ParameterInformation', () {
    group('creation', () {
      test('should create with label', () {
        // Act
        const param = ParameterInformation(label: 'arg1');

        // Assert
        expect(param.label, equals('arg1'));
        expect(param.documentation, isNull);
      });

      test('should create with documentation', () {
        // Act
        const param = ParameterInformation(
          label: 'value',
          documentation: 'The value to process',
        );

        // Assert
        expect(param.documentation, equals('The value to process'));
      });
    });

    group('equality', () {
      test('should be equal with same data', () {
        const param1 = ParameterInformation(
          label: 'test',
          documentation: 'Test param',
        );

        const param2 = ParameterInformation(
          label: 'test',
          documentation: 'Test param',
        );

        expect(param1, equals(param2));
      });

      test('should not be equal with different label', () {
        const param1 = ParameterInformation(label: 'arg1');
        const param2 = ParameterInformation(label: 'arg2');

        expect(param1, isNot(equals(param2)));
      });
    });

    group('parameter types', () {
      test('should represent required parameter', () {
        const param = ParameterInformation(
          label: 'name',
          documentation: 'Required parameter',
        );

        expect(param.label, equals('name'));
      });

      test('should represent optional parameter', () {
        const param = ParameterInformation(
          label: '[options]',
          documentation: 'Optional parameter',
        );

        expect(param.label, contains('['));
        expect(param.label, contains(']'));
      });

      test('should represent named parameter', () {
        const param = ParameterInformation(
          label: '{debug}',
          documentation: 'Named parameter',
        );

        expect(param.label, contains('{'));
        expect(param.label, contains('}'));
      });
    });
  });
}
