import 'package:flutter/material.dart';
import 'dart:math' as math;

class MindMapApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mind Map',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MindMapScreen(),
    );
  }
}

class MindMapScreen extends StatefulWidget {
  @override
  _MindMapScreenState createState() => _MindMapScreenState();
}

class _MindMapScreenState extends State<MindMapScreen> with TickerProviderStateMixin {
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  Offset _lastPanUpdate = Offset.zero;
  late MindMapData _mindMapData;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _mindMapData = MindMapData();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleNode(String nodeId) {
    setState(() {
      _mindMapData.toggleNode(nodeId);
    });
    _animationController.forward(from: 0);
  }

  bool _isPointInNode(Offset point, MindMapNode node) {
    final nodeRect = Rect.fromCenter(
      center: node.position,
      width: node.width,
      height: node.height,
    );
    return nodeRect.contains(point);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('마인드맵'),
        backgroundColor: Colors.blue[600],
        actions: [
          IconButton(
            icon: Icon(Icons.zoom_in),
            onPressed: () {
              setState(() {
                _scale = (_scale * 1.2).clamp(0.5, 3.0);
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.zoom_out),
            onPressed: () {
              setState(() {
                _scale = (_scale / 1.2).clamp(0.5, 3.0);
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.center_focus_strong),
            onPressed: () {
              setState(() {
                _scale = 1.0;
                _offset = Offset.zero;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.unfold_more),
            onPressed: () {
              setState(() {
                _mindMapData.expandAll();
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.unfold_less),
            onPressed: () {
              setState(() {
                _mindMapData.collapseAll();
              });
            },
          ),
        ],
      ),
      body: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _offset += details.delta;
          });
        },
        onTapUp: (details) {
          final adjustedPosition = Offset(
            (details.localPosition.dx - _offset.dx) / _scale,
            (details.localPosition.dy - _offset.dy) / _scale,
          );
          
          for (final node in _mindMapData.getVisibleNodes()) {
            if (_isPointInNode(adjustedPosition, node)) {
              if (node.children.isNotEmpty && node.isExpandable) {
                _toggleNode(node.id);
              }
              break;
            }
          }
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.grey[50],
          child: Transform(
            transform: Matrix4.identity()
              ..translate(_offset.dx, _offset.dy)
              ..scale(_scale),
            child: CustomPaint(
              painter: MindMapPainter(
                mindMapData: _mindMapData,
                onNodeTap: _toggleNode,
                animation: _animationController,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );
  }
}

class MindMapNode {
  final String id;
  final String text;
  final Color color;
  final Offset position;
  final List<MindMapNode> children;
  final double width;
  final double height;
  bool isExpanded;
  final bool isExpandable;

  MindMapNode({
    required this.id,
    required this.text,
    required this.color,
    required this.position,
    this.children = const [],
    this.width = 120,
    this.height = 40,
    this.isExpanded = true,
    this.isExpandable = true,
  });
}

class MindMapData {
  late Map<String, MindMapNode> _nodes;
  late MindMapNode _rootNode;

  MindMapData() {
    _initializeNodes();
  }

  Map<String, MindMapNode> get nodes => _nodes;
  MindMapNode get rootNode => _rootNode;

  void toggleNode(String nodeId) {
    if (_nodes.containsKey(nodeId) && _nodes[nodeId]!.isExpandable) {
      _nodes[nodeId]!.isExpanded = !_nodes[nodeId]!.isExpanded;
    }
  }

  void expandAll() {
    _nodes.values.forEach((node) {
      if (node.isExpandable) {
        node.isExpanded = true;
      }
    });
  }

  void collapseAll() {
    _nodes.values.forEach((node) {
      if (node.isExpandable && node.id != 'center') {
        node.isExpanded = false;
      }
    });
  }

  List<MindMapNode> getVisibleNodes() {
    List<MindMapNode> visibleNodes = [_rootNode];
    _addVisibleChildren(_rootNode, visibleNodes);
    return visibleNodes;
  }

  void _addVisibleChildren(MindMapNode parent, List<MindMapNode> visibleNodes) {
    if (parent.isExpanded) {
      for (final child in parent.children) {
        visibleNodes.add(child);
        _addVisibleChildren(child, visibleNodes);
      }
    }
  }

  void _initializeNodes() {
    _nodes = {};
    
    // 계층적 레이아웃을 위한 상수들
    final double level0X = 150;  // 루트 노드 X 위치
    final double level1X = 400;  // 1레벨 노드들 X 위치  
    final double level2X = 700;  // 2레벨 노드들 X 위치
    final double nodeSpacing = 80; // 노드 간 수직 간격
    final double groupSpacing = 20; // 그룹 내 노드 간격
    
    // 교육 정책 수립과 하위 노드들
    final educationSubs = [
      MindMapNode(id: 'edu_dev', text: '교육과정 개발', color: Colors.green[200]!, position: Offset(level2X, 50), width: 110, height: 30, isExpandable: false),
      MindMapNode(id: 'edu_goal', text: '교육목표 설정', color: Colors.green[200]!, position: Offset(level2X, 80), width: 110, height: 30, isExpandable: false),
      MindMapNode(id: 'edu_method', text: '교육방법론 연구', color: Colors.green[200]!, position: Offset(level2X, 110), width: 110, height: 30, isExpandable: false),
      MindMapNode(id: 'edu_eval', text: '교육평가 체계', color: Colors.green[200]!, position: Offset(level2X, 140), width: 110, height: 30, isExpandable: false),
    ];
    educationSubs.forEach((node) => _nodes[node.id] = node);

    final educationPolicy = MindMapNode(
      id: 'education',
      text: '교육 정책 수립',
      color: Colors.green[300]!,
      position: Offset(level1X, 95),
      children: educationSubs,
    );
    _nodes['education'] = educationPolicy;

    // 학습 관리 시스템과 하위 노드들
    final learningSubs = [
      MindMapNode(id: 'learn_progress', text: '학습진도 관리', color: Colors.orange[200]!, position: Offset(level2X, 170), width: 100, height: 30, isExpandable: false),
      MindMapNode(id: 'learn_grade', text: '성적 관리', color: Colors.orange[200]!, position: Offset(level2X, 200), width: 100, height: 30, isExpandable: false),
      MindMapNode(id: 'learn_attend', text: '출결 관리', color: Colors.orange[200]!, position: Offset(level2X, 230), width: 100, height: 30, isExpandable: false),
      MindMapNode(id: 'learn_analysis', text: '학습 분석', color: Colors.orange[200]!, position: Offset(level2X, 260), width: 100, height: 30, isExpandable: false),
    ];
    learningSubs.forEach((node) => _nodes[node.id] = node);

    final learningSystem = MindMapNode(
      id: 'learning',
      text: '학습 관리 시스템',
      color: Colors.orange[300]!,
      position: Offset(level1X, 215),
      children: learningSubs,
    );
    _nodes['learning'] = learningSystem;

    // 콘텐츠 관리와 하위 노드들
    final contentSubs = [
      MindMapNode(id: 'content_material', text: '교육자료 제작', color: Colors.purple[200]!, position: Offset(level2X, 290), width: 100, height: 30, isExpandable: false),
      MindMapNode(id: 'content_media', text: '멀티미디어 콘텐츠', color: Colors.purple[200]!, position: Offset(level2X, 320), width: 120, height: 30, isExpandable: false),
      MindMapNode(id: 'content_online', text: '온라인 강의', color: Colors.purple[200]!, position: Offset(level2X, 350), width: 100, height: 30, isExpandable: false),
      MindMapNode(id: 'content_exam', text: '평가문제 개발', color: Colors.purple[200]!, position: Offset(level2X, 380), width: 100, height: 30, isExpandable: false),
      MindMapNode(id: 'content_tool', text: '학습 도구', color: Colors.purple[200]!, position: Offset(level2X, 410), width: 100, height: 30, isExpandable: false),
    ];
    contentSubs.forEach((node) => _nodes[node.id] = node);

    final contentManagement = MindMapNode(
      id: 'content',
      text: '콘텐츠 관리',
      color: Colors.purple[300]!,
      position: Offset(level1X, 350),
      children: contentSubs,
    );
    _nodes['content'] = contentManagement;

    // 기술 지원과 하위 노드들
    final techSubs = [
      MindMapNode(id: 'tech_system', text: '시스템 운영', color: Colors.teal[200]!, position: Offset(level2X, 440), width: 90, height: 30, isExpandable: false),
      MindMapNode(id: 'tech_support', text: '기술 지원', color: Colors.teal[200]!, position: Offset(level2X, 470), width: 90, height: 30, isExpandable: false),
      MindMapNode(id: 'tech_platform', text: '플랫폼 관리', color: Colors.teal[200]!, position: Offset(level2X, 500), width: 90, height: 30, isExpandable: false),
      MindMapNode(id: 'tech_security', text: '보안 관리', color: Colors.teal[200]!, position: Offset(level2X, 530), width: 90, height: 30, isExpandable: false),
    ];
    techSubs.forEach((node) => _nodes[node.id] = node);

    final techSupport = MindMapNode(
      id: 'tech',
      text: '기술 지원',
      color: Colors.teal[300]!,
      position: Offset(level1X, 485),
      children: techSubs,
    );
    _nodes['tech'] = techSupport;

    // 품질 관리와 하위 노드들
    final qualitySubs = [
      MindMapNode(id: 'quality_eval', text: '품질 평가', color: Colors.indigo[200]!, position: Offset(level2X, 560), width: 90, height: 30, isExpandable: false),
      MindMapNode(id: 'quality_improve', text: '개선 방안', color: Colors.indigo[200]!, position: Offset(level2X, 590), width: 90, height: 30, isExpandable: false),
      MindMapNode(id: 'quality_survey', text: '만족도 조사', color: Colors.indigo[200]!, position: Offset(level2X, 620), width: 90, height: 30, isExpandable: false),
      MindMapNode(id: 'quality_feedback', text: '피드백 수집', color: Colors.indigo[200]!, position: Offset(level2X, 650), width: 90, height: 30, isExpandable: false),
      MindMapNode(id: 'quality_continuous', text: '지속적 개선', color: Colors.indigo[200]!, position: Offset(level2X, 680), width: 90, height: 30, isExpandable: false),
      MindMapNode(id: 'quality_cert', text: '품질 인증', color: Colors.indigo[200]!, position: Offset(level2X, 710), width: 90, height: 30, isExpandable: false),
      MindMapNode(id: 'quality_std', text: '표준화', color: Colors.indigo[200]!, position: Offset(level2X, 740), width: 90, height: 30, isExpandable: false),
    ];
    qualitySubs.forEach((node) => _nodes[node.id] = node);

    final qualityManagement = MindMapNode(
      id: 'quality',
      text: '품질 관리',
      color: Colors.indigo[300]!,
      position: Offset(level1X, 650),
      children: qualitySubs,
    );
    _nodes['quality'] = qualityManagement;

    // 운영 관리와 하위 노드들
    final operationSubs = [
      MindMapNode(id: 'op_schedule', text: '일정 관리', color: Colors.amber[200]!, position: Offset(level2X, 770), width: 80, height: 30, isExpandable: false),
      MindMapNode(id: 'op_resource', text: '자원 관리', color: Colors.amber[200]!, position: Offset(level2X, 800), width: 80, height: 30, isExpandable: false),
      MindMapNode(id: 'op_budget', text: '예산 관리', color: Colors.amber[200]!, position: Offset(level2X, 830), width: 80, height: 30, isExpandable: false),
      MindMapNode(id: 'op_hr', text: '인력 관리', color: Colors.amber[200]!, position: Offset(level2X, 860), width: 80, height: 30, isExpandable: false),
      MindMapNode(id: 'op_facility', text: '시설 관리', color: Colors.amber[200]!, position: Offset(level2X, 890), width: 80, height: 30, isExpandable: false),
    ];
    operationSubs.forEach((node) => _nodes[node.id] = node);

    final operationManagement = MindMapNode(
      id: 'operation',
      text: '운영 관리',
      color: Colors.amber[300]!,
      position: Offset(level1X, 830),
      children: operationSubs,
    );
    _nodes['operation'] = operationManagement;

    // 협력 관계와 하위 노드들
    final cooperationSubs = [
      MindMapNode(id: 'coop_org', text: '기관 협력', color: Colors.cyan[200]!, position: Offset(level2X, 920), width: 80, height: 30, isExpandable: false),
      MindMapNode(id: 'coop_industry', text: '산학 협력', color: Colors.cyan[200]!, position: Offset(level2X, 950), width: 80, height: 30, isExpandable: false),
      MindMapNode(id: 'coop_intl', text: '국제 협력', color: Colors.cyan[200]!, position: Offset(level2X, 980), width: 80, height: 30, isExpandable: false),
      MindMapNode(id: 'coop_local', text: '지역 협력', color: Colors.cyan[200]!, position: Offset(level2X, 1010), width: 80, height: 30, isExpandable: false),
    ];
    cooperationSubs.forEach((node) => _nodes[node.id] = node);

    final cooperation = MindMapNode(
      id: 'cooperation',
      text: '협력 관계',
      color: Colors.cyan[300]!,
      position: Offset(level1X, 965),
      children: cooperationSubs,
    );
    _nodes['cooperation'] = cooperation;

    // 연구 개발과 하위 노드들
    final researchSubs = [
      MindMapNode(id: 'research_edu', text: '교육 연구', color: Colors.pink[200]!, position: Offset(level2X, 1040), width: 80, height: 30, isExpandable: false),
      MindMapNode(id: 'research_tech', text: '기술 연구', color: Colors.pink[200]!, position: Offset(level2X, 1070), width: 80, height: 30, isExpandable: false),
      MindMapNode(id: 'research_policy', text: '정책 연구', color: Colors.pink[200]!, position: Offset(level2X, 1100), width: 80, height: 30, isExpandable: false),
      MindMapNode(id: 'research_trend', text: '트렌드 분석', color: Colors.pink[200]!, position: Offset(level2X, 1130), width: 80, height: 30, isExpandable: false),
    ];
    researchSubs.forEach((node) => _nodes[node.id] = node);

    final research = MindMapNode(
      id: 'research',
      text: '연구 개발',
      color: Colors.pink[300]!,
      position: Offset(level1X, 1085),
      children: researchSubs,
    );
    _nodes['research'] = research;

    // 루트 노드의 자식들 설정
    _rootNode = MindMapNode(
      id: 'center',
      text: '기획관리',
      color: Colors.blue[400]!,
      position: Offset(level0X, 600),  // 중앙 위치로 조정
      width: 120,
      height: 50,
      isExpandable: false,
      children: [
        educationPolicy,
        learningSystem,
        contentManagement,
        techSupport,
        qualityManagement,
        operationManagement,
        cooperation,
        research,
      ],
    );
    _nodes['center'] = _rootNode;
  }
}

class MindMapPainter extends CustomPainter {
  final MindMapData mindMapData;
  final Function(String) onNodeTap;
  final Animation<double> animation;

  MindMapPainter({
    required this.mindMapData,
    required this.onNodeTap,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    final visibleNodes = mindMapData.getVisibleNodes();

    // 연결선 그리기
    _drawConnections(canvas, paint, visibleNodes);
    
    // 노드 그리기
    _drawNodes(canvas, textPainter, visibleNodes, size);
  }

  void _drawConnections(Canvas canvas, Paint paint, List<MindMapNode> visibleNodes) {
    paint.color = Colors.grey[400]!;
    paint.strokeWidth = 2.0;

    for (final node in visibleNodes) {
      if (node.isExpanded) {
        for (final child in node.children) {
          if (visibleNodes.contains(child)) {
            _drawCurvedLine(canvas, paint, node.position, child.position);
          }
        }
      }
    }
  }

  void _drawCurvedLine(Canvas canvas, Paint paint, Offset start, Offset end) {
    final path = Path();
    path.moveTo(start.dx, start.dy);
    
    final controlPoint1 = Offset(
      start.dx + (end.dx - start.dx) * 0.5,
      start.dy,
    );
    final controlPoint2 = Offset(
      start.dx + (end.dx - start.dx) * 0.5,
      end.dy,
    );
    
    path.cubicTo(
      controlPoint1.dx, controlPoint1.dy,
      controlPoint2.dx, controlPoint2.dy,
      end.dx, end.dy,
    );
    
    canvas.drawPath(path, paint);
  }

  void _drawNodes(Canvas canvas, TextPainter textPainter, List<MindMapNode> visibleNodes, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    for (final node in visibleNodes) {
      _drawNode(canvas, textPainter, paint, node, size);
    }
  }

  void _drawNode(Canvas canvas, TextPainter textPainter, Paint paint, MindMapNode node, Size size) {
    // 노드 배경 그리기
    paint.color = node.color;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: node.position, width: node.width, height: node.height),
      Radius.circular(20),
    );
    canvas.drawRRect(rect, paint);

    // 테두리 그리기
    paint.style = PaintingStyle.stroke;
    paint.color = node.color.withOpacity(0.8);
    paint.strokeWidth = 2;
    canvas.drawRRect(rect, paint);
    paint.style = PaintingStyle.fill;

    // 확장/축소 아이콘 그리기 (하위 노드가 있는 경우)
    if (node.children.isNotEmpty && node.isExpandable) {
      _drawExpandIcon(canvas, paint, node);
    }

    // 텍스트 그리기
    textPainter.text = TextSpan(
      text: node.text,
      style: TextStyle(
        color: Colors.black87,
        fontSize: node.text.length > 8 ? 11 : 12,
        fontWeight: FontWeight.w600,
      ),
    );
    textPainter.layout(maxWidth: node.width - 10);
    
    final textOffset = Offset(
      node.position.dx - textPainter.width / 2,
      node.position.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, textOffset);
  }

  void _drawExpandIcon(Canvas canvas, Paint paint, MindMapNode node) {
    paint.color = Colors.white;
    paint.style = PaintingStyle.fill;
    
    final iconSize = 16.0;
    final iconCenter = Offset(
      node.position.dx + node.width / 2 - iconSize / 2,
      node.position.dy - node.height / 2 + iconSize / 2,
    );
    
    // 원형 배경
    canvas.drawCircle(iconCenter, iconSize / 2, paint);
    
    // 테두리
    paint.color = Colors.grey[600]!;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1;
    canvas.drawCircle(iconCenter, iconSize / 2, paint);
    
    // +/- 아이콘
    paint.color = Colors.grey[700]!;
    paint.strokeWidth = 2;
    paint.style = PaintingStyle.stroke;
    
    // 가로선 (항상 그리기)
    canvas.drawLine(
      Offset(iconCenter.dx - 4, iconCenter.dy),
      Offset(iconCenter.dx + 4, iconCenter.dy),
      paint,
    );
    
    // 세로선 (접혀있을 때만 그리기)
    if (!node.isExpanded) {
      canvas.drawLine(
        Offset(iconCenter.dx, iconCenter.dy - 4),
        Offset(iconCenter.dx, iconCenter.dy + 4),
        paint,
      );
    }
  }

  @override
  bool hitTest(Offset position) => true;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

void main() {
  runApp(MindMapApp());
}