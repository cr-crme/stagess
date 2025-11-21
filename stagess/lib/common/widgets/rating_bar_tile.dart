import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class RatingBarTile extends StatelessWidget {
  const RatingBarTile({
    super.key,
    required this.title,
    required this.rating,
  });

  final String title;
  final double rating;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: rating >= 0 && rating <= 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          RatingBar(
            initialRating: rating,
            onRatingUpdate: (value) {},
            allowHalfRating: true,
            ignoreGestures: true,
            ratingWidget: RatingWidget(
              full: Icon(
                Icons.star,
                color: Theme.of(context).colorScheme.secondary,
              ),
              half: Icon(
                Icons.star_half,
                color: Theme.of(context).colorScheme.secondary,
              ),
              empty: Icon(
                Icons.star_border,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
