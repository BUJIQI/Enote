import 'package:flutter/material.dart';
import '../models/score_item.dart';
import '../models/score_dao.dart';
import '../models/collection_item_dao.dart';
import 'score_detail_page.dart';

class CollectionDetailPage extends StatefulWidget {
  final Map<String, dynamic> collection;
  const CollectionDetailPage({required this.collection});

  @override
  State<CollectionDetailPage> createState() => _CollectionDetailPageState();
}

class _CollectionDetailPageState extends State<CollectionDetailPage> {
  List<ScoreItem> scoreList = [];

  @override
  void initState() {
    super.initState();
    loadScores();
  }

  void loadScores() async {
    final collectionId = widget.collection['Collectionid'];
    final items = await CollectionItemDao.fetchScoresInCollection(collectionId);
    setState(() {
      scoreList = items;
    });
  }

  void openScore(ScoreItem item) {
    ScoreDao.updateModifyTime(item.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MxlScoreDetailPage(scoreItem: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('谱集内容')),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: GridView.builder(
          itemCount: scoreList.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 0.8,
          ),
          itemBuilder: (context, index) {
            final item = scoreList[index];
            return GestureDetector(
              onTap: () => openScore(item),
              child: Column(
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/imgs/score_icon.jpg',
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: 110,
                    child: Text(
                      item.name,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
