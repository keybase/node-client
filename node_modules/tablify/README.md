tablify
=======

In NodeJs programs, printing structured arrays to the console can be annoying. `tablify` fulfills your greatest desires.

It can generate a pretty table out of
 - an array of arrays
 - an array of dictionaries; this is perhaps the most common thanks to (no)SQL
 - a single dictionary, with each key/value pair getting a nice row
 - data with or without headers

For example, here's how tablify handles an array of arrays:

``` js

tablify = require('tablify').tablify
data = [
  [1,2,3]
  ["cat","dog",Math.PI]
]
console.log tablify data

```

Output:

```
---------------------------------
| 1   | 2   | 3                 |
| cat | dog | 3.141592653589793 |
---------------------------------
```

### Showing headers

If your structure has a header row, pass the optional "has_header" param:

``` js
data = [
  ["name","age"]
  ["Chris",10] 
  ["Max",8]
]
console.log tablify data, {has_header: true}
```

Output:

```
---------------
| name  | age |
---------------
| Chris | 10  |
| Max   | 8   |
---------------
```

### Even cooler: an array of dictionaries

Even with inconsistent keys, you can print an array of dictionaries. Column headers are calculated automatically using the union of all keys.

``` js
data = [
  {name: "Chris", age: 16, gender: "M"} 
  {name: "Max",   age: 12, gender: "M"}
  {name: "Sam",            gender: "F", colors: ["Orange", "Blue"]}
]
console.log tablify data
```

Output:

```
-------------------------------------------------
| # | age  | colors            | gender | name  |
-------------------------------------------------
| 0 | 16   |                   | M      | Chris |
| 1 | 12   |                   | M      | Max   |
| 2 |      | ["Orange","Blue"] | F      | Sam   |
-------------------------------------------------
```

### Selecting only specific keys:

```
console.log tablify data, {keys: ["age","name"]}
```

Output:

```
--------------------
| # | age  | name  |
--------------------
| 0 | 16   | Chris |
| 1 | 12   | Max   |
| 2 |      | Sam   |
--------------------
```

### A single dictionary:

If tablify is passed an object that's not an array, it will pivot to show keys in one column and values in another.

```
console.log tablify {"name": "Chris", "age": 25, "obj": [1,2,3,{"foo":"bar"}]}
```

Output:

```
--------------------------------
| age  | 25                    |
| name | Chris                 |
| obj  | [1,2,3,{"foo":"bar"}] |
--------------------------------
```

# List of Options 

Any subset of these can be passed as a second parameter to tablify, in a dictionary.

  - `show_index`   include a column showing the row number of each row. The default is `false` unless tablify is passed an array of dictionaries, in which case the default is `true`
  - `has_header`   include the first row as a header; this defaults to `false` unless passed an array of dicts, in which case the keys are used as a first row and this defaults to `true`; if passing a single dictionary, this is ignored
  - `keys`         which columns to use, when tablifying an array of dictionaries; by default all keys are used in alphabetical order
  - `row_start`    default = '| '
  - `row_end`      default = ' |'
  - `spacer`       default = ' | '
  - `row_sep_char` default = '-'



# Installation

```
> npm install -g tablify
```
