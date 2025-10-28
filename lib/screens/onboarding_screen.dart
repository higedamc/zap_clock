import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../l10n/app_localizations.dart';
import '../app_theme.dart';
import '../providers/storage_provider.dart';
import '../services/permission_service.dart';

/// Onboarding screen
/// Explain how to use the app on first launch
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  Future<void> _completeOnboarding(BuildContext context, WidgetRef ref) async {
    final storage = ref.read(storageServiceProvider);
    await storage.setOnboardingCompleted();
    
    if (!context.mounted) return;
    
    // Request permissions after onboarding completion
    await _requestPermissions(context);
    
    if (!context.mounted) return;
    context.go('/');
  }
  
  /// Execute permission request
  Future<void> _requestPermissions(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final permissionService = PermissionService();
    
    // Show permission request dialog
    if (!context.mounted) return;
    
    final shouldRequest = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(l10n.requestPermissions),
        content: Text(l10n.grantNextPermissions),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    
    if (shouldRequest != true) return;
    
    // Request permissions
    final results = await permissionService.requestAllPermissions();
    permissionService.logPermissionSummary(results);
    
    // Notify user if permissions are denied
    if (!context.mounted) return;
    final hasAll = await permissionService.hasAllRequiredPermissions();
    if (!hasAll) {
      if (!context.mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.permissionsInsufficient),
          content: Text(l10n.permissionsInsufficientMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Generate localized pages
    final pages = [
      _OnboardingPage(
        icon: Icons.alarm,
        iconColor: AppTheme.primaryColor,
        title: l10n.onboardingTitle1,
        description: l10n.onboardingDescription1,
      ),
      _OnboardingPage(
        icon: Icons.flash_on,
        iconColor: AppTheme.accentColor,
        title: l10n.onboardingTitle2,
        description: l10n.onboardingDescription2,
      ),
      _OnboardingPage(
        icon: Icons.settings,
        iconColor: Colors.orange,
        title: l10n.onboardingTitle3,
        description: l10n.onboardingDescription3,
      ),
      _OnboardingPage(
        icon: Icons.done_all,
        iconColor: Colors.green,
        title: l10n.onboardingTitle4,
        description: l10n.onboardingDescription4,
      ),
    ];
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            if (_currentPage < pages.length - 1)
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () => _pageController.animateToPage(
                    pages.length - 1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  ),
                  child: Text(l10n.skip),
                ),
              )
            else
              const SizedBox(height: 48),
            
            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  return pages[index];
                },
              ),
            ),
            
            // Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (index) => _buildPageIndicator(index),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Consumer(
                builder: (context, ref, child) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _currentPage == pages.length - 1
                          ? () => _completeOnboarding(context, ref)
                          : () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentPage == pages.length - 1 ? l10n.start : l10n.next,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: _currentPage == index ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index
            ? AppTheme.primaryColor
            : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// Onboarding page
class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  const _OnboardingPage({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: iconColor,
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          // Description
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

