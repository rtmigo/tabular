![Generic badge](https://img.shields.io/badge/status-draft-red.svg)
![Generic badge](https://img.shields.io/badge/tested_on-VM_|_JS-blue.svg)
[![Actions Status](https://github.com/rtmigo/tabular/workflows/unittest/badge.svg?branch=master)](https://github.com/rtmigo/tabular/actions)

# [tabular](https://github.com/rtmigo/tabular)

Converts Dart lists to a Markdown table.

``` dart
print(tabular([
  ['Winter',    'Spring', 'Summer', 'Autumn'],
  ['December',  'March',  'June',   'September'],
  ['January',   'April',  'July',   'October'],
  ['February',  'May',    'August', 'November']
]));
```
``` text
| Winter   | Spring | Summer | Autumn    |
|----------|--------|--------|-----------|
| December | March  | June   | September |
| January  | April  | July   | October   |
| February | May    | August | November  |
```

``` dart
print(tabular([
    ['Country', 'Islands'],
    ['Sweden', 221800],
    ['Finland', 188000],
    ['Norway', 55000],
    ['Canada', 52455],
    ['Indonesia', 17508],
    ['Japan', 6853],
]));
```

``` text
| Country    | Islands |
|-----------|---------|
| Sweden    |  221800 |
| Finland   |  188000 |
| Norway    |   55000 |
| Canada    |   52455 |
| Indonesia |   17508 |
| Japan     |    6853 |
```