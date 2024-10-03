import 'package:flutter/material.dart';
import 'package:library_application/Pages/login.dart';
import 'package:library_application/Pages/book.dart';
import 'package:library_application/Pages/transcation.dart';
import 'package:library_application/Pages/user.dart';
import 'package:library_application/model/books.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; 

class DashboardScreen extends StatefulWidget {
  final String userName;
  final int userId;

  const DashboardScreen({
    super.key,
    required this.userName,
    required this.userId,
  });

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late List<ChartData> chartData = [];
  late bool dataLoaded = false;
  late DashboardStats _dashboardStats;
  
  @override
  void initState() {
    super.initState();
    fetchDataAndPopulateChart();
  }

  Future<void> fetchDataAndPopulateChart() async {
    final response = await http.get(Uri.parse('http://192.168.1.5:3000/books'));

    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      List<Book> bookList = jsonResponse.map((book) => Book.fromJson(book)).toList();

      Map<String, int> dayCount = {
        'Mon': 0,
        'Tue': 0,
        'Wed': 0,
        'Thu': 0,
        'Fri': 0,
        'Sat': 0,
        'Sun': 0,
      };

      int totalCopies = 0;
      int borrowedCopies = 0;
      int availableCopies = 0;
      int overdueCopies = 0;

      for (var book in bookList) {
        for (var copy in book.copies) {
          totalCopies++;

          print('Copy ID: ${copy.bookCopyId}, Status: ${copy.status}');

          if (copy.status.trim().toLowerCase() == 'available') {
            availableCopies++;
          } else if (copy.status.trim().toLowerCase() == 'borrowed') {
            borrowedCopies++;
            if (copy.dueDate != null && copy.dueDate!.isBefore(DateTime.now())) {
              overdueCopies++;
            }

            if (copy.dueDate != null) {
              String day = getDayFromDate(copy.dueDate!);
              dayCount[day] = (dayCount[day] ?? 0) + 1;
            }
          }
        }
      }
      // Update chartData for the bar chart
      setState(() {
        chartData = dayCount.entries.map((entry) => ChartData(entry.key, entry.value.toDouble())).toList();
        dataLoaded = true;
        _dashboardStats = DashboardStats(totalCopies, borrowedCopies, availableCopies, overdueCopies);
      });
    } else {
      throw Exception('Failed to load books');
    }
  }

  String getDayFromDate(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book),
            label: 'Books',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.brown,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
      backgroundColor: const Color.fromARGB(255, 255, 247, 242),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: dataLoaded
                ? _buildDashboard()
                : const Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return Column(
      children: [
        _buildUserInfo(),
        const SizedBox(height: 20),
        _buildStatsCards(),
        const SizedBox(height: 20),
        _buildPieChart(),
        const SizedBox(height: 20),
        _buildBarChart(),
      ],
    );
  }

  Widget _buildUserInfo() {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                "Welcome' ${widget.userName}",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          IconButton(
            alignment: Alignment.centerRight,
            iconSize: 30,
            icon: const Icon(Icons.exit_to_app),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(child: _buildStatCard('Total Books', _dashboardStats.totalBooks)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard('Borrowed', _dashboardStats.borrowedBooks)),
        const SizedBox(width: 10),
        Expanded(child: _buildStatCard('Overdue', _dashboardStats.overdueBooks)),
      ],
    );
  }

  Widget _buildStatCard(String label, int value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(247, 100, 70, 52),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromARGB(247, 100, 70, 52)),
        borderRadius: BorderRadius.circular(17),
      ),
      constraints: const BoxConstraints(
        maxHeight: 300,
      ),
      child: Center(
        child: SfCircularChart(
          legend: const Legend(isVisible: true),
          series: <PieSeries<_PieData, String>>[
            PieSeries<_PieData, String>(
              explode: true,
              explodeIndex: 0,
              radius: '100%',
              dataSource: [
                _PieData('Borrowed', _dashboardStats.borrowedBooks, '${_dashboardStats.borrowedBooks}'),
                _PieData('Available', _dashboardStats.availableBooks, '${_dashboardStats.availableBooks}'),
              ],
              xValueMapper: (_PieData data, _) => data.xData,
              yValueMapper: (_PieData data, _) => data.yData,
              dataLabelMapper: (_PieData data, _) => data.text,
              dataLabelSettings: const DataLabelSettings(isVisible: true),
              pointColorMapper: (_PieData data, _) => data.xData == 'Borrowed'
                  ? const Color.fromARGB(255, 142, 71, 71)
                  : const Color.fromARGB(255, 224, 135, 138),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color.fromARGB(247, 100, 70, 52)),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Center(
        child: SfCartesianChart(
          primaryXAxis: const CategoryAxis(),
          series: <CartesianSeries>[
            ColumnSeries<ChartData, String>(
              dataSource: chartData,
              xValueMapper: (ChartData data, _) => data.x,
              yValueMapper: (ChartData data, _) => data.y,
              color: Colors.brown[300],
              dataLabelSettings: const DataLabelSettings(isVisible: true),
            ),
          ],
        ),
      ),
    );
  }

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      switch (index) {
        case 0:
          // already here boss.
          break;
        case 1:
          Navigator.push(context, MaterialPageRoute(builder: (context) => BookGridScreen(userName: widget.userName, userId: widget.userId,)));
          break;
        case 2:
          Navigator.push(context, MaterialPageRoute(builder: (context) => Transaction(userName: widget.userName, userId: widget.userId)));
          break;
        case 3:
          Navigator.push(context, MaterialPageRoute(builder: (context) => UserListScreen(userName: widget.userName, userId: widget.userId)));
          break;
      }
    });
  }

}

class _PieData {
  _PieData(this.xData, this.yData, [this.text]);

  final String xData;
  final num yData;
  String? text;
}

class ChartData {
  ChartData(this.x, this.y);

  final String x;
  final double y;
}

class DashboardStats {
  final int totalBooks;
  final int borrowedBooks;
  final int availableBooks;
  final int overdueBooks;

  DashboardStats(this.totalBooks, this.borrowedBooks, this.availableBooks, this.overdueBooks);
}
