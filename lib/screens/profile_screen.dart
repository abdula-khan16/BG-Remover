import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../utils/image_storage_helper.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  User? _user;
  bool _isGuest = false;
  List<String> _recentPaths = [];
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    final prefs = await SharedPreferences.getInstance();
    _isGuest = prefs.getBool('isGuest') ?? false;
    
    if (!_isGuest) {
      _user = supabase.auth.currentUser;
      // If user is null but not guest, maybe session expired
      if (_user == null) {
        _isGuest = true;
      } else {
        // Trigger background sync
        _syncAndReload();
      }
    }

    _recentPaths = await ImageStorageHelper.getSavedImages();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _syncAndReload() async {
    await ImageStorageHelper.syncCloudEdits();
    final paths = await ImageStorageHelper.getSavedImages();
    if (mounted) {
      setState(() {
        _recentPaths = paths;
      });
    }
  }

  String _getUserName() {
    if (_isGuest || _user == null) return 'Guest User';
    final metadata = _user!.userMetadata;
    if (metadata != null) {
      final fullName = metadata['full_name'] as String?;
      if (fullName != null && fullName.trim().isNotEmpty) {
        return fullName.trim();
      }
      final firstName = metadata['first_name'] as String?;
      final lastName = metadata['last_name'] as String?;
      if (firstName != null && firstName.trim().isNotEmpty) {
        return '${firstName.trim()} ${lastName?.trim() ?? ''}'.trim();
      }
    }
    final email = _user!.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    return 'User Name';
  }

  Future<void> _uploadImage(String filePath) async {
    if (_isGuest || _user == null) {
      _showSnackBar('Please login to sync with cloud', Colors.orange);
      return;
    }
    
    setState(() => _isUploading = true);
    try {
      final file = File(filePath);
      final fileName = filePath.split('/').last;
      final path = '${_user!.id}/$fileName';

      await supabase.storage.from('edits').upload(
            path,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      _showSnackBar('✅ Image synced to cloud!', Colors.green);
    } catch (e) {
      _showSnackBar('❌ Upload failed: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isGuest ? 'Exit Guest Mode' : 'Sign Out'),
        content: Text(_isGuest ? 'Are you sure you want to exit?' : 'Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(_isGuest ? 'Exit' : 'Sign Out', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!_isGuest) await supabase.auth.signOut();
      
      // Clear local edits cache and files on logout
      await ImageStorageHelper.clearLocalEdits();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isGuest', false);

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isGuest ? Icons.login : Icons.logout, color: Colors.white),
            onPressed: _signOut,
            tooltip: _isGuest ? 'Login' : 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              child: Column(
                children: [
                  // ========== HEADER / USER INFO ==========
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          child: Icon(
                            _isGuest ? Icons.person_outline : Icons.person,
                            size: 60,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _getUserName(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _isGuest ? 'Limited access mode' : (_user?.email ?? 'email@example.com'),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        if (_isGuest)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: ElevatedButton(
                              onPressed: () => Navigator.pushNamed(context, '/login'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                              ),
                              child: const Text('Login to Sync'),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ========== STATS ==========
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatCard('Local Edits', '${_recentPaths.length}'),
                        _buildStatCard('Cloud Sync', _isGuest ? 'Off' : 'Active'),
                        _buildStatCard('Plan', _isGuest ? 'Guest' : 'Free'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ========== RECENT EDITS SECTION ==========
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Your Recent Edits',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            if (_isUploading)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _recentPaths.isEmpty
                            ? _buildEmptyState()
                            : GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _recentPaths.length > 6 ? 6 : _recentPaths.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.8,
                                ),
                                itemBuilder: (context, index) {
                                  final path = _recentPaths[index];
                                  return Card(
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    clipBehavior: Clip.antiAlias,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.file(
                                          File(path),
                                          fit: BoxFit.cover,
                                        ),
                                        if (!_isGuest)
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.bottomCenter,
                                                  end: Alignment.topCenter,
                                                  colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                                                ),
                                              ),
                                              padding: const EdgeInsets.all(4),
                                              child: TextButton.icon(
                                                onPressed: _isUploading ? null : () => _uploadImage(path),
                                                icon: const Icon(Icons.cloud_upload, size: 16, color: Colors.white),
                                                label: const Text('Sync', style: TextStyle(color: Colors.white, fontSize: 12)),
                                                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppColors.gray),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.grayLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.image_outlined, size: 48, color: AppColors.gray),
          SizedBox(height: 16),
          Text('No edits yet', style: TextStyle(color: AppColors.gray, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
