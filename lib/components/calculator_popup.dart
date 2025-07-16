
import 'package:flutter/material.dart';

class CalculatorPopup extends StatefulWidget {
  const CalculatorPopup({super.key});

  @override
  State<CalculatorPopup> createState() => _CalculatorPopupState();
}

class _CalculatorPopupState extends State<CalculatorPopup> {
  String _output = "0";
  String _currentInput = "";
  double _num1 = 0;
  double _num2 = 0;
  String _operator = "";

  void _buttonPressed(String buttonText) {
    setState(() {
      if (buttonText == "AC") {
        _output = "0";
        _currentInput = "";
        _num1 = 0;
        _num2 = 0;
        _operator = "";
      } else if (buttonText == "CE") {
        _currentInput = "";
        _output = "0";
      } else if (buttonText == "+" ||
          buttonText == "-" ||
          buttonText == "*" ||
          buttonText == "/") {
        _num1 = double.parse(_output);
        _operator = buttonText;
        _currentInput = "";
      } else if (buttonText == ".") {
        if (!_currentInput.contains(".")) {
          _currentInput += buttonText;
        }
      } else if (buttonText == "=") {
        _num2 = double.parse(_output);
        if (_operator == "+") {
          _output = (_num1 + _num2).toString();
        }
        if (_operator == "-") {
          _output = (_num1 - _num2).toString();
        }
        if (_operator == "*") {
          _output = (_num1 * _num2).toString();
        }
        if (_operator == "/") {
          _output = (_num1 / _num2).toString();
        }
        _num1 = 0;
        _num2 = 0;
        _operator = "";
        _currentInput = _output;
      } else {
        _currentInput += buttonText;
        _output = _currentInput;
      }
    });
  }

  Widget _buildButton(
      String buttonText, Color color, Color textColor, int flex) {
    return Expanded(
      flex: flex,
      child: ElevatedButton(
        onPressed: () => _buttonPressed(buttonText),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
        ),
        child: Text(
          buttonText,
          style: TextStyle(
            fontSize: 20,
            color: textColor,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4.0,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
              child: Text(
                _output,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(),
            Row(
              children: [
                _buildButton("AC", Colors.red, Colors.white, 1),
                const SizedBox(width: 10),
                _buildButton("CE", Colors.orange, Colors.white, 1),
                const SizedBox(width: 10),
                _buildButton("%", Colors.grey, Colors.black, 1),
                const SizedBox(width: 10),
                _buildButton("/", Colors.grey, Colors.black, 1),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildButton("7", Colors.grey[300]!, Colors.black, 1),
                const SizedBox(width: 10),
                _buildButton("8", Colors.grey[300]!, Colors.black, 1),
                const SizedBox(width: 10),
                _buildButton("9", Colors.grey[300]!, Colors.black, 1),
                const SizedBox(width: 10),
                _buildButton("*", Colors.grey, Colors.black, 1),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildButton("4", Colors.grey[300]!, Colors.black, 1),
                const SizedBox(width: 10),
                _buildButton("5", Colors.grey[300]!, Colors.black, 1),
                const SizedBox(width: 10),
                _buildButton("6", Colors.grey[300]!, Colors.black, 1),
                const SizedBox(width: 10),
                _buildButton("-", Colors.grey, Colors.black, 1),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildButton("1", Colors.grey[300]!, Colors.black, 1),
                const SizedBox(width: 10),
                _buildButton("2", Colors.grey[300]!, Colors.black, 1),
                const SizedBox(width: 10),
                _buildButton("3", Colors.grey[300]!, Colors.black, 1),
                const SizedBox(width: 10),
                _buildButton("+", Colors.grey, Colors.black, 1),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildButton("0", Colors.grey[300]!, Colors.black, 2),
                const SizedBox(width: 10),
                _buildButton(".", Colors.grey[300]!, Colors.black, 1),
                const SizedBox(width: 10),
                _buildButton("=", Colors.green, Colors.white, 1),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
