import 'dart:math';

import 'package:bubble_spinner/component/bubble.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      body: Center(
        child: Container(
          child: GameWidget(game: BubbleSpinnerGame()),
        ),
      ),
    ),
  ));
}

class BubbleSpinnerGame extends FlameGame with TapDetector {
  late List<BubbleComponent> bubbles;
  late Vector2 shooterPosition;
  late Vector2 shooterDirection;
  late BubbleComponent nextBubble;
  final Random random = Random();

  bool isGameOver = false; // 게임 종료 상태 추가

  double rotationAngle = 0.0; // 클러스터 회전 각도

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    shooterPosition = Vector2(size.x / 2, size.y - 50);
    shooterDirection = Vector2(0, -1);

    bubbles = [];
    _initializeBubbles();
    _createNextBubble();
  }

  void _initializeBubbles() {
    final center = Vector2(size.x / 2, size.y / 2);
    for (int i = 0; i < 20; i++) {
      final angle = i * 0.30;
      final position = center + Vector2(cos(angle), sin(angle)) * 100;
      final bubble =
          BubbleComponent(position: position, color: _getRandomColor());
      add(bubble);
      bubbles.add(bubble);
    }
  }

  void _createNextBubble() {
    nextBubble =
        BubbleComponent(position: shooterPosition, color: _getRandomColor());
    add(nextBubble);
  }

  Color _getRandomColor() {
    return [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
    ][random.nextInt(5)];
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (isGameOver) return; // 게임 종료 시 업데이트 중지

    // 게임 오버 조건 확인: 클러스터의 버블이 경계선에 닿았는지 확인
    for (final bubble in bubbles) {
      if (bubble.position.x <= 0 ||
          bubble.position.x + bubble.radius * 2 >= size.x ||
          bubble.position.y <= 0 ||
          bubble.position.y + bubble.radius * 2 >= size.y) {
        endGame();
        break;
      }
    }

    bubbles.removeWhere((bubble) => bubble.shouldRemove);
    _rotateBubbles(dt); // 클러스터 회전
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = Colors.white,
    );

    super.render(canvas);

    // 경계선을 빨간색으로 그리기
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      paint,
    );

    // Draw shooter line
    if (!isGameOver) {
      canvas.drawLine(
        shooterPosition.toOffset(),
        (shooterPosition + shooterDirection * 50).toOffset(),
        Paint()
          ..color = Colors.black
          ..strokeWidth = 2,
      );
    }
  }

  @override
  void onTapUp(TapUpInfo info) {
    shooterDirection =
        (info.eventPosition.global - shooterPosition).normalized();
    _shootBubble();
  }

  void _shootBubble() {
    nextBubble.shoot(shooterDirection);
    _createNextBubble();
  }

  void _rotateBubbles(double dt) {
    rotationAngle += dt; // 회전 각도 증가
    final center = Vector2(size.x / 2, size.y / 2);
    for (final bubble in bubbles) {
      final direction = bubble.position - center;
      final distance = direction.length;
      final angle = atan2(direction.y, direction.x) + dt; // 각도 증가
      bubble.position = center + Vector2(cos(angle), sin(angle)) * distance;
    }
  }

  void endGame() {
    isGameOver = true;
    pauseEngine();
    _showGameOverDialog();
  }

  void _showGameOverDialog() {
    // 게임 종료 팝업 표시 로직 추가
    showDialog(
      context: buildContext!,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Game Over'),
          content: Text('You have hit the boundary!'),
          actions: <Widget>[
            TextButton(
              child: Text('Restart'),
              onPressed: () {
                Navigator.of(context).pop();
                _restartGame();
              },
            ),
          ],
        );
      },
    );
  }

  void _restartGame() {
    // 게임 재시작 로직 추가
    isGameOver = false;
    bubbles.clear();
    children.whereType<BubbleComponent>().forEach((bubble) {
      remove(bubble);
    });

    _initializeBubbles();
    _createNextBubble();
    resumeEngine();
  }
}
