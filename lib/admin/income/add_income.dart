import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sonia_public_school/api_service.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class AddIncomeExpPage extends StatefulWidget {
  final String? expenseId;

  const AddIncomeExpPage({super.key, this.expenseId});

  @override
  State<AddIncomeExpPage> createState() => _AddIncomeExpPageState();
}

class _AddIncomeExpPageState extends State<AddIncomeExpPage> {
  // Controllers
  final TextEditingController priceCtrl = TextEditingController();
  final TextEditingController qtyCtrl = TextEditingController();
  final TextEditingController remarkCtrl = TextEditingController();
  File? attachmentFile;
  bool isLoading = false;
  final LayerLink _itemLink = LayerLink();
  bool editLoading = false;
  String? existingAttachment;

  // update support
  String? expenseId; // pass from previous page if edit
  bool isUpdate = false;

  // Selected values
  DateTime? selectedDate;
  String selectedType = "Income";
  String selectedItem = "";
  String selectedPayMode = "";
  List<String> payModeList = [];

  OverlayEntry? _overlayEntry;
  final LayerLink _typeLink = LayerLink();
  final LayerLink _payModeLink = LayerLink();
  // Dropdown data
  List<String> typeList = ["Income", "Expenses"];
  List<String> itemList = [];

  @override
  void initState() {
    super.initState();

    selectedDate = DateTime.now();

    expenseId = widget.expenseId;
    isUpdate = expenseId != null;

    fetchItems();
    fetchPayModes();

    if (isUpdate) {
      loadEditData();
    }
  }

  Future<void> loadEditData() async {
    editLoading = true;
    setState(() {});

    try {
      final response = await ApiService.post(
        context,
        "/admin/expense/edit",
        body: {"ExpenseId": expenseId},
      );

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);

        selectedType = data["Type"];
        selectedItem = data["ItemName"];
        selectedPayMode = data["Mode"];

        priceCtrl.text = data["Price"].toString();
        qtyCtrl.text = data["Quantity"].toString();
        remarkCtrl.text = data["Remark"] ?? "";

        selectedDate = DateTime.parse(data["Date"]);

        existingAttachment = data["Attachment"] != null
            ? data["Attachment"].toString().split('/').last
            : null;

        await fetchItems();
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    editLoading = false;
    setState(() {});
  }

  Future<void> fetchPayModes() async {
    try {
      final response = await ApiService.post(context, "/get_mode");

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);

        payModeList = List<String>.from(
          data.map((e) => e["Paymode"].toString()),
        );
        setState(() {});
      }
    } catch (e) {
      debugPrint("PayMode error: $e");
    }
  }

  Future<void> fetchItems() async {
    try {
      final response = await ApiService.post(
        context,
        "/get_exp_item",
        body: {"Type": selectedType},
      );

      if (response != null && response.statusCode == 200) {
        final data = jsonDecode(response.body);

        itemList = List<String>.from(data.map((e) => e["ItemName"].toString()));

        setState(() {});
      }
    } catch (e) {
      debugPrint("Item fetch error: $e");
    }
  }

  void _showCompactDropdown({
    required List<String> items,
    required LayerLink link,
    required Function(String) onSelect,
  }) {
    _removeDropdown(); // 🔴 IMPORTANT

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 40,
        child: CompositedTransformFollower(
          link: link,
          offset: const Offset(0, 40),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 160),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: items.map((e) {
                  return InkWell(
                    onTap: () {
                      onSelect(e);
                      _removeDropdown();
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 12)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();

    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        attachmentFile = File(image.path);
      });

      debugPrint("FILE PATH => ${attachmentFile!.path}");
      debugPrint("FILE EXISTS => ${attachmentFile!.existsSync()}");
    }
  }

  String get amount {
    double price = double.tryParse(priceCtrl.text) ?? 0;
    double qty = double.tryParse(qtyCtrl.text) ?? 0;
    return (price * qty).toString();
  }

  Future<void> saveExpense() async {
    if (selectedDate == null ||
        selectedItem.isEmpty ||
        selectedPayMode.isEmpty ||
        priceCtrl.text.isEmpty ||
        qtyCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Fill all required fields")));
      return;
    }

    setState(() => isLoading = true);

    try {
      String formattedDate =
          "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";

      var uri = Uri.parse("${ApiService.baseUrl}/admin/expense/store");

      var request = http.MultipartRequest("POST", uri);

      request.headers.addAll(await ApiService.multipartHeaders());

      request.fields['Date'] = formattedDate;
      request.fields['TxnType'] = selectedType;
      request.fields['ItemName'] = selectedItem;
      request.fields['Price'] = priceCtrl.text;
      request.fields['Quantity'] = qtyCtrl.text;
      request.fields['Amount'] = amount;
      request.fields['Mode'] = selectedPayMode;
      request.fields['Remark'] = remarkCtrl.text;

      if (isUpdate && expenseId != null) {
        request.fields['Type'] = "update";
        request.fields['ExpenseId'] = expenseId!;
      }

      if (attachmentFile != null && attachmentFile!.existsSync()) {
        request.files.add(
          await http.MultipartFile.fromPath('Attachment', attachmentFile!.path),
        );
      }
      var streamed = await request.send();
      var res = await http.Response.fromStream(streamed);

      debugPrint(res.body);
      debugPrint("FIELDS => ${request.fields}");
      debugPrint("FILE => ${attachmentFile?.path}");
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Saved Successfully")));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(res.body)));
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    setState(() => isLoading = false);
  }

  void _removeDropdown() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6ECFB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: BackButton(),
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          isUpdate ? 'Edit Income/Expense' : 'Add Income/Expense',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),

        centerTitle: true,
      ),
      body: editLoading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _removeDropdown,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(10),
                child: Column(children: [_formCard()]),
              ),
            ),
    );
  }

  Widget _formCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _box(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              /// DATE
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Date*'),
                    InkWell(
                      onTap: () async {
                        DateTime? d = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );

                        if (d != null) {
                          setState(() => selectedDate = d);
                        }
                      },
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: _innerBox(),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          selectedDate == null
                              ? "Select Date"
                              : "${selectedDate!.day}-${selectedDate!.month}-${selectedDate!.year}",
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              /// TYPE
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Type*'),
                    _dropdown(selectedType, typeList, _typeLink, (val) async {
                      selectedType = val;
                      itemList.clear();
                      selectedItem = "";

                      setState(() {});

                      await fetchItems();
                    }),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          _label('Item Name*'),
          _dropdown(
            selectedItem.isEmpty ? "Select Item" : selectedItem,
            itemList,
            _itemLink,
            (val) => setState(() => selectedItem = val),
          ),

          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Item Price*'),
                    _field(
                      'Enter Price',
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Item Qty*'),
                    _field(
                      'Qty',
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          _label('Pay Mode*'),
          _dropdown(
            selectedPayMode.isEmpty ? "Select Mode" : selectedPayMode,
            payModeList,
            _payModeLink,
            (val) => setState(() => selectedPayMode = val),
          ),

          const SizedBox(height: 10),

          const SizedBox(height: 8),
          _label('Remark'),
          _field('Enter Remark', controller: remarkCtrl),

          const SizedBox(height: 8),

          _label('Attachment'),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: pickImage,
                  child: Container(
                    height: 38,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: _innerBox(),
                    child: Text(
                      attachmentFile != null
                          ? attachmentFile!.path.split('/').last
                          : (existingAttachment != null
                                ? existingAttachment!.split('/').last
                                : "No file selected"),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: pickImage,
                child: Container(
                  height: 38,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _saveButton(),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(text, style: const TextStyle(fontSize: 11)),
  );

  Widget _field(
    String hint, {
    TextEditingController? controller,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: _innerBox(),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Widget _dropdown(
    String value,
    List<String> list,
    LayerLink link,
    Function(String) onSelect,
  ) {
    return CompositedTransformTarget(
      link: link,
      child: InkWell(
        onTap: () {
          _showCompactDropdown(items: list, link: link, onSelect: onSelect);
        },
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: _innerBox(),
          child: Row(
            children: [
              Expanded(
                child: Text(value, style: const TextStyle(fontSize: 12)),
              ),
              const Icon(Icons.keyboard_arrow_down, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _saveButton() {
    return Align(
      alignment: Alignment.center,
      child: SizedBox(
        height: 40,
        width: 140,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: isLoading ? null : saveExpense,
          child: isLoading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.save, size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      isUpdate ? 'Update' : 'Save',
                      style: const TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  BoxDecoration _box() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
  );

  BoxDecoration _innerBox() => BoxDecoration(
    color: const Color(0xFFF4ECFA),
    borderRadius: BorderRadius.circular(10),
  );
}
