import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class ServiceStaffPopup extends StatefulWidget {
  const ServiceStaffPopup({super.key});

  @override
  _ServiceStaffPopupState createState() => _ServiceStaffPopupState();
}

class _ServiceStaffPopupState extends State<ServiceStaffPopup> {
  final TextEditingController _invoiceController = TextEditingController();
  final GlobalKey _key = GlobalKey();
  OverlayEntry? _overlayEntry;
  bool _showError = false;

  @override
  void dispose() {
    _invoiceController.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }

  void _showPopup() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hidePopup() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _sendInvoiceNo() {
    if (_invoiceController.text.isEmpty) {
      setState(() {
        _showError = true;
      });
      // Rebuild the overlay to show the error
    _overlayEntry?.markNeedsBuild();
    } else {
      // Handle the invoice number
      print('Invoice No: ${_invoiceController.text}');
      _hidePopup();
    }
  }

  OverlayEntry _createOverlayEntry() {
    final RenderBox renderBox = _key.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder: (context) => GestureDetector(
        onTap: _hidePopup,
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned(
                left: offset.dx - 125 + size.width / 2, // Center the popup
                top: offset.dy + size.height + 10, // Position below the icon
                child: Column(
                  children: [
                    CustomPaint(
                      painter: _ArrowPainter(),
                      child: const SizedBox(
                        width: 20,
                        height: 10,
                      ),
                    ),
                    Container(
                      width: 250,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Service staff replacement',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          StatefulBuilder(
                            builder: (BuildContext context, StateSetter setState) {
                              return TextField(
                                controller: _invoiceController,
                                decoration: InputDecoration(
                                  hintText: 'Invoice No.',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: _showError ? Colors.red : Colors.grey,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: _showError ? Colors.red : Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                                onChanged: (value) {
                                  if (_showError && value.isNotEmpty) {
                                    setState(() {
                                      _showError = false;
                                    });
                                     _overlayEntry?.markNeedsBuild();
                                  }
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _sendInvoiceNo,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: Colors.red),
                              ),
                            ).copyWith(
                              overlayColor: MaterialStateProperty.resolveWith<Color?>(
                                (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.hovered)) {
                                    return Colors.red.withOpacity(0.1);
                                  }
                                  return null;
                                },
                              ),
                            ),
                            child: const Text('Send'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _key,
      onTap: () {
        if (_overlayEntry == null) {
          _showPopup();
        } else {
          _hidePopup();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Tooltip(
          message: 'Service Staff Replacement',
          child: Icon(MdiIcons.accountSwitchOutline, color: Colors.black, size: 20),
        ),
      ),
    );
  }
}

class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, paint);

     final borderPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(size.width / 2, 0), Offset(0, size.height), borderPaint);
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width, size.height), borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}