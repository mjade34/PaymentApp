import 'dart:convert';
import 'package:http/http.dart' as http ;
import '../config/stripe_config.dart';


class StripeServices {

  static const Map<String, String> _testTokens = {
    '4591682649351275' : 'tok_visa',
    '9716824691358462' : 'tok_visa_debit',
    '1975268436512394' : 'tok_mastercard_debit',
    '5594236844621935' : 'tok_chargeDeclined',
    '1975698436852665' : 'tok_chargeDeclineInsufficientFunds',
  };

  static Future<Map<String, dynamic>> processPayment({
    required double amount,
    required String cardNumber,
    required String expMonth,
    required String expYear,
    required String cvc,
}) async {
    final amountInCentavos = (amount * 100).round().toString();
    final cleanCard = cardNumber.replaceAll('', '');
    final token = _testTokens[cleanCard];

    if (token == null) {
      return <String, dynamic>{
        'success': false,
        'error': 'unknown test card. use 4591682649351275 or 1975268436512394',
      };
    }
    try {
      final response = await http.post(
          Uri.parse('${StripeConfig.apiUrl}/payment_intents'),
          headers: <String, String>{
            'Authorization': 'Bearer ${StripeConfig.secretKey}',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: <String, String>{
            'amount': amountInCentavos,
            'currency': 'php',
            'payment_method_types[]': 'card',
            'payment_method_data[type]': 'card',
            'payment_method_data[card][token]': token,
            'confirm': 'true',
          },
        );
          final data = jsonDecode(response.body) as Map<String, dynamic>;
      // final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['status'] == 'succeeded') {
      return <String, dynamic>{
        'success': true,
        'id': data['id'].toString(),
        'amount': (data['amount'] as num) / 100,
        'status': data['status'].toString(),
      };
    } else {
        final errorMsg = data['error'] is Map
        ? (data['error'] as Map) ['message']?.toString() ?? 'Payment failed'
        : 'Payment failed';

        return <String, dynamic>{'success': false, 'error': errorMsg};
    }
  } catch (e) {
    return <String, dynamic>{'success': false, 'error': e.toString()};
    }
  }
}