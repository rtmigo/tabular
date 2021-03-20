// SPDX-FileCopyrightText: (c) 2021 Art Galkin <github.com/rtmigo>
// SPDX-License-Identifier: MIT

import 'dart:math';

import 'package:quiver/iterables.dart' show enumerate;

/// Sets the cell alignment. In the case of horizontal alignment, [Side.start] means left,
/// [Side.end] means right.
enum Side { start, end, center }

/// Describes the rules by which an individual column should be aligned.
class Align {
  Align(this.column, this.side);

  /// Identifies the column that we are sorting. This can be either [int],
  /// which specifies the column index, or [String], which specifies
  /// the column name.
  final dynamic column;

  /// Specifies which way each column cell should be shifted after converting
  /// the cell value to [String].
  final Side side;
}

/// Describes the rules by which an individual column should be sorted.
class Sort {
  Sort(this.column, {this.ascending = true, this.emptyFirst = false});

  /// Identifies the column that we are sorting. This can be either [int],
  /// which specifies the column index, or [String], which specifies
  /// the column name.
  dynamic column;

  /// Defines the sort order of cells that have values. That is, cells that are
  /// not null or not an empty string.
  final bool ascending;

  /// Specifies whether the empty values should be placed at the beginning
  /// or at the end of the sorted column.
  final bool emptyFirst;
}

String alignText(String text, int targetWidth, Side align) {
  switch (align) {
    case Side.start:
      return text.padRight(targetWidth);
    case Side.end:
      return text.padLeft(targetWidth);
    case Side.center:
      return alignTextCenter(text, targetWidth);
  }
}

String alignTextCenter(String text, int targetWidth) {
  final half = (targetWidth - text.length) >> 1;
  text = text.padLeft(text.length + half);
  text = text.padRight(targetWidth);
  return text;
}

/// Specifies how to convert the source value of the cell to a [String].
typedef FormatCell = String Function(dynamic value);

class Cell implements Comparable<Cell> {
  Cell(this.rawCell, {this.nullReplacement = ''});

  final dynamic rawCell;
  final String nullReplacement;
  FormatCell? format;

  @override
  String toString() {
    if (rawCell == null) {
      return nullReplacement;
    } else {
      return rawCell.toString();
    }
  }

  String toFinalString() {
    // todo cache
    if (this.format != null) {
      return this.format!(this.rawCell);
    }
    return this.toString();
  }

  bool get isEmpty {
    return this.rawCell == null || this.rawCell.toString().isEmpty;
  }

  bool isNumber() {
    if (rawCell == null || rawCell == '' || rawCell is num) {
      return true;
    }

    final s = rawCell.toString();

    return int.tryParse(s) != null || double.tryParse(s) != null;
  }

  Side guessAlign() {
    return isNumber() ? Side.end : Side.start;
  }

  num? tryGetNum() {
    // todo cache
    if (this.rawCell is num) {
      return this.rawCell;
    }
    return int.tryParse(this.rawCell.toString()) ?? double.tryParse(this.rawCell.toString());
  }

  @override
  int compareTo(Cell other) {
    num? thisNum = this.tryGetNum();
    if (thisNum != null) {
      num? otherNum = other.tryGetNum();
      if (otherNum != null) {
        return thisNum.compareTo(otherNum);
      }
    }
    // todo null
    return this.toString().compareTo(other.toString());
  }
}

class CellsColumn {
  CellsColumn(this.matrix, this.index) {
    if (cells.length <= 1) {
      throw ArgumentError.value(cells.length, 'cells.length');
    }
  }

  final int index;
  final CellsMatrix matrix;

  Iterable<Cell> get cells sync* {
    for (var i = 0; i < matrix.rows.length; ++i) {
      yield this.matrix.rows[i][this.index];
    }
  }

  int get textWidth {
    // todo cache
    return this.cells.map<int>((cell) => cell.toFinalString().length).reduce(max);
  }

  Side guessAlign() {
    Side? result;

    for (final cell in this.cells.skip(1)) {
      if (result == null) {
        result = cell.guessAlign();
      } else if (cell.guessAlign() != result) {
        return Side.start; // default
      }
    }

    result ??= Side.start;
    return result;
  }
}

class CellsMatrix {
  CellsMatrix(List<List<dynamic>> rawRows, Map<dynamic, FormatCell>? format) {
    if (rawRows.length <= 1) {
      throw ArgumentError.value(rawRows.length, 'rawRows.length',
          'Must contain at least two items: the header and the first row.');
    }

    // determining the maximum count of cells in each row
    final columnsCount = rawRows.map<int>((r) => r.length).reduce(max);

    if (columnsCount <= 0) {
      throw ArgumentError('rawRows contains zero columns.');
    }

    // creating [rows] field
    for (final srcRow in rawRows) {
      // copying raw cell data into list on Cells

      final newRow = srcRow.map((raw) => Cell(raw)).toList();
      // adding empty cells to the end of the row, if needed
      while (newRow.length < columnsCount) {
        newRow.add(Cell(null));
      }
      this.rows.add(newRow);
    }

    // creating the columns list
    for (var i = 0; i < columnsCount; ++i) {
      this.columns.add(CellsColumn(this, i));
    }

    // now, with [rows] initialized we have [header],
    // so we can locate columns by their dynamic identifiers.
    // We also have now have [columns]
    if (format != null) {
      for (final me in format.entries) {
        final iCol = this.columnIndex(me.key);
        for (final cell in this.columns[iCol].cells.skip(1)) {
          cell.format = me.value;
        }
      }
    }

    assert(this.rows.isNotEmpty);
  }

  List<Cell> get header => rows[0];

  List<List<Cell>> rows = <List<Cell>>[];

  Iterable<Cell> iterCellsByColumn(int columnIdx) sync* {
    for (var i = 0; i < rows.length; ++i) {
      yield rows[i][columnIdx];
    }
  }

  List<CellsColumn> columns = <CellsColumn>[];

  int columnIndex(dynamic col) {
    if (col is int) {
      return col;
    }
    String colStr = col.toString();
    for (var me in enumerate(header)) {
      if (me.value.toString() == colStr) {
        return me.index;
      }
    }
    throw ArgumentError.value(col, 'col', 'Column not found.');
  }

  void sortBy(List<Sort> rules) {
    if (this.columns.isEmpty) {
      return;
    }

    final indexedRules =
        rules.map((e) => MapEntry<int, Sort>(this.columnIndex(e.column), e)).toList();

    // replacing header with empty placeholder
    final temporaryRemovedHeader = this.rows[0];
    this.rows[0] = [];
    // since this.columnsCount>0, only a placeholder can be an empty row

    try {
      this.rows.sort((rowA, rowB) {
        if (rowA.isEmpty) {
          // header placeholder
          return -1;
        }

        if (rowB.isEmpty) {
          // header placeholder
          return 1;
        }

        for (final entry in indexedRules) {
          int columnIndex = entry.key;
          Sort rule = entry.value;

          final A_IS_SMALLER = rule.ascending ? -1 : 1;
          final A_IS_LARGER = rule.ascending ? 1 : -1;

          var cell1 = rowA[columnIndex];
          var cell2 = rowB[columnIndex];

          if (cell1.isEmpty || cell2.isEmpty) {
            if (cell1.isEmpty && cell2.isEmpty) {
              continue;
            }
            return cell1.isEmpty ? (rule.emptyFirst ? -1 : 1) : (rule.emptyFirst ? 1 : -1);
          }

          int cmp = cell1.compareTo(cell2);
          if (cmp == 0) {
            continue;
          }
          if (cmp > 0) {
            return A_IS_LARGER;
          }
          return A_IS_SMALLER;
        }
        ;
        return 0;
      });
    } finally {
      this.rows[0] = temporaryRemovedHeader;
    }
  }
}

/// @param rowsOnly Rows to be sorted (without the header).
/// @param columnIndexes Determines the sorting order. `[2,-3,1]` means, that rows must
/// be sorted by column 2 ascending, or -3 descending, or 1 ascending.
void sortRo(List<List<dynamic>> rowsOnly, List<int> columnIndexes1based) {
  rowsOnly.sort((row1, row2) {
    for (final colIndex1based in columnIndexes1based) {
      if (colIndex1based == 0) {
        throw ArgumentError.value(colIndex1based, 'colIndex');
      }
      var idx = colIndex1based.abs() - 1;
      var cell1 = row1[idx];
      var cell2 = row2[idx];

      if (cell1 == cell2) {
        continue;
      }
      if (cell1 > cell2) {
        return colIndex1based.sign;
      }
      return -colIndex1based.sign;
    }
    ;
    return 0;
  });
}

extension ListExt<T> on List<T> {
  void setFilling(int index, T value, T empty) {
    while (this.length < index) {
      this.add(empty);
    }
    if (this.length > index) {
      this[index] = value;
    } else {
      this.add(value);
    }
  }

  T tryGet(int index, T empty) {
    return (this.length > index) ? this[index] : empty;
  }
}

/// Transforms a map with optional alignment rules to a list will all elements set.
/// @returns A `result` list such as `result[columnIndex]` is the alignment for the column.
List<Side> createColToAlign<T>(CellsMatrix matrix, Map<dynamic, Side>? align) {
  List<Side?> colToAlignNullable = <Side?>[];
  if (align != null) {
    for (final me in align.entries) {
      int iCol = matrix.columnIndex(me.key);
      colToAlignNullable.setFilling(iCol, me.value, null);
    }
  }
  for (var iCol = 0; iCol < matrix.columns.length; iCol++) {
    if (colToAlignNullable.tryGet(iCol, null) == null) {
      colToAlignNullable.setFilling(iCol, matrix.columns[iCol].guessAlign(), null);
    }
  }

  List<Side> colToAlign = colToAlignNullable.map((e) => e!).toList();

  return colToAlign;
}

/// Converts a set of cells defined by a two-dimensional list to a Markdown formatted ASCII table.
///
/// @param rows Source data for the table. The first of the lists will be the header, the
/// others - ordinary lines. The values can be [String]s, [num]s, [null], or any objects. Either
/// way, they end up being converted to strings.
///
/// @param align Specifies which way all cells in a particular column should be aligned. The keys
/// of this [Map] can be of type [int] then they denote the index of the column, or of type
/// [String] - then they denote the name of the column.
///
/// @param format Specifies how to convert each cell of a particular column to a row.
/// This conversion occurs after sorting, but before alignment. The keys of this [Map] can be
/// of type [int] then they denote the index of the column, or of type [String] - then they
/// denote the name of the column.
///
/// @param sort Determines the sorting order. Sorting can take place in several columns at once.
/// Priority will be given to the ones at the beginning of the list.
///
/// @param markdownAlign Determines whether to add the ':' characters to the delimiter under
/// the header. These symbols tell services like GitHub which way to align the columns after
/// converting the table to HTML.
///
/// @param outerBorder Determines whether to add vertical borders to the left and right sides
/// of the table.
///
/// @returns A string containing a converted ASCII table that is ready for printing.
String tabular(List<List<dynamic>> rows,
    {Map<dynamic, Side>? align,
    Map<dynamic, FormatCell>? format,
    List<Sort>? sort,
    markdownAlign = false,
    outerBorder = false}) {
  final matrix = CellsMatrix(rows, format);

  if (sort != null) {
    matrix.sortBy(sort);
  }

  List<Side> colToAlign = createColToAlign(matrix, align);

  String bar = '';
  if (outerBorder) {
    bar += '|';
  }
  for (int i = 0; i < matrix.columns.length; ++i) {
    final align = markdownAlign ? colToAlign[i] : null;
    final width = matrix.columns[i].textWidth;

    final bool isFirstColumn = i == 0;
    final bool isLastColumn = i == matrix.columns.length - 1;

    int extra = ((isFirstColumn || isLastColumn) && !outerBorder) ? -1 : 0;

    switch (align) {
      case null:
      case Side.start:
        bar += ('-' * (width + 2 + extra));
        break;
      case Side.end:
        bar += ('-' * (width + 1 + extra) + ':');
        break;
      case Side.center:
        bar += (':' + '-' * width + ':');
    }

    if (outerBorder || !isLastColumn) {
      bar += '|';
    }
  }

  final formattedRows = <String>[];

  var iRow = -1;
  for (var row in matrix.rows) {
    iRow++;

    if (iRow == 1) {
      formattedRows.add(bar);
    }

    var formatted = '';

    var iCol = -1;

    for (final me in enumerate(row)) {
      final cell = me.value;
      if (me.index == 0) {
        if (outerBorder) {
          formatted += '| ';
        }
      } else {
        formatted += ' | ';
      }
      iCol++;
      formatted +=
          alignText(cell.toFinalString(), matrix.columns[iCol].textWidth, colToAlign[iCol]);
    }

    if (outerBorder) {
      formatted += ' |';
    }

    formattedRows.add(formatted);
  }

  return formattedRows.join('\n');
}
