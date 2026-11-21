import 'package:flutter_test/flutter_test.dart';
import 'package:kiosk_ps/models/staff_report_model.dart';

void main() {
  test('StaffReportModel mem-parse laporan per petugas', () {
    final report = StaffReportModel.fromJson({
      'period': {
        'startDate': '2026-11-22',
        'endDate': '2026-11-22',
        'totalDays': 1,
      },
      'staff': [
        {
          'userId': 'u1',
          'username': 'kasir1',
          'fullName': 'Kasir Satu',
          'role': 'kasir',
          'days': [
            {
              'date': '2026-11-22',
              'sessions': [
                {
                  'loginAt': '2026-11-22T02:00:00Z',
                  'logoutAt': '2026-11-22T10:00:00Z',
                  'durationMinutes': 480,
                  'stillLoggedIn': false,
                }
              ],
              'revenue': {
                'rental': 100000,
                'food': 20000,
                'dailyRental': 50000,
                'membership': 25000,
                'game': 0,
                'total': 195000,
                'rentalTrx': 2,
                'foodTrx': 1,
                'dailyRentalTrx': 1,
                'membershipTrx': 1,
                'gameTrx': 0,
                'totalTrx': 5,
              },
            }
          ],
          'totals': {
            'total': 195000,
            'totalTrx': 5,
          },
        }
      ],
    });

    expect(report.period.totalDays, 1);
    expect(report.staff, hasLength(1));
    expect(report.staff.first.username, 'kasir1');
    expect(report.staff.first.days.first.sessions.first.durationMinutes, 480);
    expect(report.staff.first.days.first.revenue.total, 195000);
    expect(report.staff.first.totals.totalTrx, 5);
  });
}
