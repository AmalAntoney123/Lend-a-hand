import 'package:flutter/material.dart';
import 'package:lendahand/theme/app_theme.dart';
import '../../services/auth_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final AuthService _authService = AuthService();
  String _selectedRole = 'Commoner'; // Default role
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Add new controllers
  final _fullNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _skillsController = TextEditingController();
  String _selectedSex = 'MALE'; // Default sex

  // Add blood group options
  String _selectedBloodGroup = 'A+'; // Default blood group
  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-'
  ];

  // Add these properties after other controllers
  File? _certificateFile;
  String? _certificateFileName;

  // Add this method to handle file picking
  Future<void> _pickCertificate() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() {
          _certificateFile = File(result.files.single.path!);
          _certificateFileName = result.files.single.name;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error picking certificate'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // Heading
                      Container(
                        padding: const EdgeInsets.all(24.0),
                        child: const Text(
                          'Create an Account',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkBlue,
                          ),
                        ),
                      ),
                      // Form section
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Email and Full Name
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _emailController,
                                      decoration: InputDecoration(
                                        labelText: 'Email',
                                        prefixIcon: Icon(
                                          Icons.email_outlined,
                                          color: AppColors.secondaryYellow,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your email';
                                        }
                                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                            .hasMatch(value)) {
                                          return 'Please enter a valid email';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _fullNameController,
                                      decoration: InputDecoration(
                                        labelText: 'Full Name',
                                        prefixIcon: Icon(
                                          Icons.person,
                                          color: AppColors.secondaryYellow,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your full name';
                                        }
                                        if (value.length < 3) {
                                          return 'Name should be at least 3 characters';
                                        }
                                        if (!RegExp(r'^[a-zA-Z\s]+$')
                                            .hasMatch(value)) {
                                          return 'Name should only contain letters';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Age and Sex
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _ageController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: 'Age',
                                        prefixIcon: Icon(
                                          Icons.calendar_today,
                                          color: AppColors.secondaryYellow,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your age';
                                        }
                                        final age = int.tryParse(value);
                                        if (age == null) {
                                          return 'Please enter a valid age';
                                        }
                                        if (age < 18 || age > 100) {
                                          return 'Age must be between 18 and 100';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedSex,
                                      decoration: InputDecoration(
                                        labelText: 'Sex',
                                        prefixIcon: Icon(
                                          Icons.people,
                                          color: AppColors.secondaryYellow,
                                        ),
                                      ),
                                      items: ['MALE', 'FEMALE', 'OTHER']
                                          .map((sex) => DropdownMenuItem(
                                                value: sex,
                                                child: Text(sex),
                                              ))
                                          .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedSex = value!;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Blood Group and Phone Number
                              Row(
                                children: [
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedBloodGroup,
                                      decoration: InputDecoration(
                                        labelText: 'Blood Group',
                                        prefixIcon: Icon(
                                          Icons.bloodtype,
                                          color: AppColors.secondaryYellow,
                                        ),
                                      ),
                                      items: _bloodGroups
                                          .map((group) => DropdownMenuItem(
                                                value: group,
                                                child: Text(group),
                                              ))
                                          .toList(),
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedBloodGroup = value!;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _phoneNumberController,
                                      keyboardType: TextInputType.phone,
                                      decoration: InputDecoration(
                                        labelText: 'Phone Number',
                                        prefixIcon: Icon(
                                          Icons.phone,
                                          color: AppColors.secondaryYellow,
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter your phone number';
                                        }
                                        if (!RegExp(r'^\d{10}$')
                                            .hasMatch(value)) {
                                          return 'Enter a valid 10-digit number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Address
                              TextFormField(
                                controller: _addressController,
                                decoration: InputDecoration(
                                  labelText: 'Address',
                                  prefixIcon: Icon(
                                    Icons.home,
                                    color: AppColors.secondaryYellow,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your address';
                                  }
                                  if (value.length < 10) {
                                    return 'Address should be at least 10 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              // Skills as a text box
                              TextFormField(
                                controller: _skillsController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  labelText: 'Skills (Optional)',
                                  hintText:
                                      'Enter your skills (comma separated)',
                                  prefixIcon: Icon(
                                    Icons.psychology,
                                    color: AppColors.secondaryYellow,
                                  ),
                                  alignLabelWithHint: true,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    color: AppColors.secondaryYellow,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: AppColors.secondaryYellow,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  if (!RegExp(r'(?=.*[A-Z])').hasMatch(value)) {
                                    return 'Password must contain at least one uppercase letter';
                                  }
                                  if (!RegExp(r'(?=.*[!@#$%^&*(),.?":{}|<>])')
                                      .hasMatch(value)) {
                                    return 'Password must contain at least one special character';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Confirm Password',
                                  prefixIcon: Icon(
                                    Icons.lock_outline,
                                    color: AppColors.secondaryYellow,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: AppColors.secondaryYellow,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please confirm your password';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: _selectedRole,
                                decoration: InputDecoration(
                                  labelText: 'Role',
                                  prefixIcon: Icon(
                                    Icons.person_outline,
                                    color: AppColors.secondaryYellow,
                                  ),
                                ),
                                items: ['Coordinator', 'Volunteer', 'Commoner']
                                    .map((role) => DropdownMenuItem(
                                          value: role,
                                          child: Text(role),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedRole = value!;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              if (_selectedRole.toLowerCase() == 'coordinator')
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Certificate Upload (Optional)',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _certificateFileName ??
                                                  'No certificate selected',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color:
                                                    _certificateFileName == null
                                                        ? Colors.grey
                                                        : Colors.black,
                                              ),
                                            ),
                                          ),
                                          TextButton.icon(
                                            onPressed: _pickCertificate,
                                            icon: Icon(
                                              Icons.upload_file,
                                              color: AppColors.secondaryYellow,
                                            ),
                                            label: const Text(
                                                'Upload Certificate'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () async {
                                        if (_formKey.currentState!.validate()) {
                                          setState(() => _isLoading = true);

                                          try {
                                            final (result, error) = await _authService.registerWithEmailAndPassword(
                                              _emailController.text,
                                              _passwordController.text,
                                              _selectedRole,
                                              fullName: _fullNameController.text,
                                              address: _addressController.text,
                                              age: int.parse(_ageController.text),
                                              sex: _selectedSex,
                                              bloodGroup: _selectedBloodGroup,
                                              phoneNumber: _phoneNumberController.text,
                                              skills: _skillsController.text.isEmpty ? 'None' : _skillsController.text,
                                              certificateFile: _selectedRole.toLowerCase() == 'coordinator' ? _certificateFile : null,
                                            );

                                            if (!mounted) return;
                                            setState(() => _isLoading = false);

                                            if (error != null) {
                                              if (!mounted) return;
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(error),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            } else if (result != null) {
                                              if (!mounted) return;
                                              Navigator.pushReplacementNamed(context, '/login');
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(_selectedRole == 'Commoner' 
                                                    ? 'Registration successful! Please login.' 
                                                    : 'Registration successful! Please wait for admin approval.'),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (!mounted) return;
                                            setState(() => _isLoading = false);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Error: ${e.toString()}'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(color: Colors.white),
                                      )
                                    : const Text(
                                        'Register',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Already have an account? ',
                                    style: TextStyle(color: AppColors.darkBlue),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushReplacementNamed(
                                          context, '/login');
                                    },
                                    child: const Text(
                                      'Login',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
