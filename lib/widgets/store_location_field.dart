import 'package:flutter/material.dart';
import '../models/store_location.dart';
import 'simple_location_picker.dart';

class StoreLocationField extends StatelessWidget {
  final int index;
  final StoreLocation store;
  final Function(int index, StoreLocation store) onStoreUpdated;
  final VoidCallback? onRemove;
  final bool canRemove;

  const StoreLocationField({
    super.key,
    required this.index,
    required this.store,
    required this.onStoreUpdated,
    this.onRemove,
    this.canRemove = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.store,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Store ${index + 1}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              if (canRemove && onRemove != null)
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: theme.colorScheme.error,
                  tooltip: 'Remove Store',
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Location type selection
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Store Name'),
                  subtitle: const Text('Just enter store name'),
                  value: 'name',
                  groupValue: store.locationType,
                  onChanged: (value) {
                    final updatedStore = store.copyWith(locationType: value!);
                    onStoreUpdated(index, updatedStore);
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Map Location'),
                  subtitle: const Text('Select exact location'),
                  value: 'map',
                  groupValue: store.locationType,
                  onChanged: (value) {
                    final updatedStore = store.copyWith(locationType: value!);
                    onStoreUpdated(index, updatedStore);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Location input based on type
          if (store.locationType == 'name')
            _buildStoreNameField(theme)
          else
            _buildStoreMapField(theme),
        ],
      ),
    );
  }

  Widget _buildStoreNameField(ThemeData theme) {
    return TextFormField(
      initialValue: store.name,
      decoration: InputDecoration(
        labelText: 'Store Name *',
        hintText: 'e.g., Shoprite, Spar, Pharmacy, etc.',
        prefixIcon: Icon(Icons.store, color: theme.colorScheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onChanged: (value) {
        final updatedStore = store.copyWith(name: value);
        onStoreUpdated(index, updatedStore);
      },
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Store name is required';
        }
        return null;
      },
    );
  }

  Widget _buildStoreMapField(ThemeData theme) {
    return SimpleLocationPicker(
      initialAddress: store.address,
      labelText: 'Store Location *',
      hintText: 'Where should we shop?',
      prefixIcon: Icons.store,
      iconColor: theme.colorScheme.primary,
      onLocationSelected: (address, lat, lng) {
        final updatedStore = store.copyWith(
          address: address,
          latitude: lat,
          longitude: lng,
        );
        onStoreUpdated(index, updatedStore);
      },
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Store location is required';
        }
        return null;
      },
    );
  }
}
