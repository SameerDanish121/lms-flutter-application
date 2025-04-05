import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:lmsv2/api/ApiConfig.dart';
import 'dart:convert';
import '../../Theme/theme.dart';
import '../../alerts/custom_alerts.dart';
class CreateCourseContentScreen extends StatefulWidget {
  final String teacherId;

  const CreateCourseContentScreen({Key? key, required this.teacherId}) : super(key: key);

  @override
  _CreateCourseContentScreenState createState() => _CreateCourseContentScreenState();
}
class _CreateCourseContentScreenState extends State<CreateCourseContentScreen> {
  List<dynamic> courses = [];
  bool isLoading = true;
  bool isSubmitting = false;
  String? selectedCourseId;
  String? selectedType;
  int? selectedWeek;
  File? selectedFile;
  List<Map<String, dynamic>> mcqs = [];
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers
  final List<TextEditingController> _questionControllers = [];
  final List<List<TextEditingController>> _optionControllers = [];
  final List<TextEditingController> _answerControllers = [];
  final List<TextEditingController> _pointControllers = [];

  @override
  void initState() {
    super.initState();
    _fetchActiveCourses();
  }

  Future<void> _fetchActiveCourses() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.apiBaseUrl}Teachers/active/courses?teacher_id=${widget.teacherId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          courses = data['courses'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load courses');
      }
    } catch (e) {
      setState(() => isLoading = false);
      CustomAlert.error(context, 'Error', 'Failed to load courses: ${e.toString()}');
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null) {
        setState(() {
          selectedFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      CustomAlert.error(context, 'Error', 'Failed to pick file: ${e.toString()}');
    }
  }

  void _addMcqQuestion() {
    setState(() {
      mcqs.add({
        'qNO': mcqs.length + 1,
        'question_text': '',
        'points': '',
        'option1': '',
        'option2': '',
        'option3': '',
        'option4': '',
        'Answer': '',
      });
      _questionControllers.add(TextEditingController());
      _optionControllers.add([
        TextEditingController(),
        TextEditingController(),
        TextEditingController(),
        TextEditingController(),
      ]);
      _answerControllers.add(TextEditingController());
      _pointControllers.add(TextEditingController());
    });
  }

  void _removeMcqQuestion(int index) {
    setState(() {
      mcqs.removeAt(index);
      _questionControllers.removeAt(index);
      _optionControllers.removeAt(index);
      _answerControllers.removeAt(index);
      _pointControllers.removeAt(index);
      // Update question numbers
      for (int i = 0; i < mcqs.length; i++) {
        mcqs[i]['qNO'] = i + 1;
      }
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedType == 'MCQS' && mcqs.isEmpty) {
      CustomAlert.error(context, 'Error', 'Please add at least one MCQ question');
      return;
    }

    // Validate MCQ answers if type is MCQS
    if (selectedType == 'MCQS') {
      for (var mcq in mcqs) {
        if (mcq['Answer'] == null || mcq['Answer'].isEmpty) {
          CustomAlert.error(context, 'Error', 'Please select correct answer for all questions');
          return;
        }
      }
    }

    setState(() => isSubmitting = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.apiBaseUrl}Teachers/create/course_content'),
      );
      request.fields.addAll({
        'offered_course_id': selectedCourseId!,
        'week': selectedWeek.toString(),
        'type': selectedType!,
      });
      if (selectedType != 'MCQS') {
        if (selectedFile == null) {
          throw Exception('File is required for ${selectedType!}');
        }
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          selectedFile!.path,
        ));
      } else {
        // Prepare MCQs data as a List<Map>
        // final List<Map<String, dynamic>> mcqsData = mcqs.map((mcq) {
        //   return {
        //     'qNO': mcq['qNO'],
        //     'question_text': mcq['question_text'],
        //     'points': mcq['points'],
        //     'option1': mcq['option1'],
        //     'option2': mcq['option2'],
        //     'option3': mcq['option3'],
        //     'option4': mcq['option4'],
        //     'Answer': mcq['Answer'],
        //   };
        // }).toList();
        //
        // // Convert to JSON string and add to request
        // request.fields['MCQS'] = json.encode(mcqsData);
        for (int i = 0; i < mcqs.length; i++) {
          request.fields['MCQS[$i][qNO]'] = mcqs[i]['qNO'].toString();
          request.fields['MCQS[$i][question_text]'] = mcqs[i]['question_text'];
          request.fields['MCQS[$i][points]'] = mcqs[i]['points'].toString();
          request.fields['MCQS[$i][option1]'] = mcqs[i]['option1'];
          request.fields['MCQS[$i][option2]'] = mcqs[i]['option2'];
          request.fields['MCQS[$i][option3]'] = mcqs[i]['option3'];
          request.fields['MCQS[$i][option4]'] = mcqs[i]['option4'];
          request.fields['MCQS[$i][Answer]'] = mcqs[i]['Answer'];
        }
      }

      print('Sending request with fields: ${request.fields}');
      if (request.files.isNotEmpty) {
        print('With file: ${request.files.first.field}');
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      final decodedResponse = json.decode(responseData);

      print('API Response: $decodedResponse');

      if (response.statusCode == 200) {

       CustomAlert.success(
            context,
            decodedResponse['message'] ?? 'Course content created successfully!'
        );
       await Future.delayed(Duration(seconds: 4));
        _resetForm();
      } else {
        throw Exception(decodedResponse['error'] ?? decodedResponse['message'] ?? 'Failed to create content');
      }
    } catch (e) {
      print('Error: $e');
      CustomAlert.error(context, 'Error', e.toString());
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  void _resetForm() {
    setState(() {
      // Reset all form fields
      selectedCourseId = null;
      selectedType = null;
      selectedWeek = null;
      selectedFile = null;
      mcqs.clear();

      // Clear all controllers
      for (var controller in _questionControllers) {
        controller.clear();
      }
      for (var options in _optionControllers) {
        for (var controller in options) {
          controller.clear();
        }
      }
      for (var controller in _answerControllers) {
        controller.clear();
      }
      for (var controller in _pointControllers) {
        controller.clear();
      }

      // Refresh course list
      _fetchActiveCourses();
    });
  }

  @override
  void dispose() {
    for (var controller in _questionControllers) {
      controller.dispose();
    }
    for (var options in _optionControllers) {
      for (var controller in options) {
        controller.dispose();
      }
    }
    for (var controller in _answerControllers) {
      controller.dispose();
    }
    for (var controller in _pointControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildCourseCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.8),
              AppTheme.backgroundColor.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
            'Current Session',
            style: AppTheme.bodyStyle.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Fall-2025',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Divider(color: Colors.white.withOpacity(0.3),),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Courses',
                  style: AppTheme.bodyStyle.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    courses.length.toString(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurpleAccent,
                    ),
                  ),
                ),
              ],
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Select Course',
        labelStyle: AppTheme.bodyStyle,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      value: selectedCourseId,
      items: courses.map((course) {
        return DropdownMenuItem<String>(
          value: course['offered_course_id'].toString(),
          child: Text(
            course['course_name'],
            style: AppTheme.bodyStyle,
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedCourseId = value;
        });
      },
      validator: (value) => value == null ? 'Please select a course' : null,
      style: AppTheme.bodyStyle,
      icon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
    );
  }

  Widget _buildSectionsInfo() {
    if (selectedCourseId == null) return SizedBox();

    final course = courses.firstWhere(
          (course) => course['offered_course_id'].toString() == selectedCourseId,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 12),
        Text(
          'Teaching Sections:',
          style: AppTheme.bodyStyle.copyWith(
            fontWeight: FontWeight.w500,
            color: AppTheme.textColor.withOpacity(0.8),
          ),
        ),
        SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: course['sections'].map<Widget>((section) {
            return Chip(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              label: Text(
                section['section_name'],
                style: AppTheme.bodyStyle.copyWith(
                  color: AppTheme.primaryColor,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.2)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWeekDropdown() {
    return DropdownButtonFormField<int>(
      decoration: InputDecoration(
        labelText: 'Week Number',
        labelStyle: AppTheme.bodyStyle,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      value: selectedWeek,
      items: List.generate(16, (index) => index + 1).map((week) {
        return DropdownMenuItem<int>(
          value: week,
          child: Text(
            'Week $week',
            style: AppTheme.bodyStyle,
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          selectedWeek = value;
        });
      },
      validator: (value) => value == null ? 'Please select a week' : null,
      style: AppTheme.bodyStyle,
      icon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
    );
  }

  Widget _buildTypeDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Content Type',
        labelStyle: AppTheme.bodyStyle,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryColor),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      value: selectedType,
      items: [
        DropdownMenuItem(
          value: 'Quiz',
          child: Text('Quiz', style: AppTheme.bodyStyle),
        ),
        DropdownMenuItem(
          value: 'Assignment',
          child: Text('Assignment', style: AppTheme.bodyStyle),
        ),
        DropdownMenuItem(
          value: 'Notes',
          child: Text('Notes', style: AppTheme.bodyStyle),
        ),
        if (selectedCourseId != null &&
            courses.firstWhere((course) => course['offered_course_id'].toString() == selectedCourseId)['course_of_lab'] == 'Yes')
          DropdownMenuItem(
            value: 'LabTask',
            child: Text('Lab Task', style: AppTheme.bodyStyle),
          ),
        DropdownMenuItem(
          value: 'MCQS',
          child: Text('MCQs', style: AppTheme.bodyStyle),
        ),
      ],
      onChanged: (value) {
        setState(() {
          selectedType = value;
          if (value != 'MCQS') {
            mcqs.clear();
          }
        });
      },
      validator: (value) => value == null ? 'Please select content type' : null,
      style: AppTheme.bodyStyle,
      icon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryColor),
    );
  }

  Widget _buildFilePicker() {
    return Column(
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            elevation: 2,
          ),
          onPressed: _pickFile,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.attach_file, size: 20),
              SizedBox(width: 8),
              Text('Select File (PDF/DOC)'),
            ],
          ),
        ),
        SizedBox(height: 12),
        if (selectedFile != null)
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.2)),
            ),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.insert_drive_file, color: AppTheme.primaryColor),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedFile!.path.split('/').last,
                      style: AppTheme.bodyStyle,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() => selectedFile = null);
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMcqForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            elevation: 2,
          ),
          onPressed: _addMcqQuestion,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 20),
              SizedBox(width: 8),
              Text('Add MCQ Question'),
            ],
          ),
        ),
        SizedBox(height: 16),
        if (mcqs.isEmpty)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[800]),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please add at least one MCQ question',
                    style: TextStyle(color: Colors.orange[800]),
                  ),
                ),
              ],
            ),
          ),
        ...List.generate(mcqs.length, (index) {
          return Card(
            elevation: 2,
            margin: EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.2)),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Question ${index + 1}',
                        style: AppTheme.subHeadingStyle,
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeMcqQuestion(index),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  TextFormField(
                    controller: _questionControllers[index],
                    decoration: InputDecoration(
                      labelText: 'Question Text',
                      labelStyle: AppTheme.bodyStyle,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.primaryColor),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    style: AppTheme.bodyStyle,
                    onChanged: (value) => mcqs[index]['question_text'] = value,
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _pointControllers[index],
                    decoration: InputDecoration(
                      labelText: 'Points',
                      labelStyle: AppTheme.bodyStyle,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.primaryColor),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    style: AppTheme.bodyStyle,
                    keyboardType: TextInputType.number,
                    onChanged: (value) => mcqs[index]['points'] = value,
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  SizedBox(height: 16),
                  Text('Options:', style: AppTheme.bodyStyle.copyWith(
                    fontWeight: FontWeight.w500,
                  )),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Select the correct answer by clicking the radio button',
                      style: TextStyle(
                        color: Colors.green[800],
                        fontSize: 12,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  ...List.generate(4, (optionIndex) {
                    return Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _optionControllers[index][optionIndex],
                              decoration: InputDecoration(
                                labelText: 'Option ${optionIndex + 1}',
                                labelStyle: AppTheme.bodyStyle,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppTheme.primaryColor),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              style: AppTheme.bodyStyle,
                              onChanged: (value) {
                                setState(() {
                                  mcqs[index]['option${optionIndex + 1}'] = value;
                                  // Update answer if this was the selected option
                                  if (_answerControllers[index].text == value) {
                                    mcqs[index]['Answer'] = value;
                                  }
                                });
                              },
                              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          SizedBox(width: 8),
                          Tooltip(
                            message: 'Mark as correct answer',
                            child: Radio<String>(
                              value: mcqs[index]['option${optionIndex + 1}'],
                              groupValue: mcqs[index]['Answer'],
                              onChanged: (value) {
                                setState(() {
                                  mcqs[index]['Answer'] = value!;
                                  _answerControllers[index].text = value;
                                });
                              },
                              fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                                if (states.contains(MaterialState.selected)) {
                                  return AppTheme.primaryColor;
                                }
                                return Colors.grey;
                              }),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (mcqs[index]['Answer'] == null || mcqs[index]['Answer'].isEmpty)
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Please select the correct answer',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Center(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
          elevation: 2,
        ),
        onPressed: isSubmitting ? null : _submitForm,
        child: isSubmitting
            ? SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : Text(
          'Create Content',
          style: AppTheme.bodyStyle.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.themeData,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text('Create Course Content', style: AppTheme.headingStyle.copyWith(color: Colors.white)),
          backgroundColor: AppTheme.primaryColor,
          elevation: 0,
          centerTitle: true,
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
            : SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCourseCard(),
                SizedBox(height: 24),
                _buildCourseDropdown(),
                SizedBox(height: 16),
                _buildSectionsInfo(),
                SizedBox(height: 24),
                _buildWeekDropdown(),
                SizedBox(height: 16),
                _buildTypeDropdown(),
                SizedBox(height: 24),
                if (selectedType != null && selectedType != 'MCQS') _buildFilePicker(),
                if (selectedType == 'MCQS') _buildMcqForm(),
                SizedBox(height: 32),
                _buildSubmitButton(),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}