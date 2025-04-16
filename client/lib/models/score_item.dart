class ScoreItem {
  final String id;
  final String name;
  final String image;
  final String? mxlPath;
  final String? modifyTime; // ✅ 新增字段

  ScoreItem({
    required this.id,
    required this.name,
    required this.image,
    this.mxlPath,
    this.modifyTime,
  });
}
