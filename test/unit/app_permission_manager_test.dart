import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax/iconsax.dart';
import 'package:enterprise_kit/core/permissions/app_permission_manager.dart';

void main() {
  group('AppPermissionManager Metadata Resolution & Overrides', () {
    test('default meta resolution', () {
      final meta = AppPermissionManager.resolveMeta(AppPermissionType.camera);
      expect(meta.title, 'Camera');
      expect(meta.rationale, contains('We need camera access'));
    });

    test('placeholder template replacement', () {
      const customBase = AppPermissionMeta(
        title: 'Camera for {location}',
        rationale: 'We need access to {customVar} to {usecase} in {location}.',
        deniedMessage: 'Denied in {location}.',
        icon: Iconsax.camera,
        color: Colors.red,
      );

      final resolved = AppPermissionManager.resolveMeta(
        AppPermissionType.camera,
        location: 'checkout',
        useCase: 'scan payment card',
        variables: {'customVar': 'important card'},
        metaOverride: customBase,
      );

      expect(resolved.title, 'Camera for checkout');
      expect(resolved.rationale, 'We need access to important card to scan payment card in checkout.');
      expect(resolved.deniedMessage, 'Denied in checkout.');
    });

    test('registry overrides with wildcards', () {
      const specialMeta = AppPermissionMeta(
        title: 'Profile Pic',
        rationale: 'Choose a profile pic',
        deniedMessage: 'Pic blocked',
        icon: Iconsax.user,
        color: Colors.blue,
      );

      // Register exact override
      AppPermissionManager.registerOverride(
        type: AppPermissionType.camera,
        location: 'profile',
        useCase: 'upload_avatar',
        meta: specialMeta,
      );

      // Verify exact lookup matches
      final exactResolved = AppPermissionManager.resolveMeta(
        AppPermissionType.camera,
        location: 'profile',
        useCase: 'upload_avatar',
      );
      expect(exactResolved.title, 'Profile Pic');

      // Verify exact fallback to default for non-matching useCase
      final nonMatchingResolved = AppPermissionManager.resolveMeta(
        AppPermissionType.camera,
        location: 'profile',
        useCase: 'other_usecase',
      );
      expect(nonMatchingResolved.title, 'Camera'); // defaults back

      // Register wildcard location override
      const locationWildcardMeta = AppPermissionMeta(
        title: 'Checkout Camera',
        rationale: 'Scan checkout code',
        deniedMessage: 'Checkout camera blocked',
        icon: Iconsax.scan,
        color: Colors.green,
      );
      AppPermissionManager.registerOverride(
        type: AppPermissionType.camera,
        location: 'checkout',
        useCase: '*',
        meta: locationWildcardMeta,
      );

      // Verify location-wide wildcard matches any useCase under 'checkout'
      final wildcardResolved = AppPermissionManager.resolveMeta(
        AppPermissionType.camera,
        location: 'checkout',
        useCase: 'anything_here',
      );
      expect(wildcardResolved.title, 'Checkout Camera');
    });

    test('global resolver callback', () {
      AppPermissionManager.resolver = (type, {location, useCase}) {
        if (location == 'dynamic_loc') {
          return const AppPermissionMeta(
            title: 'Dynamic Resolver Title',
            rationale: 'Dynamic Rationale',
            deniedMessage: 'Dynamic Denied',
            icon: Iconsax.info_circle,
            color: Colors.purple,
          );
        }
        return null;
      };

      final resolved = AppPermissionManager.resolveMeta(
        AppPermissionType.camera,
        location: 'dynamic_loc',
      );
      expect(resolved.title, 'Dynamic Resolver Title');

      // Reset resolver for other tests
      AppPermissionManager.resolver = null;
    });
  });
}
