import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../widgets/custom_button.dart';

class ReportPrioritizationScreen extends StatefulWidget {
  const ReportPrioritizationScreen({super.key});

  @override
  State<ReportPrioritizationScreen> createState() => _ReportPrioritizationScreenState();
}

class _ReportPrioritizationScreenState extends State<ReportPrioritizationScreen> with SingleTickerProviderStateMixin {
  // Tab controller for different priority views
  late TabController _tabController;
  
  // Selected filter
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Today', 'This Week', 'This Month'];
  
  // Statistics
  int _totalReports = 0;
  int _highPriority = 0;
  int _mediumPriority = 0;
  int _lowPriority = 0;
  int _resolvedReports = 0;
  
  // Sample reports data
  List<Map<String, dynamic>> _reports = [
    {
      'id': 'RPT001',
      'title': 'Armed Robbery at Bank',
      'category': 'Robbery',
      'location': 'Main Branch, Downtown',
      'time': '10 minutes ago',
      'priority': 'High',
      'status': 'Pending',
      'description': 'Two masked men armed with guns robbed the bank. They escaped with cash.',
      'keywords': ['gun', 'weapon', 'robbery', 'armed', 'escape'],
      'aiScore': 95,
    },
    {
      'id': 'RPT002',
      'title': 'Street Harassment Incident',
      'category': 'Harassment',
      'location': 'Market Area',
      'time': '25 minutes ago',
      'priority': 'High',
      'status': 'In Progress',
      'description': 'Group of men harassing women near the market. Using inappropriate language.',
      'keywords': ['harassment', 'group', 'women', 'abuse'],
      'aiScore': 88,
    },
    {
      'id': 'RPT003',
      'title': 'Suspicious Package Found',
      'category': 'Suspicious Activity',
      'location': 'Bus Terminal',
      'time': '1 hour ago',
      'priority': 'High',
      'status': 'Pending',
      'description': 'Unattended bag found at platform. Security alerted.',
      'keywords': ['bomb', 'suspicious', 'bag', 'terminal', 'security'],
      'aiScore': 92,
    },
    {
      'id': 'RPT004',
      'title': 'Phone Snatching',
      'category': 'Snatching',
      'location': 'Metro Station',
      'time': '2 hours ago',
      'priority': 'Medium',
      'status': 'Pending',
      'description': 'Man on motorcycle snatched phone from pedestrian.',
      'keywords': ['snatch', 'motorcycle', 'phone', 'theft'],
      'aiScore': 75,
    },
    {
      'id': 'RPT005',
      'title': 'Corruption Complaint',
      'category': 'Corruption',
      'location': 'Government Office',
      'time': '3 hours ago',
      'priority': 'Medium',
      'status': 'Under Review',
      'description': 'Officer demanding bribe for document approval.',
      'keywords': ['bribe', 'corruption', 'officer', 'money'],
      'aiScore': 72,
    },
    {
      'id': 'RPT006',
      'title': 'Car Theft',
      'category': 'Theft',
      'location': 'Parking Lot',
      'time': '5 hours ago',
      'priority': 'Medium',
      'status': 'In Progress',
      'description': 'White Honda Civic stolen from parking lot.',
      'keywords': ['car', 'stolen', 'vehicle', 'honda'],
      'aiScore': 78,
    },
    {
      'id': 'RPT007',
      'title': 'Noise Complaint',
      'category': 'Disturbance',
      'location': 'Residential Area',
      'time': '6 hours ago',
      'priority': 'Low',
      'status': 'Resolved',
      'description': 'Loud music playing late at night.',
      'keywords': ['noise', 'music', 'disturbance', 'night'],
      'aiScore': 35,
    },
    {
      'id': 'RPT008',
      'title': 'Parking Issue',
      'category': 'Traffic',
      'location': 'Shopping Mall',
      'time': '8 hours ago',
      'priority': 'Low',
      'status': 'Resolved',
      'description': 'Car parked blocking entrance.',
      'keywords': ['parking', 'blocked', 'traffic', 'car'],
      'aiScore': 25,
    },
    {
      'id': 'RPT009',
      'title': 'Street Light Not Working',
      'category': 'Infrastructure',
      'location': 'Main Road',
      'time': '1 day ago',
      'priority': 'Low',
      'status': 'Pending',
      'description': 'Street light broken, area dark at night.',
      'keywords': ['light', 'broken', 'street', 'dark'],
      'aiScore': 15,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _calculateStatistics();
  }

  void _calculateStatistics() {
    _totalReports = _reports.length;
    _highPriority = _reports.where((r) => r['priority'] == 'High').length;
    _mediumPriority = _reports.where((r) => r['priority'] == 'Medium').length;
    _lowPriority = _reports.where((r) => r['priority'] == 'Low').length;
    _resolvedReports = _reports.where((r) => r['status'] == 'Resolved').length;
  }

  // Get color based on priority
  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Get icon based on category
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Robbery':
        return Iconsax.lock;
      case 'Harassment':
        return Iconsax.warning_2;
      case 'Suspicious Activity':
        return Iconsax.eye;
      case 'Snatching':
        return Iconsax.money;
      case 'Corruption':
        return Iconsax.money_tick;
      case 'Theft':
        return Iconsax.box_remove;
      case 'Disturbance':
        return Iconsax.volume_high;
      case 'Traffic':
        return Iconsax.car;
      case 'Infrastructure':
        return Iconsax.buildings;
      default:
        return Iconsax.note;
    }
  }

  // AI Analysis Dialog
  void _showAIAnalysis(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Iconsax.cpu, color: const Color(0xFF2563EB)),
            const SizedBox(width: 8),
            const Text('AI Priority Analysis'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getPriorityColor(report['priority']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.status,
                    color: _getPriorityColor(report['priority']),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AI Priority Score',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          '${report['priority']} Priority',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _getPriorityColor(report['priority']),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(report['priority']),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${report['aiScore']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 15),
            
            const Text(
              'Detected Keywords',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: (report['keywords'] as List<String>).map((keyword) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  keyword,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )).toList(),
            ),
            
            const SizedBox(height: 15),
            
            const Text(
              'NLP Analysis',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildAnalysisRow(
                    label: 'Threat Level',
                    value: report['aiScore'] > 80 ? 'Critical' : report['aiScore'] > 50 ? 'Moderate' : 'Low',
                    color: report['aiScore'] > 80 ? Colors.red : report['aiScore'] > 50 ? Colors.orange : Colors.green,
                  ),
                  const Divider(height: 8),
                  _buildAnalysisRow(
                    label: 'Urgency',
                    value: report['priority'],
                    color: _getPriorityColor(report['priority']),
                  ),
                  const Divider(height: 8),
                  _buildAnalysisRow(
                    label: 'Confidence',
                    value: '${report['aiScore']}%',
                    color: const Color(0xFF2563EB),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisRow({
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Prioritization'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'All Reports'),
            Tab(text: 'AI Analysis'),
            Tab(text: 'Statistics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // All Reports Tab
          _buildAllReportsTab(),
          
          // AI Analysis Tab
          _buildAIAnalysisTab(),
          
          // Statistics Tab
          _buildStatisticsTab(),
        ],
      ),
    );
  }

  // Tab 1: All Reports
  Widget _buildAllReportsTab() {
    return Column(
      children: [
        // Filter Row
        Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _filters.map((filter) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(filter),
                  selected: _selectedFilter == filter,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  backgroundColor: Colors.grey.shade100,
                  selectedColor: const Color(0xFF2563EB).withOpacity(0.2),
                  checkmarkColor: const Color(0xFF2563EB),
                  labelStyle: TextStyle(
                    color: _selectedFilter == filter
                        ? const Color(0xFF2563EB)
                        : Colors.grey.shade700,
                    fontWeight: _selectedFilter == filter
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              )).toList(),
            ),
          ),
        ),

        // Stats Summary
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildStatChip('Total', _totalReports.toString(), Colors.blue),
              const SizedBox(width: 8),
              _buildStatChip('High', _highPriority.toString(), Colors.red),
              const SizedBox(width: 8),
              _buildStatChip('Medium', _mediumPriority.toString(), Colors.orange),
              const SizedBox(width: 8),
              _buildStatChip('Low', _lowPriority.toString(), Colors.green),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Reports List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _reports.length,
            itemBuilder: (context, index) {
              final report = _reports[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: InkWell(
                    onTap: () => _showAIAnalysis(report),
                    borderRadius: BorderRadius.circular(15),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(report['priority']).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _getCategoryIcon(report['category']),
                                  color: _getPriorityColor(report['priority']),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      report['title'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Iconsax.location,
                                          size: 12,
                                          color: Colors.grey.shade500,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            report['location'],
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: _getPriorityColor(report['priority']).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _getPriorityColor(report['priority']).withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _getPriorityColor(report['priority']),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      report['priority'],
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: _getPriorityColor(report['priority']),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            report['description'],
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Iconsax.clock,
                                    size: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    report['time'],
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: report['status'] == 'Resolved'
                                      ? Colors.green.shade100
                                      : report['status'] == 'In Progress'
                                          ? Colors.blue.shade100
                                          : Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  report['status'],
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: report['status'] == 'Resolved'
                                        ? Colors.green.shade700
                                        : report['status'] == 'In Progress'
                                            ? Colors.blue.shade700
                                            : Colors.orange.shade700,
                                  ),
                                ),
                              ),
                            ],
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

  // Tab 2: AI Analysis
  Widget _buildAIAnalysisTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'AI Priority Classification',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Reports automatically classified using NLP keyword analysis',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Priority Distribution
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
                  'Priority Distribution',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                
                _buildPriorityBar('High', _highPriority, _totalReports, Colors.red),
                const SizedBox(height: 10),
                _buildPriorityBar('Medium', _mediumPriority, _totalReports, Colors.orange),
                const SizedBox(height: 10),
                _buildPriorityBar('Low', _lowPriority, _totalReports, Colors.green),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Keyword Analysis
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
                  'Top Keywords Detected',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                
                _buildKeywordRow('gun', 12, Colors.red),
                _buildKeywordRow('robbery', 10, Colors.red),
                _buildKeywordRow('harassment', 8, Colors.orange),
                _buildKeywordRow('snatching', 7, Colors.orange),
                _buildKeywordRow('corruption', 6, Colors.orange),
                _buildKeywordRow('theft', 5, Colors.green),
                _buildKeywordRow('noise', 4, Colors.green),
                _buildKeywordRow('parking', 3, Colors.green),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // NLP Explanation
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildNLPFeature(
                  icon: Iconsax.search_normal,
                  title: 'Keyword Extraction',
                  description: 'Identifies threat-related keywords in reports',
                ),
                const Divider(),
                _buildNLPFeature(
                  icon: Iconsax.weight,
                  title: 'Sentiment Analysis',
                  description: 'Analyzes urgency and emotional tone',
                ),
                const Divider(),
                _buildNLPFeature(
                  icon: Iconsax.category,
                  title: 'Context Classification',
                  description: 'Categorizes based on incident type',
                ),
                const Divider(),
                _buildNLPFeature(
                  icon: Iconsax.graph,
                  title: 'Priority Scoring',
                  description: 'Calculates priority score (0-100)',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Tab 3: Statistics
  Widget _buildStatisticsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Stats Cards
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.2,
          children: [
            _buildStatCard(
              'Total Reports',
              _totalReports.toString(),
              Iconsax.document,
              Colors.blue,
              'All time',
            ),
            _buildStatCard(
              'High Priority',
              _highPriority.toString(),
              Iconsax.warning_2,
              Colors.red,
              '${((_highPriority / _totalReports) * 100).toStringAsFixed(1)}%',
            ),
            _buildStatCard(
              'Medium Priority',
              _mediumPriority.toString(),
              Iconsax.status,
              Colors.orange,
              '${((_mediumPriority / _totalReports) * 100).toStringAsFixed(1)}%',
            ),
            _buildStatCard(
              'Low Priority',
              _lowPriority.toString(),
              Iconsax.tick_circle,
              Colors.green,
              '${((_lowPriority / _totalReports) * 100).toStringAsFixed(1)}%',
            ),
            _buildStatCard(
              'Resolved',
              _resolvedReports.toString(),
              Iconsax.tick_circle,
              Colors.green,
              '${((_resolvedReports / _totalReports) * 100).toStringAsFixed(1)}%',
            ),
            _buildStatCard(
              'Pending',
              (_totalReports - _resolvedReports).toString(),
              Iconsax.clock,
              Colors.orange,
              'Needs attention',
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Response Time Chart
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
                  'Average Response Time',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                
                _buildResponseRow('High Priority', '8 min', 0.9, Colors.red),
                const SizedBox(height: 8),
                _buildResponseRow('Medium Priority', '25 min', 0.6, Colors.orange),
                const SizedBox(height: 8),
                _buildResponseRow('Low Priority', '2 hours', 0.3, Colors.green),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Category Distribution
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
                  'Reports by Category',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                
                _buildCategoryRow('Robbery', 1, Colors.red),
                _buildCategoryRow('Harassment', 1, Colors.orange),
                _buildCategoryRow('Snatching', 1, Colors.orange),
                _buildCategoryRow('Theft', 1, Colors.orange),
                _buildCategoryRow('Corruption', 1, Colors.green),
                _buildCategoryRow('Disturbance', 1, Colors.green),
                _buildCategoryRow('Traffic', 1, Colors.green),
                _buildCategoryRow('Infrastructure', 1, Colors.green),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper Widgets
  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: color,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBar(String label, int count, int total, Color color) {
    double percentage = total > 0 ? count / total : 0;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
            Text(
              '$count reports (${(percentage * 100).toStringAsFixed(1)}%)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildKeywordRow(String keyword, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              keyword,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${count * 5} occurrences',
              style: TextStyle(
                fontSize: 10,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNLPFeature({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF2563EB), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseRow(String label, String time, double value, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              time,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
      ],
    );
  }

  Widget _buildCategoryRow(String category, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              category,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}