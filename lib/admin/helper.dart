import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReusableOverlayDropdown extends StatefulWidget {
  final String label;
  final String hint;
  final List<Map<String, dynamic>> list;
  final String labelKey;
  final String valueKey;
  final TextEditingController controller;
  final Function(String value, String label) onSelected;

  const ReusableOverlayDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.list,
    required this.labelKey,
    required this.valueKey,
    required this.controller,
    required this.onSelected,
  });

  @override
  State<ReusableOverlayDropdown> createState() =>
      _ReusableOverlayDropdownState();
}

class _ReusableOverlayDropdownState extends State<ReusableOverlayDropdown> {
  final GlobalKey fieldKey = GlobalKey();
  OverlayEntry? overlayEntry;

  void showOverlay() {
    /// close previous overlay
    if (overlayEntry != null) {
      overlayEntry!.remove();
      overlayEntry = null;
    }

    final renderBox = fieldKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    double itemHeight = 40;
    double maxHeight = widget.list.length * itemHeight;

    if (maxHeight > 220) {
      maxHeight = 220;
    }

    overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          /// tap anywhere to close
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                overlayEntry?.remove();
                overlayEntry = null;
              },
              child: Container(color: Colors.transparent),
            ),
          ),

          /// dropdown
          Positioned(
            left: offset.dx,
            top: offset.dy + size.height,
            width: size.width,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: maxHeight,
                color: Colors.white,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: widget.list.length,
                  itemBuilder: (context, index) {
                    final item = widget.list[index];

                    return InkWell(
                      onTap: () {
                        widget.controller.text = item[widget.labelKey];

                        widget.onSelected(
                          item[widget.valueKey].toString(),
                          item[widget.labelKey],
                        );

                        overlayEntry?.remove();
                        overlayEntry = null;
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Text(
                          item[widget.labelKey],
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(overlayEntry!);
  }

  @override
  void dispose() {
    overlayEntry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: fieldKey,
      onTap: showOverlay,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.label.isNotEmpty) ...[
            Text(
              widget.label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2), 
          ],
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.controller.text.isEmpty
                        ? widget.hint
                        : widget.controller.text,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
