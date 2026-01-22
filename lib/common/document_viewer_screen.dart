import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Uint8List
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart'; // NEW: Import the PDF viewer
import 'package:provider/provider.dart'; // Import Provider
import '../home/theme_mode_provider.dart'; // Import ThemeModeProvider


class DocumentViewerScreen extends StatelessWidget {
  final Uint8List? documentBytes;
  final bool isImage;
  final String title;

  const DocumentViewerScreen({
    super.key,
    required this.documentBytes,
    required this.isImage,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final themeMode = Provider.of<ThemeModeProvider>(context).themeMode;
    final isDarkMode = themeMode == ThemeMode.dark;

    // Define colors based on theme
    final Color backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final Color appBarColor = const Color(0xffEB7720); // Always orange
    final Color appBarIconColor = Colors.white;
    final Color appBarTextColor = Colors.white;
    final Color warningIconColor = isDarkMode ? Colors.grey[600]! : Colors.grey[400]!;
    final Color warningTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;


    return Scaffold(
      backgroundColor: backgroundColor, // Apply theme color
      appBar: AppBar(
        backgroundColor: appBarColor, // Always orange
        title: Text(
          title,
          style: GoogleFonts.poppins(color: appBarTextColor, fontSize: 18),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: appBarIconColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Center(
        child: documentBytes != null
            ? (isImage
            ? InteractiveViewer( // Allows zooming and panning for images
          child: Image.memory(
            documentBytes!,
            fit: BoxFit.contain, // Ensure image scales to fit
          ),
        )
            : // NEW: PDF Viewer integration
        SfPdfViewer.memory(
          documentBytes!,
          // You can add various properties here to control the viewer:
          // pageSpacing: 8,
          // enableDoubleTapZooming: true,
          // enableHyperlinkNavigation: true,
          // initialZoomLevel: 1.0,
          // controller: PdfViewerController(), // If you need programmatic control
          // onDocumentLoadFailed: (details) {
          //   print('PDF load failed: ${details.description}');
          //   // Optionally show an error message to the user
          // },
          // onDocumentLoaded: (details) {
          //   print('PDF loaded successfully!');
          // },
        )
        )
            : Column( // Display if no document is available
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber,
              color: warningIconColor, // Apply theme color
              size: 80,
            ),
            const SizedBox(height: 20),
            Text(
              'No document available',
              style: GoogleFonts.poppins(
                  fontSize: 18, color: warningTextColor), // Apply theme color
            ),
          ],
        ),
      ),
    );
  }
}
