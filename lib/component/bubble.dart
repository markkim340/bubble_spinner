import 'package:bubble_spinner/main.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class BubbleComponent extends CircleComponent {
  static const double bubbleRadius = 20;
  bool shouldRemove = false;
  Vector2? velocity;

  BubbleComponent({required Vector2 position, required Color color})
      : super(
          position: position,
          radius: bubbleRadius,
          paint: Paint()..color = color,
        );

  void shoot(Vector2 direction) {
    velocity = direction * 600;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (velocity != null) {
      position += velocity! * dt;

      // Check for collision with screen boundaries and bounce
      final gameRef = findGame()! as BubbleSpinnerGame;

      if (position.x <= 0 || position.x + 40 >= gameRef.size.x) {
        velocity!.x = -velocity!.x; // Reverse the x-direction velocity
      }
      if (position.y <= 0 || position.y + 40 >= gameRef.size.y) {
        velocity!.y = -velocity!.y; // Reverse the y-direction velocity
      }

      // Check for collision with other bubbles
      for (final otherBubble in gameRef.bubbles) {
        if (otherBubble != this &&
            position.distanceTo(otherBubble.position) < radius * 2) {
          final overlap =
              radius * 2 - position.distanceTo(otherBubble.position);
          final adjustment =
              (position - otherBubble.position).normalized() * overlap;
          position += adjustment;

          // Set velocity to null and add to cluster
          velocity = null;
          if (!gameRef.bubbles.contains(this)) {
            gameRef.bubbles.add(this); // 클러스터에 추가
          }
          _checkForMatches(gameRef);
          break;
        }
      }

      // Remove if out of bounds
      if (position.y < 0 || position.x < 0 || position.x > gameRef.size.x) {
        shouldRemove = true;
      }
    }
  }

  void _checkForMatches(BubbleSpinnerGame game) {
    final matches = [this];
    _findMatches(matches, game.bubbles);

    if (matches.length >= 3) {
      for (final bubble in matches) {
        bubble.shouldRemove = true;
        game.remove(bubble); // 게임에서 제거
      }
    }
  }

  void _findMatches(
      List<BubbleComponent> matches, List<BubbleComponent> allBubbles) {
    for (final bubble in allBubbles) {
      if (!matches.contains(bubble) &&
          bubble.paint.color == paint.color &&
          position.distanceTo(bubble.position) < radius * 2.1) {
        matches.add(bubble);
        bubble._findMatches(matches, allBubbles);
      }
    }
  }
}
