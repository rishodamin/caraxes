import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/location_model.dart';
import '../../services/location_service.dart';

class SOSPage extends StatefulWidget {
  const SOSPage({super.key});

  @override
  State<SOSPage> createState() => _SOSPageState();
}

class _SOSPageState extends State<SOSPage> {
  final _formKey = GlobalKey<FormState>();
  final LocationService _locationService = LocationService();

  final _peopleController = TextEditingController();
  final _contactController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedDamageType;
  String? _selectedUrgency;
  
  List<LocationModel> _locations = [];
  LocationModel? _selectedLocation;
  bool _isLoading = false;

  final List<String> _damageTypes = [
    'Flood',
    'Road Block',
    'Bridge Damage',
    'Building Collapse',
    'Landslide',
    'Fire',
    'Power Outage',
    'Other'
  ];

  final List<String> _urgencyLevels = [
    'Low',
    'Medium',
    'High',
    'Critical'
  ];

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  @override
  void dispose() {
    _peopleController.dispose();
    _contactController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final locations = await _locationService.getLocations();
      setState(() {
        _locations = locations;
        if (_locations.isNotEmpty) {
          _pickRandomLocation();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading locations: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _pickRandomLocation() {
    if (_locations.isNotEmpty) {
      final random = Random();
      final index = random.nextInt(_locations.length);
      setState(() {
        _selectedLocation = _locations[index];
      });
    }
  }

  Future<void> _submitSOS() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a location first.')),
      );
      return;
    }

    if (_selectedDamageType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a damage type.')),
      );
      return;
    }

    if (_selectedUrgency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an urgency level.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User is not authenticated.');
      }

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final userName = userDoc.data()?['name'] ?? 'Unknown User';

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final sosId = 'SOS_$timestamp';

      final sosData = {
        "sos_id": sosId,
        "uid": user.uid,
        "user_name": userName,
        "location_id": _selectedLocation!.id,
        "latitude": _selectedLocation!.latitude,
        "longitude": _selectedLocation!.longitude,
        "people_affected": int.parse(_peopleController.text.trim()),
        "damage_type": _selectedDamageType,
        "urgency": _selectedUrgency,
        "contact_number": _contactController.text.trim(),
        "additional_notes": _notesController.text.trim(),
        "status": "pending",
        "created_at": FieldValue.serverTimestamp()
      };

      await FirebaseFirestore.instance.collection('sos').doc(sosId).set(sosData);

      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit SOS: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('SOS Sent Successfully'),
        content: const Text(
            'Your emergency request has been submitted.\nRescue teams will be able to view your request.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Reset the form
              _formKey.currentState?.reset();
              _peopleController.clear();
              _contactController.clear();
              _notesController.clear();
              setState(() {
                _selectedDamageType = null;
                _selectedUrgency = null;
                _pickRandomLocation();
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Emergency Request'),
        backgroundColor: Colors.red.shade800,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildWarningCard(),
                  const SizedBox(height: 24),
                  _buildLocationSection(),
                  const SizedBox(height: 24),
                  _buildPeopleAffectedField(),
                  const SizedBox(height: 16),
                  _buildDamageTypeDropdown(),
                  const SizedBox(height: 16),
                  _buildUrgencyDropdown(),
                  const SizedBox(height: 16),
                  _buildContactNumberField(),
                  const SizedBox(height: 16),
                  _buildAdditionalNotesField(),
                  const SizedBox(height: 32),
                  _buildSubmitButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Submitting...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWarningCard() {
    return Card(
      color: Colors.red.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.shade200),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Emergency Assistance Request',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Use this feature only when immediate help is required. Your request will be visible to rescue teams.',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Location',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (_selectedLocation != null) ...[
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Location ID: ${_selectedLocation!.id}'),
                        Text('Name: ${_selectedLocation!.name}'),
                        Text('Latitude: ${_selectedLocation!.latitude.toStringAsFixed(6)}'),
                        Text('Longitude: ${_selectedLocation!.longitude.toStringAsFixed(6)}'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ] else if (_isLoading) ...[
              const Center(child: Text('Loading location data...')),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _pickRandomLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('Change Location (Demo)'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeopleAffectedField() {
    return TextFormField(
      controller: _peopleController,
      decoration: const InputDecoration(
        labelText: 'Number of People Affected',
        hintText: 'e.g. 5',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.people),
      ),
      keyboardType: TextInputType.number,
      enabled: !_isLoading,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter the number of people affected';
        }
        final number = int.tryParse(value);
        if (number == null || number <= 0) {
          return 'Please enter a valid number greater than 0';
        }
        return null;
      },
    );
  }

  Widget _buildDamageTypeDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Type of Damage',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.dangerous),
      ),
      value: _selectedDamageType,
      items: _damageTypes.map((type) {
        return DropdownMenuItem(
          value: type,
          child: Text(type),
        );
      }).toList(),
      onChanged: _isLoading
          ? null
          : (value) {
              setState(() {
                _selectedDamageType = value;
              });
            },
    );
  }

  Widget _buildUrgencyDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Urgency Level',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.priority_high),
      ),
      value: _selectedUrgency,
      items: _urgencyLevels.map((level) {
        return DropdownMenuItem(
          value: level,
          child: Text(level),
        );
      }).toList(),
      onChanged: _isLoading
          ? null
          : (value) {
              setState(() {
                _selectedUrgency = value;
              });
            },
    );
  }

  Widget _buildContactNumberField() {
    return TextFormField(
      controller: _contactController,
      decoration: const InputDecoration(
        labelText: 'Contact Number',
        hintText: 'Enter a valid phone number',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.phone),
      ),
      keyboardType: TextInputType.phone,
      enabled: !_isLoading,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a contact number';
        }
        if (value.length < 10) {
          return 'Contact number must be at least 10 digits';
        }
        return null;
      },
    );
  }

  Widget _buildAdditionalNotesField() {
    return TextFormField(
      controller: _notesController,
      decoration: const InputDecoration(
        labelText: 'Additional Notes (Optional)',
        hintText: 'e.g. Trapped on rooftop, need medical assistance',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.note),
      ),
      maxLines: 3,
      enabled: !_isLoading,
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _submitSOS,
      icon: const Icon(Icons.sos, size: 32),
      label: const Text('SEND SOS'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        textStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
