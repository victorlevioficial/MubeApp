# Edit Profile Migration Guide

## Overview

Guide for updating the edit profile screens to use the same modern UI as the redesigned onboarding flow.

---

## Current Edit Profile Structure

The edit profile screen (`lib/src/features/profile/presentation/edit_profile_screen.dart`) currently uses:
- Tabbed interface (Info & Gallery)
- Type-specific form fields
- Separate widgets for each user type

---

## Recommended Updates

### 1. Use New Components

#### For Category Selection (Professional)
Replace the current category selection UI with:

```dart
import '../onboarding/presentation/steps/professional_category_step.dart';

// In the professional form fields widget:
ProfessionalCategoryStep(
  selectedCategories: state.selectedCategories,
  onCategoriesChanged: (categories) {
    ref.read(editProfileControllerProvider(userId).notifier)
        .updateCategories(categories);
  },
  onNext: () {}, // Not needed in edit mode
  onBack: () {}, // Not needed in edit mode
)
```

#### For Multi-Select Fields
Replace all multi-select implementations with `EnhancedMultiSelectModal`:

```dart
// Genres Selection
_buildSelectionSection(
  title: 'Gêneros Musicais *',
  subtitle: _selectedGenres.isEmpty
      ? 'Selecione os estilos que você domina'
      : '${_selectedGenres.length} gênero${_selectedGenres.length > 1 ? 's' : ''} selecionado${_selectedGenres.length > 1 ? 's' : ''}',
  buttonText: _selectedGenres.isEmpty
      ? 'Selecionar Gêneros'
      : 'Editar Gêneros',
  selectedItems: _selectedGenres,
  onTap: () async {
    final result = await EnhancedMultiSelectModal.show<String>(
      context: context,
      title: 'Gêneros Musicais',
      subtitle: 'Selecione os estilos que você toca/canta',
      items: genres,
      selectedItems: _selectedGenres,
      searchHint: 'Buscar gênero...',
    );
    if (result != null) {
      setState(() => _selectedGenres = result);
      controller.updateGenres(result);
    }
  },
)
```

### 2. Update Professional Form Fields Widget

**File**: `lib/src/features/profile/presentation/edit_profile/widgets/forms/professional_form_fields.dart`

#### Current Issues
- Uses `AppSelectionModal` (old style)
- Separate sections for categories, instruments, genres
- Less intuitive UI

#### Recommended Changes

```dart
import '../../../../../../design_system/components/inputs/enhanced_multi_select_modal.dart';

class ProfessionalFormFields extends ConsumerWidget {
  // ... existing code ...

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editProfileControllerProvider(userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Categories Section (Use full-width cards)
        Text(
          'Categorias',
          style: AppTypography.titleMedium,
        ),
        const SizedBox(height: AppSpacing.s12),
        
        // Use the same category cards as onboarding
        ...professionalCategories.map((cat) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.s12),
            child: FullWidthSelectionCard(
              icon: cat['icon'],
              title: cat['label'],
              description: _getCategoryDescription(cat['id']),
              isSelected: state.selectedCategories.contains(cat['id']),
              onTap: () {
                ref.read(editProfileControllerProvider(userId).notifier)
                    .toggleCategory(cat['id']);
              },
            ),
          );
        }).toList(),

        const SizedBox(height: AppSpacing.s24),

        // Genres Selection (Use enhanced modal)
        _buildEnhancedSelectionSection(
          context: context,
          ref: ref,
          userId: userId,
          title: 'Gêneros Musicais *',
          currentItems: state.selectedGenres,
          allItems: genres,
          modalTitle: 'Gêneros Musicais',
          modalSubtitle: 'Selecione os estilos que você domina',
          searchHint: 'Buscar gênero...',
          onUpdate: (items) {
            ref.read(editProfileControllerProvider(userId).notifier)
                .updateGenres(items);
          },
        ),

        // Instruments (if instrumentalist)
        if (state.selectedCategories.contains('instrumentalist')) ...[
          const SizedBox(height: AppSpacing.s24),
          _buildEnhancedSelectionSection(
            context: context,
            ref: ref,
            userId: userId,
            title: 'Instrumentos *',
            currentItems: state.selectedInstruments,
            allItems: instruments,
            modalTitle: 'Instrumentos',
            modalSubtitle: 'Selecione os instrumentos que você domina',
            searchHint: 'Buscar instrumento...',
            onUpdate: (items) {
              ref.read(editProfileControllerProvider(userId).notifier)
                  .updateInstruments(items);
            },
          ),
        ],

        // Crew Roles (if crew)
        if (state.selectedCategories.contains('crew')) ...[
          const SizedBox(height: AppSpacing.s24),
          _buildEnhancedSelectionSection(
            context: context,
            ref: ref,
            userId: userId,
            title: 'Funções Técnicas *',
            currentItems: state.selectedRoles,
            allItems: crewRoles,
            modalTitle: 'Funções Técnicas',
            modalSubtitle: 'Selecione suas áreas de atuação',
            searchHint: 'Buscar função...',
            onUpdate: (items) {
              ref.read(editProfileControllerProvider(userId).notifier)
                  .updateRoles(items);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildEnhancedSelectionSection({
    required BuildContext context,
    required WidgetRef ref,
    required String userId,
    required String title,
    required List<String> currentItems,
    required List<String> allItems,
    required String modalTitle,
    required String modalSubtitle,
    required String searchHint,
    required ValueChanged<List<String>> onUpdate,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.all16,
        border: Border.all(
          color: currentItems.isEmpty ? AppColors.error : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              color: currentItems.isEmpty ? AppColors.error : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            currentItems.isEmpty
                ? 'Nenhum item selecionado'
                : '${currentItems.length} item${currentItems.length > 1 ? 's' : ''} selecionado${currentItems.length > 1 ? 's' : ''}',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (currentItems.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s12),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: currentItems.take(3).map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s10,
                    vertical: AppSpacing.s6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceHighlight,
                    borderRadius: AppRadius.all8,
                  ),
                  child: Text(
                    item,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              }).toList()
                ..add(
                  if (currentItems.length > 3)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s10,
                        vertical: AppSpacing.s6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: AppRadius.all8,
                      ),
                      child: Text(
                        '+${currentItems.length - 3}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ),
            ),
          ],
          const SizedBox(height: AppSpacing.s16),
          SizedBox(
            width: double.infinity,
            child: AppButton.outline(
              text: currentItems.isEmpty
                  ? 'Selecionar'
                  : 'Editar Seleção',
              onPressed: () async {
                final result = await EnhancedMultiSelectModal.show<String>(
                  context: context,
                  title: modalTitle,
                  subtitle: modalSubtitle,
                  items: allItems,
                  selectedItems: currentItems,
                  searchHint: searchHint,
                );
                if (result != null) {
                  onUpdate(result);
                }
              },
              icon: Icon(
                currentItems.isEmpty ? Icons.add : Icons.edit_outlined,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getCategoryDescription(String id) {
    switch (id) {
      case 'singer':
        return 'Vocalista principal, coral, backing vocal';
      case 'instrumentalist':
        return 'Guitarra, bateria, piano, baixo, cordas, sopros';
      case 'crew':
        return 'Técnico de som, luz, roadie, produtor';
      case 'dj':
        return 'DJ de festa, club, eventos, produtor musical';
      default:
        return '';
    }
  }
}
```

### 3. Update Band Form Fields Widget

**File**: `lib/src/features/profile/presentation/edit_profile/widgets/forms/band_form_fields.dart`

```dart
// Replace genre selection with enhanced modal
_buildEnhancedSelectionSection(
  context: context,
  ref: ref,
  userId: userId,
  title: 'Gêneros Musicais *',
  currentItems: state.bandGenres,
  allItems: genres,
  modalTitle: 'Gêneros Musicais',
  modalSubtitle: 'Selecione os estilos da banda',
  searchHint: 'Buscar gênero...',
  onUpdate: (items) {
    ref.read(editProfileControllerProvider(userId).notifier)
        .updateBandGenres(items);
  },
)
```

### 4. Update Studio Form Fields Widget

**File**: `lib/src/features/profile/presentation/edit_profile/widgets/forms/studio_form_fields.dart`

```dart
// Replace service selection with enhanced modal
_buildEnhancedSelectionSection(
  context: context,
  ref: ref,
  userId: userId,
  title: 'Serviços Oferecidos *',
  currentItems: state.selectedServices,
  allItems: studioServices,
  modalTitle: 'Serviços do Estúdio',
  modalSubtitle: 'Selecione os serviços que você oferece',
  searchHint: 'Buscar serviço...',
  onUpdate: (items) {
    ref.read(editProfileControllerProvider(userId).notifier)
        .updateServices(items);
  },
)
```

---

## Visual Improvements

### Before
- Grid-based category cards
- Simple list modals
- Less visual feedback
- Basic selection UI

### After
- Full-width category cards with descriptions
- Enhanced modals with search
- Rich visual feedback with chips
- Professional, modern UI

---

## Step-by-Step Migration

1. **Import New Components**
   ```dart
   import '../../../../design_system/components/inputs/enhanced_multi_select_modal.dart';
   import '../../../../design_system/components/patterns/full_width_selection_card.dart';
   ```

2. **Replace Category Selection** (Professional only)
   - Use `FullWidthSelectionCard` for each category
   - Keep multi-select functionality

3. **Replace All Multi-Select Modals**
   - Genres → `EnhancedMultiSelectModal`
   - Instruments → `EnhancedMultiSelectModal`
   - Roles → `EnhancedMultiSelectModal`
   - Services → `EnhancedMultiSelectModal`

4. **Update Visual Containers**
   - Use section containers like onboarding
   - Show selected items as chips
   - Add selection count

5. **Test Each User Type**
   - Professional
   - Band
   - Studio
   - Contractor

---

## Key Principles

1. **Consistency**: Use the same components as onboarding
2. **Reusability**: Extract common patterns into helper methods
3. **Visual Feedback**: Show selection state clearly
4. **Search**: Enable search for large lists
5. **Validation**: Keep existing validation logic

---

## Expected Result

The edit profile screens will have:
- ✅ Same modern UI as onboarding
- ✅ Better visual hierarchy
- ✅ More intuitive selection process
- ✅ Consistent design language
- ✅ Improved user experience

---

## Timeline

Estimated time for migration:
- Professional form: 2-3 hours
- Band form: 1 hour
- Studio form: 1 hour
- Contractor form: Already minimal, no changes needed
- Testing: 1-2 hours

**Total**: ~5-7 hours for complete edit profile modernization
