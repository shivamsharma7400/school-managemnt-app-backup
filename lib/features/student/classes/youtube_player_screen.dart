import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../data/models/online_class_model.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;

class YouTubePlayerScreen extends StatefulWidget {
  final OnlineClass onlineClass;

  const YouTubePlayerScreen({Key? key, required this.onlineClass}) : super(key: key);

  @override
  _YouTubePlayerScreenState createState() => _YouTubePlayerScreenState();
}

class _YouTubePlayerScreenState extends State<YouTubePlayerScreen> {

  late YoutubePlayerController _controller;
  bool _isLive = false;
  bool _isLoadingContent = true;

  @override
  void initState() {
    super.initState();
    _checkLiveStatus();
  }

  Future<void> _checkLiveStatus() async {
    try {
      final ytExplode = yt.YoutubeExplode();
      final video = await ytExplode.videos.get(widget.onlineClass.youtubeVideoId);
      if (mounted) {
        setState(() {
          _isLive = video.isLive;
        });
      }
    } catch (e) {
      debugPrint("Failed to fetch YouTube Live status: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingContent = false;
          _controller = YoutubePlayerController(
            initialVideoId: widget.onlineClass.youtubeVideoId,
            flags: YoutubePlayerFlags(
              autoPlay: true,
              mute: false,
              isLive: _isLive,
              enableCaption: true,
            ),
          );
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingContent) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(widget.onlineClass.title),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator(color: Colors.red)),
      );
    }

    return YoutubePlayerBuilder(
       player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.red,
        onReady: () {
          // Additional setup if needed
        },
        bottomActions: [
          const SizedBox(width: 14.0),
          CurrentPosition(),
          const SizedBox(width: 8.0),
          ProgressBar(isExpanded: true),
          const SizedBox(width: 8.0),
          RemainingDuration(),
          IconButton(
            icon: const Icon(Icons.speed, color: Colors.white),
            onPressed: () => _showSpeedDialog(context),
            tooltip: 'Playback Speed',
          ),
          const FullScreenButton(),
        ],
        topActions: <Widget>[
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              _controller.metadata.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18.0,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.settings,
              color: Colors.white,
              size: 25.0,
            ),
            onPressed: () {
              // Open resolution/quality selector (simulated)
              _showQualityDialog(context);
            },
          ),
        ],
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: Text(widget.onlineClass.title),
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                player,
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _isLive ? Colors.red : Colors.blue,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _isLive ? 'LIVE' : 'RECORDED',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () => _showSpeedDialog(context),
                            icon: const Icon(Icons.speed_outlined, size: 18),
                            label: const Text('Speed'),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.indigo[50],
                              foregroundColor: Colors.indigo,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.onlineClass.title,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.indigo[50],
                            child: Text(widget.onlineClass.teacherName[0]),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.onlineClass.teacherName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('Faculty Instructor', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text('About this lesson', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(
                        widget.onlineClass.description,
                        style: TextStyle(color: Colors.grey[700], height: 1.5),
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.chat_bubble_outline, color: Colors.grey[600]),
                            const SizedBox(width: 12),
                            Text('Live Chat is disabled for this view', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100), // Padding for scroll
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSpeedDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Playback Speed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _speedOption(0.5, '0.5x (Slow)'),
            _speedOption(0.75, '0.75x'),
            _speedOption(1.0, 'Normal'),
            _speedOption(1.25, '1.25x'),
            _speedOption(1.5, '1.5x'),
            _speedOption(2.0, '2.0x (Fast)'),
          ],
        ),
      ),
    );
  }

  Widget _speedOption(double speed, String label) {
    final isSelected = _controller.value.playbackRate == speed;
    return ListTile(
      title: Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.indigo) : null,
      onTap: () {
        _controller.setPlaybackRate(speed);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Playback speed: ${speed}x'), duration: const Duration(seconds: 1)),
        );
      },
    );
  }
  void _showQualityDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Select Video Quality"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text("Auto"),
              onTap: () => Navigator.pop(context),
              selected: true,
              trailing: Icon(Icons.check, color: Colors.green),
            ),
            ListTile(
              title: Text("1080p"),
              subtitle: Text("YouTube will adjust based on connection"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: Text("720p"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: Text("480p"),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
