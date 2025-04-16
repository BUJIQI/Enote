import 'package:flutter/material.dart';
import 'score_detail_page.dart';  // 这里是你创建的 dart 文件路径
import '../widgets/import_score.dart';
import '../models/score_item.dart';
import '../models/score_dao.dart';
import '../models/collection_dao.dart';
import 'collection_detail_page.dart';
import '../models/user_session.dart';
import 'package:uuid/uuid.dart';
import '../models/collection_info_dao.dart';
import '../models/collection_item_dao.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Register.dart';
import 'enter.dart';
import 'user_info.dart';



/// 首页：包含顶部导航、标签栏、曲谱列表和排序菜单
class ScoreHomePage extends StatefulWidget {
  @override
  _ScoreHomePageState createState() => _ScoreHomePageState();
}

class _ScoreHomePageState extends State<ScoreHomePage> {
  late ImportHandler importHandler;
  List<ScoreItem> scoreList = [];
  List<Map<String, dynamic>> collectionList = [];
  Map<String, dynamic>? selectedCollection;
  String? token;
  String? username;




  @override
  void initState() {
    super.initState();
    loadScoresFromDB();
    loadCollections();
    _loadUserData().then((data) {
      setState(() {
        token = data['token'];
        username = data['username'];
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      importHandler = ImportHandler(
        context: context,
        onImageImport: () {
          print('以图像方式导入曲谱');
        },
        onMxlImported: (ScoreItem item) async {
          final userid = UserSession.getUserId();

          final scoreId = await ScoreDao.insertScore(
            userid: userid,
            title: item.name,
            mxlPath: item.mxlPath, // ✅ 改为 mxlPath
            image: item.image,
          );

          final savedItem = ScoreItem(
            id: scoreId,
            name: item.name,
            image: item.image,
            mxlPath: item.mxlPath,
          );

          setState(() {
            scoreList.add(savedItem);
            sortScores(); // ✅ 保持当前排序方式
          });

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MxlScoreDetailPage(scoreItem: savedItem),
            ),
          );
        },

      );
    });
  }



  String activeTab = 'shelf';
  bool showSortMenu = false;
  String currentSort = '时间排序';
  TextEditingController searchController = TextEditingController();

  void loadScoresFromDB() async {
    final userid = UserSession.getUserId();
    final result = await ScoreDao.fetchAllScores(userid: userid);

    setState(() {
      scoreList = result.map((row) => ScoreItem(
        id: row['Scoreid'] as String,
        name: row['Title'] as String,
        image: row['Image'] as String? ?? 'assets/imgs/score_icon.jpg',
        mxlPath: row['MxlPath'] as String?,
        accessTime: row['Access_time'] as String?, // ✅ 加上这行
      )).toList();
      sortScores(); // ✅ 排序
    });
  }

  void sortScores() {
    if (currentSort == '时间排序') {
      scoreList.sort((a, b) {
        final aTime = DateTime.tryParse(a.accessTime ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = DateTime.tryParse(b.accessTime ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime); // ✅ 最近时间在前
      });
    } else if (currentSort == '首字母排序') {
      scoreList.sort((a, b) => a.name.compareTo(b.name));
    }
  }


  void addNewScore(String name) async {
    final userid = UserSession.getUserId();
    await ScoreDao.insertScore(userid: userid, title: name);
    loadScoresFromDB();
  }

  void deleteScoreByIndex(int index) async {
    final score = scoreList[index];
    await ScoreDao.deleteScore(score.id);
    setState(() {
      scoreList.removeAt(index);
    });
  }
  Future<void> createAndAddScoreToCollection({
    required String title,
    required String collectionId,
  }) async {
    final userid = UserSession.getUserId();
    final scoreId = await ScoreDao.insertScore(userid: userid, title: title);

    await CollectionItemDao.insertScoreToCollection(
      collectionId: collectionId,
      scoreId: scoreId,
      orderno: DateTime.now().millisecondsSinceEpoch,
    );
    await ScoreDao.debugPrintAllScores();
    await CollectionItemDao.debugPrintAllCollectionItems();
    print('✅ 插入 Score 和 CollectionItem 完成：$scoreId');
  }

  void addCollection(String collectionId, String scoreId) async {
    final orderno = scoreList.length + 1;
    await CollectionItemDao.insertScoreToCollection(
      collectionId: collectionId,
      scoreId: scoreId,
      orderno: orderno,
    );
    loadCollections();
  }


  void removeCollection(String collectionid, int index) async {
    await CollectionInfoDao.deleteCollection(collectionid);
    setState(() {
      scoreList.removeAt(index);
    });
  }

  void loadCollections() async {
    final userid = UserSession.getUserId();
    final result = await CollectionInfoDao.fetchCollections(userid);
    setState(() {
      collectionList = result;
    });
  }

  String searchText = '';

  List<ScoreItem> getFilteredScores() {
    if (searchText.isEmpty) return scoreList;
    return scoreList.where((score) =>
        score.name.toLowerCase().contains(searchText.toLowerCase())).toList();
  }

  void switchTab(String tab) {
    setState(() {
      activeTab = tab;

      if (tab == 'shelf') {
        selectedCollection = null; // ✅ 切换回谱架时清除谱集选中状态
      }
    });
  }


  void toggleSortMenu() {
    setState(() {
      showSortMenu = !showSortMenu;
    });
  }

  void selectSort(String type) {
    setState(() {
      currentSort = type == 'time' ? '时间排序' : '首字母排序';
      showSortMenu = false;
      sortScores();
    });
  }

  // 导航到个人主页（示例页面）
  void navigateToProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? username = prefs.getString('username');

    if (token != null && username != null) {
      // 已登录，跳转到用户信息页
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => UserInfoPage(token: token,username: username)),
      );
    } else {
      // 未登录，跳转到登录页
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) =>  ProfilePage()),
      );
    }

  }
  
  void showSearch() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('搜索曲谱'),
          content: TextField(
            controller: searchController,
            autofocus: true,
            decoration: InputDecoration(hintText: '输入曲谱标题'),
            onChanged: (value) {
              setState(() {
                searchText = value;
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  searchText = '';
                  searchController.clear();
                });
                Navigator.pop(context);
              },
              child: Text('清除'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('关闭'),
            ),
          ],
        );
      },
    );
  }



  void navigateToMxlScoreDetail(ScoreItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MxlScoreDetailPage(scoreItem: item),
      ),
    );
  }


  void addCollectionToCollection(String scoreId, String collectionId) async {
    final orderno = DateTime.now().millisecondsSinceEpoch;  // 用时间戳做排序更自然

    await CollectionItemDao.insertScoreToCollection(
      collectionId: collectionId,
      scoreId: scoreId, // ✅ 正确传入函数参数
      orderno: DateTime.now().millisecondsSinceEpoch,
    );
    print('✅ 插入成功：$scoreId 添加到 $collectionId');

    setState(() {
      // 重新加载谱集（可以优化为不全重新加载）
      loadCollections();
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('曲谱已添加到谱集'),
    ));
  }


  void showAddToCollectionDialog(ScoreItem item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('选择要添加的谱集'),
          content: Container(
            width: double.maxFinite,
            height: 300, // ✅ 显式设置整个内容区域高度
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: CollectionInfoDao.fetchCollections(UserSession.getUserId()),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Text("出错了：${snapshot.error}");
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text("你还没有谱集，请先创建一个"));
                }

                final collections = snapshot.data!;
                return ListView.builder(
                  itemCount: collections.length,
                  itemBuilder: (context, index) {
                    final collection = collections[index];
                    return ListTile(
                      title: Text(collection['Title'] ?? '未命名谱集'),
                        onTap: () async {
                          print("👉 正在添加 ${item.id} 到谱集 ${collection['Collectionid']}");

                          await CollectionItemDao.insertScoreToCollection(
                            collectionId: collection['Collectionid'],
                            scoreId: item.id,
                            orderno: DateTime.now().millisecondsSinceEpoch,
                          );

                          print("✅ 添加完成，插入成功");

                          await CollectionItemDao.debugPrintAllCollectionItems();

                          Navigator.pop(context);
                          setState(() {}); // ✅ 触发 UI 刷新
                        }

                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }


  void showScoreActions(ScoreItem item, int index) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.edit),
                title: Text('重命名'),
                onTap: () {
                  Navigator.pop(context);
                  showRenameDialog(item, index);
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('删除'),
                onTap: () {
                  setState(() {
                    scoreList.removeAt(index);
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: Icon(Icons.share),
                title: Text('分享'),
                onTap: () {
                  Navigator.pop(context);
                  // 这里可以调用系统分享逻辑或其它扩展
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('分享功能待实现'),
                  ));
                },
              ),
              ListTile(
                leading: Icon(Icons.add_box),
                title: Text('添加到谱集'),
                onTap: () {
                  Navigator.pop(context);
                  showAddToCollectionDialog(item);
                },
              ),
            ],
          ),
        );
      },
    );
  }


  void showRenameDialog(ScoreItem item, int index) {
    TextEditingController controller = TextEditingController(text: item.name);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('重命名曲谱'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: '请输入新名称'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  scoreList[index] = ScoreItem(
                    id: item.id,
                    name: controller.text,
                    image: item.image,
                    mxlPath: item.mxlPath,
                  );
                });
                Navigator.pop(context);
              },
              child: Text('确认'),
            ),
          ],
        );
      },
    );
  }

  void showCreateCollectionDialog() {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('创建新谱集'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: '请输入谱集名称'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = controller.text.trim();
                if (title.isEmpty) return;

                final userid = UserSession.getUserId();
                await CollectionInfoDao.createCollection(userid, title);
                Navigator.pop(context);
                loadCollections(); // 刷新列表
              },
              child: Text('创建'),
            ),
          ],
        );
      },
    );
  }


  Widget buildScoreGrid() {
    final filteredScores = getFilteredScores();
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 0.8,
      ),
      itemCount: filteredScores.length,
      itemBuilder: (context, index) {
        final item = filteredScores[index];
        return GestureDetector(
          onTap: () {
              navigateToMxlScoreDetail(item);
            },
          onLongPress: () => showScoreActions(item, index),
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
              )
            ],
          ),
        );
      },
    );
  }

  Widget buildCollectionGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 0.8,
      ),
      itemCount: collectionList.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return GestureDetector(
            onTap: showCreateCollectionDialog,
            child: Column(
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[300],
                  ),
                  child: Icon(Icons.add, size: 40, color: Colors.black54),
                ),
                SizedBox(height: 8),
                Container(
                  width: 110,
                  child: Text(
                    '新建谱集',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              ],
            ),
          );
        }

        final item = collectionList[index - 1]; // ⚠️ 注意减一
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedCollection = item;
            });
          },
          onLongPress: () {
            // 未来添加：弹出谱集操作栏
          },
          child: Column(
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.amber[200],
                ),
                child: Icon(Icons.folder, size: 40),
              ),
              SizedBox(height: 8),
              Container(
                width: 110,
                child: Text(
                  item['Title'] ?? '未命名谱集',
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      }
    );
  }
  Widget buildSelectedCollectionScoreGrid() {
    return FutureBuilder<List<ScoreItem>>(
      future: CollectionItemDao.fetchScoresInCollection(selectedCollection!['Collectionid']),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('❌ 查询出错：${snapshot.error}');
          return Center(child: Text('加载出错'));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          print('🔍 没查到谱集曲谱！');
          return Center(child: Text('该谱集中暂无曲谱'));
        }

        final scores = snapshot.data!;
        print('🎯 查到 ${scores.length} 首曲谱');
        return GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: scores.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: 0.8,
          ),
          itemBuilder: (context, index) {
            final item = scores[index];
            return GestureDetector(
              onTap: () {
                  navigateToMxlScoreDetail(item);
                },
              child: Column(
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(item.image),
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
        );
      },
    );
  }
  @override

  Future<Map<String, String>> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';
    String username = prefs.getString('username') ?? '';
    return {'token': token, 'username': username};
  }
  
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Column(
            children: [
              // 顶部导航栏
              Container(
                padding: EdgeInsets.only(left: 30.0, right: 30.0, top: 55.0),
                color: Color(0xFFFFE9BF),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: navigateToProfile,
                      child: Container(
                        width: 40.0,
                        height: 40.0,
                        decoration: BoxDecoration(
                          color: Color(0xFFFDFDFD),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person, size: 24.0, color: Color(0xFF666666)),
                      ),
                    ),
                    SizedBox(width: 20.0),
                    Expanded(
                      child: GestureDetector(
                        onTap: showSearch,
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            color: Color(0xFFFDFDFD),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 15),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(Icons.search, size: 20, color: Color(0xFF999999)),
                              SizedBox(width: 10),
                              Text(
                                '搜索我的曲谱',
                                style: TextStyle(color: Color(0xFF999999), fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 20),
                    GestureDetector(
                      onTap: () => importHandler.showImportDialog(),
                      child: Container(
                        width: 40.0,
                        height: 40.0,
                        alignment: Alignment.center,
                        child: Icon(Icons.add, size: 24.0, color: Color(0xFF666666)),
                      ),
                    ),
                  ],
                ),
              ),
              // 分类标签栏
              Container(
                padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 15.0),
                color: Color(0xFFFFE9BF),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => switchTab('shelf'),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.0),
                            child: Text(
                              '谱架',
                              style: TextStyle(
                                fontSize: activeTab == 'shelf' ? 22.0 : 18.0,
                                color: activeTab == 'shelf' ? Color(0xFF333333) : Color(0xFF999999),
                                fontWeight: activeTab == 'shelf' ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 40.0),
                        GestureDetector(
                          onTap: () {
                            switchTab('collection');
                            setState(() {
                              selectedCollection = null;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.0),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    switchTab('collection');
                                    setState(() {
                                      selectedCollection = null;
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10.0),
                                    child: Text(
                                      '谱集',
                                      style: TextStyle(
                                        fontSize: activeTab == 'collection' ? 22.0 : 18.0,
                                        color: activeTab == 'collection' ? Color(0xFF333333) : Color(0xFF999999),
                                        fontWeight: activeTab == 'collection' ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),

                                if (selectedCollection != null) ...[
                                  SizedBox(width: 6),
                                  Icon(Icons.chevron_right, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    selectedCollection!['Title'] ?? '',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Color(0xFF999999),
                                    ),
                                  ),
                                ]
                              ],
                            )

                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: toggleSortMenu,
                      child: Row(
                        children: [
                          Text(currentSort, style: TextStyle(fontSize: 18.0, color: Color(0xFF666666))),
                          Icon(Icons.arrow_drop_down, size: 14.0, color: Color(0xFF666666)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // 主体内容（曲谱或谱集）
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: activeTab == 'shelf'
                      ? buildScoreGrid()
                      : selectedCollection == null
                        ? buildCollectionGrid()
                        : buildSelectedCollectionScoreGrid(),
                ),
              ),
            ],
          ),
          if (showSortMenu)
            Positioned(
              top: 180.0,
              right: 30.0,
              child: Material(
                elevation: 4.0,
                borderRadius: BorderRadius.circular(12.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => selectSort('time'),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                          child: Text('时间排序', style: TextStyle(fontSize: 12.0, color: Color(0xFF333333))),
                        ),
                      ),
                      InkWell(
                        onTap: () => selectSort('letter'),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                          child: Text('首字母排序', style: TextStyle(fontSize: 12.0, color: Color(0xFF333333))),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

//个人主页
class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<String?> usernameFuture;

  final Color primaryColor = Color(0xFFFFE9BF);
  final Color secondaryColor = Color(0xFF3C3C39);
  final Color backgroundColor = Colors.white;
  final Color buttonYellow = Color(0xFFFADB7D);

  @override
  void initState() {
    super.initState();
    usernameFuture = _getUsername();
  }

  Future<String?> _getUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 20, color: Colors.black),
          onPressed: () async {
            // 清除登录信息
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.remove('token');
            await prefs.remove('username');

            // 跳转到主页面并清空栈（防止用户返回）
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => ScoreHomePage()), // 你主页面的 widget
                  (Route<dynamic> route) => false,
            );
          },
        ),

        title: Text(
          "个人主页",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ),
      body: FutureBuilder<String?>(
        future: usernameFuture,
        builder: (context, snapshot) {
          final username = snapshot.data ?? '未登录';

          return SingleChildScrollView(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 头像区域
                    Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person,
                            size: 32,
                            color: secondaryColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          username.isNotEmpty ? username : '未登录',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32),
                    // 按钮区域
                    Column(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.black,
                            fixedSize: Size(240, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => LoginPage()),
                            );
                            setState(() {
                              usernameFuture = _getUsername(); // 登录回来刷新昵称
                            });
                          },
                          child: Text(
                            '登录',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                        SizedBox(height: 16),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: secondaryColor),
                            foregroundColor: Colors.black,
                            fixedSize: Size(240, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => RegisterPage()),
                            );
                          },
                          child: Text(
                            '注册',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 32),
                    Text(
                      '登录后可开启云同步功能',
                      style: TextStyle(
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

