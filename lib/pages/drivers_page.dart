import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sivani_transport/core/app_colors.dart';
import 'package:sivani_transport/models/driver.dart';
import 'package:sivani_transport/providers/driver_provider.dart';
import 'package:sivani_transport/providers/search_provider.dart';
import 'package:sivani_transport/widgets/app_components.dart';
import 'package:sivani_transport/pages/history_page.dart';

class DriversPage extends ConsumerStatefulWidget {
  const DriversPage({super.key});

  @override
  ConsumerState<DriversPage> createState() => _DriversPageState();
}

class _DriversPageState extends ConsumerState<DriversPage> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: ref.read(driverSearchProvider));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Driver> _getFilteredDrivers(List<Driver> drivers, String searchQuery, String selectedFilter) {
    return drivers.where((driver) {
      final query = searchQuery.toLowerCase();
      final searchMatch = driver.name.toLowerCase().contains(query) ||
          driver.phone.toLowerCase().contains(query) ||
          driver.email.toLowerCase().contains(query);

      final statusMatch = selectedFilter == 'All' ||
          (selectedFilter == 'Available' && driver.isAvailable) ||
          (selectedFilter == 'Busy' && !driver.isAvailable);

      return searchMatch && statusMatch;
    }).toList();
  }

  void _showAddDriverForm({Driver? driver}) {
    context.push('/drivers/add', extra: driver);
  }

  @override
  Widget build(BuildContext context) {
    final driversAsync = ref.watch(driversStreamProvider);
    final searchQuery = ref.watch(driverSearchProvider);
    final selectedFilter = ref.watch(driverFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: driversAsync.when(
        data: (drivers) {
          final filteredDrivers = _getFilteredDrivers(drivers, searchQuery, selectedFilter);
          return Column(
            children: [
              MasterPageHeader(
                searchController: _searchController,
                searchHint: 'Search by Name',
                onSearchChanged: (val) {
                  ref.read(driverSearchProvider.notifier).state = val;
                  setState(() {});
                },
                onSearchCleared: () {
                  _searchController.clear();
                  ref.read(driverSearchProvider.notifier).state = '';
                  setState(() {});
                },
                addButtonLabel: 'Add New Driver',
                onAddPressed: () => _showAddDriverForm(),
                selectedFilter: selectedFilter,
                onFilterChanged: (val) => ref.read(driverFilterProvider.notifier).state = val,
                filters: [
                  FilterTabItem(label: 'All', count: drivers.length, icon: Icons.group_rounded),
                  FilterTabItem(label: 'Available', count: drivers.where((d) => d.isAvailable).length, icon: Icons.check_circle_rounded),
                  FilterTabItem(label: 'Busy', count: drivers.where((d) => !d.isAvailable).length, icon: Icons.timer_rounded),
                ],
              ),
              Expanded(
                child: filteredDrivers.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredDrivers.length,
                        itemBuilder: (context, index) {
                          final driver = filteredDrivers[index];
                          return MasterCard(
                            title: driver.name,
                            subtitle: driver.phone,
                            image: driver.pickedImage != null
                                ? Image.file(File(driver.pickedImage!.path), fit: BoxFit.cover)
                                : AppImageWidget(
                                    source: driver.image,
                                    placeholder: Container(
                                      color: Colors.grey.shade100,
                                      child: Icon(Icons.person, color: Colors.grey.shade300, size: 30),
                                    ),
                                  ),
                            statusBadge: _buildStatusBadge(driver.isAvailable),
                            onEdit: () => _showAddDriverForm(driver: driver),
                            onDelete: () => _showDeleteConfirmation(driver),
                            onHistory: () {
                              Navigator.of(context, rootNavigator: true).push(
                                MaterialPageRoute(
                                  builder: (_) => HistoryPage(
                                    entityId: driver.id,
                                    entityName: driver.name,
                                    type: HistoryType.driver,
                                  ),
                                ),
                              );
                            },
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

  Widget _buildStatusBadge(bool isAvailable) {
    final baseColor = isAvailable ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: baseColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: baseColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isAvailable ? 'Available' : 'Busy',
            style: TextStyle(
              color: baseColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
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
              Icons.person_off_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No drivers found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or add a new driver.',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Driver driver) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Driver'),
        content: Text('Are you sure you want to delete ${driver.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(driverActionProvider.notifier).deleteDriver(driver.id, driver.name);
              if (context.mounted) {
                Navigator.pop(context);
                AppToast.show(context, 'Driver removed successfully');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// Temporary compatibility class for hot reload after migration
class AddDriverSheet extends StatelessWidget {
  final dynamic driver;
  const AddDriverSheet({super.key, this.driver});
  @override
  Widget build(BuildContext context) => const SizedBox();
}
