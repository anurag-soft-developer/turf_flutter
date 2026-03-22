import '../models/turf_model.dart';
import 'api_service.dart';

class TurfService {
  static final TurfService _instance = TurfService._internal();
  factory TurfService() => _instance;
  TurfService._internal();

  final ApiService _apiService = ApiService();

  List<TurfModel> get _dummyTurfs => [
    TurfModel(
      id: '1',
      postedBy: 'user1',
      name: 'Green Valley Sports Complex',
      description:
          'Premium football turf with modern amenities and excellent lighting. Perfect for professional matches and tournaments.',
      location: LocationModel(
        address: 'Sector 18, Noida, Uttar Pradesh',
        coordinates: CoordinatesModel(lat: 28.5704, lng: 77.3269),
      ),
      images: [
        'https://images.unsplash.com/photo-1551698618-1dfe5d97d256?w=800&h=600',
        'https://images.unsplash.com/photo-1575361204480-aadea25e6e68?w=800&h=600',
        'https://images.unsplash.com/photo-1589487391730-58f20eb2c308?w=800&h=600',
      ],
      amenities: [
        'Parking',
        'Changing Room',
        'Washrooms',
        'Water Facility',
        'Lighting',
      ],
      dimensions: DimensionsModel(length: 100, width: 60, unit: 'meters'),
      sportType: ['Football', 'Cricket'],
      pricing: PricingModel(basePricePerHour: 1500, weekendSurge: 0.3),
      operatingHours: OperatingHoursModel(open: '06:00', close: '23:00'),
      isAvailable: true,
      slotBufferMins: 15,
      averageRating: 4.8,
      totalReviews: 142,
      createdAt: '2024-01-15T10:00:00Z',
      updatedAt: '2024-03-15T14:30:00Z',
    ),
    TurfModel(
      id: '2',
      postedBy: 'user2',
      name: 'Champions Basketball Court',
      description:
          'Indoor basketball court with professional-grade flooring and excellent acoustics.',
      location: LocationModel(
        address: 'Connaught Place, New Delhi',
        coordinates: CoordinatesModel(lat: 28.6315, lng: 77.2167),
      ),
      images: [
        'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=800&h=600',
        'https://images.unsplash.com/photo-1574623452334-1e0ac2b3ccb4?w=800&h=600',
      ],
      amenities: [
        'Parking',
        'Changing Room',
        'Washrooms',
        'First Aid',
        'Equipment Rental',
      ],
      dimensions: DimensionsModel(length: 28, width: 15, unit: 'meters'),
      sportType: ['Basketball'],
      pricing: PricingModel(basePricePerHour: 800, weekendSurge: 0.25),
      operatingHours: OperatingHoursModel(open: '07:00', close: '22:00'),
      isAvailable: true,
      slotBufferMins: 10,
      averageRating: 4.5,
      totalReviews: 89,
      createdAt: '2024-02-01T09:00:00Z',
      updatedAt: '2024-03-10T16:20:00Z',
    ),
    TurfModel(
      id: '3',
      postedBy: 'user3',
      name: 'Elite Cricket Ground',
      description:
          'Full-size cricket ground with natural grass pitch and modern facilities.',
      location: LocationModel(
        address: 'Gurgaon Sports Complex, Haryana',
        coordinates: CoordinatesModel(lat: 28.4595, lng: 77.0266),
      ),
      images: [
        'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=800&h=600',
        'https://images.unsplash.com/photo-1540979388789-6cee28a1cdc9?w=800&h=600',
        'https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=800&h=600',
      ],
      amenities: [
        'Parking',
        'Changing Room',
        'Food Court',
        'First Aid',
        'Equipment Rental',
      ],
      dimensions: DimensionsModel(length: 150, width: 150, unit: 'meters'),
      sportType: ['Cricket'],
      pricing: PricingModel(basePricePerHour: 2500, weekendSurge: 0.4),
      operatingHours: OperatingHoursModel(open: '05:00', close: '20:00'),
      isAvailable: true,
      slotBufferMins: 30,
      averageRating: 4.9,
      totalReviews: 203,
      createdAt: '2024-01-01T08:00:00Z',
      updatedAt: '2024-03-20T12:15:00Z',
    ),
    TurfModel(
      id: '4',
      postedBy: 'user4',
      name: 'Urban Badminton Center',
      description:
          'Modern badminton center with 8 courts and air conditioning.',
      location: LocationModel(
        address: 'Koramangala, Bangalore, Karnataka',
        coordinates: CoordinatesModel(lat: 12.9279, lng: 77.6271),
      ),
      images: [
        'https://images.unsplash.com/photo-1544717684-4f5579934dd8?w=800&h=600',
      ],
      amenities: ['Parking', 'Changing Room', 'Washrooms', 'Water Facility'],
      dimensions: DimensionsModel(length: 13.4, width: 6.1, unit: 'meters'),
      sportType: ['Badminton'],
      pricing: PricingModel(basePricePerHour: 600, weekendSurge: 0.2),
      operatingHours: OperatingHoursModel(open: '06:30', close: '23:30'),
      isAvailable: true,
      slotBufferMins: 5,
      averageRating: 4.3,
      totalReviews: 67,
      createdAt: '2024-02-15T11:00:00Z',
      updatedAt: '2024-03-18T09:45:00Z',
    ),
    TurfModel(
      id: '5',
      postedBy: 'user5',
      name: 'Tennis Academy Pro Courts',
      description:
          'Professional tennis courts with clay and hard court surfaces.',
      location: LocationModel(
        address: 'Bandra West, Mumbai, Maharashtra',
        coordinates: CoordinatesModel(lat: 19.0596, lng: 72.8295),
      ),
      images: [
        'https://images.unsplash.com/photo-1549476464-37392f717541?w=800&h=600',
        'https://images.unsplash.com/photo-1622163642998-1ea32b0bbc06?w=800&h=600',
      ],
      amenities: [
        'Parking',
        'Changing Room',
        'First Aid',
        'Equipment Rental',
        'Food Court',
      ],
      dimensions: DimensionsModel(length: 23.77, width: 10.97, unit: 'meters'),
      sportType: ['Tennis'],
      pricing: PricingModel(basePricePerHour: 1200, weekendSurge: 0.35),
      operatingHours: OperatingHoursModel(open: '06:00', close: '22:30'),
      isAvailable: true,
      slotBufferMins: 15,
      averageRating: 4.7,
      totalReviews: 156,
      createdAt: '2024-01-20T07:30:00Z',
      updatedAt: '2024-03-12T13:20:00Z',
    ),
  ];

  Future<TurfModel?> createTurf(CreateTurfRequest request) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/turf',
      data: request.toJson(),
    );

    if (response == null) {
      return null;
    }

    final turf = TurfModel.fromJson(response);
    return turf;
  }

  Future<List<TurfModel>?> searchTurfs({
    String? globalSearchText,
    List<String>? sportTypes,
    List<String>? amenities,
    LocationModel? location,
    double? radius,
    double? minPrice,
    double? maxPrice,
    bool? includeWeekendSurge,
    bool? isAvailable,
    double? minRating,
    String? operatingTime,
    int page = 1,
    int limit = 10,
    String? sort,
  }) async {
    return _dummyTurfs;
    final Map<String, dynamic> queryParams = {};

    if (globalSearchText?.isNotEmpty == true) {
      queryParams['globalSearchText'] = globalSearchText;
    }
    if (sportTypes?.isNotEmpty == true) {
      queryParams['sportTypes'] = sportTypes!.join(',');
    }
    if (amenities?.isNotEmpty == true) {
      queryParams['amenities'] = amenities!.join(',');
    }
    if (location != null) {
      if (location.coordinates.lat != null) {
        queryParams['location[lat]'] = location.coordinates.lat.toString();
      }
      if (location.coordinates.lng != null) {
        queryParams['location[lng]'] = location.coordinates.lng.toString();
      }
      if (radius != null) {
        queryParams['location[radius]'] = radius.toString();
      }
    }
    if (minPrice != null) {
      queryParams['pricing[minPrice]'] = minPrice.toString();
    }
    if (maxPrice != null) {
      queryParams['pricing[maxPrice]'] = maxPrice.toString();
    }
    if (includeWeekendSurge != null) {
      queryParams['pricing[includeWeekendSurge]'] = includeWeekendSurge
          .toString();
    }
    if (isAvailable != null) {
      queryParams['isAvailable'] = isAvailable.toString();
    }
    if (minRating != null) {
      queryParams['minRating'] = minRating.toString();
    }
    if (operatingTime?.isNotEmpty == true) {
      queryParams['operatingTime'] = operatingTime;
    }
    if (sort?.isNotEmpty == true) {
      queryParams['sort'] = sort;
    }

    queryParams['page'] = page.toString();
    queryParams['limit'] = limit.toString();

    final response = await _apiService.get<List<dynamic>>(
      '/turf',
      queryParameters: queryParams,
    );

    if (response == null) {
      return [];
    }

    final turfs = response
        .map((turfJson) => TurfModel.fromJson(turfJson as Map<String, dynamic>))
        .toList();

    return turfs;
  }

  Future<Map<String, dynamic>?> getTurfStats() async {
    final response = await _apiService.get<Map<String, dynamic>>('/turf/stats');

    return response;
  }

  Future<TurfModel?> getTurfById(String turfId) async {
    return _dummyTurfs[0];
    final response = await _apiService.get<Map<String, dynamic>>(
      '/turf/$turfId',
    );

    if (response == null) {
      return null;
    }

    final turf = TurfModel.fromJson(response);
    return turf;
  }

  Future<TurfModel?> updateTurf(
    String turfId,
    UpdateTurfRequest request,
  ) async {
    final response = await _apiService.patch<Map<String, dynamic>>(
      '/turf/$turfId',
      data: request.toJson(),
    );

    if (response == null) {
      return null;
    }

    final updatedTurf = TurfModel.fromJson(response);
    return updatedTurf;
  }

  Future<bool> deleteTurf(String turfId) async {
    final response = await _apiService.delete('/turf/$turfId');
    return response != null;
  }

  /// Get featured/recommended turfs
  Future<List<TurfModel>?> getFeaturedTurfs({int limit = 5}) async {
    return await searchTurfs(
      sort: 'averageRating',
      limit: limit,
      minRating: 4.0,
    );
  }
}
