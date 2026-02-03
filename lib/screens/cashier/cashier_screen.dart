import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pos_app/models/products.dart';
import 'package:pos_app/screens/cashier/components/checkout_panel.dart';
import 'package:pos_app/screens/cashier/components/printer_selector.dart';
import 'package:pos_app/screens/cashier/components/product_card.dart';
import 'package:pos_app/screens/cashier/components/qr_result_modal.dart';
import 'package:pos_app/utils/currency_format.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  bool _connected = false;
  final Map<Product, int> _cart = {};

  @override
  void initState( ) {
    super.initState();
    _initBluetooth();
  }

  // LOGIKA BLUETOOTH
  Future<void> _initBluetooth() async {
    // minta izin lokasi dan bluetooth (Wajib)
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location
    ].request();

    List<BluetoothDevice> devices = [
      // list ini akan terotomatis terisi, juka bluetooth di hp menyala, dan sudah ada 
    ];
    try {
      devices = await bluetooth.getBondedDevices();
    } catch (e) {
      debugPrint('error Bluetooth: $e');
    }

    if (mounted) {
      setState(() {
        _devices = devices;
      });
    }

     bluetooth.onStateChanged().listen((state) {
      if (mounted) {
        setState(() {
          _connected = state == BlueThermalPrinter.CONNECTED;
        });
      }
     });
  }
  
  // Kalau ada device →
  // cek bluetooth udah connect apa belum →
  // kalau belum → coba connect →
  // kalau gagal → tandai gagal →
  // simpan device (kalo printernya hidup) ke state biar UI update

  @override
  void _connectedToDevice(BluetoothDevice? device) { 
    if (device!= null) { 
      bluetooth.isConnected.then((isConnected) { 
        if (isConnected == false) {
          bluetooth.connect(device).catchError((error) {
              if (mounted) setState(() => _connected = false ); 
          });

         if (mounted) setState(() => _selectedDevice = device); 
        }
      });
    }
  }
  
  
  // LOGIKA CARD
  // handle action ketika user nambah product
  void _addtoCard(Product product) {
    setState(() {
      // ada 2 kondisi, 
      _cart.update(product, 
      (value) => value + 1, // ketika user memilih lebih dri 1 product
      ifAbsent: () => 1); // ketika user cuma click 1x product
      
    });
  }
   
   // perbedaan antara bang & not, baik fungsi dan positioning
  void removeFromCart(Product product) {
    setState(() {
      if (_cart.containsKey(product) && _cart[product] ! > 1) {
        _cart[product] = _cart[product]! - 1;
      } else {
        _cart.remove(product);
      }
    });
  }
   
  int _calculateTotal() {
    int total = 0;
    _cart.forEach((key, value) => total += (key.price * value));
    return total;
  }


  // LOGIKA PRINTING
  void _handlePrint() async {
    int total = _calculateTotal();
    if (total == 0) {
      ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text("Keranjang Masih Kosong")));
    }
    String trxid = "TRX-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}";
    String qrData = "PAY:$trxid:$total";
    bool isPrinting = false;

    // menyiapkan tanggal saat ini (current date)
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('dd-MM-yyyy HH:mm').format(now);

    // LAYOUTING STRUK
    if (_selectedDevice != null && await bluetooth.isConnected == true) {
      // header struk
      bluetooth.printNewLine();
      bluetooth.printCustom("IDN CAFE", 3, 1); // judul besar (center)
      bluetooth.printNewLine();
      bluetooth.printCustom("Jl. Bagus Dayeuh", 1, 1); // alamat (center)

      // TANGGAL & ID
      bluetooth.printNewLine();
      bluetooth.printLeftRight("Waktu:", formattedDate, 1);

      //daftar items
      bluetooth.printCustom('-----------------------------', 1, 1);
      _cart.forEach((product, qty) {
        String priceTotal = formatRupiah(product.price * qty);
        // cetak nama barang x qty
        bluetooth.printLeftRight("${product.name} x ${qty}", priceTotal, 1);
      });
       bluetooth.printCustom('-----------------------------', 1, 1);

       // total & QR
       bluetooth.printLeftRight("TOTAL", formatRupiah(total), 3);
       bluetooth.printNewLine();
       bluetooth.printCustom("Scan QR Dibawah:", 1, 1);
       bluetooth.printQRcode(qrData, 200, 200, 1);
       bluetooth.printNewLine();
       bluetooth.printCustom("Thank You", 1, 1);
       bluetooth.printNewLine();
       bluetooth.printNewLine();

       isPrinting = true;
    }

    // untuk menampilkan modal hasil QR Code (Pop-up)
    _showQRModal(qrData, total, isPrinting) {
     showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => QrResultModal(
        qrData: qrData,
        total: total,
        isPrinting: isPrinting,
        onClose: () => Navigator.pop(context),
      )
     );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          "Menu Kasir",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Colors.black87,
        ),
        centerTitle: true,
        // biar di tengah 
      ),
      // ini code buat isi menunya sama printernya (1 body)
      body: Column(
        children: [
          // DROPDOWN SELECT PRINTER
          PrinterSelector(
            devices: _devices, 
            selectedDevice: _selectedDevice,
            isConnected: _connected,
            onSelected: _connectedToDevice,
          ),

          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: menus.length,
              itemBuilder: (context, index) {
                final product = menus[index];
                final qty = _cart[product] ?? 0;

                // pemanggilan product list pada product card
                return ProductCard(
                  product: product,
                  qty: qty,
                  onAdd: () => _addtoCard(product),
                  onRemoved: () => removeFromCart(product),
                  
                );
              },
            ),
          ),

          // bottom sheet panel
          CheckoutPanel(
            total: _calculateTotal(),
            onPressed: _handlePrint,
          )
        ],
      ),
    );
  }
}