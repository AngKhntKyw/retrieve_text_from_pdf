import 'dart:developer';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String extractedText = "No text extracted yet.Mingalarbar?";
  List<String> wordsToSearch = [
    'dart',
    'flutter',
    'java',
    'software developer',
  ];

  Future<bool> _checkAndRequestPermission() async {
    PermissionStatus status = await Permission.manageExternalStorage.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      // Request storage permission
      status = await Permission.manageExternalStorage.request();
    }
    return status.isGranted;
  }

  /// Open File Picker to select a PDF file
  Future<void> pickAndExtractText() async {
    try {
      //Check and request permission
      bool isPermissionGranted = await _checkAndRequestPermission();

      if (!isPermissionGranted) {
        setState(() {
          extractedText = "Permission denied. Cannot access files.";
        });
        return;
      }

      // Open file picker to select a PDF
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        // allowedExtensions: ['pdf'],
      );

      if (result != null) {
        // Get the selected file
        File file = File(result.files.single.path!);

        // Read the file as bytes
        final List<int> bytes = await file.readAsBytes();

        // Load the PDF document
        final PdfDocument pdfDocument = PdfDocument(inputBytes: bytes);

        // Extract text from the entire PDF document
        String text = PdfTextExtractor(pdfDocument).extractText();

        // Dispose of the document
        pdfDocument.dispose();

        // Update the extracted text in the UI
        setState(() {
          extractedText = text;
        });
        log(extractedText);
      } else {
        setState(() {
          extractedText = "No file selected.";
        });
      }
    } catch (e) {
      setState(() {
        extractedText = "Error occurred: $e";
      });
    }
  }

  Future<void> generateAndSavePdf() async {
    try {
      // Create a new PDF document
      PdfDocument document = PdfDocument();

      // Add a page to the document
      PdfPage page = document.pages.add();

      // Create a PDF graphics object and draw text
      page.graphics.drawString(
        'Hello World', // The text to display
        PdfStandardFont(PdfFontFamily.helvetica, 20), // Font style and size
        bounds: const Rect.fromLTWH(0, 0, 500, 50), // Position on the page
      );

      // Save the document to bytes
      List<int> bytes = document.saveSync();

      // Dispose of the document
      document.dispose();

      // Save the PDF file to the storage
      final String filePath = await _savePdfFile(bytes);
      final params = SaveFileDialogParams(sourceFilePath: filePath);
      await FlutterFileDialog.saveFile(params: params);
      log("PDF saved at: $filePath");
    } catch (e) {
      log("Error generating PDF: $e");
    }
  }

  Future<String> _savePdfFile(List<int> bytes) async {
    // Get the external storage directory
    final directory = await getExternalStorageDirectory();

    // Create the file path
    final String path = '${directory!.path}/hello_world.pdf';

    // Write the bytes to a file
    File file = File(path);
    await file.writeAsBytes(bytes, flush: true);

    return path;
  }

  void checkWords() {
    for (String word in wordsToSearch) {
      if (extractedText.toLowerCase().contains(word)) {
        log("Word found: $word");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Retrieve Texts from PDF file'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: pickAndExtractText,
                child: const Text("Pick PDF and Extract Text"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await generateAndSavePdf();
                },
                child: const Text("Generate PDF"),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: checkWords,
                child: const Text("Check Words"),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    extractedText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
