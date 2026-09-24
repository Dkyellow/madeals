import 'dart:convert';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../repositories/listing_repository.dart';
import '../../models/listing_item.dart';

/// Local SQLite database (`madeals.db`) — single source of truth for
/// listings: instant offline search, category filtering and caching.
class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();

  static const String dbName = 'madeals.db';
  static const int dbVersion = 1;
  static const String tableListings = 'listings';

  Database? _db;

  Future<Database> get database async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, dbName),
      version: dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $tableListings (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            price REAL NOT NULL,
            category TEXT NOT NULL,
            location TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            description TEXT,
            image_url TEXT,
            seller_phone TEXT,
            is_verified INTEGER NOT NULL DEFAULT 0,
            is_featured INTEGER NOT NULL DEFAULT 0,
            status TEXT NOT NULL DEFAULT 'active',
            created_at INTEGER NOT NULL,
            distance_km REAL NOT NULL DEFAULT 0,
            is_negotiable INTEGER NOT NULL DEFAULT 1,
            allows_barter INTEGER NOT NULL DEFAULT 0,
            trade_details TEXT,
            seller_name TEXT,
            seller_rating REAL DEFAULT 4.9,
            seller_reviews INTEGER DEFAULT 0,
            seller_avatar TEXT,
            time_listed TEXT,
            meetup_spot TEXT,
            specs TEXT,
            tags TEXT,
            is_bookmarked INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_listings_status ON $tableListings(status)',
        );
        await db.execute(
          'CREATE INDEX idx_listings_category ON $tableListings(category)',
        );
        await db.execute(
          'CREATE INDEX idx_listings_location ON $tableListings(location)',
        );
      },
      onOpen: (db) async {
        await seedIfEmpty(db);
      },
    );
  }

  /// Seeds the catalog from [ListingRepository] on first launch.
  Future<void> seedIfEmpty(Database db) async {
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM $tableListings'),
    );
    if ((count ?? 0) == 0) {
      final batch = db.batch();
      for (final item in ListingRepository.getInitialListings()) {
        batch.insert(
          tableListings,
          _toMap(item),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    }
  }

  /// Opens (and seeds) the DB, then returns all active listings.
  Future<List<ListingItem>> getListings({
    String? query,
    String? category,
    double? maxPrice,
    bool verifiedOnly = false,
    String status = 'active',
    bool activeOnly = true,
  }) async {
    final db = await database;

    final where = <String>[];
    final args = <Object?>[];

    if (activeOnly) {
      where.add('status = ?');
      args.add(status);
    }
    if (category != null && category.isNotEmpty && category != 'All') {
      where.add('LOWER(category) = ?');
      args.add(category.toLowerCase());
    }
    if (maxPrice != null) {
      where.add('price <= ?');
      args.add(maxPrice);
    }
    if (verifiedOnly) {
      where.add('is_verified = 1');
    }
    if (query != null && query.trim().isNotEmpty) {
      where.add(
        '(LOWER(title) LIKE ? OR LOWER(description) LIKE ? OR LOWER(location) LIKE ? OR LOWER(tags) LIKE ?)',
      );
      final like = '%${query.trim().toLowerCase()}%';
      args.addAll([like, like, like, like]);
    }

    final rows = await db.query(
      tableListings,
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: where.isEmpty ? null : args,
      orderBy: 'is_featured DESC, created_at DESC',
    );
    return rows.map(fromMap).toList();
  }

  Future<void> insertListing(ListingItem item) async {
    final db = await database;
    await db.insert(
      tableListings,
      _toMap(item),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateBookmark(String id, bool isBookmarked) async {
    final db = await database;
    await db.update(
      tableListings,
      {'is_bookmarked': isBookmarked ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateStatus(String id, String status) async {
    final db = await database;
    await db.update(
      tableListings,
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Map<String, Object?> _toMap(ListingItem item) {
    return {
      'id': item.id,
      'title': item.title,
      'price': item.price,
      'category': item.category,
      'location': item.location,
      'latitude': item.latitude,
      'longitude': item.longitude,
      'description': item.description,
      'image_url': jsonEncode(item.images),
      'seller_phone': item.sellerPhone,
      'is_verified': item.isVerified ? 1 : 0,
      'is_featured': item.isFeatured ? 1 : 0,
      'status': 'active',
      'created_at': DateTime.now().millisecondsSinceEpoch,
      'distance_km': item.distanceKm,
      'is_negotiable': item.isNegotiable ? 1 : 0,
      'allows_barter': item.allowsBarter ? 1 : 0,
      'trade_details': item.tradeDetails,
      'seller_name': item.sellerName,
      'seller_rating': item.sellerRating,
      'seller_reviews': item.sellerReviewsCount,
      'seller_avatar': item.sellerAvatar,
      'time_listed': item.timeListedAgo,
      'meetup_spot': item.meetupSpot,
      'specs': jsonEncode(item.specs),
      'tags': jsonEncode(item.tags),
      'is_bookmarked': item.isBookmarked ? 1 : 0,
    };
  }

  static ListingItem fromMap(Map<String, Object?> row) {
    return ListingItem(
      id: row['id'] as String,
      title: row['title'] as String,
      price: (row['price'] as num).toDouble(),
      category: row['category'] as String,
      location: row['location'] as String,
      latitude: (row['latitude'] as num?)?.toDouble() ?? -17.8252,
      longitude: (row['longitude'] as num?)?.toDouble() ?? 31.0335,
      description: (row['description'] as String?) ?? '',
      images: _decodeStringList(row['image_url'] as String?),
      sellerPhone: (row['seller_phone'] as String?) ?? '',
      isVerified: (row['is_verified'] as int? ?? 0) == 1,
      isFeatured: (row['is_featured'] as int? ?? 0) == 1,
      distanceKm: (row['distance_km'] as num?)?.toDouble() ?? 0,
      isNegotiable: (row['is_negotiable'] as int? ?? 1) == 1,
      allowsBarter: (row['allows_barter'] as int? ?? 0) == 1,
      tradeDetails: row['trade_details'] as String?,
      sellerName: (row['seller_name'] as String?) ?? 'Local Seller',
      sellerRating: (row['seller_rating'] as num?)?.toDouble() ?? 4.9,
      sellerReviewsCount: (row['seller_reviews'] as int?) ?? 0,
      sellerAvatar: row['seller_avatar'] as String?,
      timeListedAgo: (row['time_listed'] as String?) ?? 'Just now',
      meetupSpot: (row['meetup_spot'] as String?) ?? 'Harare CBD (Safe Daylight Zone)',
      specs: _decodeStringMap(row['specs'] as String?),
      tags: _decodeStringList(row['tags'] as String?),
      isBookmarked: (row['is_bookmarked'] as int? ?? 0) == 1,
    );
  }

  static List<String> _decodeStringList(String? raw) {
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.map((e) => e.toString()).toList();
    } catch (_) {}
    return [raw];
  }

  static Map<String, String> _decodeStringMap(String? raw) {
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    } catch (_) {}
    return {};
  }
}
