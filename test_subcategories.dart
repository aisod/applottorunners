import 'package:supabase_flutter/supabase_flutter.dart';

// Test script to verify subcategories are working
void main() async {
  // Initialize Supabase (you'll need to add your credentials)
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_ANON_KEY',
  );

  try {
    print('🔍 Testing subcategories query...');
    
    // Test the new subcategories query without category_id
    final response = await Supabase.instance.client
        .from('service_subcategories')
        .select('*')
        .eq('is_active', true)
        .order('name');
    
    print('✅ Subcategories loaded successfully!');
    print('📊 Total subcategories: ${response.length}');
    
    if (response.isNotEmpty) {
      print('📋 First subcategory: ${response.first}');
      print('📋 All subcategories:');
      for (var subcategory in response) {
        print('  - ${subcategory['name']}: ${subcategory['description']}');
      }
    } else {
      print('⚠️ No subcategories found');
    }
    
  } catch (e) {
    print('❌ Error: $e');
  }
}
