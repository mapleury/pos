import 'package:flutter/material.dart';
import 'package:pos_app/utils/currency_format.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrResultModal extends StatefulWidget {
  final String qrData;
  final int total;
  final bool isPrinting;
  final VoidCallback onClose;

  const QrResultModal({
    super.key,
    required this.qrData,
    required this.total,
    required this.isPrinting,
    required this.onClose,
  });

  @override
  State<QrResultModal> createState() => _QrResultModalState();
}

class _QrResultModalState extends State<QrResultModal> {
  // variable untuk menyimpan status cetak
  late bool _printFinished;

  @override
  void initState() {
    super.initState();
    //awalnya anggap proses print belum selesai
    _printFinished = false;

    //Jika mode mencetak (printer nyala), kita buat simulasi loading
    if (widget.isPrinting) {
      Future.delayed(Duration(seconds: 2), () {
        // Mengecek Jika proses delay sesuai dengan waktu printer ketika mencetak
        if (mounted) {
          // mounted = kondisi widget masih aktif
          setState(() {
            _printFinished = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // tentukan warna dan teks berdassarkan status
    Color statusColor;
    Color statusBgColor;
    IconData statusIcon;
    String statusText;

    if (!widget.isPrinting) {
      // kondisi 1: Printer mati / mode tanpa printer
      statusColor = Colors.orange;
      statusBgColor = Colors.orange.shade50;
      statusIcon = Icons.print_disabled;
      statusText = 'Mode Tanpa Printer';
    } else if (!_printFinished) {
      // kondisi 2: Printer sedang print
      statusColor = Colors.blue;
      statusBgColor = Colors.blue.shade50;
      statusIcon = Icons.print;
      statusText = 'Mencetak Struk Fisik...';
    } else {
      // kondisi 3: Printer sudah selesai print
      statusColor = Colors.green;
      statusBgColor = Colors.green.shade50;
      statusIcon = Icons.check_circle;
      statusText = 'Cetak Selesai';
    }

    return Container(
      height: 530,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          SizedBox(height: 20),

          // Status / Mode
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 20, color: statusColor),
                SizedBox(width: 10),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Text(
            'SCAN UNTUK MEMBAYAR',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF2E3192),
            ),
          ),
          SizedBox(height: 25),
          Text(
            'Total: ${formatRupiah(widget.total)}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),

          // QR
          Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.1),
                  blurRadius: 15,
                ),
              ],
            ),
            child: QrImageView(
              data: widget.qrData,
              version: QrVersions.auto,
              size: 220.0,
            ),
          ),
          Spacer(),

          // Close button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: widget.onClose,
              child: Text('Tutup'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
