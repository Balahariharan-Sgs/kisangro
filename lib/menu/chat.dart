import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kisangro/menu/complaint.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../home/theme_mode_provider.dart';
import '../common/common_app_bar.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentRecordingPath;
  int? _currentlyPlayingIndex;

  final List<Map<String, dynamic>> messages = [
    {
      "text": "Hello ! Mr. RK, We recently received your job et, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
      "isUser": false,
      "time": "12:43 pm",
      "type": "text"
    },
    {
      "text": "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et",
      "isUser": true,
      "time": "12:43 pm",
      "type": "text"
    },
    {
      "text": "Lorem ipsum dolor sit amet, consectetur adipiscing.",
      "isUser": true,
      "time": "12:43 pm",
      "type": "text"
    },
  ];

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      setState(() {
        _currentlyPlayingIndex = null;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.isRecording()) {
        await _stopRecording();
        return;
      }

      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw 'Microphone permission not granted';
      }

      final directory = await getTemporaryDirectory();
      final path = '${directory.path}/voice_message_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );

      setState(() {
        _isRecording = true;
        _currentRecordingPath = path;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start recording: $e')),
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });

      if (path != null) {
        setState(() {
          messages.add({
            "audioPath": path,
            "isUser": true,
            "time": _getCurrentTime(),
            "type": "audio",
            "duration": "0:15" // Placeholder duration
          });
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to stop recording: $e')),
      );
    }
  }

  Future<void> _playAudio(String path, int index) async {
    if (_isPlaying && _currentlyPlayingIndex == index) {
      await _audioPlayer.stop();
      setState(() {
        _currentlyPlayingIndex = null;
      });
      return;
    }

    try {
      if (_currentlyPlayingIndex != null) {
        await _audioPlayer.stop();
      }

      await _audioPlayer.play(DeviceFileSource(path));
      setState(() {
        _currentlyPlayingIndex = index;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to play audio: $e')),
      );
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      messages.add({
        "text": text,
        "isUser": true,
        "time": _getCurrentTime(),
        "type": "text"
      });
      _controller.clear();
    });
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return "${now.hour}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'pm' : 'am'}";
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, int index) {
    final isUser = msg['isUser'];
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isUser ? userBubbleColor : companyBubbleColor;
    final sender = isUser ? "You" : "Company";
    final time = msg["time"] ?? "";
    final type = msg["type"] ?? "text";

    return Column(
      crossAxisAlignment: isUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 2),
          child: Text(
            sender,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: const Color(0xffEB7720),
            ),
          ),
        ),
        Align(
          alignment: alignment,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (type == "text")
                  Text(
                    msg['text'],
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: bubbleTextColor,
                    ),
                  ),
                if (type == "audio")
                  _buildAudioMessage(msg, index),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: bubbleTimeColor,
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAudioMessage(Map<String, dynamic> msg, int index) {
    final bool isPlaying = _currentlyPlayingIndex == index;

    return GestureDetector(
      onTap: () => _playAudio(msg['audioPath'], index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              color: const Color(0xffEB7720),
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              isPlaying ? "Playing..." : "Voice message",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              msg['duration'] ?? "0:15",
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Get colors based on theme
  late Color userBubbleColor;
  late Color companyBubbleColor;
  late Color bubbleTextColor;
  late Color bubbleTimeColor;

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    // Define colors based on theme
    final Color gradientStartColor = isDarkMode ? Colors.black : const Color(0xffFFD9BD);
    final Color gradientEndColor = isDarkMode ? Colors.black : const Color(0xffFFFFFF);
    final Color complaintButtonBg = Colors.white;
    final Color complaintButtonTextColor = Colors.black;
    final Color chatHeaderTextColor = isDarkMode ? Colors.white : Colors.black;
    final Color chatHeaderSubtitleColor = isDarkMode ? Colors.white70 : Colors.black;
    final Color dateDividerColor = isDarkMode ? Colors.grey[600]! : Colors.grey;
    userBubbleColor = isDarkMode ? Colors.grey[700]! : const Color(0xFFFFFFFF);
    companyBubbleColor = isDarkMode ? Colors.grey[800]! : Colors.white;
    bubbleTextColor = isDarkMode ? Colors.white : Colors.black;
    bubbleTimeColor = isDarkMode ? Colors.grey[400]! : Colors.grey;
    final Color inputFieldBgColor = isDarkMode ? Colors.grey[800]!.withOpacity(0.5) : Colors.white.withOpacity(0.5);
    final Color inputFieldHintColor = isDarkMode ? Colors.grey[400]! : Colors.grey;
    final Color inputFieldIconColor = isDarkMode ? Colors.grey[400]! : Colors.grey;
    final Color sendIconColor = isDarkMode ? Colors.white : Colors.black;
    final Color recordingIconColor = _isRecording ? Colors.red : inputFieldIconColor;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffEB7720),
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0.0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          "Ask Us!",
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 18),
        ),
        actions: [
          // Complaint Button in the app bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: complaintButtonBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: GestureDetector(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const RaiseComplaintScreen()));
              },
              child: Row(
                children: [
                  Image.asset("assets/complaint.png", height: 24, width: 24, color: isDarkMode ? Colors.black : null),
                  const SizedBox(width: 6),
                  Text(
                    "Complaint",
                    style: GoogleFonts.poppins(
                      color: complaintButtonTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [gradientStartColor, gradientEndColor],
          ),
        ),
        child: Column(
          children: [
            // Header Text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:  [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Type or send a voice note",
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: chatHeaderTextColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "-our team is ready to assist you in real time.",
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: chatHeaderSubtitleColor),
                    ),
                  ),
                ],
              ),
            ),

            // Chat Messages
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: messages.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Center(
                        child: Text(
                          "09/04/2025",
                          style: GoogleFonts.poppins(color: dateDividerColor, fontSize: 12),
                        ),
                      ),
                    );
                  }
                  final msg = messages[index - 1];
                  return _buildMessageBubble(msg, index - 1);
                },
              ),
            ),

            // Input Field with Voicemail
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: Container(
                decoration: BoxDecoration(
                  color: inputFieldBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: GoogleFonts.poppins(color: bubbleTextColor),
                        decoration: InputDecoration(
                          hintText: "Ask your doubts with us...",
                          hintStyle: GoogleFonts.poppins(color: inputFieldHintColor),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        // Voicemail Icon
                        GestureDetector(
                          onTap: () {
                            if (_isRecording) {
                              _stopRecording();
                            } else {
                              _startRecording();
                            }
                          },
                          child: Icon(
                            _isRecording ? Icons.stop : Icons.mic,
                            color: recordingIconColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _sendMessage,
                          child: Icon(Icons.send, color: sendIconColor, size: 28),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}