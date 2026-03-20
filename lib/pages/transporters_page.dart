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
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Transporters',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        elevation: 0,
      ),
      body: transportersAsync.when(
        data: (transporters) {
          final filteredTransporters = _getFilteredTransporters(transporters, searchQuery, selectedFilter);
          return Column(
            children: [
              // Sticky Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSearchAndFilter(filteredTransporters.length, transporters),
              ),
              Expanded(
                child: filteredTransporters.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredTransporters.length,
                        itemBuilder: (context, index) =>
                            _buildTransporterCard(filteredTransporters[index]),
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

  Widget _buildSearchAndFilter(int transporterCount, List<Transporter> transporters) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Colors.blueGrey.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            height: 52,
            alignment: Alignment.center,
            child: TextField(
              controller: _searchController,
              onChanged: (val) => ref.read(transporterSearchProvider.notifier).state = val,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              decoration: const InputDecoration(
                hintText: 'Search transporters',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Add Transporter',
            onPressed: _showAddTransporterForm,
            icon: Icons.add_business_outlined,
            height: 46,
          ),
          const SizedBox(height: 20),
          Container(
            height: 48,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(child: _buildFilterTab('All', transporters.length, Icons.group_rounded)),
                Expanded(child: _buildFilterTab('Available', transporters.where((t) => t.isAvailable == true).length, Icons.check_circle_rounded)),
                Expanded(child: _buildFilterTab('Busy', transporters.where((t) => t.isAvailable == false).length, Icons.timer_rounded)),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, int count, IconData icon) {
    final selectedFilter = ref.watch(transporterFilterProvider);
    final bool isSelected = selectedFilter == label;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ref.read(transporterFilterProvider.notifier).state = label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        height: double.infinity,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : Colors.blueGrey.shade400,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.blueGrey.shade700,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.white.withValues(alpha: 0.15) 
                    : Colors.blueGrey.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.blueGrey.shade700,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
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

  Widget _buildTransporterCard(Transporter transporter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar Section
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AppImageWidget(
                  source: transporter.image,
                  placeholder: Container(
                    color: Colors.grey.shade100,
                    child: Icon(Icons.business, color: Colors.grey.shade300, size: 30),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Info Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    transporter.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.phone_rounded,
                          size: 13, color: Colors.blueGrey.shade300),
                      const SizedBox(width: 6),
                      Text(
                        transporter.phone,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blueGrey.shade400,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildStatusBadge(transporter.isAvailable == true),
                ],
              ),
            ),
            // Action Section
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  Icons.edit_rounded,
                  const Color(0xFFEFF6FF),
                  const Color(0xFF2563EB),
                  () => _showAddTransporterForm(transporter: transporter),
                ),
                const SizedBox(height: 8),
                _buildActionButton(
                  Icons.delete_outline_rounded,
                  const Color(0xFFFFF1F2),
                  const Color(0xFFE11D48),
                  () => _showDeleteConfirmation(transporter),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color bgColor, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: iconColor),
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
              await ref.read(transporterActionProvider.notifier).deleteTransporter(transporter.id);
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
