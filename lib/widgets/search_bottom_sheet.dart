import 'dart:async';
import 'package:flutter/material.dart';

Future<void> showSearchBottomSheet({
  required BuildContext context,
  required TextEditingController searchController,
  required List<String> searchResults,
  required String currentAddress,
  required Function(String) onSearchChanged,
  required VoidCallback onContinue,
}) {
  Timer? debounce;

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    barrierColor: Colors.transparent,
    builder: (context) {
      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
          final expandedHeight = 650.0;
          final initialHeight = 250.0;
          final currentHeight = keyboardHeight > 0 ? expandedHeight : initialHeight;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusScope.of(context).unfocus(),
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
                          currentAddress,
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
                          controller: searchController,
                          onChanged: (value) {
                            debounce?.cancel();
                            debounce = Timer(
                              const Duration(milliseconds: 200),
                              () => onSearchChanged(value),
                            );
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
                    child: searchResults.isEmpty
                        ? const Center(
                            child: Text(
                              'Начните вводить адрес',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: searchResults.length,
                            itemBuilder: (context, index) {
                              final place = searchResults[index];
                              return ListTile(
                                title: Text(place),
                                onTap: () {
                                  searchController.text = place;
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
                        onPressed: onContinue,
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
        },
      );
    },
  );
}
