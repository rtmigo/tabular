import 'package:tabular/tabular.dart';

void main() {
  var data = [
    ['Season', '#', 'Name', 'Days', 'Sun'],
    ['Winter', 1, 'January', 31, 94],
    ['Winter', 2, 'February', 28, 123],
    ['Spring', 3, 'March', 31, 42],
    ['Spring', 4, 'April', 30, 243],
    ['Spring', 5, 'May', 31, 5523],
    ['Summer', 6, 'June', 30, 11251],
    ['Summer', 7, 'July', 31, 17451],
    ['Summer', 8, 'August', 31, 18707],
    ['Autumn', 9, 'September', 30, 7025],
    ['Autumn', 10, 'October', 31, 5041],
    ['Autumn', 11, 'November', 30, 2302],
    ['Winter', 12, 'December', 31, 258],
  ];

  String title(s) => '\n\n$s\n';

  print(title('JUST TABLE'));
  print(tabular(data));

  print(title('WITH BORDER'));
  print(tabular(data, outerBorder: true));

  print(title('WITH MARKDOWN ":"'));
  print(tabular(data, markdownAlign: true));

  print(title('WITH MODIFIED ALIGNMENT'));
  print(tabular(data, align: {'Days': Side.start, 'Name': Side.end}));


  print(title('SORTED BY FIRST COLUMN'));
  print(tabular(data, sort: [Sort(0)]));

  print(title('SORTED BY TWO COLUMNS "DAYS" AND "SUN"'));
  print(tabular(data, sort: [Sort('Days', ascending: false), Sort('Sun')]));
}
