import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:qwickyprofessional/widgets/colors.dart';
import 'dart:convert';

class RatingPart extends StatefulWidget {
  final int professionalId;

  const RatingPart({super.key, required this.professionalId});

  @override
  State<RatingPart> createState() => _RatingPartState();
}

class _RatingPartState extends State<RatingPart> {
  double averageRating = 0;
  int totalReviews = 0;
  List<dynamic> reviews = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchReviews();
  }

  Future<void> _fetchReviews() async {
    try {
      final String apiUrl = dotenv.env['BACK_END_API'] ?? 'http://192.168.1.37:3000/api';
      final response = await http.get(
        Uri.parse('$apiUrl/user-review-prof/${widget.professionalId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          averageRating = (data['averageRating'] ?? 0).toDouble();
          totalReviews = data['totalReviews'] ?? 0;
          reviews = data['reviews'] ?? [];
          isLoading = false;
        });
      } else {
        print('Failed to fetch reviews: ${response.statusCode}');
        setState(() {
          averageRating = 0;
          totalReviews = 0;
          reviews = [];
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching reviews: $e');
      setState(() {
        averageRating = 0;
        totalReviews = 0;
        reviews = [];
        isLoading = false;
      });
    }
  }

  Widget _buildStarRating(double rating) {
    return Row(
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Colors.yellow, size: 20);
        } else if (index < rating && rating - index >= 0.5) {
          return const Icon(Icons.star_half, color: Colors.yellow, size: 20);
        } else {
          return const Icon(Icons.star_border, color: Colors.grey, size: 20);
        }
      }),
    );
  }

  void _showReviewsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('All Reviews'),
          content: Container(
            width: double.maxFinite,
            height: MediaQuery.of(context).size.height * 0.6,
            child: reviews.isEmpty
                ? const Center(child: Text('No ratings available'))
                : ListView.builder(
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review['username'] ?? 'Anonymous',
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.height * 0.022,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    review['rating'].toStringAsFixed(1),
                                    style: TextStyle(
                                      fontSize: MediaQuery.of(context).size.height * 0.020,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildStarRating(review['rating'].toDouble()),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                review['review_text'] ?? 'No comment',
                                style: TextStyle(
                                  fontSize: MediaQuery.of(context).size.height * 0.018,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Card(
      elevation: 4,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        width: width * 0.9,
        padding: EdgeInsets.only(left:height * 0.02, right:height * 0.02),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Reviews',
                        style: TextStyle(
                          fontSize: height * 0.021,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      TextButton(
                        onPressed: _showReviewsDialog,
                        child: Text(
                          'View All',
                          style: TextStyle(
                            fontSize: height * 0.018,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  totalReviews == 0
                      ? Text(
                          'Awaiting first rating',
                          style: TextStyle(
                            fontSize: height * 0.020,
                            color: Colors.grey,
                          ),
                        )
                      : Row(
                          children: [
                            Text(
                              averageRating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: height * 0.035,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStarRating(averageRating),
                            const SizedBox(width: 8),
                            Text(
                              '($totalReviews Reviews)',
                              style: TextStyle(
                                fontSize: height * 0.020,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                ],
              ),
      ),
    );
  }
}
