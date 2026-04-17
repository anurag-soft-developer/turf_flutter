import 'package:flutter/material.dart';

import '../../../turf/model/turf_model.dart';

class ProposeTurfSheet extends StatefulWidget {
  final List<TurfModel> turfs;

  const ProposeTurfSheet({super.key, required this.turfs});

  @override
  State<ProposeTurfSheet> createState() => _ProposeTurfSheetState();
}

class _ProposeTurfSheetState extends State<ProposeTurfSheet> {
  String? _selectedTurfId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selectedTurfId == null || _selectedTurfId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a turf to propose.')),
      );
      return;
    }
    Navigator.of(context).pop(_selectedTurfId);
  }

  @override
  Widget build(BuildContext context) {
    final filteredTurfs = widget.turfs.where((turf) {
      if (_searchQuery.trim().isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      final name = turf.displayName.toLowerCase();
      final address = (turf.location?.address ?? '').toLowerCase();
      return name.contains(query) || address.contains(query);
    }).toList();

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.92,
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Propose Turf',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search turf by name or address',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: 12),
              if (widget.turfs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No turfs available to propose.'),
                )
              else if (filteredTurfs.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No turfs match your search.'),
                )
              else
                Expanded(
                  child: RadioGroup<String>(
                    groupValue: _selectedTurfId,
                    onChanged: (value) => setState(() => _selectedTurfId = value),
                    child: ListView.separated(
                      itemCount: filteredTurfs.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final turf = filteredTurfs[index];
                        final turfId = turf.id ?? '';
                        final isSelectable = turfId.isNotEmpty;
                        return InkWell(
                          onTap: !isSelectable
                              ? null
                              : () => setState(() => _selectedTurfId = turfId),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: turf.mainImage != null
                                      ? Image.network(
                                          turf.mainImage!,
                                          width: 56,
                                          height: 56,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) => Container(
                                            width: 56,
                                            height: 56,
                                            color: Colors.grey.shade200,
                                            child: const Icon(Icons.image_not_supported),
                                          ),
                                        )
                                      : Container(
                                          width: 56,
                                          height: 56,
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.image),
                                        ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        turf.displayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (turf.location?.address != null)
                                        Text(
                                          turf.location!.address,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.black54,
                                          ),
                                        ),
                                      const Text(
                                        'Distance: -- km away from your location',
                                        style: TextStyle(
                                          color: Colors.black45,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                isSelectable
                                    ? Radio<String>(value: turfId)
                                    : const Icon(
                                        Icons.block,
                                        size: 20,
                                        color: Colors.black26,
                                      ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.turfs.isEmpty ? null : _submit,
                  child: const Text('Send Proposal'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
