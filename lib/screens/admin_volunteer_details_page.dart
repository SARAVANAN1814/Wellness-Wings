import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import '../services/api_service.dart';

class AdminVolunteerDetailsPage extends StatefulWidget {
  final Map<String, dynamic> volunteer;

  const AdminVolunteerDetailsPage({super.key, required this.volunteer});

  @override
  _AdminVolunteerDetailsPageState createState() => _AdminVolunteerDetailsPageState();
}

class _AdminVolunteerDetailsPageState extends State<AdminVolunteerDetailsPage> {
  final ApiService _apiService = ApiService();
  bool _isProcessing = false;
  bool _isAnalysing = false;
  Map<String, dynamic>? _analysisResult;

  // ============================================================
  //  WMCS — Weighted Multi-Criteria Scoring Algorithm v2.0
  //  Levels: L1 (Image Quality), L2 (Cross-Validation), L3 (OCR)
  // ============================================================

  Future<Map<String, dynamic>> _analyseVolunteer() async {
    final v = widget.volunteer;
    int totalScore = 0;
    List<Map<String, dynamic>> breakdown = [];

    // ---- LEVEL 1: Image Quality Analysis (20 pts) ----
    int imgQualityScore = 0;
    String imgQualityDetail = '';
    final idCardBase64 = v['id_card_path']?.toString() ?? '';

    if (idCardBase64.isNotEmpty) {
      try {
        final Uint8List imageBytes = base64Decode(idCardBase64);
        final int fileSizeKB = (imageBytes.length / 1024).round();

        // Decode image to check resolution
        final img.Image? decoded = img.decodeImage(imageBytes);
        if (decoded != null) {
          final int width = decoded.width;
          final int height = decoded.height;
          final double aspectRatio = width / height;

          // Score resolution (min 300x200 for readable doc)
          if (width >= 600 && height >= 400) {
            imgQualityScore += 8;
            imgQualityDetail += '✅ Resolution: ${width}x$height (Good)\n';
          } else if (width >= 300 && height >= 200) {
            imgQualityScore += 4;
            imgQualityDetail += '⚠️ Resolution: ${width}x$height (Low)\n';
          } else {
            imgQualityDetail += '❌ Resolution: ${width}x$height (Too small)\n';
          }

          // Score file size (5KB-5MB is normal for a doc photo)
          if (fileSizeKB >= 5 && fileSizeKB <= 5000) {
            imgQualityScore += 6;
            imgQualityDetail += '✅ File size: ${fileSizeKB}KB (Normal)\n';
          } else if (fileSizeKB < 5) {
            imgQualityDetail += '❌ File size: ${fileSizeKB}KB (Suspiciously small)\n';
          } else {
            imgQualityScore += 3;
            imgQualityDetail += '⚠️ File size: ${fileSizeKB}KB (Very large)\n';
          }

          // Score aspect ratio (ID cards: ~1.4-1.8, portrait docs: ~0.6-0.8)
          if ((aspectRatio >= 1.2 && aspectRatio <= 2.0) || (aspectRatio >= 0.5 && aspectRatio <= 0.85)) {
            imgQualityScore += 6;
            imgQualityDetail += '✅ Aspect ratio: ${aspectRatio.toStringAsFixed(2)} (Document-like)';
          } else {
            imgQualityScore += 2;
            imgQualityDetail += '⚠️ Aspect ratio: ${aspectRatio.toStringAsFixed(2)} (Unusual for ID)';
          }
        } else {
          imgQualityDetail = '❌ Could not decode image data';
        }
      } catch (e) {
        imgQualityDetail = '❌ Corrupt or invalid image data';
      }
    } else {
      imgQualityDetail = '❌ No ID photo uploaded';
    }
    totalScore += imgQualityScore;
    breakdown.add({'label': '📸 L1: Image Quality', 'score': imgQualityScore, 'max': 20, 'detail': imgQualityDetail.trim()});

    // ---- LEVEL 2: ID Format Cross-Validation (15 pts) ----
    int idFormatScore = 0;
    String idFormatDetail = '';
    final idType = v['id_type']?.toString() ?? '';
    final idNumber = (v['verification_id']?.toString() ?? '').toUpperCase().trim();

    if (idType.isNotEmpty && idNumber.isNotEmpty) {
      bool valid = false;
      String expectedFormat = '';
      if (idType == 'Aadhar') {
        valid = RegExp(r'^\d{12}$').hasMatch(idNumber);
        expectedFormat = '12 digits';
      } else if (idType == 'PAN') {
        valid = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(idNumber);
        expectedFormat = 'ABCDE1234F';
      } else if (idType == 'Voter ID') {
        valid = RegExp(r'^[A-Z]{3}[0-9]{7}$').hasMatch(idNumber);
        expectedFormat = 'ABC1234567';
      } else if (idType == 'Driving License') {
        valid = RegExp(r'^[A-Z]{2}\d{2}\s?\d{4}\d{7}$').hasMatch(idNumber);
        expectedFormat = 'TN0120191234567';
      }

      if (valid) {
        idFormatScore = 15;
        idFormatDetail = '✅ $idType number "$idNumber" matches expected format ($expectedFormat)';
      } else {
        idFormatDetail = '❌ $idType number "$idNumber" does NOT match expected format ($expectedFormat)';
      }
    } else {
      idFormatDetail = '❌ Missing ID type or number';
    }
    totalScore += idFormatScore;
    breakdown.add({'label': '🔍 L2: Format Validation', 'score': idFormatScore, 'max': 15, 'detail': idFormatDetail});

    // ---- LEVEL 3: OCR Text Extraction & Matching (30 pts) ----
    // Checks BOTH the ID number AND the volunteer's name in the document
    int ocrScore = 0;
    String ocrDetail = '';
    final String volunteerName = (v['full_name']?.toString() ?? '').trim();

    if (idCardBase64.isNotEmpty && idNumber.isNotEmpty) {
      try {
        final Uint8List imageBytes = base64Decode(idCardBase64);

        // Write to temp file for ML Kit
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/temp_id_analysis.jpg');
        await tempFile.writeAsBytes(imageBytes);

        // Run OCR
        final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
        final inputImage = InputImage.fromFilePath(tempFile.path);
        final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
        await textRecognizer.close();

        // Clean up temp file
        if (await tempFile.exists()) await tempFile.delete();

        final String extractedTextRaw = recognizedText.text;
        final String extractedTextClean = extractedTextRaw.toUpperCase().replaceAll(RegExp(r'\s+'), '');
        final String cleanIdNumber = idNumber.replaceAll(RegExp(r'\s+'), '');

        if (extractedTextRaw.isNotEmpty) {
          ocrDetail += '📝 Extracted ${recognizedText.blocks.length} text blocks\n';

          // --- Part A: ID Number Verification (20 pts) ---
          if (extractedTextClean.contains(cleanIdNumber)) {
            ocrScore += 20;
            ocrDetail += '✅ ID number "$idNumber" FOUND in document!\n';
          } else {
            // Partial matching
            int matchCount = 0;
            for (int i = 0; i < cleanIdNumber.length; i++) {
              final end = (i + 4).clamp(0, cleanIdNumber.length);
              if (end > i && extractedTextClean.contains(cleanIdNumber.substring(i, end))) {
                matchCount++;
              }
            }
            double matchRatio = cleanIdNumber.isNotEmpty ? matchCount / cleanIdNumber.length : 0;
            if (matchRatio > 0.5) {
              ocrScore += 12;
              ocrDetail += '⚠️ ID partial match (${(matchRatio * 100).round()}%) — partially visible\n';
            } else {
              ocrDetail += '❌ ID number NOT found in document\n';
              ocrDetail += '🚨 RISK: Document may not match entered ID\n';
            }
          }

          // --- Part B: Name Verification (10 pts) ---
          if (volunteerName.isNotEmpty) {
            final String extractedUpper = extractedTextRaw.toUpperCase();
            final String nameUpper = volunteerName.toUpperCase();
            final List<String> nameParts = nameUpper.split(RegExp(r'\s+')).where((p) => p.length >= 2).toList();

            if (extractedUpper.contains(nameUpper)) {
              // Full name found
              ocrScore += 10;
              ocrDetail += '✅ Name "$volunteerName" FOUND in document!\n';
            } else {
              // Check individual name parts (first/last name)
              int partsFound = 0;
              List<String> matchedParts = [];
              for (final part in nameParts) {
                if (extractedUpper.contains(part)) {
                  partsFound++;
                  matchedParts.add(part);
                }
              }
              if (nameParts.isNotEmpty && partsFound >= (nameParts.length * 0.5).ceil()) {
                ocrScore += 6;
                ocrDetail += '⚠️ Partial name match: ${matchedParts.join(", ")} found (${partsFound}/${nameParts.length} parts)\n';
              } else if (partsFound > 0) {
                ocrScore += 3;
                ocrDetail += '⚠️ Weak name match: only "${matchedParts.join(", ")}" found\n';
              } else {
                ocrDetail += '❌ Name "$volunteerName" NOT found in document\n';
                ocrDetail += '🚨 RISK: Name on ID may not match registered name\n';
              }
            }
          } else {
            ocrDetail += '⚠️ No volunteer name to verify\n';
          }

          // Overall OCR verdict
          if (ocrScore >= 25) {
            ocrDetail += '🔒 Document verified: ID + Name AUTHENTIC';
          } else if (ocrScore >= 15) {
            ocrDetail += '🔶 Partial verification — manual review advised';
          } else {
            ocrDetail += '🚨 Document authenticity could NOT be confirmed';
          }
        } else {
          ocrDetail = '⚠️ OCR could not extract any text from the image\n';
          ocrDetail += '📋 Possible reasons: blurry photo, handwritten ID, or non-standard format';
          ocrScore = 3;
        }
      } catch (e) {
        ocrDetail = '⚠️ OCR analysis failed: ${e.toString().split('\n').first}\n';
        ocrDetail += '📋 Manual verification recommended';
        ocrScore = 0;
      }
    } else {
      ocrDetail = '❌ Cannot perform OCR — missing ID photo or ID number';
    }
    totalScore += ocrScore;
    breakdown.add({'label': '🤖 L3: OCR Document Scan', 'score': ocrScore, 'max': 30, 'detail': ocrDetail.trim()});

    // ---- Interview / Experience (25 pts) ----
    final hasExperience = v['has_experience'] == true;
    int contentScore = 0;
    String contentDetail = '';

    if (hasExperience) {
      final details = v['experience_details']?.toString() ?? '';
      if (details.length >= 50) {
        contentScore = 25;
        contentDetail = '✅ Detailed experience (${details.length} chars)';
      } else if (details.length >= 20) {
        contentScore = 15;
        contentDetail = '⚠️ Brief experience (${details.length} chars)';
      } else {
        contentScore = 5;
        contentDetail = '❌ Very short experience (${details.length} chars)';
      }
    } else {
      Map<String, dynamic>? answers;
      if (v['interview_answers'] is Map) {
        answers = Map<String, dynamic>.from(v['interview_answers']);
      } else if (v['interview_answers'] is String) {
        try { answers = jsonDecode(v['interview_answers']); } catch (_) {}
      }
      if (answers != null && answers.isNotEmpty) {
        final idealAnswers = {
          '1. Have you ever been involved in any criminal activity or legal disputes?': 'No, never',
          '2. Do you formally consent to a thorough background check of your provided documents?': 'Yes, I consent',
          '3. In case of a medical emergency during a visit, what is your first point of action?': 'Call 108/Emergency Services immediately',
          '4. Can you guarantee availability for at least 5 hours per week for our community?': 'Yes, definitely',
          '5. Do you have any prior experience or certifications in providing elderly care or first aid?': 'Yes, I am certified',
        };
        final pointsMap = {0: 7, 1: 5, 2: 5, 3: 5, 4: 3};
        int idx = 0;
        int matched = 0;
        for (var entry in idealAnswers.entries) {
          final userAnswer = answers[entry.key]?.toString() ?? '';
          if (userAnswer == entry.value) {
            contentScore += pointsMap[idx] ?? 0;
            matched++;
          } else if (idx == 2 && userAnswer.isNotEmpty) {
            contentScore += 2;
          } else if (idx == 3 && userAnswer.contains('Maybe')) {
            contentScore += 2;
          } else if (idx == 4 && userAnswer.contains('experience')) {
            contentScore += 2;
          }
          idx++;
        }
        contentDetail = '📝 Interview: $matched/5 ideal answers';
      } else {
        contentDetail = '❌ No interview answers found';
      }
    }
    totalScore += contentScore;
    breakdown.add({
      'label': hasExperience ? '💼 Experience Quality' : '📋 Interview Answers',
      'score': contentScore, 'max': 25, 'detail': contentDetail,
    });

    // ---- Profile Completeness (10 pts) ----
    int profileScore = 0;
    List<String> missing = [];
    if ((v['full_name']?.toString() ?? '').isNotEmpty) profileScore += 2; else missing.add('Name');
    if ((v['email']?.toString() ?? '').isNotEmpty) profileScore += 2; else missing.add('Email');
    if ((v['phone_number']?.toString() ?? '').isNotEmpty) profileScore += 2; else missing.add('Phone');
    if ((v['place']?.toString() ?? '').isNotEmpty) profileScore += 2; else missing.add('Location');
    if (v['price_per_hour'] != null) profileScore += 2; else missing.add('Price');
    totalScore += profileScore;
    breakdown.add({
      'label': '👤 Profile Completeness',
      'score': profileScore, 'max': 10,
      'detail': missing.isEmpty ? '✅ All fields complete' : '⚠️ Missing: ${missing.join(", ")}',
    });

    // ---- Profile Photo (5 pts) ----
    final hasPhoto = v['profile_picture'] != null && v['profile_picture'].toString().isNotEmpty;
    final photoScore = hasPhoto ? 5 : 0;
    totalScore += photoScore;
    breakdown.add({'label': '📷 Profile Photo', 'score': photoScore, 'max': 5, 'detail': hasPhoto ? '✅ Present' : '⚠️ Not uploaded'});

    // ---- FINAL RECOMMENDATION ----
    String recommendation;
    Color recColor;
    IconData recIcon;
    if (totalScore >= 70) {
      recommendation = 'Recommend: APPROVE';
      recColor = Colors.green;
      recIcon = Icons.verified;
    } else if (totalScore >= 50) {
      recommendation = 'Review Carefully';
      recColor = Colors.orange;
      recIcon = Icons.warning_amber;
    } else {
      recommendation = 'Recommend: REJECT';
      recColor = Colors.red;
      recIcon = Icons.dangerous;
    }

    return {
      'totalScore': totalScore,
      'breakdown': breakdown,
      'recommendation': recommendation,
      'recColor': recColor,
      'recIcon': recIcon,
    };
  }

  Future<void> _runAnalysis() async {
    setState(() => _isAnalysing = true);
    try {
      final result = await _analyseVolunteer();
      if (mounted) {
        setState(() {
          _analysisResult = result;
          _isAnalysing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalysing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _approve() async {
    setState(() => _isProcessing = true);
    final result = await _apiService.approveVolunteer(widget.volunteer['id']);
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Volunteer Approved!'), backgroundColor: Colors.green));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: Colors.red));
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _reject() async {
    setState(() => _isProcessing = true);
    final result = await _apiService.rejectVolunteer(widget.volunteer['id']);
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Volunteer Rejected!'), backgroundColor: Colors.orange));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: Colors.red));
      setState(() => _isProcessing = false);
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard() {
    if (_analysisResult == null) return const SizedBox.shrink();
    final result = _analysisResult!;
    final int score = result['totalScore'];
    final List<Map<String, dynamic>> breakdown = result['breakdown'];
    final String rec = result['recommendation'];
    final Color recColor = result['recColor'];
    final IconData recIcon = result['recIcon'];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [recColor.withOpacity(0.1), recColor.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: recColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(recIcon, color: recColor, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rec, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: recColor)),
                    Text('Trust Score: $score / 100', style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: score / 100.0,
              minHeight: 14,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(recColor),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Detailed Analysis Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(thickness: 1.5),
          ...breakdown.map((item) => Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item['label'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: item['score'] >= item['max'] * 0.7
                            ? Colors.green.shade100
                            : item['score'] >= item['max'] * 0.4
                                ? Colors.orange.shade100
                                : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${item['score']} / ${item['max']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: item['score'] >= item['max'] * 0.7 ? Colors.green.shade800 : item['score'] >= item['max'] * 0.4 ? Colors.orange.shade800 : Colors.red.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(item['detail'], style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.4)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.volunteer;
    return Scaffold(
      appBar: AppBar(
        title: Text(v['full_name'] ?? 'Details', style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo.shade900,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Personal Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const Divider(),
            _buildInfoRow('Name', v['full_name'] ?? ''),
            _buildInfoRow('Gender', v['gender'] ?? ''),
            _buildInfoRow('Email', v['email'] ?? ''),
            _buildInfoRow('Phone', v['phone_number']?.toString() ?? ''),
            _buildInfoRow('Location', '${v['place']}, ${v['state']}, ${v['country']}'),
            const SizedBox(height: 20),
            
            const Text('Professional Background', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const Divider(),
            _buildInfoRow('Price/Hour', '₹${v['price_per_hour']}'),
            _buildInfoRow('Experienced?', v['has_experience'] == true ? 'Yes' : 'No'),
            if (v['has_experience'] == true) _buildInfoRow('Details', v['experience_details'] ?? 'N/A'),
            const SizedBox(height: 20),
            
            const Text('Interview Answers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const Divider(),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
              child: Text(
                v['interview_answers'] is Map 
                  ? (v['interview_answers'] as Map).entries.map((e) => "${e.key}\nAns: ${e.value}").join("\n\n")
                  : (v['interview_answers']?.toString() ?? 'No answers provided.'),
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 20),
            
            const Text('ID Proof (Government ID)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const Divider(),
            _buildInfoRow('ID Type', v['id_type'] ?? 'N/A'),
            _buildInfoRow('ID Number', v['verification_id'] ?? 'N/A'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: v['id_card_path'] != null 
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(base64Decode(v['id_card_path']), fit: BoxFit.cover,
                      errorBuilder: (c,e,s) => const Center(child: Text('Image Error'))),
                  )
                : const Center(child: Text('No Image Uploaded')),
            ),
            const SizedBox(height: 24),

            // --- ANALYSE BUTTON ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _isAnalysing
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.document_scanner, size: 24),
                label: Text(
                  _isAnalysing ? 'Scanning Document...' : '🔍 Analyse Volunteer (L1+L2+L3)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                onPressed: _isAnalysing ? null : _runAnalysis,
              ),
            ),

            // --- ANALYSIS RESULT CARD ---
            _buildAnalysisCard(),

            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _isProcessing ? null : _reject,
                    child: const Text('REJECT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _isProcessing ? null : _approve,
                    child: _isProcessing 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('APPROVE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
