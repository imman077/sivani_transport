import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sivani_transport/core/app_colors.dart';
import 'package:sivani_transport/models/transporter.dart';
import 'package:sivani_transport/providers/transporter_provider.dart';
import 'package:sivani_transport/providers/search_provider.dart';
import 'package:sivani_transport/widgets/app_components.dart';
import 'package:go_router/go_router.dart';

class TransportersPage extends ConsumerStatefulWidget {
  const TransportersPage({super.key});

  @override
  ConsumerState<TransportersPage> createState() => _TransportersPageState();
}

class _TransportersPageState extends ConsumerState<TransportersPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: ref.read(transporterSearchProvider));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Transporter> _getFilteredTransporters(List<Transporter> transporters, String searchQuery, String selectedFilter) {
    return transporters.where((t) {
      final query = searchQuery.toLowerCase();
      final searchMatch = t.name.toLowerCase().contains(query) ||
          t.phone.toLowerCase().contains(query) ||
          (t.email?.toLowerCase().contains(query) ?? false);

      final statusMatch = selectedFilter == 'All' ||
          (selectedFilter == 'Available' && t.isAvailable == true) ||
          (selectedFilter == 'Busy' && t.isAvailable == false);

      return searchMatch && statusMatch;
    }).toList();
  }

  void _showAddTransporterForm({Transporter? transporter}) {
    context.push('/transporters/add', extra: transporter);
  }

  @override
  Widget build(BuildContext context) {
    final transportersAsync = ref.watch(transportersStreamProvider);
    final searchQuery = ref.watch(transporterSearchProvider);
    final selectedFilter = ref.watch(transporterFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: transportersAsync.when(
        data: (transporters) {
          final filteredTransporters = _getFilteredTransporters(transporters, searchQuery, selectedFilter);
          return Column(
            children: [
              MasterPageHeader(
                searchController: _searchController,
                searchHint: 'Search by Name',
                onSearchChanged: (val) {
                  ref.read(transporterSearchProvider.notifier).state = val;
                  setState(() {});
                },
                onSearchCleared: () {
                  _searchController.clear();
                  ref.read(transporterSearchProvider.notifier).state = '';
                  setState(() {});
                },
                addButtonLabel: 'Add Transporter',
                onAddPressed: () => _showAddTransporterForm(),
                selectedFilter: selectedFilter,
                onFilterChanged: (val) => ref.read(transporterFilterProvider.notifier).state = val,
                filters: [
                  FilterTabItem(label: 'All', count: transporters.length, icon: Icons.group_rounded),
                  FilterTabItem(label: 'Available', count: transporters.where((t) => t.isAvailable).length, icon: Icons.check_circle_rounded),
                  FilterTabItem(label: 'Busy', count: transporters.where((t) => !t.isAvailable).length, icon: Icons.timer_rounded),
                ],
              ),
              Expanded(
                child: filteredTransporters.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredTransporters.length,
                        itemBuilder: (context, index) {
                          final transporter = filteredTransporters[index];
                          return MasterCard(
                            title: transporter.name,
                            subtitle: transporter.phone,
                            image: AppImageWidget(
                              source: transporter.image,
                              placeholder: Container(
                                color: Colors.grey.shade100,
                                child: Icon(Icons.business, color: Colors.grey.shade300, size: 30),
                              ),
                            ),
                            onEdit: () => _showAddTransporterForm(transporter: transporter),
                            onDelete: () => _showDeleteConfirmation(transporter),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.domain_disabled,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No transporters found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or add a new transporter.',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Transporter transporter) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transporter'),
        content: Text('Are you sure you want to delete ${transporter.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(transporterActionProvider.notifier).deleteTransporter(transporter.id, transporter.name);
              if (context.mounted) {
                Navigator.pop(context);
                AppToast.show(context, 'Transporter deleted successfully');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
