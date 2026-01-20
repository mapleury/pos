import 'package:flutter/material.dart';

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

    return Container();
  }
}
