import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/listing_item.dart';
import '../../providers/listings_provider.dart';
import '../../widgets/common/custom_button.dart';

class PostDealScreen extends ConsumerStatefulWidget {
  const PostDealScreen({super.key});

  @override
  ConsumerState<PostDealScreen> createState() => _PostDealScreenState();
}

class _PostDealScreenState extends ConsumerState<PostDealScreen> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController(text: 'Harare Central, ZW');
  final _sellerNameController = TextEditingController(text: 'Tendai Moyo');
  final _sellerPhoneController = TextEditingController(text: '+263774128990');
  final _tradeDetailsController = TextEditingController();
  final _conditionController = TextEditingController(text: 'Brand New / Pristine');

  String _selectedCategory = 'Phones';
  bool _isNegotiable = true;
  bool _allowsBarter = true;
  String _selectedMeetup = 'Harare CBD (Meikles / Joina City)';

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _pickedImages = [];

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _locationController.dispose();
    _sellerNameController.dispose();
    _sellerPhoneController.dispose();
    _tradeDetailsController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _pickedImages.addAll(images);
        });
      }
    } catch (_) {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _pickedImages.add(image);
        });
      }
    }
  }

  Future<void> _takePhotoWithCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _pickedImages.add(photo);
        });
      }
    } catch (_) {
      // Fallback
    }
  }

  Future<void> _submitListing() async {
    final title = _titleController.text.trim().isEmpty
        ? 'Featured Deal in Harare'
        : _titleController.text.trim();
    final price = double.tryParse(_priceController.text) ?? 280.0;

    const uuid = Uuid();
    final newId = 'deal_${uuid.v4().substring(0, 8)}';

    // Use locally picked photos (persisted with the SQLite row),
    // falling back to placeholder images when none were selected.
    final List<String> imagePaths = _pickedImages.map((img) => img.path).toList();
    final images = imagePaths.isNotEmpty
        ? imagePaths
        : [
            'https://images.unsplash.com/photo-1510557880182-3d4d3cba35a5?w=800&auto=format&fit=crop&q=80',
            'https://images.unsplash.com/photo-1592750475338-74b7b21085ab?w=800&auto=format&fit=crop&q=80',
          ];

    final newListing = ListingItem(
      id: newId,
      title: title,
      price: price,
      category: _selectedCategory,
      location: _locationController.text.trim().isEmpty ? 'Harare Central' : _locationController.text.trim(),
      distanceKm: 1.2,
      isVerified: true,
      isFeatured: true,
      isNegotiable: _isNegotiable,
      images: images,
      specs: {
        'Condition': _conditionController.text.trim(),
        'Location': _locationController.text.trim(),
        'Category': _selectedCategory,
        'Commission': '0% Free P2P',
      },
      description: _descController.text.trim().isEmpty
          ? 'Genuine item listed directly on MADEALS Zimbabwe. Available for local inspection in Harare. Cash or EcoCash accepted.'
          : _descController.text.trim(),
      allowsBarter: _allowsBarter,
      tradeDetails: _allowsBarter
          ? (_tradeDetailsController.text.trim().isNotEmpty
              ? _tradeDetailsController.text.trim()
              : 'Open to barter swap offers with electronics or vehicles + cash')
          : null,
      sellerName: _sellerNameController.text.trim().isNotEmpty ? _sellerNameController.text.trim() : 'Local Seller',
      sellerPhone: _sellerPhoneController.text.trim().isNotEmpty ? _sellerPhoneController.text.trim() : '+263771234567',
      sellerRating: 5.0,
      sellerReviewsCount: 12,
      timeListedAgo: 'Just now',
      meetupSpot: _selectedMeetup,
      tags: ['New', 'Direct Seller', 'Harare Deal'],
    );

    // Persist to SQLite (`madeals.db`) then surface at the top of the feed.
    await ref.read(listingsProvider.notifier).addListing(newListing);
    if (!mounted) return;
    context.go('/home');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.zimGreen,
        duration: Duration(seconds: 4),
        content: Text('🎉 Deal Listed Successfully! Your item is now live at the top of the feed with 0% commission.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 22),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Post a Deal (0% Fee)',
          style: AppTextStyles.titleLarge.copyWith(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Uploader & Image Picker Box
              _buildImagePickerBox(),
              const SizedBox(height: 20),
              // Title
              Text(
                'Listing Title',
                style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'e.g. iPhone 13 128GB Midnight or Toyota Axio',
                ),
              ),
              const SizedBox(height: 16),
              // Category
              Text(
                'Category',
                style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(),
                items: [
                  'Phones',
                  'Vehicles',
                  'Electronics',
                  'Solar & Power',
                  'Property',
                  'Jobs & Services',
                ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedCategory = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              // Price & Negotiable
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Price (USD \$)',
                          style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: '380',
                            prefixText: '\$ ',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Negotiable',
                          style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _isNegotiable ? 'Yes' : 'Fixed',
                                style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Switch(
                                value: _isNegotiable,
                                activeThumbColor: AppColors.primary,
                                onChanged: (val) => setState(() => _isNegotiable = val),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Condition
              Text(
                'Item Condition',
                style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _conditionController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Foreign Used / Like New (9/10) / Sealed',
                ),
              ),
              const SizedBox(height: 16),
              // Seller Phone Number for WhatsApp & Calls
              Text(
                'WhatsApp / Phone Number',
                style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _sellerPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '+263 77 123 4567',
                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 16),
              // Barter Toggle & details
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Accept Trade-in / Barter Swaps',
                  style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Allow buyers to offer item swaps + cash top-ups',
                  style: AppTextStyles.bodySmall,
                ),
                value: _allowsBarter,
                activeThumbColor: AppColors.zimGreen,
                onChanged: (val) => setState(() => _allowsBarter = val),
              ),
              if (_allowsBarter) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: _tradeDetailsController,
                  decoration: const InputDecoration(
                    labelText: 'What would you like to trade for?',
                    hintText: 'e.g. Open to trade with iPhone 11 Pro + \$50',
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Meetup Zone
              Text(
                'Safe Public Meetup Zone',
                style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedMeetup,
                decoration: const InputDecoration(),
                items: [
                  'Harare CBD (Meikles / Joina City)',
                  'Avondale Shopping Centre',
                  'Sam Levy’s Village (Borrowdale)',
                  'Westgate Shopping Mall',
                  'Eastgate Mall Area',
                ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedMeetup = val;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              // Description
              Text(
                'Description & Notes',
                style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Mention battery health, warranty, accessories, or reason for selling.',
                ),
              ),
              const SizedBox(height: 32),
              // Submit Button
              CustomButton(
                text: 'Publish Listing Live',
                leadingIcon: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
                onPressed: _submitListing,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickerBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (ctx) => Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                      title: const Text('Choose from Photo Gallery'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _pickImageFromGallery();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                      title: const Text('Take Photo with Camera'),
                      onTap: () {
                        Navigator.pop(ctx);
                        _takePhotoWithCamera();
                      },
                    ),
                  ],
                ),
              ),
            );
          },
          child: Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add_a_photo_outlined, color: AppColors.primary, size: 30),
                const SizedBox(height: 6),
                Text(
                  'Add Photos via Gallery or Camera',
                  style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Direct upload with image_picker',
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
        if (_pickedImages.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 75,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _pickedImages.length,
              itemBuilder: (context, index) {
                final img = _pickedImages[index];
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 75,
                  height: 75,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: kIsWeb
                            ? Image.network(img.path, fit: BoxFit.cover, width: 75, height: 75)
                            : Image.file(File(img.path), fit: BoxFit.cover, width: 75, height: 75),
                      ),
                      Positioned(
                        top: 2,
                        right: 2,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _pickedImages.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
