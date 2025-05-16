import 'package:flutter/material.dart';
import 'package:my_part_project/services/map_service.dart';
import 'package:my_part_project/services/search_service.dart';

void showCustomBottomSheet(BuildContext context, MapController mapController) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    barrierColor: Colors.transparent,
    builder: (context) {
      return _BottomSheetContent(mapController: mapController);
    },
  );
}

class _BottomSheetContent extends StatefulWidget {
  final MapController mapController;

  const _BottomSheetContent({required this.mapController});

  @override
  State<_BottomSheetContent> createState() => _BottomSheetContentState();
}

class _BottomSheetContentState extends State<_BottomSheetContent> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  late SearchService _searchService;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final expandedHeight = 650.0;
    final initialHeight = 250.0;
    final currentHeight = keyboardHeight > 0 ? expandedHeight : initialHeight;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: currentHeight,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.mapController.currentAddress,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(),
            Row(
              children: [
                const Icon(Icons.flag),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: (value) {
                      widget.mapController.searchStreet(value);
                      setState(() {}); // Trigger rebuild to show results
                    },
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      labelText: 'Куда едем?',
                      labelStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Container(
              color: Colors.black,
              width: double.infinity,
              height: 1,
            ),
            Expanded(
              child: _searchService.searchResults.isEmpty
                  ? const Center(
                      child: Text(
                        'Начните вводить адрес',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _searchService.searchResults.length,
                      itemBuilder: (context, index) {
                        final place = _searchService.searchResults[index];
                        return ListTile(
                          title: Text(place),
                          onTap: () {
                            setState(() {
                              _searchController.text = place;
                            });
                            FocusScope.of(context).unfocus();
                          },
                        );
                      },
                    ),
            ),
            if (!(keyboardHeight > 0))
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Продолжить'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}