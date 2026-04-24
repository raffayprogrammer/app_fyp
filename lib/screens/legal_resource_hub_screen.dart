import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../widgets/custom_button.dart';

class LegalResourceHubScreen extends StatefulWidget {
  const LegalResourceHubScreen({super.key});

  @override
  State<LegalResourceHubScreen> createState() => _LegalResourceHubScreenState();
}

class _LegalResourceHubScreenState extends State<LegalResourceHubScreen>
    with SingleTickerProviderStateMixin {
  // Tab controller
  late TabController _tabController;

  // Search controller
  final TextEditingController _searchController = TextEditingController();

  // Selected category
  String _selectedCategory = 'All';

  // Chatbot messages
  List<Map<String, dynamic>> _chatMessages = [
    {
      'sender': 'bot',
      'message': 'Hello! I\'m your legal assistant. How can I help you today?',
      'time': '10:00 AM',
    },
    {
      'sender': 'bot',
      'message':
          'You can ask me about:\n• Legal rights\n• Complaint procedures\n• Self-defense tips\n• Evidence collection',
      'time': '10:00 AM',
    },
  ];

  final TextEditingController _chatController = TextEditingController();

  // Legal categories
  final List<Map<String, dynamic>> _legalCategories = [
    {'name': 'All', 'icon': Iconsax.category, 'color': Colors.blue},
    {'name': 'Rights', 'icon': Iconsax.shield_tick, 'color': Colors.green},
    {'name': 'Complaints', 'icon': Iconsax.document, 'color': Colors.orange},
    {'name': 'Self-Defense', 'icon': Iconsax.activity, 'color': Colors.purple},
    {'name': 'Evidence', 'icon': Iconsax.camera, 'color': Colors.red},
    {'name': 'Laws', 'icon': Iconsax.book, 'color': Colors.teal},
  ];

  // Legal resources data
  final List<Map<String, dynamic>> _legalResources = [
    {
      'title': 'Your Rights During Arrest',
      'category': 'Rights',
      'description':
          'Know what to do if you are arrested by police. Learn about your fundamental rights under the law.',
      'icon': Iconsax.shield_tick,
      'color': Colors.green,
      'content': '''
• Right to remain silent
• Right to know the reason for arrest
• Right to legal representation
• Right to inform family/friend
• Right to medical examination
• Right to be produced before magistrate within 24 hours
• Protection against self-incrimination
• Right to bail for bailable offenses
      ''',
      'steps': [
        'Stay calm and cooperative',
        'Ask for the reason of arrest',
        'Request to call your lawyer',
        'Inform your family members',
        'Do not sign anything without lawyer',
        'Remember the officer\'s name and badge number',
      ],
    },
    {
      'title': 'How to File an FIR',
      'category': 'Complaints',
      'description':
          'Step-by-step guide to filing a First Information Report (FIR) at the police station.',
      'icon': Iconsax.document,
      'color': Colors.orange,
      'content': '''
• FIR is the written document prepared by police when they receive information about a cognizable offense
• It is your right to have an FIR registered
• Free of cost service
• You are entitled to a free copy of the FIR
      ''',
      'steps': [
        'Go to the nearest police station',
        'Inform the officer in charge about the incident',
        'Provide all details: date, time, location, description',
        'The officer will write the FIR as you dictate',
        'Read it carefully before signing',
        'Ask for a free copy of the FIR',
        'If police refuse, contact a lawyer or higher authorities',
      ],
    },
    {
      'title': 'Self-Defense Basics',
      'category': 'Self-Defense',
      'description':
          'Essential self-defense techniques for personal safety in threatening situations.',
      'icon': Iconsax.activity,
      'color': Colors.purple,
      'content': '''
• Self-defense is a legal right to protect yourself from harm
• Use only reasonable force necessary
• Aim for vulnerable areas: eyes, nose, throat, groin
• Create distance and run to safety
• Attract attention by shouting
      ''',
      'steps': [
        'Stay aware of your surroundings',
        'Trust your instincts - if it feels wrong, leave',
        'Keep distance from suspicious individuals',
        'Learn basic strikes: palm strike, knee strike, elbow strike',
        'Target vulnerable areas: eyes, nose, throat, groin',
        'Use everyday objects as defense: keys, umbrella, bag',
        'Run to populated areas and shout for help',
      ],
    },
    {
      'title': 'Collecting Evidence',
      'category': 'Evidence',
      'description':
          'How to properly collect and preserve evidence after an incident.',
      'icon': Iconsax.camera,
      'color': Colors.red,
      'content': '''
• Evidence is crucial for legal proceedings
• Preserve all physical evidence
• Take photographs immediately
• Note down witness information
• Keep medical reports if injured
      ''',
      'steps': [
        'Take photos/videos of the scene',
        'Preserve any physical evidence',
        'Get contact details of witnesses',
        'Visit doctor for medical examination',
        'Keep all documents safe',
        'Note down exact date and time',
        'Save any CCTV footage locations',
      ],
    },
    {
      'title': 'Women Safety Laws',
      'category': 'Laws',
      'description':
          'Important legal protections and rights for women under Pakistani law.',
      'icon': Iconsax.book,
      'color': Colors.teal,
      'content': '''
• Protection against harassment at workplace
• Laws against domestic violence
• Right to equal pay
• Maternity benefits
• Protection against forced marriage
      ''',
      'steps': [
        'Workplace Harassment Law 2010',
        'Domestic Violence Prevention Act',
        'Acid Control and Acid Crime Prevention Act',
        'Women in Distress and Detention Fund',
        'Anti-Women Practices Act',
        'Honor Killing Laws',
      ],
    },
    {
      'title': 'Cyber Crime Reporting',
      'category': 'Complaints',
      'description':
          'How to report online harassment, fraud, and other cyber crimes.',
      'icon': Iconsax.mobile,
      'color': Colors.blue,
      'content': '''
• Cyber crimes include online harassment, fraud, identity theft
• Report to FIA Cyber Crime Wing
• Preserve all digital evidence
• Take screenshots of all communication
• Do not delete any messages
      ''',
      'steps': [
        'Save all evidence: screenshots, messages, emails',
        'Note down URLs and profiles',
        'Report to FIA Cyber Crime Wing',
        'Visit website: https://fia.gov.pk',
        'Call helpline: 1991',
        'Visit nearest FIA office',
        'Block the person on all platforms',
      ],
    },
    {
      'title': 'Traffic Violations',
      'category': 'Laws',
      'description':
          'Understanding traffic laws, fines, and your rights during traffic stops.',
      'icon': Iconsax.car,
      'color': Colors.amber,
      'content': '''
• Always carry driving license and documents
• Know traffic fines and penalties
• Rights during police traffic stop
• How to challenge unfair challans
• Insurance requirements
      ''',
      'steps': [
        'Keep license, registration, and documents handy',
        'Know speed limits in different areas',
        'Understand traffic signs',
        'Never drink and drive',
        'Wear seatbelt at all times',
        'Use indicators when turning',
        'Respect pedestrian crossings',
      ],
    },
    {
      'title': 'Emergency Contacts',
      'category': 'Rights',
      'description':
          'Important helpline numbers for emergencies and legal assistance.',
      'icon': Iconsax.call,
      'color': Colors.red,
      'content': '''
• Keep these numbers handy
• Save in your phone
• Share with family members
• Call immediately in emergency
      ''',
      'steps': [
        'Police Emergency: 15',
        'Ambulance: 115',
        'Fire Brigade: 16',
        'Women Helpline: 1099',
        'Child Protection: 1121',
        'Cyber Crime: 1991',
        'Anti-Narcotics: 111-555-555',
      ],
    },
  ];

  // Self-defense videos
  final List<Map<String, dynamic>> _selfDefenseVideos = [
    {
      'title': 'Basic Palm Strike',
      'duration': '2:30',
      'views': '12K',
      'level': 'Beginner',
    },
    {
      'title': 'Escape from Wrist Grab',
      'duration': '3:15',
      'views': '18K',
      'level': 'Beginner',
    },
    {
      'title': 'Defense Against Choke',
      'duration': '4:00',
      'views': '22K',
      'level': 'Intermediate',
    },
    {
      'title': 'Using Keys as Weapon',
      'duration': '2:45',
      'views': '15K',
      'level': 'Beginner',
    },
    {
      'title': 'Ground Defense Techniques',
      'duration': '5:20',
      'views': '25K',
      'level': 'Advanced',
    },
    {
      'title': 'Escaping Bear Hug',
      'duration': '3:30',
      'views': '14K',
      'level': 'Intermediate',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  // Send message in chatbot
  void _sendMessage() {
    if (_chatController.text.trim().isEmpty) return;

    setState(() {
      _chatMessages.add({
        'sender': 'user',
        'message': _chatController.text.trim(),
        'time':
            '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      });

      // Simulate bot response
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _chatMessages.add({
            'sender': 'bot',
            'message': _getBotResponse(_chatController.text.trim()),
            'time':
                '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
          });
        });
      });

      _chatController.clear();
    });
  }

  // Get bot response based on user input
  String _getBotResponse(String message) {
    String lowerMsg = message.toLowerCase();

    if (lowerMsg.contains('fir') || lowerMsg.contains('report')) {
      return 'To file an FIR:\n1. Go to nearest police station\n2. Provide incident details\n3. Get free copy of FIR\n4. If refused, contact a lawyer';
    } else if (lowerMsg.contains('right') || lowerMsg.contains('arrest')) {
      return 'Your rights during arrest:\n• Remain silent\n• Know reason for arrest\n• Call lawyer\n• Inform family\n• Medical examination';
    } else if (lowerMsg.contains('self defense') ||
        lowerMsg.contains('defend')) {
      return 'Self-defense tips:\n• Stay aware of surroundings\n• Target vulnerable areas\n• Create distance\n• Run to safety\n• Shout for help';
    } else if (lowerMsg.contains('evidence') || lowerMsg.contains('proof')) {
      return 'Evidence collection:\n• Take photos/videos\n• Preserve physical evidence\n• Get witness contacts\n• Medical reports\n• Save screenshots';
    } else if (lowerMsg.contains('helpline') || lowerMsg.contains('contact')) {
      return 'Emergency contacts:\nPolice: 15\nAmbulance: 115\nWomen Helpline: 1099\nCyber Crime: 1991';
    } else if (lowerMsg.contains('harassment')) {
      return 'For harassment:\n• Report to police\n• Save all evidence\n• Workplace Harassment Law 2010\n• Women Helpline: 1099';
    } else {
      return 'I can help you with:\n• Legal rights\n• Filing complaints\n• Self-defense tips\n• Evidence collection\n• Emergency contacts\nWhat would you like to know?';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Legal Resource Hub'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Resources'),
            Tab(text: 'Self-Defense'),
            Tab(text: 'Legal Assistant'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Resources Tab
          _buildResourcesTab(),

          // Self-Defense Tab
          _buildSelfDefenseTab(),

          // Legal Assistant Tab
          _buildLegalAssistantTab(),
        ],
      ),
    );
  }

  // Tab 1: Legal Resources
  Widget _buildResourcesTab() {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search legal resources...',
              prefixIcon: const Icon(Iconsax.search_normal),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),

        // Categories
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _legalCategories.length,
            itemBuilder: (context, index) {
              final category = _legalCategories[index];
              final isSelected = _selectedCategory == category['name'];

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category['name']),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = category['name'];
                    });
                  },
                  backgroundColor: Colors.grey.shade100,
                  selectedColor: category['color'].withOpacity(0.2),
                  checkmarkColor: category['color'],
                  avatar: Icon(
                    category['icon'],
                    color: isSelected ? category['color'] : Colors.grey,
                    size: 16,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? category['color']
                        : Colors.grey.shade700,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // Resources List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _legalResources
                .where(
                  (r) =>
                      _selectedCategory == 'All' ||
                      r['category'] == _selectedCategory,
                )
                .length,
            itemBuilder: (context, index) {
              final filteredResources = _legalResources
                  .where(
                    (r) =>
                        _selectedCategory == 'All' ||
                        r['category'] == _selectedCategory,
                  )
                  .toList();

              final resource = filteredResources[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: InkWell(
                    onTap: () => _showResourceDetails(resource),
                    borderRadius: BorderRadius.circular(15),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: resource['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              resource['icon'],
                              color: resource['color'],
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  resource['title'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  resource['description'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: resource['color'].withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    resource['category'],
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: resource['color'],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Tab 2: Self-Defense Videos
  Widget _buildSelfDefenseTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Featured Video
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: const DecorationImage(
              image: NetworkImage(
                'https://via.placeholder.com/400x200/2563EB/ffffff?text=Self-Defense+Tutorial',
              ),
              fit: BoxFit.cover,
            ),
          ),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                  ),
                ),
              ),
              const Positioned(
                bottom: 16,
                left: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Essential Self-Defense',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Complete guide for beginners',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Positioned(
                bottom: 16,
                right: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.play_arrow, color: Color(0xFF2563EB)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          'Video Tutorials',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(
          'Learn basic self-defense techniques',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),

        const SizedBox(height: 15),

        // Videos Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.8,
          ),
          itemCount: _selfDefenseVideos.length,
          itemBuilder: (context, index) {
            final video = _selfDefenseVideos[index];
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        color: Colors.blue.shade100,
                        image: const DecorationImage(
                          image: NetworkImage(
                            'https://via.placeholder.com/200x150/2563EB/ffffff?text=Video',
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.5),
                                ],
                              ),
                            ),
                          ),
                          const Positioned(
                            bottom: 8,
                            right: 8,
                            child: CircleAvatar(
                              radius: 15,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.play_arrow,
                                size: 15,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade700,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                video['duration'],
                                style: const TextStyle(
                                  fontSize: 8,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video['title'],
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.visibility,
                                size: 8,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                video['views'],
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: video['level'] == 'Beginner'
                                      ? Colors.green.shade100
                                      : video['level'] == 'Intermediate'
                                      ? Colors.orange.shade100
                                      : Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  video['level'],
                                  style: TextStyle(
                                    fontSize: 6,
                                    fontWeight: FontWeight.bold,
                                    color: video['level'] == 'Beginner'
                                        ? Colors.green.shade700
                                        : video['level'] == 'Intermediate'
                                        ? Colors.orange.shade700
                                        : Colors.red.shade700,
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
            );
          },
        ),

        const SizedBox(height: 20),

        // Tips Section
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Self-Defense Tips',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 15),
                _buildTipRow(
                  icon: Iconsax.eye,
                  title: 'Stay Aware',
                  description: 'Always be alert of your surroundings',
                ),
                const SizedBox(height: 10),
                _buildTipRow(
                  icon: Iconsax.activity,
                  title: 'Create Distance',
                  description: 'Put space between you and threat',
                ),
                const SizedBox(height: 10),
                _buildTipRow(
                  icon: Iconsax.volume_high,
                  title: 'Make Noise',
                  description: 'Shout loudly to attract attention',
                ),
                const SizedBox(height: 10),
                _buildTipRow(
                  icon: Iconsax.flash,
                  title: 'Target Areas',
                  description: 'Eyes, nose, throat, groin',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Tab 3: Legal Assistant Chatbot
  Widget _buildLegalAssistantTab() {
    return Column(
      children: [
        // Chat Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withOpacity(0.1),
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.message,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Legal Assistant',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Ask me about legal rights and procedures',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Online',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Chat Messages
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _chatMessages.length,
            itemBuilder: (context, index) {
              final message = _chatMessages[index];
              final isBot = message['sender'] == 'bot';

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: isBot
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isBot) ...[
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(
                            0xFF2563EB,
                          ).withOpacity(0.1),
                          child: const Icon(
                            Iconsax.cpu,
                            size: 14,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ],
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isBot
                              ? Colors.grey.shade100
                              : const Color(0xFF2563EB),
                          borderRadius: BorderRadius.circular(15).copyWith(
                            bottomLeft: isBot ? const Radius.circular(5) : null,
                            bottomRight: !isBot
                                ? const Radius.circular(5)
                                : null,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message['message'],
                              style: TextStyle(
                                color: isBot ? Colors.black87 : Colors.white,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                message['time'],
                                style: TextStyle(
                                  fontSize: 8,
                                  color: isBot
                                      ? Colors.grey.shade500
                                      : Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!isBot) ...[
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey.shade200,
                        child: const Icon(
                          Icons.person,
                          size: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),

        // Suggested Questions
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          height: 60,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildSuggestionChip('How to file FIR?'),
              _buildSuggestionChip('My rights during arrest'),
              _buildSuggestionChip('Self-defense tips'),
              _buildSuggestionChip('Evidence collection'),
              _buildSuggestionChip('Emergency contacts'),
            ],
          ),
        ),

        // Message Input
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  decoration: InputDecoration(
                    hintText: 'Type your question...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF2563EB),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white, size: 18),
                  onPressed: _sendMessage,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onPressed: () {
          setState(() {
            _chatController.text = label;
          });
        },
        backgroundColor: Colors.grey.shade100,
      ),
    );
  }

  void _showResourceDetails(Map<String, dynamic> resource) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: resource['color'].withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        resource['icon'],
                        color: resource['color'],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            resource['title'],
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: resource['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              resource['category'],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: resource['color'],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      const Text(
                        'Overview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        resource['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Key Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          resource['content'],
                          style: const TextStyle(height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Step-by-Step Guide',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(resource['steps'].length, (index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: resource['color'].withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: resource['color'],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  resource['steps'][index],
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTipRow({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF2563EB), size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
